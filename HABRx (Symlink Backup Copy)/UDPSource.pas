unit UDPSource;

interface

uses Source, Classes, SysUtils, Miscellaneous,
{$IFDEF ANDROID}
     Androidapi.JNI.WiFiManager, Androidapi.Helpers,
{$ENDIF}
     IdBaseComponent, IdComponent, IdUDPServer, IdUDPBase, IdGlobal, IdSocketHandle;

type
  TUDPSource = class(TSource)
  private
    { Private declarations }
    UDPServer: TIdUDPServer;
    procedure UDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
  protected
    { Protected declarations }
    procedure Execute; override;
  public
    { Public declarations }
  public
    constructor Create(ID: Integer; Group: String; Callback: TSourcePositionCallback);
  end;

implementation

procedure TUDPSource.Execute;
var
    Position: THABPosition;
    PortList, TempPortList: String;
    PortNumber: Integer;
{$IFDEF ANDROID}
    wifi_manager: JWiFiManager;
    multiCastLock: JMulticastLock;
{$ENDIF}
begin
    FillChar(Position, SizeOf(Position), 0);
    SyncCallback(SourceID, True, '', Position);

{$IFDEF ANDROID}
    wifi_manager := GetWiFiManager;
    multiCastLock := wifi_manager.createMulticastLock(StringToJString('HABMobile'));
    multiCastLock.setReferenceCounted(true);
    multiCastLock.acquire;
{$ENDIF}

    while not Terminated do begin
        SetGroupChangedFlag(GroupName, False);
        PortList := GetSettingString(GroupName, 'Port', '');

        if PortList = '' then begin
            SyncCallback(SourceID, True, 'No ports specified', Position);
        end else begin
            // Create client
            UDPServer := TIdUDPServer.Create;
            TempPortList := PortList;

            while TempPortList <> '' do begin
                PortNumber := StrToIntDef(GetString(TempPortList, ','), 0);
                if PortNumber > 0 then begin
                    with UDPServer.Bindings.Add do begin
                        IP := '0.0.0.0';
                        Port := PortNumber;
                    end;
                end;
            end;

            SyncCallback(SourceID, True, 'Listening to ' + PortList + ' ...', Position);
            UDPServer.ReuseSocket := rsTrue;
            UDPServer.ThreadedEvent := True;
            UDPServer.OnUDPRead := UDPRead;

            try
                UDPServer.Active := True;

                while (not Terminated) and (not GetGroupChangedFlag(GroupName)) do begin
                    Sleep(100);
                end;
            except
                SyncCallback(SourceID, True, 'Failed to listen to ' + PortList + ' ...', Position);
            end;

            UDPServer.Active := False;
            UDPServer.Free;
        end;

        Sleep(1000);
    end;
end;

procedure TUDPSource.UDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
var
    Position: THABPosition;
    Sentence, Line: String;
begin
    Line := BytesToString(AData);

    while Length(Line) > 2 do begin
        Sentence := GetString(Line, #10);

        try
            Position := ExtractPositionFrom(Sentence, 'UDP');

            if Position.InUse then begin
                SyncCallback(SourceID, True, Line, Position);
            end;
        except
            //
        end;
    end;
end;

constructor TUDPSource.Create(ID: Integer; Group: String; Callback: TSourcePositionCallback);
begin
    inherited Create(ID, Group, Callback);
end;

end.
