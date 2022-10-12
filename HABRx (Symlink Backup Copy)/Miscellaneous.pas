unit Miscellaneous;

interface

uses DateUtils, Math, Source, HABTypes, INIFiles,
{$IFDEF ANDROID}
     Androidapi.JNI.Interfaces.JGeomagneticField,
{$ENDIF}
     Generics.Collections, System.IOUtils;

type
  TStatusCallback = procedure(SourceID: Integer; Active, OK: Boolean) of object;

type
  TSettings = TDictionary<String, Variant>;

type
  TIPLookup = record
    HostName:   String;
    IPAddress:  String;
  end;

type
  TIPLookups = record
    IPLookups:  Array[1..8] of TIPLookup;
    Count:      Integer;
  end;

function GetJSONString(Line: String; FieldName: String): String;
function GetJSONInteger(Line: String; FieldName: String): LongInt;
function GetJSONFloat(Line: String; FieldName: String): Double;
function GetUDPString(Line: String; FieldName: String): String;
function PayloadHasFieldType(Position: THABPosition; FieldType: TFieldType): Boolean;
procedure InsertDate(var TimeStamp: TDateTime);
function CalculateDescentTime(Altitude, DescentRate, Land: Double): Double;
function DataFolder: String;
function ImageFolder: String;
function GetString(var Line: String; Delimiter: String=','): String;
function SourceName(SourceID: Integer): String;
procedure AddHostNameToIPAddress(HostName, IPAddress: String);
function GetIPAddressFromHostName(HostName: String): String;
function MyStrToFloat(Value: String): Double;

{$IFDEF ANDROID}
    function MagneticDeclination: Single;
{$ENDIF}

procedure InitialiseSettings;

function GetSettingString(Section, Item, Default: String): String;
function GetSettingInteger(Section, Item: String; Default: Integer): Integer;
function GetSettingBoolean(Section, Item: String; Default: Boolean): Boolean;
function GetGroupChangedFlag(Section: String): Boolean;

procedure SetSettingString(Section, Item, Value: String);
procedure SetSettingInteger(Section, Item: String; Value: Integer);
procedure SetSettingBoolean(Section, Item: String; Value: Boolean);
procedure SetGroupChangedFlag(Section: String; Changed: Boolean);

const
    GPS_SOURCE = 0;
    SERIAL_SOURCE = 1;
    BLUETOOTH_SOURCE = 2;
    UDP_SOURCE = 3;
    HABITAT_SOURCE = 4;
    GATEWAY_SOURCE_1 = 5;
    GATEWAY_SOURCE_2 = 6;


var
    INIFileName: String;

implementation

uses SysUtils;

var
    Settings: TSettings;
    Ini: TIniFile;
    IPLookups: TIPLookups;

function SourceName(SourceID: Integer): String;
const
    SourceNames: Array[0..6] of String = ('GPS', 'Serial', 'Bluetooth', 'UDP', 'Habitat', 'Gateway', 'Gateway 2');
begin
    if (SourceID >= Low(SourceNames)) and (SourceID <= High(SourceNames)) then begin
        Result := SourceNames[SourceID];
    end else begin
        Result := '';
    end;
end;

function DataFolder: String;
begin
    if ParamCount > 0 then begin
        Result := ParamStr(1);
    end else begin
        Result := ExtractFilePath(ParamStr(0));
    end;

    {$IF Defined(IOS) or Defined(ANDROID)}
        Result := TPath.GetDocumentsPath;
    {$ENDIF}

    Result := IncludeTrailingPathDelimiter(Result);
end;

function ImageFolder: String;
begin
    Result := DataFolder;

    {$IFDEF MSWINDOWS}
        Result := TPath.Combine(DataFolder, 'Images');
    {$ENDIF}
end;


function GetUDPString(Line: String; FieldName: String): String;
var
    Position: Integer;
begin
    // Gateway:HOST=xxxx,IP=yyyyy

    Position := Pos(FieldName + '=', Line);

    if Position > 0 then begin
        Line := Copy(Line, Position + Length(FieldName) + 1, 999);

        Position := Pos(',', Line);

        Result := Copy(Line, 1, Position-1);
    end;
end;

function GetJSONString(Line: String; FieldName: String): String;
var
    Position: Integer;
begin
    // {"class":"POSN","payload":"NOTAFLIGHT","time":"13:01:56","lat":52.01363,"lon":-2.50647,"alt":5507,"rate":7.0}

    Position := Pos('"' + FieldName + '":', Line);

    if Copy(Line, Position + Length(FieldName) + 3, 1) = '"' then begin
        Line := Copy(Line, Position + Length(FieldName) + 4, 999);
        Position := Pos('"', Line);

        Result := Copy(Line, 1, Position-1);
//    end else if Line[Position + Length(FieldName) + 4] = '"' then begin
//        Line := Copy(Line, Position + Length(FieldName) + 5, 999);
//        Position := Pos('"', Line);
//
//        Result := Copy(Line, 1, Position-1);
    end else begin
        Line := Copy(Line, Position + Length(FieldName) + 3, 999);

        Position := Pos(',', Line);
        if Position = 0 then begin
            Position := Pos('}', Line);
        end;

        Result := Copy(Line, 1, Position-1);
    end;
