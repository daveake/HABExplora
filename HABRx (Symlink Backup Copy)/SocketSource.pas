unit SocketSource;

interface

uses Source, Classes, SysUtils, Miscellaneous,
     IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient;

type
  TSocketSource = class(TSource)
  private
    { Private declarations }
    AClient: TIdTCPClient;
    Commands: TStringList;
  protected
    { Protected declarations }
    procedure AddCommand(Command: String);
    procedure InitialiseDevice; virtual;
    procedure Execute; override;
  public
    { Public declarations }
  public
    constructor Create(ID: Integer; Group: String; Callback: TSourcePositionCallback);
  end;

implementation

procedure TSocketSource.Execute;
var
    Position: THABPosition;
    Host, HostOrIP, Line: String;
begin
    Commands := TStringList.Create;

    // Create client
    AClient := TIdTCPClient.Create;

    while not Terminated do begin
        // Connect to socket server
        Host := GetSettingString(GroupName, 'Host', '');
        AClient.Port := GetSettingInteger(GroupName, 'Port', 0);
        SetGroupChangedFlag(GroupName, False);

        if (Host = '') or (AClient.Port <= 0) then begin
            Sleep(1000);
        end else begin
            while (not Terminated) and (not GetGroupChangedFlag(GroupName)) do begin
                HostOrIP := GetIPAddressFromHostName(Host);
                if HostOrIP = '' then begin
                    HostOrIP := Host;
                end;

                try
                    FillChar(Position, SizeOf(Position), 0);
                    SyncCallback(SourceID, True, 'Connecting to ' + HostOrIP + '...', Position);
                    AClient.Host := HostOrIP;
                    AClient.Connect;
                    SyncCallback(SourceID, True, 'Connected to ' + HostOrIP, Position);
                    InitialiseDevice;
                    while not GetGroupChangedFlag(GroupName) do begin
                        while Commands.Count > 0 do begin
                            AClient.IOHandler.WriteLn(Commands[0]);
                            Commands.Delete(0);
                        end;

                        Line := AClient.IOHandler.ReadLn;
                        if Line <> '' then begin
                            Position := ExtractPositionFrom(Line);
                            if Position.InUse or Position.HasPacketRSSI or Position.HasCurrentRSSI then begin
                                SyncCallback(SourceID, True, '', Position);
                            end;
                        end;
                    end;
                    AClient.IOHandler.InputBuffer.clear;
                    AClient.IOHandler.CloseGracefully;
                    AClient.Disconnect;
                except
                    // Wait before retrying
                    SyncCallback(SourceID, False, 'No Connection to ' + HostOrIP, Position);
                    Sleep(5000);
                end;
            end;
        end;
    end;
end;

constructor TSocketSource.Create(ID: Integer; Group: String; Callback: TSourcePositionCallback);
begin
    inherited Create(ID, Group, Callback);
end;

procedure TSocketSource.InitialiseDevice;
begin
    // virtual;
end;

procedure TSocketSource.AddCommand(Command: String);
begin
    Commands.Add(Command);
end;

end.
