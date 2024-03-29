unit SourcesForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, Math, Sondehub,
  GPSSource, Source, Base, Miscellaneous, SSDV, SourceForm, Uploaders,
  SerialSource, BluetoothSource, BLESource, UDPSource, WSMQTTSource,
  System.DateUtils, System.TimeSpan, System.Sensors, System.Sensors.Components,
  IdUDPServer, IdGlobal, IdSocketHandle, IdBaseComponent, IdComponent, IdUDPBase,
  IdUDPClient;

type
  TSourcePanel = record
      Source: TSource;
      Form:             TfrmSource;
//      ValueLabel:       TLabel;
//      RSSILabel:        TLabel;
//      PacketRSSILabel:  TLabel;
//      FreqLabel:        TLabel;
      PacketCount:      Integer;
      FrequencyError:   Double;
      Version:          String;
      ConnectInfo:      String;
      Device:           String;
      PacketRSSI:       String;
      PacketStatus:     String;
      HadAPosition:     Boolean;
  end;

type
    TGPSPosition = record
        Latitude, Longitude:  Double;
    end;

type
  TfrmSources = class(TfrmBase)
    LocationSensor: TLocationSensor;
    tmrGPS: TTimer;
    rectGPS: TRectangle;
    rectSH: TRectangle;
    rectUSB: TRectangle;
    rectBT: TRectangle;
    UDPClient: TIdUDPClient;
    MotionSensor1: TMotionSensor;
    OrientationSensor1: TOrientationSensor;
    rectUDP: TRectangle;
    procedure FormCreate(Sender: TObject);
    procedure tmrGPSTimer(Sender: TObject);
    procedure UDPServerUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure OrientationSensor1SensorChoosing(Sender: TObject;
      const Sensors: TSensorArray; var ChoseSensorIndex: Integer);
    procedure FormDestroy(Sender: TObject);
    procedure pnlMainResize(Sender: TObject);
    // procedure Label11Click(Sender: TObject);
    // procedure Label3Click(Sender: TObject);
  private
    { Private declarations }
    CompassPresent: Boolean;
    MagneticHeading, Declination: Double;
    SondehubUploader: TSondehubThread;
    SSDVUploader: TSSDVThread;
    Sources: Array[0..8] of TSourcePanel;
    GPSCount: Integer;
{$IFDEF MSWINDOWS}
    procedure GPSCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
{$ENDIF}
    procedure CloseThread(Thread: TThread);
    procedure WaitForThread(Thread: TThread);
    function GetMagneticHeading: Double;
    procedure NewGPSPosition(Timestamp: TDateTime; Latitude, Longitude, Altitude, Direction: Double; UsingCompass: Boolean);
    procedure HABCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
    // procedure CarStatusCallback(SourceID: Integer; Active, OK: Boolean; Status: String);
    procedure SondehubStatusCallback(SourceID: Integer; Active, OK: Boolean; Status: String);
  public
    { Public declarations }
    procedure UpdatePayloadList(PayloadList: String);
    procedure SendParameterToSource(SourceIndex: Integer; ValueName, Value: String);
    procedure EnableGPS;
    procedure EnableCompass;
    function GetPacketCount(SourceIndex: Integer): Integer;
    procedure ResetPacketCount(SourceIndex: Integer);
    function FrequencyError(SourceIndex: Integer): Double;
    procedure SendUplink(SourceIndex: Integer; When: TUplinkWhen; WhenValue, Channel: Integer; Prefix, Msg, Password: String);
    function WaitingToSend(SourceIndex: Integer): Boolean;
    procedure UpdateCarUploadSettings;
    procedure SetGPSStatus(Status: String);
end;

var
  frmSources: TfrmSources;

implementation

uses Main, Misc, Debug;

{$R *.fmx}

procedure TfrmSources.EnableGPS;
begin
    if not LocationSensor.Active then begin
        LocationSensor.Active := True;
        tmrGPS.Enabled := True;
    end;
end;