end;

function GetJSONFloat(Line: String; FieldName: String): Double;
var
    Position: Integer;
begin
    // {"class":"POSN","payload":"NOTAFLIGHT","time":"13:01:56","lat":52.01363,"lon":-2.50647,"alt":5507,"rate":7.0}

    Position := Pos('"' + FieldName + '":', Line);

    if Position > 0 then begin
        Line := Copy(Line, Position + Length(FieldName) + 3, 999);

        Position := Pos(',', Line);
        if Position = 0 then begin
            Position := Pos('}', Line);
        end else if Pos('}', Line) < Position then begin
            Position := Pos('}', Line);
        end;


        Line := Copy(Line, 1, Position-1);

        if Copy(Line, 1, 1) = '"' then begin
            Line := Copy(Line,2, Length(Line)-2);
        end;

        try
            Result := MyStrToFloat(Line);
        except
            Result := 0;
        end;
    end else begin
        Result := 0;
    end;
end;

function GetJSONInteger(Line: String; FieldName: String): LongInt;
var
    Position: Integer;
begin
    // {"class":"POSN","payload":"NOTAFLIGHT","time":"13:01:56","lat":52.01363,"lon":-2.50647,"alt":5507,"rate":7.0}

    Position := Pos('"' + FieldName + '":', Line);

    if Position > 0 then begin
        Line := Copy(Line, Position + Length(FieldName) + 3, 999);

        Position := Pos(',', Line);
        if Position = 0 then begin
            Position := Pos('}', Line);
        end;

        Line := Copy(Line, 1, Position-1);

        if Copy(Line, 1, 1) = '"' then begin
            Line := Copy(Line,2, Length(Line)-2);
        end;

        Result := StrToIntDef(Line, 0);
    end else begin
        Result := 0;
    end;
end;

function PayloadHasFieldType(Position: THABPosition; FieldType: TFieldType): Boolean;
var
    i: Integer;
begin
    for i := 0 to length(Position.FieldList)-1 do begin
        if Position.FieldList[i] = FieldType then begin
            Result := True;
            Exit;
        end;
    end;

    Result := False;
end;

procedure InsertDate(var TimeStamp: TDateTime);
begin
    if TimeStamp < 1 then begin
        // Add today's date
        TimeStamp := TimeStamp + Trunc(TTimeZone.Local.ToUniversalTime(Now));

        if (TimeStamp > 0.99) and (Frac(TTimeZone.Local.ToUniversalTime(Now)) < 0.01) then begin
            // Just past midnight, but payload transmitted just before midnight, so use yesterday's date
            TimeStamp := TimeStamp - 1;
        end;
    end;
end;


function CalculateAirDensity(alt: Double): Double;
var
    Temperature, Pressure: Double;
begin
    if alt < 11000.0 then begin
        // below 11Km - Troposphere
        Temperature := 15.04 - (0.00649 * alt);
        Pressure := 101.29 * power((Temperature + 273.1) / 288.08, 5.256);
    end else if alt < 25000.0 then begin
        // between 11Km and 25Km - lower Stratosphere
        Temperature := -56.46;
        Pressure := 22.65 * exp(1.73 - ( 0.000157 * alt));
    end else begin
        // above 25Km - upper Stratosphere
        Temperature := -131.21 + (0.00299 * alt);
        Pressure := 2.488 * power((Temperature + 273.1) / 216.6, -11.388);
    end;

    Result := Pressure / (0.2869 * (Temperature + 273.1));
end;

function CalculateDescentRate(Weight, Density, CDTimesArea: Double): Double;
begin
    Result := sqrt((Weight * 9.81)/(0.5 * Density * CDTimesArea));
end;

function CalculateCDA(Weight, Altitude, DescentRate: Double): Double;
var
	Density: Double;
begin
	Density := CalculateAirDensity(Altitude);

    Result := (Weight * 9.81)/(0.5 * Density * DescentRate * DescentRate);
end;

function CalculateDescentTime(Altitude, DescentRate, Land: Double): Double;
var
    Density, CDTimesArea, TimeAtAltitude, TotalTime, Step: Double;
begin
    Step := 100;

    CDTimesArea := CalculateCDA(1.0, Altitude, DescentRate);

    TotalTime := 0;

    while Altitude > Land do begin
        Density := CalculateAirDensity(Altitude);

        DescentRate := CalculateDescentRate(1.0, Density, CDTimesArea);

        TimeAtAltitude := Step / DescentRate;
        TotalTime := TotalTime + TimeAtAltitude;

        Altitude := Altitude - Step;
    end;

    Result := TotalTime;
end;

procedure InitialiseSettings;
begin
    Settings := TSettings.Create;

    Ini := TIniFile.Create(INIFileName);
end;

function GetSettingString(Section, Item, Default: String): String;
var
    Key: String;
begin
    Key := Section + '/' + Item;

    if Settings.ContainsKey(Key) then begin
        Result := Settings[Key];
    end else begin
        Result := Ini.ReadString(Section, Item, Default);
        Settings.Add(Key, Result);
    end;
