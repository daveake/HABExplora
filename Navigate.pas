unit Navigate;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TargetForm, FMX.Controls.Presentation;

type
  TfrmNavigate = class(TfrmTarget)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    chkPayload1: TLabel;
    chkPayload2: TLabel;
    chkPayload3: TLabel;
    chkPrediction: TLabel;
    chkCurrent: TLabel;
    tmrInit: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure chkPayload1Click(Sender: TObject);
    procedure chkCurrentClick(Sender: TObject);
    procedure tmrInitTimer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
    Labels: Array[1..3] of TLabel;
    function SelectedPayloadIndex: Integer;
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure UpdatePayloadID(Index: Integer; PayloadID: String); override;
    procedure NewSelection(Index: Integer); override;
  end;

var
  frmNavigate: TfrmNavigate;

implementation

uses Main;

{$R *.fmx}

function TfrmNavigate.SelectedPayloadIndex: Integer;
begin
    if LCARSLabelIsChecked(chkPayload1) then begin
        Result := 1;
    end else if LCARSLabelIsChecked(chkPayload2) then begin
        Result := 2;
    end else if LCARSLabelIsChecked(chkPayload2) then begin
        Result := 3;
    end else begin
        Result := 0;
    end;
end;

procedure TfrmNavigate.Button1Click(Sender: TObject);
begin
    frmMain.NavigateToPayload(SelectedPayloadIndex, LCARSLabelIsChecked(chkPrediction));
end;

procedure TfrmNavigate.Button2Click(Sender: TObject);
begin
    frmMain.ShowRouteToPayload(SelectedPayloadIndex, LCARSLabelIsChecked(chkPrediction));
end;

procedure TfrmNavigate.Button3Click(Sender: TObject);
begin
    frmMain.NavigateToPayload(SelectedPayloadIndex, LCARSLabelIsChecked(chkPrediction), True);
end;

procedure TfrmNavigate.chkCurrentClick(Sender: TObject);
begin
    CheckLCARSLabel(chkCurrent, TLabel(Sender) = chkCurrent);
    CheckLCARSLabel(chkPrediction, TLabel(Sender) = chkPrediction);
end;

procedure TfrmNavigate.chkPayload1Click(Sender: TObject);
var
    i: Integer;
begin
    if TLabel(Sender).Text <> '' then begin
        for i := 1 to 3 do begin
            CheckLCARSLabel(Labels[i], Labels[i] = TLabel(Sender));
        end;
    end;
end;

procedure TfrmNavigate.FormCreate(Sender: TObject);
begin
    Labels[1] := chkPayload1;
    Labels[2] := chkPayload2;
    Labels[3] := chkPayload3;
end;

procedure TfrmNavigate.UpdatePayloadID(Index: Integer; PayloadID: String);
begin
    inherited;

    Labels[Index].Text := PayloadID;
end;

procedure TfrmNavigate.LoadForm;
begin
    inherited;

    tmrInit.Enabled := True;
end;

procedure TfrmNavigate.NewSelection(Index: Integer);
var
    i: Integer;
begin
    inherited;

    for i := 1 to 3 do begin
        CheckLCARSLabel(Labels[i], i = Index);
    end;
end;

procedure TfrmNavigate.tmrInitTimer(Sender: TObject);
begin
    tmrInit.Enabled := False;

    CheckLCARSLabel(chkCurrent, True);
    CheckLCARSLabel(chkPrediction, False);

    NewSelection(SelectedIndex);
end;

end.