procedure TfrmSources.FormCreate(Sender: TObject);
begin
    inherited;

    // Sondehub uploader
    SondehubUploader := TSondehubThread.Create(SondehubStatusCallback);
    UpdateCarUploadSettings;

    // SSDV Uploader
    SSDVUploader := TSSDVThread.Create(nil);

    // GPS Source
    Sources[GPS_SOURCE].Form := TfrmSource.Create(Self);
    Sources[GPS_SOURCE].Form.pnlMain.Parent := rectGPS;
    Sources[GPS_SOURCE].Form.lblPacketInfo.Visible := True;
    Sources[GPS_SOURCE].Form.lblCaption.Text := 'GPS Source';
    Sources[GPS_SOURCE].Form.frmLog.lblCaption.Text := 'GPS Log';
{$IFDEF MSWINDOWS}
    Sources[GPS_SOURCE].Source := TGPSSource.Create(GPS_SOURCE, 'GPS', GPSCallback);
{$ENDIF}

    // USB LoRa device
    {$IF Defined(MSWINDOWS) or Defined(ANDROID)}
        Sources[SERIAL_SOURCE].Form := TfrmSource.Create(Self);
        Sources[SERIAL_SOURCE].Form.pnlMain.Parent := rectUSB;
        Sources[SERIAL_SOURCE].Form.lblFrequencyError.Visible := True;
        Sources[SERIAL_SOURCE].Form.lblPacketInfo.Visible := True;
        Sources[SERIAL_SOURCE].Form.lblRSSI.Visible := True;
        Sources[SERIAL_SOURCE].Form.lblCaption.Text := 'USB LoRa Telemetry';
        Sources[SERIAL_SOURCE].Form.frmLog.lblCaption.Text := 'USB LoRa Telemetry Log';
        Sources[SERIAL_SOURCE].Source := TSerialSource.Create(SERIAL_SOURCE, 'LoRaSerial', HABCallback);
    {$ELSE}
        // Label11.Text := '';
    {$ENDIF}

    // BT/BLE LoRa device
    Sources[BLUETOOTH_SOURCE].Form := TfrmSource.Create(Self);
    Sources[BLUETOOTH_SOURCE].Form.pnlMain.Parent := rectBT;
    Sources[BLUETOOTH_SOURCE].Form.lblFrequencyError.Visible := True;
    Sources[BLUETOOTH_SOURCE].Form.lblPacketInfo.Visible := True;
    Sources[BLUETOOTH_SOURCE].Form.lblRSSI.Visible := True;
    Sources[BLUETOOTH_SOURCE].Form.lblCaption.Text := 'BT LoRa Telemetry';
    Sources[BLUETOOTH_SOURCE].Form.frmLog.lblCaption.Text := 'BT LoRa Telemetry Log';
    {$IF Defined(MSWINDOWS) or Defined(ANDROID)}
        Sources[BLUETOOTH_SOURCE].Source := TBluetoothSource.Create(BLUETOOTH_SOURCE, 'LoRaBluetooth', HABCallback);
    {$ELSE}
        Sources[BLUETOOTH_SOURCE].Source := TBLESource.Create(BLUETOOTH_SOURCE, 'LoRaBluetooth', HABCallback);
        Label4.Text := 'BLE LoRa Telemetry:';
    {$ENDIF}

    // Sondehub Source
    Sources[SONDEHUB_SOURCE].Form := TfrmSource.Create(Self);
    Sources[SONDEHUB_SOURCE].Form.pnlMain.Parent := rectSH;
    Sources[SONDEHUB_SOURCE].Form.lblCaption.Text := 'Sondehub Telemetry';
    Sources[SONDEHUB_SOURCE].Form.frmLog.lblCaption.Text := 'Sondehub Telemetry Log';
    SetSettingString('Sondehub', 'Host', 'ws-reader.v2.sondehub.org');
    SetSettingString('Sondehub', 'Port', '443');
    SetSettingString('Sondehub', 'Topic', 'amateur/');
    SetSettingString('Sondehub', 'ExtraPayloads', '');
    SetSettingBoolean('Sondehub', 'Filtered', True);
    Sources[SONDEHUB_SOURCE].Source := TWSMQTTSource.Create(SONDEHUB_SOURCE, 'Sondehub', HABCallback);

    Sources[UDP_SOURCE].Form := TfrmSource.Create(Self);
    Sources[UDP_SOURCE].Form.pnlMain.Parent := rectUDP;
    Sources[UDP_SOURCE].Form.lblCaption.Text := 'UDP Telemetry';
    Sources[UDP_SOURCE].Form.frmLog.lblCaption.Text := 'UDP Telemetry Log';
    Sources[UDP_SOURCE].Source := TUDPSource.Create(UDP_SOURCE, 'UDP', HABCallback);

{$IFDEF ANDROID}
    Declination := MagneticDeclination;
    if frmDebug <> nil then begin
        frmDebug.Debug('Declination = ' + FloatToStr(Declination));
    end;
{$ELSE}
    Declination := 0;
{$ENDIF}
end;

