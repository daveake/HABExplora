unit TargetForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Base, FMX.Controls.Presentation, Source;

type
  TPositions = record
    Position: THABPosition;
    Changed: Boolean;
  end;

type
  TfrmTarget = class(TfrmBase)
    tmrUpdates: TTimer;
    procedure tmrUpdatesTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  protected
    SelectedIndex: Integer;
    Positions: Array[0..3] of TPositions;
    function ProcessNewPosition(Index: Integer): Boolean; virtual;
    procedure ProcessNewDirection(Index: Integer); virtual;
  public
    { Public declarations }
    procedure UpdatePayloadID(Index: Integer; PayloadID: String); virtual;
    procedure NewSelection(Index: Integer); virtual;
    procedure NewPosition(Index: Integer; Position: THABPosition); virtual;
  end;

implementation

{$R *.fmx}

procedure TfrmTarget.FormCreate(Sender: TObject);
begin
    SelectedIndex := 1;
end;

procedure TfrmTarget.NewPosition(Index: Integer; Position: THABPosition);
begin
    // virtual
    Positions[Index].Position := Position;
    Positions[Index].Changed := True;
end;

procedure TfrmTarget.NewSelection(Index: Integer);
begin
    // virtual
    SelectedIndex := Index;
    if Positions[0].Position.InUse and Positions[SelectedIndex].Position.InUse then begin
        ProcessNewDirection(SelectedIndex);
    end;
end;

procedure TfrmTarget.tmrUpdatesTimer(Sender: TObject);
var
    Index: Integer;
begin
    if SelectedIndex > 0 then begin
        if Positions[0].Position.InUse and Positions[SelectedIndex].Position.InUse then begin
            if Positions[0].Changed or Positions[SelectedIndex].Changed then begin
                ProcessNewDirection(SelectedIndex);
            end;
        end;
    end;

    for Index := 0 to 3 do begin
        if Positions[Index].Changed then begin
            if ProcessNewPosition(Index) then begin
                Positions[Index].Changed := False;
            end;
        end;
    end;
end;

function TfrmTarget.ProcessNewPosition(Index: Integer): Boolean;
begin
    // virtual
    Result := True;
end;

procedure TfrmTarget.ProcessNewDirection(Index: Integer);
begin
    // virtual
end;

procedure TfrmTarget.UpdatePayloadID(Index: Integer; PayloadID: String);
begin
    // virtual
end;

end.
