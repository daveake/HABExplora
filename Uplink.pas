unit Uplink;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TargetForm, FMX.Controls.Presentation, FMX.TMSCustomEdit, FMX.TMSEdit,
  FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics, FMX.TMSFNCGraphicsTypes,
  FMX.Objects, FMX.TMSFNCHTMLImageContainer, FMX.TMSFNCRadioButton,
  FMX.TMSFNCPageControl, FMX.TMSFNCCustomControl, FMX.TMSFNCTabSet;

type
  TfrmUplink = class(TfrmTarget)
    chkPayload1: TLabel;
    chkPayload2: TLabel;
    chkPayload3: TLabel;
    tmrInit: TTimer;
    chkSource1: TLabel;
    chkSource2: TLabel;
    btnSearch: TButton;
    TMSFNCPageControl1: TTMSFNCPageControl;
    TMSFNCPageControl1Page0: TTMSFNCPageControlContainer;
    TMSFNCPageControl1Page1: TTMSFNCPageControlContainer;
    TMSFNCPageControl1Page2: TTMSFNCPageControlContainer;
    TMSFNCPageControl1Page3: TTMSFNCPageControlContainer;
    TMSFNCPageControlContainer1: TTMSFNCPageControlContainer;
    TMSFNCPageControlContainer2: TTMSFNCPageControlContainer;
    TMSFNCPageControlContainer3: TTMSFNCPageControlContainer;
    TMSFNCPageControlContainer4: TTMSFNCPageControlContainer;
    TMSFNCPageControlContainer5: TTMSFNCPageControlContainer;
    lblCutown: TLabel;
    edtCutdownPeriod: TTMSFMXEdit;
    chkImmediate: TTMSFNCRadioButton;
    chkCutdownAltitude: TTMSFNCRadioButton;
    Label2: TLabel;
    edtAltitude: TTMSFMXEdit;
    TMSFNCPageControlContainer6: TTMSFNCPageControlContainer;
    Label3: TLabel;
    edtPin: TTMSFMXEdit;
    Label4: TLabel;
    edtPinPeriod: TTMSFMXEdit;
    TMSFNCPageControlContainer7: TTMSFNCPageControlContainer;
    Label5: TLabel;
    edtServoPin: TTMSFMXEdit;
    Label6: TLabel;
    edtServoPeriod: TTMSFMXEdit;
    Label7: TLabel;
    edtServoPosition: TTMSFMXEdit;
    TMSFNCPageControlContainer8: TTMSFNCPageControlContainer;
    Label8: TLabel;
    edtScriptName: TTMSFMXEdit;
    rectWhen: TRectangle;
    chkNow: TTMSFNCRadioButton;
    chkRx: TTMSFNCRadioButton;
    chkSeconds: TTMSFNCRadioButton;
    edtSeconds: TTMSFMXEdit;
    Label1: TLabel;
    edtPassword: TTMSFMXEdit;
    tmrSending: TTimer;
    lblSending: TLabel;
    procedure chkPayload1Click(Sender: TObject);
    procedure tmrInitTimer(Sender: TObject);
    procedure chkSource1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure tmrSendingTimer(Sender: TObject);
    procedure pnlMainResize(Sender: TObject);
  private
    { Private declarations }
    PayloadLabels: Array[1..3] of TLabel;
    TargetLabels: Array[1..2] of TLabel;
    function SelectedPayloadIndex: Integer;
    procedure ShowAvailableSources(Index: Integer);
    function BuildUplinkCommand: String;
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure UpdatePayloadID(Index: Integer; PayloadID: String); override;
    procedure NewSelection(Index: Integer); override;
  end;

var
  frmUplink: TfrmUplink;

implementation

{$R *.fmx}

uses Main, Miscellaneous, SourcesForm, Source;


function TfrmUplink.BuildUplinkCommand: String;
var
    PayloadID, Command: String;
begin
    if LCARSLabelIsChecked(chkPayload1) then begin
        PayloadID := chkPayload1.Text;
    end else if LCARSLabelIsChecked(chkPayload2) then begin
        PayloadID := chkPayload2.Text;
    end else if LCARSLabelIsChecked(chkPayload3) then begin
        PayloadID := chkPayload3.Text;
    end else begin
        PayloadID := '';
    end;

    if TMSFNCPageControl1.ActivePageIndex = 0 then begin
        Command := 'C';
        if chkCutdownAltitude.Checked then begin
            Command := Command + 'A' + IntToStr(StrToIntDef(edtAltitude.Text, 0));
        end else begin
            Command := Command + 'N' + IntToStr(StrToIntDef(edtCutdownPeriod.Text, 0));
        end;
    end else if TMSFNCPageControl1.ActivePageIndex = 1 then begin
        Command := 'P' + IntToStr(StrToIntDef(edtPin.Text, 0)) + '/' +
                         IntToStr(StrToIntDef(edtPinPeriod.Text, 0))
    end else if TMSFNCPageControl1.ActivePageIndex = 2 then begin
        Command := 'S' + IntToStr(StrToIntDef(edtServoPin.Text, 0)) + '/' +
                         IntToStr(StrToIntDef(edtServoPeriod.Text, 0)) + '/' +
                         IntToStr(StrToIntDef(edtServoPosition.Text, 0));
    end else begin
        Command := 'R' + edtScriptName.Text;
    end;

    if (PayloadID <> '') and (Command <> '') then begin
        Result := PayloadID + '/' + Command;
    end;
