unit HABLink;

interface

uses Classes, SysUtils, SyncObjs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, HABTypes, Miscellaneous;

type
    THABLinkThread = class(TThread)
private
    CritSection: TCriticalSection;
    HablinkMessage: String;
    StatusCallback: TStatusCallback;
    // procedure SyncCallback(SourceID: Integer; Active, OK: Boolean);
  public
    procedure SendMessage(Msg: String);
    procedure Execute; override;
  published
    constructor Create(Callback: TStatusCallback);
end;

implementation

procedure THABLinkThread.SendMessage(Msg: String);
begin
    CritSection.Enter;
    try
        HablinkMessage := Msg;
    finally
        CritSection.Leave;
    end;
end;

procedure THABLinkThread.Execute;
var
    Msg: String;
    AClient: TIdTCPClient;
    SentOK: Boolean;
begin
    AClient := TIdTCPClient.Create;

    while not Terminated do begin
        if not AClient.Connected then begin
            AClient.Host := 'hab.link';
            AClient.Port := 8887;
            AClient.Connect;
        end;

        if AClient.Connected then begin
            // Telemetry
            Msg := '';
            CritSection.Enter;
            try
                Msg := HablinkMessage;
            finally
                CritSection.Leave;
            end;

            if Msg <> '' then begin
                SentOK := False;

                try
                    AClient.IOHandler.WriteLn(Msg);
    //                AClient.IOHandler.CloseGracefully;
    //                AClient.Disconnect;
                    SentOK := True;
                except
                    SentOK := False;
                end;

                if SentOK then begin
                    CritSection.Enter;
                    try
                        HablinkMessage := '';;
                    finally
                        CritSection.Leave;
                    end;
                end;
            end;
        end;

        sleep(100);
    end;
end;

constructor THABLinkThread.Create(Callback: TStatusCallback);
begin
    CritSection := TCriticalSection.Create;

    StatusCallback := Callback;

    inherited Create(False);
end;

//procedure THABLinkThread.SyncCallback(SourceID: Integer; Active, OK: Boolean);
//begin
//    Synchronize(
//        procedure begin
//            StatusCallback(SourceID, Active, OK);
//        end
//    );
//end;

end.
