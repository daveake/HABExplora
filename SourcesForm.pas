unit SourcesForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, Math,
  GPSSource, Source, Base, CarUpload, Miscellaneous, Habitat,
  HabitatSource, SerialSource, BluetoothSource, BLESource,
  System.DateUtils, System.TimeSpan, System.Sensors, System.Sensors.Components,
  IdUDPServer, IdGlobal, IdSocketHandle, IdBaseComponent, IdComponent, IdUDPBase,
  IdUDPClient;

type
  TSourcePanel = record
      Source: TSource;
      ValueLabel:       TLabel;
      RSSILabel:        TLabel;
      PacketRSSILabel:  TLabel;
      FreqLabel:        TLabel;
  end;

type
    TGPSPosition = record
        Latitude, Longitude:  Double;
        Score:  Integer;
    end;

type
  TfrmSources = class(TfrmBase)
    LocationSensor: TLocationSensor;
    tmrGPS: TTimer;
    Rectangle2: TRectangle;
    lblGPS: TLabel;
    Rectangle3: TRectangle;
    lblHabitat: TLabel;
    Rectangle6: TRectangle;
    lblSerial: TLabel;
    Label11: TLabel;
    lblSerialRSSI: TLabel;
    lblPacketInfo: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    lblFrequencyError: TLabel;
    lblDirection: TLabel;
    Rectangle1: TRectangle;
    lblBluetooth: TLabel;
    Label4: TLabel;
    lblBluetoothRSSI: TLabel;
    lblBTPacketInfo: TLabel;
    lblBTFrequencyError: TLabel;
    UDPClient: TIdUDPClient;
    MotionSensor1: TMotionSensor;
    OrientationSensor1: TOrientationSensor;
    procedure FormCreate(Sender: TObject);
    procedure tmrGPSTimer(Sender: TObject);
    procedure UDPServerUDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure OrientationSensor1SensorChoosing(Sender: TObject;
      const Sensors: TSensorArray; var ChoseSensorIndex: Integer);
  private
    { Private declarations }
    CarUploader: TCarUpload;
    CompassPresent: Boolean;
    MagneticHeading, Declination: Double;
    HabitatUploader: THabitatThread;
    Sources: Array[1..6] of TSourcePanel;
    GPSPositions: Array[1..5] of TGPSPosition;
    GPSCount: Integer;
{$IFDEF MSWINDOWS}
    GPSSource: TGPSSource;
    procedure GPSCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
{$ENDIF}
    function GetMagneticHeading: Double;
    procedure NewGPSPosition(Timestamp: TDateTime; Latitude, Longitude, Altitude, Direction: Double; UsingCompass: Boolean);
    procedure HABCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
    procedure HabitatStatusCallback(SourceID: Integer; Active, OK: Boolean);
    procedure CarStatusCallback(SourceID: Integer; Active, OK: Boolean);
    function SavePosition(Latitude, Longitude: Double): TGPSPosition;
  public
    { Public declarations }
    procedure UpdatePayloadList(PayloadList: String);
    procedure SendParameterToSource(SourceIndex: Integer; ValueName, Value: String);
    procedure EnableGPS;
    procedure EnableCompass;
end;

var
  frmSources: TfrmSources;

implementation

uses Main, Debug;

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

    // Car uploader
    CarUploader := TCarUpload.Create(CarStatusCallback);

    // Habitat uploader
    HabitatUploader := THabitatThread.Create(HabitatStatusCallback);

    // GPS Source
{$IFDEF MSWINDOWS}
    GPSSource := TGPSSource.Create(GPS_SOURCE, 'GPS', GPSCallback);
{$ENDIF}

    // USB LoRa device
    {$IF Defined(MSWINDOWS) or Defined(ANDROID)}
        Sources[SERIAL_SOURCE].ValueLabel := lblSerial;
        Sources[SERIAL_SOURCE].RSSILabel := lblSerialRSSI;
        Sources[SERIAL_SOURCE].PacketRSSILabel := lblPacketInfo;
        Sources[SERIAL_SOURCE].FreqLabel := lblFrequencyError;
        Sources[SERIAL_SOURCE].Source := TSerialSource.Create(SERIAL_SOURCE, 'LoRaSerial', HABCallback);
    {$ELSE}
        Label11.Text := '';
    {$ENDIF}

    // BT/BLE LoRa device
    Sources[BLUETOOTH_SOURCE].ValueLabel := lblBluetooth;
    Sources[BLUETOOTH_SOURCE].RSSILabel := lblBlueToothRSSI;
    Sources[BLUETOOTH_SOURCE].PacketRSSILabel := lblBTPacketInfo;
    Sources[BLUETOOTH_SOURCE].FreqLabel := lblBTFrequencyError;
    {$IF Defined(MSWINDOWS) or Defined(ANDROID)}
        Sources[BLUETOOTH_SOURCE].Source := TBluetoothSource.Create(BLUETOOTH_SOURCE, 'LoRaBluetooth', HABCallback);
    {$ELSE}
        Sources[BLUETOOTH_SOURCE].Source := TBLESource.Create(BLUETOOTH_SOURCE, 'LoRaBluetooth', HABCallback);
        Label4.Text := 'BLE LoRa Telemetry:';
    {$ENDIF}

    Sources[HABITAT_SOURCE].ValueLabel := lblHabitat;
    Sources[HABITAT_SOURCE].RSSILabel := nil;
    Sources[HABITAT_SOURCE].PacketRSSILabel := nil;
    Sources[HABITAT_SOURCE].FreqLabel := nil;
    Sources[HABITAT_SOURCE].Source := THabitatSource.Create(HABITAT_SOURCE, 'Habitat', HABCallback);