procedure TfrmSources.CloseThread(Thread: TThread);
begin
    if Thread <> nil then begin
        Thread.Terminate;
    end;
end;


procedure TfrmSources.WaitForThread(Thread: TThread);
begin
    if Thread <> nil then begin
        Thread.WaitFor;
    end;
end;


procedure TfrmSources.FormDestroy(Sender: TObject);
var
    Index: Integer;
begin
    // Close and wait for threads

    for Index := Low(Sources) to High(Sources) do begin
        CloseThread(Sources[Index].Source);
    end;

    CloseThread(SSDVUploader);
    CloseThread(SondehubUploader);

    WaitForThread(SSDVUploader);
    WaitForThread(SondehubUploader);

    for Index := Low(Sources) to High(Sources) do begin
        WaitForThread(Sources[Index].Source);
    end;

    SSDVUploader.Free;
    SondehubUploader.Free;

    for Index := Low(Sources) to High(Sources) do begin
        if Sources[Index].Source <> nil then Sources[Index].Source.Free;
    end;
end;

{$IFDEF MSWINDOWS}
procedure TfrmSources.GPSCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
const
    Offset: Double = 0;
begin
    if Position.InUse then begin
        NewGPSPosition(Position.TimeStamp, Position.Latitude + Offset, Position.Longitude, Position.Altitude, Position.Direction, False);
    end else begin
        Sources[GPS_SOURCE].Form.lblValue.Text := Line;
    end;
end;
{$ENDIF}

procedure TfrmSources.NewGPSPosition(Timestamp: TDateTime; Latitude, Longitude, Altitude, Direction: Double; UsingCompass: Boolean);
var
    Position: THABPosition;
    Temp: String;
    GPSPosition: TGPSPosition;
begin
    if IsNan(Latitude) then begin
//        Temp := 'GPS ...';
//        frmMain.lblGPS.Text := Temp;
//        lblGPS.Text := Temp;
    end else begin
        GPSPosition.Latitude := Latitude;
        GPSPosition.Longitude := Longitude;

        FillChar(Position, SizeOf(Position), 0);

        Temp := Format('%f', [Altitude]);
        if IsNan(Altitude) then begin
            Temp := FormatDateTime('hh:nn:ss', Timestamp) + '  ' +
                                   Format('%2.6f', [Latitude]) + ',' +
                                   Format('%2.6f', [Longitude]);
            Altitude := 0;
        end else begin
            Altitude := Altitude - GetSettingInteger('CHASE', 'Offset', 0);
            Temp := FormatDateTime('hh:nn:ss', Timestamp) + '  ' +
                                   Format('%2.6f', [Latitude]) + ',' +
                                   Format('%2.6f', [Longitude]) + ', ' +
                                   Format('%.0f', [Altitude]) + 'm ';
        end;

        Sources[GPS_SOURCE].Form.lblValue.Text := Temp;

        Position.TimeStamp := Timestamp;
        Position.Latitude := GPSPosition.Latitude;
        Position.Longitude := GPSPosition.Longitude;
        Position.Altitude := Altitude;

        if IsNan(Direction) then begin
            Position.DirectionValid := False;
        end else begin
            Position.DirectionValid := True;
            if Direction < -180 then Direction := Direction + 360;
            if Direction > 180 then Direction := Direction - 360;

            if UsingCompass then begin
                Sources[GPS_SOURCE].Form.lblPacketInfo.Text := 'Compass Direction = ' + MyFormatFloat('0.0', Direction);
            end else begin
                Sources[GPS_SOURCE].Form.lblPacketInfo.Text := 'GPS Direction = ' + MyFormatFloat('0.0', Direction);
            end;
            Position.Direction := Direction;
            Position.UsingCompass := UsingCompass;
        end;

        Position.ReceivedAt := Now;

        Position.InUse := True;
        Position.IsChase := True;
        Position.PayloadID := 'Chase';

        frmMain.NewPosition(GPS_SOURCE, Position);

        if SondehubUploader <> nil then begin
            SondehubUploader.SetListenerPosition(Position.Latitude, Position.Longitude, Position.Altitude);
        end;
    end;
end;

procedure TfrmSources.OrientationSensor1SensorChoosing(Sender: TObject;
  const Sensors: TSensorArray; var ChoseSensorIndex: Integer);
var
    i: Integer;
    Found: Integer;