end;

function TfrmUplink.SelectedPayloadIndex: Integer;
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

procedure TfrmUplink.btnSearchClick(Sender: TObject);
var
    SourceIndex, WhenSeconds: Integer;
    When: TUplinkWhen;
begin
    if LCARSLabelIsChecked(chkSource1) then begin
        SourceIndex := SERIAL_SOURCE;
    end else begin
        SourceIndex := BLUETOOTH_SOURCE;
    end;

    WhenSeconds := 0;

    if SourceIndex in [SERIAL_SOURCE, BLUETOOTH_SOURCE] then begin
        if chkNow.Checked then begin
            When := uwNow;
        end else if chkSeconds.Checked then begin
            When := uwSecondsAfterMinute;
            WhenSeconds := StrToIntDef(edtSeconds.Text, 0);
        end else begin
            When := uwAfterRx;
        end;
    end else begin
        When := uwNow;
    end;


    if SourceIndex > 0 then begin
        lblSending.Visible := True;

        frmSources.SendUplink(SourceIndex, When, WhenSeconds, -1, '~T*', BuildUplinkCommand, edtPassword.Text);

        tmrSending.Tag := SourceIndex;
        tmrSending.Enabled := True;
    end;
end;

procedure TfrmUplink.chkPayload1Click(Sender: TObject);
var
    i: Integer;
begin
    if TLabel(Sender).Text <> '' then begin
        for i := 1 to 3 do begin
            CheckLCARSLabel(PayloadLabels[i], PayloadLabels[i] = TLabel(Sender));
        end;
        ShowAvailableSources(TLabel(Sender).Tag);
    end;
end;

procedure TfrmUplink.chkSource1Click(Sender: TObject);
var
    i: Integer;
begin
    for i := 1 to 2 do begin
        CheckLCARSLabel(TargetLabels[i], TargetLabels[i] = TLabel(Sender));
    end;

    lblCutown.Enabled := True;

    btnSearch.Enabled := True;
end;

procedure TfrmUplink.FormCreate(Sender: TObject);
begin
    inherited;

    PayloadLabels[1] := chkPayload1;
    PayloadLabels[2] := chkPayload2;
    PayloadLabels[3] := chkPayload3;

    TargetLabels[1] := chkSource1;
    TargetLabels[2] := chkSource2;
end;

procedure TfrmUplink.LoadForm;
begin
    inherited;

    tmrInit.Enabled := True;
end;

procedure TfrmUplink.UpdatePayloadID(Index: Integer; PayloadID: String);
begin
    inherited;

    PayloadLabels[Index].Text := PayloadID;
    PayloadLabels[Index].Enabled := PayloadID <> '';
end;

procedure TfrmUplink.NewSelection(Index: Integer);
var
    i: Integer;
begin
    inherited;

    for i := 1 to 3 do begin
        CheckLCARSLabel(PayloadLabels[i], i = Index);
    end;

    ShowAvailableSources(SelectedIndex);
end;

procedure TfrmUplink.pnlMainResize(Sender: TObject);
begin
    inherited;

    TMSFNCPageControl1.TabSize.Width := TMSFNCPageControl1.Width / TMSFNCPageControl1.Pages.Count;
end;

function BitForButton(ButtonNumber: Integer): Integer;
begin
    case ButtonNumber of
        1:  Result := (1 shl (2 * 1)) shl 0;
        2:  Result := (1 shl (2 * 2)) shl 0;
    end;
end;

procedure TfrmUplink.ShowAvailableSources(Index: Integer);
var
    i: Integer;
    ChooseFirst: Boolean;
begin
    ChooseFirst := True;

    for i := 1 to 2 do begin
        if Index in [1..3] then begin
            TargetLabels[i].Enabled := (frmMain.GetSourceMask(Index) and BitForButton(i)) > 0;
            if TargetLabels[i].Enabled and ChooseFirst then begin
                ChooseFirst := False;
                chkSource1Click(TargetLabels[i]);
            end;

        end else begin
            TargetLabels[i].Enabled := False;
        end;
    end;
end;


procedure TfrmUplink.tmrInitTimer(Sender: TObject);
begin
    tmrInit.Enabled := False;

//    chkCutdown.Enabled := False;
    lblCutown.Enabled := False;
//    edtCutdown.Enabled := False;
    btnSearch.Enabled := False;

//    CheckLCARSLabel(chkCurrent, True);
//    CheckLCARSLabel(chkPrediction, False);

    NewSelection(SelectedIndex);
end;

procedure TfrmUplink.tmrSendingTimer(Sender: TObject);
begin
    if not frmSources.WaitingToSend(TTimer(Sender).Tag) then begin
        lblSending.Visible := False;
        tmrSending.Enabled := False;
    end;
end;

end.
