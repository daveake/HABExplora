unit BLESource;

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  System.Bluetooth, System.Bluetooth.Components, Source, Classes, SysUtils, Miscellaneous;

type
  TBLESource = class(TSource)
  private
    { Private declarations }
    Commands: TStringList;
    DeviceName, ReceiveBuffer: String;
    BluetoothLE1: TBluetoothLE;
    SerialDevice: TBluetoothLEDevice;
    SerialService: TBluetoothGattService;
    procedure AddCommand(Command: String);
    procedure InitialiseDevice;
    procedure BluetoothLE1DiscoverLEDevice(const Sender: TObject;
      const ADevice: TBluetoothLEDevice; Rssi: Integer;
      const ScanResponse: TScanResponse);
    procedure BluetoothLE1EndDiscoverDevices(const Sender: TObject;
      const ADeviceList: TBluetoothLEDeviceList);
    procedure BluetoothLE1EndDiscoverServices(const Sender: TObject; const AServiceList: TBluetoothGattServiceList);
    procedure BluetoothLE1CharacteristicRead(const Sender: TObject;
      const ACharacteristic: TBluetoothGattCharacteristic;
      AGattStatus: TBluetoothGattStatus);
  protected
    { Protected declarations }
    procedure Execute; override;
    function ExtractPositionFrom(Line: String; PayloadID: String = ''): THABPosition; override;
  public
    { Public declarations }
    procedure SendSetting(SettingName, SettingValue: String); override;
  end;

implementation

procedure TBLESource.InitialiseDevice;
begin
    SendSetting('F', GetSettingString(GroupName, 'Frequency', '434.250'));
    SendSetting('M', GetSettingString(GroupName, 'Mode', '1'));
end;

procedure TBLESource.BluetoothLE1DiscoverLEDevice(
  const Sender: TObject; const ADevice: TBluetoothLEDevice; Rssi: Integer;
  const ScanResponse: TScanResponse);
var
    i, Index: Integer;
begin
    if SerialDevice = nil then begin
        for i := 0 to BluetoothLE1.DiscoveredDevices.Count-1 do begin
            if BluetoothLE1.DiscoveredDevices.Items[i].DeviceName = DeviceName then begin
                SendMessage('Found Device ' + DeviceName);
                SerialDevice := BluetoothLE1.DiscoveredDevices[i];
                Exit;
            end;
        end;
    end;
end;

procedure TBLESource.BluetoothLE1EndDiscoverDevices(const Sender: TObject;
  const ADeviceList: TBluetoothLEDeviceList);
begin
//    if SerialDevice <> nil then begin
//        SendMessage('Discovering Services');
//        BluetoothLE1.DiscoverServices(SerialDevice);
//    end;
end;

procedure TBLESource.BluetoothLE1EndDiscoverServices(const Sender: TObject;
  const AServiceList: TBluetoothGattServiceList);
var
    i: Integer;
    TempService: TBluetoothGattService;
begin
    TempService := nil;

    for i := 0 to AServiceList.Count-1 do begin
        if (AServiceList.Items[i].UUIDName = 'Key Service') or
           (AServiceList.Items[i].UUIDName = '') then begin
           // (AServiceList.Items[i].UUID.ToString = '{6E400001-B5A3-F393-E0A9-E50E24DCCA9E}') then begin
            try
                TempService := SerialDevice.GetService(AServiceList.Items[i].UUID);
            finally
            end;
        end;
    end;

    if TempService = nil then begin
        SendMessage(AServiceList.Count.ToString + ' services found');
    end else if TempService.Characteristics.Count = 0 then begin
        SendMessage('No characteristics found');
    end else begin
        try
            if BluetoothLE1.SubscribeToCharacteristic(SerialDevice, TempService.Characteristics[0]) then begin
                SerialService := TempService;
            end else begin
                SendMessage('Failed To Connect To Device');
            end;
        finally

        end;
    end;
end;

procedure TBLESource.BluetoothLE1CharacteristicRead(const Sender: TObject;
  const ACharacteristic: TBluetoothGattCharacteristic;
  AGattStatus: TBluetoothGattStatus);
var
    Temp: String;
    i, j: Integer;
begin
    j := Length(ACharacteristic.Value);
    Temp := '';

    for i := 0 to j-1 do begin
        Temp := Temp + Chr(ACharacteristic.GetValueAsInt8(i));
    end;

    ReceiveBuffer := ReceiveBuffer + Temp;
end;


procedure TBLESource.Execute;
var
    Position: THABPosition;
    i, TimeOut, LineBreak, NoDataTimeout: Integer;
    Connected: Boolean;
    Bytes: TBytes;
    Line: String;