begin
    Found := -1;
    for i := 0 to High(Sensors) do begin
        if (TCustomOrientationSensor.TProperty.HeadingX in TCustomOrientationSensor(Sensors[I]).AvailableProperties) then begin
            Found := i;
            Break;
        end;
    end;

    if Found >= 0 then begin
        ChoseSensorIndex := Found;
        CompassPresent := True;
    end;
end;

procedure TfrmSources.pnlMainResize(Sender: TObject);
begin
end;

// this function x,y,z axis for the phone in vertical orientation (portrait)
function calcTiltCompensatedMagneticHeading(const {acel}aGx,aGy,aGz,{mag} aMx,aMy,aMz:double ):double; //return heading in degrees
var Phi,Theta,cosPhi,sinPhi,Gz2,By2,Bz2,Bx3:Double;
begin
  Result := NaN;   //=invalid
  // https://www.st.com/content/ccc/resource/technical/document/design_tip/group0/56/9a/e4/04/4b/6c/44/ef/DM00269987/files/DM00269987.pdf/jcr:content/translations/en.DM00269987.pdf
  Phi := ArcTan2(aGy,aGz);    //calc Roll (Phi)
  cosPhi := Cos(Phi);         //memoise phi trigs
  sinPhi := Sin(Phi);

  Gz2 := aGy*sinPhi+aGz*cosPhi;
  if (Gz2<>0) then
    begin
      Theta := Arctan(-aGx/Gz2);                 // Theta = Pitch
      By2 := aMz * sinPhi - aMy * cosPhi;
      Bz2 := aMy * sinPhi + aMz * cosPhi;
      Bx3 := aMx * Cos(Theta) + Bz2 * Sin(Theta);
      Result := ArcTan2(By2,Bx3)*180/Pi-90;      //convert to degrees and then add   90 for North based heading  (Psi)
    end;
end;

function TfrmSources.GetMagneticHeading: Double;
var
    mx, my, mz, aGx, aGy, aGz: Double;
begin
    mx := OrientationSensor1.Sensor.HeadingX;  //in mTeslas
    my := OrientationSensor1.Sensor.HeadingY;
    mz := OrientationSensor1.Sensor.HeadingZ;

    aGx := MotionSensor1.Sensor.AccelerationX;  //get acceleration sensor
    aGy := MotionSensor1.Sensor.AccelerationY;
    aGz := MotionSensor1.Sensor.AccelerationZ;

//    if IsLandscapeMode then  //landscape phone orientation
//    begin
//      aMagHeading := calcTiltCompensatedMagneticHeading({acel}aGy,-aGx,aGz,{mag} my,-mx,mz); //rotated 90 in z axis
//    end
//    else begin  //portrait orientation
    Result := calcTiltCompensatedMagneticHeading({acel}aGx,aGy,aGz,{mag} mx,my,mz);  // normal portrait orientation
end;

procedure TfrmSources.tmrGPSTimer(Sender: TObject);
var
    UTC: TDateTime;
begin
    // Compass
    if CompassPresent then begin
        MagneticHeading := GetMagneticHeading;
    end;

    // GPS
    // if LocationSensor.Accuracy < 50 then begin
        UTC := TTimeZone.Local.ToUniversalTime(Now);

        if CompassPresent then begin
            NewGPSPosition(UTC, LocationSensor.Sensor.Latitude, LocationSensor.Sensor.Longitude, LocationSensor.Sensor.Altitude, MagneticHeading - Declination, True);
        end else begin
            NewGPSPosition(UTC, LocationSensor.Sensor.Latitude, LocationSensor.Sensor.Longitude, LocationSensor.Sensor.Altitude, LocationSensor.Sensor.TrueHeading, False);
        end;
    // end;
end;

(*
procedure TfrmSources.CarStatusCallback(SourceID: Integer; Active, OK: Boolean; Status: String);
begin
    frmMain.SondehubUploadStatus(Active, OK);
end;
*)

procedure TfrmSources.SondehubStatusCallback(SourceID: Integer; Active, OK: Boolean; Status: String);
begin
    frmMain.SondehubUploadStatus(Active, OK);
    frmUploaders.WriteSondehubStatus(Status);
end;

(*
procedure TfrmSources.Label11Click(Sender: TObject);
begin
    frmMain.LoadSettingsPage(1);
end;

procedure TfrmSources.Label3Click(Sender: TObject);
begin
    frmMain.LoadSettingsPage(1);
end;
*)

procedure TfrmSources.HABCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
var
    Callsign: String;
    Port: Integer;
begin
    frmMain.NewPosition(ID, Position);

    // New position
    try
        if Position.InUse then begin
            Inc(Sources[ID].PacketCount);
