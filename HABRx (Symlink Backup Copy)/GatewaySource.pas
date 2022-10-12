unit GatewaySource;

interface

uses SocketSource, Source, SysUtils, Classes,
{$IFDEF VCL}
  ExtCtrls, Windows
{$ELSE}
  FMX.Types
{$ENDIF}
;

type
  TGatewaySource = class(TSocketSource)
  private
    { Private declarations }
    PreviousLines: Array[0..2] of String;
    function ProcessJSON(Line: String): THABPosition;
  protected
    { Protected declarations }
    procedure InitialiseDevice; override;
    function ExtractPositionFrom(Line: String; PayloadID: String = ''): THABPosition; override;
  public
    { Public declarations }
    procedure SendSetting(SettingName, SettingValue: String); override;
  end;

implementation

uses Miscellaneous;

procedure TGatewaySource.InitialiseDevice;
begin
    SendSetting('frequency_0', GetSettingString(GroupName, 'Frequency_0', '434.250'));
    SendSetting('mode_0', GetSettingString(GroupName, 'Mode_0', '1'));

    SendSetting('frequency_1', GetSettingString(GroupName, 'Frequency_1', '434.350'));
    SendSetting('mode_1', GetSettingString(GroupName, 'Mode_1', '1'));
end;


function TGatewaySource.ExtractPositionFrom(Line: String; PayloadID: String = ''): THABPosition;
var
    Position: THABPosition;
begin
    FillChar(Position, SizeOf(Position), 0);

    if Line <> '' then begin
        if GetJSONString(Line, 'class') = 'POSN' then begin
        // if Pos('"POSN"', Line) > 0 then begin
            // {"class":"POSN","index":0;"payload":"NOTAFLIGHT","time":"13:01:56","lat":52.01363,"lon":-2.50647,"alt":5507,"rate":7.0}
            Position := ProcessJSON(Line);
            if Line <> PreviousLines[Position.Channel] then begin
                PreviousLines[Position.Channel] := Line;
                Position.InUse := True;
            end;
        end else if GetJSONString(Line, 'class') = 'STATS' then begin
            Position.Channel := GetJSONInteger(Line, 'index');
            Position.CurrentRSSI := GetJSONInteger(Line, 'rssi');
            Position.HasCurrentRSSI := True;
        end;
    end;

    Result := Position;
end;

function TGatewaySource.ProcessJSON(Line: String): THABPosition;
var
    TimeStamp: String;
    Position: THABPosition;
begin
    FillChar(Position, SizeOf(Position), 0);

    // {"class":"POSN","payload":"NOTAFLIGHT","time":"13:01:56","lat":52.01363,"lon":-2.50647,"alt":5507,"rate":7.0}

    try
        Position.Channel := GetJSONInteger(Line, 'channel');
        Position.PayloadID := GetJSONString(Line, 'payload');

        TimeStamp := GetJSONString(Line, 'time');
        if Length(TimeStamp) = 8 then begin
            Position.TimeStamp := EncodeTime(StrToIntDef(Copy(TimeStamp, 1, 2), 0),
                                             StrToIntDef(Copy(TimeStamp, 4, 2), 0),
                                             StrToIntDef(Copy(TimeStamp, 7, 2), 0),
                                             0);
            InsertDate(Position.TimeStamp);
        end;
        Position.Latitude := GetJSONFloat(Line, 'lat');
        Position.Longitude := GetJSONFloat(Line, 'lon');
        Position.Altitude := GetJSONFloat(Line, 'alt');

        Position.PacketRSSI := GetJSONInteger(Line, 'rssi');

        Position.ReceivedAt := Now;

        Position.Line := GetJSONString(Line, 'sentence');

        LookForPredictionInSentence(Position);
    except
    end;

//    if PreviousTime > 0 then begin
//        if (Position.Time - PreviousTime) > 0 then begin
//            Position.Rate := (Position.Altitude - PreviousAltitude) / (86400 * (Position.Time - PreviousTime));
//        end;
//    end;

//    PreviousAltitude := Position.Altitude;

    Inc(SentenceCount);

    Result := Position;
end;

procedure TGatewaySource.SendSetting(SettingName, SettingValue: String);
const
    Implicit: Array[0..8] of Integer = (0, 1, 0, 0, 1, 0, 1, 0, 1);
    Coding: Array[0..8] of Integer = (8, 5, 8, 6, 5, 8, 5, 5, 5);
    Bandwidth: Array[0..8] of String = ('20.8', '20.8', '62.5', '250', '250', '41.7', '41.7', '20.8', '62.5');
    Spreading: Array[0..8] of Integer = (11, 6, 8, 7, 6, 11, 6, 7, 6);
    LowOpt: Array[0..8] of String = ('Y', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N');
var
    Channel: String;
    Mode: Integer;
begin
    AddCommand(SettingName + '=' + SettingValue);

    if Copy(SettingName, 1, 5) = 'mode_' then begin
        Channel := Copy(SettingName, 6, 1);
        Mode := StrToIntDef(SettingValue, 0);
        if (Mode >= Low(Implicit)) and (Mode <= High(Implicit)) then begin
            AddCommand('implicit_' + Channel + '=' + IntToStr(Implicit[Mode]));
            AddCommand('coding_' + Channel + '=' + IntToStr(Coding[Mode]));
            AddCommand('bandwidth_' + Channel + '=' + Bandwidth[Mode]);
            AddCommand('sf_' + Channel + '=' + IntToStr(Spreading[Mode]));
            AddCommand('lowopt_' + Channel + '=' + LowOpt[Mode]);
        end;
    end;
end;



end.