end;

function GetSettingInteger(Section, Item: String; Default: Integer): Integer;
var
    Key, Temp: String;
begin
    Key := Section + '/' + Item;

    if Settings.ContainsKey(Key) then begin
        try
            Result := Settings[Key];
        except
            Result := Default;
        end;
    end else begin
        Temp := Ini.ReadString(Section, Item, '');
        Result := StrToIntDef(Temp, Default);
        Settings.Add(Key, Result);
    end;
end;

function GetSettingBoolean(Section, Item: String; Default: Boolean): Boolean;
var
    Key: String;
begin
    Key := Section + '/' + Item;

    if Settings.ContainsKey(Key) then begin
        Result := Settings[Key];
    end else begin
        try
            Result := Ini.ReadBool(Section, Item, Default);
        except
            Result := Default;
        end;
        Settings.Add(Key, Result);
    end;
end;

procedure SetGroupChangedFlag(Section: String; Changed: Boolean);
begin
    Settings.AddOrSetValue(Section, Changed);
end;

function GetGroupChangedFlag(Section: String): Boolean;
begin
    if Settings.ContainsKey(Section) then begin
        Result := Settings[Section];
    end else begin
        Result := False;
        Settings.Add(Section, False);
    end;
end;

procedure SetSettingString(Section, Item, Value: String);
var
    Key: String;
begin
    Key := Section + '/' + Item;
    Settings.AddOrSetValue(Key, Value);
    Ini.WriteString(Section, Item, Value);
    Ini.UpdateFile;
end;

procedure SetSettingInteger(Section, Item: String; Value: Integer);
var
    Key: String;
begin
    Key := Section + '/' + Item;
    Settings.AddOrSetValue(Key, Value);
    Ini.WriteInteger(Section, Item, Value);
    Ini.UpdateFile;
end;

procedure SetSettingBoolean(Section, Item: String; Value: Boolean);
var
    Key: String;
begin
    Key := Section + '/' + Item;
    Settings.AddOrSetValue(Key, Value);
    Ini.WriteBool(Section, Item, Value);
    Ini.UpdateFile;
end;

function GetString(var Line: String; Delimiter: String=','): String;
var
    Position: Integer;
begin
    Position := Pos(Delimiter, string(Line));
    if Position > 0 then begin
        Result := Copy(Line, 1, Position-1);
        Line := Copy(Line, Position+Length(Delimiter), Length(Line));
    end else begin
        Result := Line;
        Line := '';
    end;
end;

procedure AddHostNameToIPAddress(HostName, IPAddress: String);
var
    i: Integer;
begin
    for i := 1 to IPLookups.Count do begin
        if IPLookups.IPLookups[i].HostName = HostName then begin
            if IPLookups.IPLookups[i].IPAddress <> IPAddress then begin
                IPLookups.IPLookups[i].IPAddress := IPAddress;
            end;
            Exit;
        end;
    end;

    if IPLookups.Count < High(IPLookups.IPLookups) then begin
        Inc(IPLookups.Count);
        IPLookups.IPLookups[IPLookups.Count].HostName := HostName;
        IPLookups.IPLookups[IPLookups.Count].IPAddress := IPAddress;
    end;
end;

function GetIPAddressFromHostName(HostName: String): String;
var
    i: Integer;
begin
    for i := 1 to IPLookups.Count do begin
        if UpperCase(IPLookups.IPLookups[i].HostName) = UpperCase(HostName) then begin
            Result := IPLookups.IPLookups[i].IPAddress;
            Exit;
        end;
    end;

    Result := '';
end;

function MyStrToFloat(Value: String): Double;
begin
    if FormatSettings.DecimalSeparator <> '.' then begin
        Value := StringReplace(Value, '.', FormatSettings.DecimalSeparator, []);
    end;

    try
        Result := StrToFloat(Value);
    except
        Result := 0;
    end;
end;

{$IFDEF ANDROID}
function SwitchDWords(n:int64):int64;    // switch hi <--> lo dwords of an int64
var i: Integer;
    nn :int64; nnA:array[0..7]  of byte absolute nn;
    nn1:int64; nn1A:array[0..7] of byte absolute nn1;
begin
  nn1 := n;           // copy n
  for i := 0 to 3 do  // switch bytes  hidword <--> lodword
    begin
      nnA[i]   := nn1A[i+4];
      nnA[i+4] := nn1A[i];
    end;
  Result := nn;
end;

function MagneticDeclination: Single;
var
    GeoField: JGeomagneticField; tm:int64;  aD:Single;
begin
    tm := System.DateUtils.DateTimeToUnix( Now, {InputAsUTC:} false )*1000;

    tm := switchDWords(tm);    // <--  hack tm

    GeoField := TJGeomagneticField.JavaClass.init({Lat:}51.95023, {Lon:}-2.54445, {Alt:}145, tm );
    aD := GeoField.getDeclination();   // <-- this shows -21.8416 which is correct !

    Result := aD;
end;
{$ENDIF}


end.