{$IFDEF ANDROID}
    Declination := MagneticDeclination;
    if frmDebug <> nil then begin
        frmDebug.Debug('Declination = ' + FloatToStr(Declination));
    end;
{$ELSE}
    Declination := 0;
{$ENDIF}
end;

{$IFDEF MSWINDOWS}
procedure TfrmSources.GPSCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
const
    Offset: Double = 0;
begin
    if Position.InUse then begin
        NewGPSPosition(Position.TimeStamp, Position.Latitude + Offset, Position.Longitude, Position.Altitude, Position.Direction, False);
    end;
end;
{$ENDIF}

procedure TfrmSources.NewGPSPosition(Timestamp: TDateTime; Latitude, Longitude, Altitude, Direction: Double; UsingCompass: Boolean);
var
    Position: THABPosition;
    Temp: String;
    CarPosition: TCarPosition;
    GPSPosition: TGPSPosition;
begin
    if IsNan(Latitude) then begin
        Temp := 'GPS ...';
        frmMain.lblGPS.Text := Temp;
        lblGPS.Text := Temp;
    end else begin
        GPSPosition := SavePosition(Latitude, Longitude);

        FillChar(Position, SizeOf(Position), 0);

        Temp := Format('%f', [Altitude]);
        if IsNan(Altitude) then begin
            Temp := FormatDateTime('hh:nn:ss', Timestamp) + '  ' +
                                   Format('%2.6f', [Latitude]) + ',' +
                                   Format('%2.6f', [Longitude]);
        end else begin
            Altitude := Altitude - GetSettingInteger('CHASE', 'Offset', 0);
            Temp := FormatDateTime('hh:nn:ss', Timestamp) + '  ' +
                                   Format('%2.6f', [Latitude]) + ',' +
                                   Format('%2.6f', [Longitude]) + ', ' +
                                   Format('%.0f', [Altitude]) + 'm ';
        end;

        lblGPS.Text := Temp;

        Position.TimeStamp := Timestamp;
        Position.Latitude := GPSPosition.Latitude;
        Position.Longitude := GPSPosition.Longitude;
        Position.Altitude := Altitude;

        if IsNan(Direction) then begin
            Position.DirectionValid := False;
        end else begin
            Position.DirectionValid := True;
            if UsingCompass then begin
                lblDirection.Text := 'Compass Direction = ' + MyFormatFloat('0.0', Direction);
            end else begin
                lblDirection.Text := 'GPS Direction = ' + MyFormatFloat('0.0', Direction);
            end;
            Position.Direction := Direction;
        end;

        Position.ReceivedAt := Now;

        Position.InUse := True;
        Position.IsChase := True;
        Position.PayloadID := 'Chase';

        frmMain.NewPosition(GPS_SOURCE, Position);

        if CarUploader <> nil then begin
            CarPosition.InUse := True;
            CarPosition.TimeStamp := TTimeZone.Local.ToUniversalTime(Now);
            CarPosition.Latitude := Position.Latitude;
            CarPosition.Longitude := Position.Longitude;
            CarPosition.Altitude := Position.Altitude;

            CarUploader.SetPosition(CarPosition);
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

procedure TfrmSources.CarStatusCallback(SourceID: Integer; Active, OK: Boolean);
begin
    frmMain.UploadStatus(SourceID, Active, OK);
end;

procedure TfrmSources.HabitatStatusCallback(SourceID: Integer; Active, OK: Boolean);
begin
    frmMain.UploadStatus(SourceID, Active, OK);
end;

procedure TfrmSources.HABCallback(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition);
var
    Callsign: String;
    Port: Integer;