//             frmMain.NewPosition(ID, Position);

            if not Position.IsSonde then begin
                if ID = SERIAL_SOURCE then begin
                    Callsign := GetSettingString('LoRaSerial', 'Callsign', '');

                    if GetSettingBoolean('LoRaSerial', 'Sondehub', False) then begin
                        SondehubUploader.SaveTelemetryToSondehub(ID, Position);
                    end;
                end else if ID = BLUETOOTH_SOURCE then begin
                    Callsign := GetSettingString('LoRaBluetooth', 'Callsign', '');

                    if GetSettingBoolean('LoRaBluetooth', 'Sondehub', False) then begin
                        SondehubUploader.SaveTelemetryToSondehub(ID, Position);
                    end;
                end;
            end;

            if ID in [SERIAL_SOURCE, BLUETOOTH_SOURCE] then begin
                Port := GetSettingInteger('General', 'UDPTxPort', 0);
                if Port > 0 then begin
                    UDPClient.Broadcast(Position.Line, Port);
                end;
            end;

            if Length(Position.Line) > 40 then begin
                Sources[ID].Form.lblValue.Text := Copy(Position.Line, 1, Length(Position.Line) div 2) + #13 +
                                                 Copy(Position.Line, Length(Position.Line) div 2 + 1, Length(Position.Line));
                Sources[ID].HadAPosition := True;
                Sources[ID].PacketStatus := 'Telemetry Packet';
                Sources[ID].Form.WriteToLog('Telemetry: ' + Position.Line);
            end else begin
                Sources[ID].Form.lblValue.Text := Position.Line;
                Sources[ID].Form.WriteToLog(Position.Line);
            end;
        end else if Position.IsSSDV then begin
            Sources[ID].PacketStatus := 'SSDV Packet';
            Sources[ID].Form.WriteToLog('Received SSDV Packet');
        end else if Position.FailedCRC then begin
            Sources[ID].PacketStatus := 'CRC Error';
            Sources[ID].Form.WriteToLog('CRC Error');
        end else if Line <> '' then begin
            Sources[ID].Form.lblValue.Text := Line;
            Sources[ID].ConnectInfo := Line;
            Sources[ID].Form.WriteToLog(Line);
        end;


        // SSDV Packet
        if (SSDVUploader <> nil) and Position.IsSSDV then begin
            if ID = SERIAL_SOURCE then begin
                if GetSettingBoolean('LoRaSerial', 'SSDV', False) then begin
                    Callsign := GetSettingString('LoRaSerial', 'Callsign', '');
                    if Callsign <> '' then begin
                        SSDVUploader.SaveSSDVToHabitat(Position.Line, Callsign);
                    end;
                end;
            end else if ID = BLUETOOTH_SOURCE then begin
                if GetSettingBoolean('LoRaBluetooth', 'SSDV', False) then begin
                    Callsign := GetSettingString('LoRaBluetooth', 'Callsign', '');
                    if Callsign <> '' then begin
                        SSDVUploader.SaveSSDVToHabitat(Position.Line, Callsign);
                    end;
                end;
            end;
        end;

        if Position.HasCurrentRSSI then begin
            Sources[ID].Form.lblRSSI.Text := 'Current RSSI = ' + IntToStr(Position.CurrentRSSI);
        end;

        if Position.HasPacketRSSI then begin
            Sources[ID].PacketRSSI := 'Packet RSSI = ' + IntToStr(Position.PacketRSSI);
            Sources[ID].Form.WriteToLog('Packet RSSI = ' + IntToStr(Position.PacketRSSI));
        end;

        if  (Sources[ID].PacketRSSI <> '') and (Sources[ID].PacketStatus <>'') then begin
            Sources[ID].Form.lblPacketInfo.Text := Sources[ID].PacketRSSI + ', ' + Sources[ID].PacketStatus;
        end;

        if Position.HasFrequency then begin
            Sources[ID].FrequencyError := Position.FrequencyError;

            if Position.CurrentFrequency > 0 then begin
                Sources[ID].Form.lblFrequencyError.Text := 'Freq. = ' + FormatFloat('0.000#', Position.CurrentFrequency) + ' MHz, Offset = ' + MyFormatFloat('0', Position.FrequencyError*1000) + ' Hz';
            end else begin
                Sources[ID].Form.lblFrequencyError.Text := 'Freq. Offset = ' + MyFormatFloat('0', Position.FrequencyError*1000) + ' Hz';
            end;

            // AFC
            if (Position.CurrentFrequency > 0) and (abs(Position.FrequencyError) > 1) then begin
                if ID = SERIAL_SOURCE then begin
                    if GetSettingBoolean('LoRaSerial', 'AFC', False) then begin
                        Sources[ID].Source.SendSetting('F', FormatFloat('0.0000', Position.CurrentFrequency + Position.FrequencyError / 1000));
                    end;
                end else if ID = BLUETOOTH_SOURCE then begin
                    if GetSettingBoolean('LoRaBluetooth', 'AFC', False) then begin
                        Sources[ID].Source.SendSetting('F', FormatFloat('0.0000', Position.CurrentFrequency + Position.FrequencyError / 1000));
                    end;
                end;
            end;
        end;

        if Position.Device <> '' then begin
            Sources[ID].Device := Position.Device;
            Sources[ID].Form.WriteToLog('Device: ' + Position.Device);
        end;

        if Position.Version <> '' then begin
            Sources[ID].Version := 'V' + Position.Version;
            Sources[ID].Form.WriteToLog('Version: ' + Position.Version);
        end;

        if (Sources[ID].ConnectInfo <> '') and (not Sources[ID].HadAPosition) then begin
            Sources[ID].Form.lblValue.Text := Sources[ID].ConnectInfo + ': ' + Sources[ID].Device + ' ' + Sources[ID].Version;
        end;
    except
        Sources[ID].Form.lblValue.Text := '** ERROR - **';
    end;
