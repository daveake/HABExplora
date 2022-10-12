unit CarUpload;

interface

uses Classes, SysUtils, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
     Math, Miscellaneous;

type
  TCarPosition = record
    InUse:      Boolean;
    TimeStamp:  TDateTime;
    Latitude:   Double;
    Longitude:  Double;
    Altitude:   Double;
  end;

type
  TCarUpload = class(TThread)
  private
    { Private declarations }
    Position: TCarPosition;
    StatusCallback: TStatusCallback;
    procedure SyncCallback(Active, OK: Boolean);
  protected
    { Protected declarations }
    Enabled: Boolean;
    procedure Execute; override;
  public
    { Public declarations }
    procedure Enable;
    procedure Disable;
    procedure SetPosition(NewPosition: TCarPosition);
  public
    constructor Create(Callback: TStatusCallback);
  end;

implementation

procedure TCarUpload.Execute;
var
    URL, Password: String;
    // HttpCli1: THttpCli;
    IdHTTP1: TIdHTTP;
    Seconds: Integer;
begin
    Seconds := 0;
    while not Terminated do begin
        if Position.InUse and
           (GetSettingString('CHASE', 'Callsign', '') <> '') and
           GetSettingBoolean('CHASE', 'Upload', False) and
           (Seconds >= Min(10, GetSettingInteger('CHASE', 'Period', 30))) then begin
            Password := 'aurora';

            URL := 'http://spacenear.us/tracker/track.php' +
                   '?vehicle=' + GetSettingString('CHASE', 'Callsign', '') + '_Chase' +
                    '&time=' + FormatDateTime('hhmmss', Position.TimeStamp) +
                    '&lat=' + FormatFloat('00.000000', Position.Latitude) +
                    '&lon=' + FormatFloat('00.000000', Position.Longitude) +
                    '&alt=' + FormatFloat('0', Position.Altitude) +
                    '&pass=' + Password;

            IdHTTP1 := TIdHTTP.Create(nil);
            try
                try
                    IdHTTP1.Get(URL);
                    SyncCallback(True, True);
                except
                    SyncCallback(True, False);
                end;
            finally
                IdHTTP1.Free;
            end;
            Seconds := 0;
        end else begin
            SyncCallback(False, False);
        end;
        Sleep(10000);
        Inc(Seconds, 10);
    end;
end;

constructor TCarUpload.Create(Callback: TStatusCallback);
begin
    Enabled := True;
    StatusCallback := Callback;
    inherited Create(False);
end;

procedure TCarUpload.Enable;
begin
    Enabled := True;
end;

procedure TCarUpload.Disable;
begin
    Enabled := False;
end;

procedure TCarUpload.SetPosition(NewPosition: TCarPosition);
begin
    Position := NewPosition;
end;

procedure TCarUpload.SyncCallback(Active, OK: Boolean);
begin
    Synchronize(
        procedure begin
            StatusCallback(GPS_SOURCE, Active, OK);
        end
    );
end;


end.