begin
    // New position
    if Position.InUse then begin
        frmMain.NewPosition(ID, Position);

        if ID = SERIAL_SOURCE then begin
            if GetSettingBoolean('LoRaSerial', 'Habitat', False) then begin
                Callsign := GetSettingString('LoRaSerial', 'Callsign', '');
                if Callsign <> '' then begin
                    HabitatUploader.SaveTelemetryToHabitat(ID, Position.Line, Callsign);
                end;
            end;
        end else if ID = BLUETOOTH_SOURCE then begin
            if GetSettingBoolean('LoRaBluetooth', 'Habitat', False) then begin
                Callsign := GetSettingString('LoRaBluetooth', 'Callsign', '');
                if Callsign <> '' then begin
                    HabitatUploader.SaveTelemetryToHabitat(ID, Position.Line, Callsign);
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
            Sources[ID].ValueLabel.Text := Copy(Position.Line, 1, Length(Position.Line) div 2) + #13 +
                                           Copy(Position.Line, Length(Position.Line) div 2 + 1, Length(Position.Line));
        end else begin
            Sources[ID].ValueLabel.Text := Position.Line;
        end;
    end else if Line <> '' then begin
        Sources[ID].ValueLabel.Text := Line;
    end;

    // SSDV Packet
    if Position.IsSSDV then begin
        if GetSettingBoolean('LoRaSerial', 'SSDV', False) then begin
            Callsign := GetSettingString('LoRaSerial', 'Callsign', '');
            if Callsign <> '' then begin
                HabitatUploader.SaveSSDVToHabitat(Position.Line, Callsign);
            end;
        end;
    end;

    if Position.HasCurrentRSSI and (Sources[ID].RSSILabel <> nil) then begin
        Sources[ID].RSSILabel.Text := 'Current RSSI = ' + IntToStr(Position.CurrentRSSI);
    end;

    if Position.HasPacketRSSI and (Sources[ID].PacketRSSILabel <> nil) then begin
        Sources[ID].PacketRSSILabel.Text := 'Packet RSSI = ' + IntToStr(Position.PacketRSSI);
    end;

    if Position.HasFrequency and (Sources[ID].FreqLabel <> nil) then begin
        Sources[ID].FreqLabel.Text := 'Frequency Offset = ' + MyFormatFloat('0', Position.FrequencyError*1000) + ' Hz';
    end;



//    if Line <> '' then begin
//        Sources[ID].Lbl.Text := Line;
//    end;

//        if Position.Channel = 0 then begin
//            RSSI1.ExtraNeedles[0].Value := Position.PacketRSSI;
//        end else if Position.Channel = 1 then begin
//            RSSI2.ExtraNeedles[0].Value := Position.PacketRSSI;
//        end;
//    end else if Position.HasRSSI then begin
//        if Position.Channel = 0 then begin
//            RSSI1.Value := Position.CurrentRSSI;
//        end else if Position.Channel = 1 then begin
//            RSSI2.Value := Position.CurrentRSSI;
//        end;
end;

procedure TfrmSources.UDPServerUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
begin
    // lblTablet.Text := BytesToString(AData);
end;

procedure TfrmSources.UpdatePayloadList(PayloadList: String);
begin
    if Sources[HABITAT_SOURCE].Source <> nil then begin
        THabitatSource(Sources[HABITAT_SOURCE].Source).PayloadList := PayloadList;
    end;
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

function TfrmSources.SavePosition(Latitude, Longitude: Double): TGPSPosition;
var
    i, j, Best: Integer;
    Distance: Double;
begin
    if GPSCount = 0 then begin
        GPSCount := High(GPSPositions);
        for i := 1 to GPSCount do begin
            GPSPositions[i].Latitude := Latitude;
            GPSPositions[i].Longitude := Longitude;
        end;
    end;

    for i := 1 to GPSCount-1 do begin
        GPSPositions[i] := GPSPositions[i+1];
    end;

    GPSPositions[GPSCount].Latitude := Latitude;
    GPSPositions[GPSCount].Longitude := Longitude;

    // Use or reject latest value

    for i := 1 to GPSCount do begin
        GPSPositions[i].Score := 0;
        for j := 1 to GPSCount do begin
            if j <> i then begin
                Distance := CalculateDistance(GPSPositions[i].Latitude, GPSPositions[i].Longitude, GPSPositions[j].Latitude, GPSPositions[j].Longitude);
                if Distance < (100 * abs(i-j)) then begin
                    Inc(GPSPositions[i].Score);
                end;
            end;
        end;
    end;

    if GPSPositions[GPSCount].Score >= 3 then begin
        Result := GPSPositions[GPSCount];
    end else begin
        Best := 1;
        for i := 2 to GPSCount do begin
            if GPSPositions[i].Score >= GPSPositions[Best].Score then begin
                Best := i;
            end;
        end;
        Result := GPSPositions[Best];
    end;
end;

end.