end;

procedure TfrmSources.UDPServerUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
begin
    // lblTablet.Text := BytesToString(AData);
end;

function RemoveDuplicatePayloads(PayloadList, WhiteList: String): String;
var
    Payload: String;
begin
    WhiteList := ',' + WhiteList + ',';

    Result := '';

    repeat
        Payload := GetString(PayloadList, ',');
        if Payload <> '' then begin
            if Pos(',' + Payload + ',', WhiteList) = 0 then begin
                if Result = '' then begin
                    Result := Payload;
                end else begin
                    Result := Payload + ',' + Payload;
                end;

            end;

        end;

    until PayloadList = '';
end;

procedure TfrmSources.UpdatePayloadList(PayloadList: String);
begin
    PayloadList := RemoveDuplicatePayloads(PayloadList, GetSettingString('Sondehub', 'WhiteList', ''));

    SetSettingString('Sondehub', 'ExtraPayloads', PayloadList);
end;

procedure TfrmSources.SendParameterToSource(SourceIndex: Integer; ValueName, Value: String);
begin
    if Sources[SourceIndex].Source <> nil then begin
        Sources[SourceIndex].Source.SendSetting(ValueName, Value);
    end;
end;

procedure TfrmSources.EnableCompass;
begin
    OrientationSensor1.Active := True;
    MotionSensor1.Active := True;
end;

function TfrmSources.GetPacketCount(SourceIndex: Integer): Integer;
begin
    Result := Sources[SourceIndex].PacketCount;
end;

procedure TfrmSources.ResetPacketCount(SourceIndex: Integer);
begin
    Sources[SourceIndex].PacketCount := 0;
end;

function TfrmSources.FrequencyError(SourceIndex: Integer): Double;
begin
    Result := Sources[SourceIndex].FrequencyError;
end;

procedure TfrmSources.SendUplink(SourceIndex: Integer; When: TUplinkWhen; WhenValue, Channel: Integer; Prefix, Msg, Password: String);
begin
    if Sources[SourceIndex].Source <> nil then begin
        Sources[SourceIndex].Source.SendUplink(When, WhenValue, Channel, Prefix, Msg, Password);
    end;
end;

function TfrmSources.WaitingToSend(SourceIndex: Integer): Boolean;
begin
    if Sources[SourceIndex].Source <> nil then begin
        Result := Sources[SourceIndex].Source.WaitingToSend;
    end else begin
        Result := False;
    end;
end;

procedure TfrmSources.UpdateCarUploadSettings;
begin
    SondehubUploader.SetListener(ApplicationName, ApplicationVersion,
                                 GetSettingString('CHASE', 'Callsign', 'UNKNOWN'),
                                 True,
                                 GetSettingInteger('CHASE', 'Period', 30),
                                 GetSettingBoolean('CHASE', 'Upload', False));
end;

procedure TfrmSources.SetGPSStatus(Status: String);
begin
    Sources[GPS_SOURCE].Form.lblValue.Text := Status;
end;

end.