begin
    SerialDevice := nil;
    SerialService := nil;

    Commands := TStringList.Create;

    BluetoothLE1 := TBluetoothLE.Create(nil);
    BluetoothLE1.Enabled := True;
    BluetoothLE1.OnDiscoverLEDevice := BluetoothLE1DiscoverLEDevice;
    BluetoothLE1.OnEndDiscoverServices := BluetoothLE1EndDiscoverServices;
    BluetoothLE1.OnCharacteristicRead := BluetoothLE1CharacteristicRead;

    while not Terminated do begin
        DeviceName := GetSettingString(GroupName, 'Device', '');
        // UUID := GetSettingString(GroupName, 'UUID', '');
        SetGroupChangedFlag(GroupName, False);

        if DeviceName = '' then begin
            SendMessage('No Device Selected');
            Sleep(1000);
        end else begin
            // Search for devices
            ReceiveBuffer := '';
            SerialDevice := nil;
            SerialService := nil;
            BluetoothLE1.DiscoverDevices(5000);
            Sleep(5000);

            if SerialDevice = nil then begin
                SendMessage('Cannot Connect To ' + DeviceName);
                Sleep(1000);
            end else begin
                SendMessage('Discovering Services');
                BluetoothLE1.DiscoverServices(SerialDevice);

                // Wait for connection
                TimeOut := 1000;
                while (SerialService = nil) and (TimeOut > 0) do begin
                    Sleep(100);
                    Dec(TimeOut);
                end;

                Sleep(1000);

                if SerialService = nil then begin
                    SendMessage('No Serial Service Found');
                end else begin
                    SendMessage('Connected To ' + DeviceName);
                    InitialiseDevice;

                    // While we're connected
                    NoDataTimeout := 0;
                    while SerialService <> nil do begin
                        // Received anything ?
                        if ReceiveBuffer <> '' then begin
                            NoDataTimeout := 0;
                            LineBreak := Pos(#13 + #10, ReceiveBuffer);
                            if LineBreak > 0 then begin
                                Line := Copy(ReceiveBuffer, 1, LineBreak-1);
                                ReceiveBuffer := Copy(ReceiveBuffer, LineBreak+2, Length(ReceiveBuffer));

                                Position := ExtractPositionFrom(Line);
                                SyncCallback(SourceID, True, '', Position);
                            end;
                        end;

                        // Anything to send ?
                        if Commands.Count > 0 then begin
                            try
                                SendMessage('Sending ' + Commands[0]);
                                Sleep(1000);
                                SerialService.Characteristics[0].SetValueAsString(Commands[0] + #13);
                                BluetoothLE1.WriteCharacteristic(SerialDevice, SerialService.Characteristics[0]);
                                Commands.Delete(0);
                                Sleep(1000);
                                SendMessage(' ');
                            except
                                // SerialService := nil;
                                // SendMessage('Disconnected From Device');
                            end;
                        end;

                        Sleep(10);
                        Inc(NoDataTimeout, 10);

                        // Device changed, or no data for 5 seconds
                        if (DeviceName <> GetSettingString(GroupName, 'Device', '')) or (NoDataTimeout > 5000) then begin
                            if BluetoothLE1.UnSubscribeToCharacteristic(SerialDevice, SerialService.Characteristics[0]) then begin
                                BluetoothLE1.ClearServices;
                                SerialDevice.Disconnect;
                                SendMessage('Disconnected From Device');

                                SerialService := nil;
                                SerialDevice := nil;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    end;
end;

function TBLESource.ExtractPositionFrom(Line: String; PayloadID: String = ''): THABPosition;
var
    Command: String;
    Position: THABPosition;
begin
    FillChar(Position, SizeOf(Position), 0);
    // Position.SignalValues := TSignalValues.Create;

    if Copy(Line, 1, 2) = '$$' then begin
        Line := 'MESSAGE=' + Line;
    end;

    Command := UpperCase(GetString(Line, '='));

    if Command = 'CURRENTRSSI' then begin
        Position.CurrentRSSI := StrToIntDef(Line, 0);
        Position.HasCurrentRSSI := True;
        SyncCallback(SourceID, True, '', Position);
    end else if Command = 'HEX' then begin
        // SSDV
        Line := '55' + Line;
        inherited;
    end else if Command = 'FREQERR' then begin
        Position.FrequencyError := StrToFloat(Line);
        Position.HasFrequency := True;
        SyncCallback(SourceID, True, '', Position);
    end else if Command = 'PACKETRSSI' then begin
        // Position.SignalValues.Add('PacketRSSI', StrToIntDef(Line, 0));
        Position.PacketRSSI := StrToIntDef(Line, 0);
        Position.HasPacketRSSI := True;
        SyncCallback(SourceID, True, '', Position);
    end else if Command = 'PACKETSNR' then begin
        // Position.SignalValues.Add('PacketSNR', StrToIntDef(Line, 0));
        SyncCallback(SourceID, True, '', Position);
    end else if Command = 'MESSAGE' then begin
        Position := inherited;
    end;

    Result := Position;
end;

procedure TBLESource.SendSetting(SettingName, SettingValue: String);
begin
    if SettingValue <> '' then begin
        AddCommand('~' + SettingName + SettingValue);
    end;
end;

procedure TBLESource.AddCommand(Command: String);
begin
    Commands.Add(Command);
end;

end.
