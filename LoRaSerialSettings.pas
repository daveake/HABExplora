unit LoRaSerialSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SettingsBase, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Controls.Presentation,
  FMX.TMSCustomEdit, FMX.TMSEdit, Miscellaneous, Math, FMX.Memo.Types;

type
  TfrmLoRaSerialSettings = class(TfrmSettingsBase)
    chkSSDV: TLabel;
    Label2: TLabel;
    edtFrequency: TTMSFMXEdit;
    btnModeDown: TLabel;
    Label3: TLabel;
    edtMode: TTMSFMXEdit;
    btnModeUp: TLabel;
    Label1: TLabel;
    edtCallsign: TTMSFMXEdit;
    chkAFC: TLabel;
    rectProgressHolder: TRectangle;
    rectProgressBar: TRectangle;
    btnSearch: TButton;
    tmrReceive: TTimer;
    tmrSearch: TTimer;
    rectRx: TRectangle;
    lblRx: TLabel;
    chkSondehub: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure chkSondehubClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure edtPortChangeTracking(Sender: TObject);
    procedure btnModeDownClick(Sender: TObject);
    procedure btnModeUpClick(Sender: TObject);
    procedure edtFrequencyExit(Sender: TObject);
    procedure tmrReceiveTimer(Sender: TObject);
    procedure tmrSearchTimer(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
  private
    { Private declarations }
    Searching: Boolean;
    SearchCentreFrequency: Double;
    SearchPacketCount, SearchStep: Integer;
    procedure SendSettingsToDevice;
    procedure NextSearch;
    procedure StopSearch;
  protected
    procedure ApplyChanges; override;
    procedure CancelChanges; override;
  public
    { Public declarations }
  end;

var
  frmLoRaSerialSettings: TfrmLoRaSerialSettings;

implementation

uses SourcesForm;

{$R *.fmx}

procedure TfrmLoRaSerialSettings.ApplyChanges;
begin
    // SetSettingString(Group, 'Port', edtPort.Text);

    SetSettingBoolean(Group, 'AFC', LCARSLabelIsChecked(chkAFC));

    SetSettingString(Group, 'Frequency', edtFrequency.Text);
    SetSettingString(Group, 'Mode', edtMode.Text);
    SetSettingString(Group, 'Callsign', edtCallsign.Text);

    SetSettingBoolean(Group, 'Sondehub', LCARSLabelIsChecked(chkSondehub));

    SetSettingBoolean(Group, 'SSDV', LCARSLabelIsChecked(chkSSDV));

    inherited;
end;

procedure TfrmLoRaSerialSettings.btnApplyClick(Sender: TObject);
begin
    inherited;

    SendSettingsToDevice;
end;

procedure TfrmLoRaSerialSettings.SendSettingsToDevice;
begin
    frmSources.SendParameterToSource(SERIAL_SOURCE, 'F', edtFrequency.Text);
    frmSources.SendParameterToSource(SERIAL_SOURCE, 'M', edtMode.Text);
end;

procedure TfrmLoRaSerialSettings.tmrReceiveTimer(Sender: TObject);
var
    PacketCount: Integer;
begin
    PacketCount := frmSources.GetPacketCount(SERIAL_SOURCE);

    Inc(SearchPacketCount, PacketCount);

    if PacketCount > 0 then begin
        rectRx.Visible := True;
        frmSources.ResetPacketCount(SERIAL_SOURCE);
    end else begin
        rectRx.Visible := False;
    end;
end;

procedure TfrmLoRaSerialSettings.tmrSearchTimer(Sender: TObject);
begin
    tmrSearch.Enabled := False;

    if SearchPacketCount > 1 then begin
        StopSearch;
    end else begin
        NextSearch;
    end;
end;

procedure TfrmLoRaSerialSettings.btnCancelClick(Sender: TObject);
begin
    inherited;
    //
end;

procedure TfrmLoRaSerialSettings.btnModeDownClick(Sender: TObject);
begin
    edtMode.Text := IntToStr(Max(0,Min(7,StrToIntDef(edtMode.Text, 0)-1)));
    SetingsHaveChanged;
end;

procedure TfrmLoRaSerialSettings.btnModeUpClick(Sender: TObject);
begin
    edtMode.Text := IntToStr(Max(0,Min(7,StrToIntDef(edtMode.Text, 0)+1)));
    SetingsHaveChanged;
end;

procedure TfrmLoRaSerialSettings.btnSearchClick(Sender: TObject);
begin
    rectProgressBar.Width := 0;
    rectProgressHolder.Visible := True;
    SearchCentreFrequency := StrToFloat(edtFrequency.Text);
    SearchStep := -6;
    Searching := True;
    NextSearch;
end;

procedure TfrmLoRaSerialSettings.CancelChanges;
begin
    // edtPort.Text := GetSettingString(Group, 'Port', '');
    edtFrequency.Text := GetSettingString(Group, 'Frequency', '');
    edtMode.Text := GetSettingString(Group, 'Mode', '');
    edtCallsign.Text := GetSettingString(Group, 'Callsign', '');

    CheckLCARSLabel(chkSondehub, GetSettingBoolean(Group, 'Sondehub', False));

    CheckLCARSLabel(chkSSDV, GetSettingBoolean(Group, 'SSDV', False));
    CheckLCARSLabel(chkAFC, GetSettingBoolean(Group, 'AFC', False));

    SendSettingsToDevice;

    inherited;
end;

procedure TfrmLoRaSerialSettings.chkSondehubClick(Sender: TObject);
begin
    SetingsHaveChanged;
    LCARSLabelClick(Sender);
end;

procedure TfrmLoRaSerialSettings.edtFrequencyExit(Sender: TObject);
begin
    FixFloatEditBox(edtFrequency);
end;

procedure TfrmLoRaSerialSettings.edtPortChangeTracking(Sender: TObject);
begin
    SetingsHaveChanged;
end;

procedure TfrmLoRaSerialSettings.FormCreate(Sender: TObject);
begin
    inherited;
    Group := 'LoRaSerial';

{$IF Defined(IOS) or Defined(ANDROID)}
    // edtPort.Visible := False;
    // lblPort.Visible := False;
{$ENDIF}
end;

procedure TfrmLoRaSerialSettings.NextSearch;
begin
    Inc(SearchStep);

    if SearchStep > 5 then begin
        // pnlSearchFrequency.Caption := '';
        rectProgressBar.Width := 0;
        rectProgressHolder.Visible := False;
        Searching := False;
        frmSources.SendParameterToSource(SERIAL_SOURCE, 'F', edtFrequency.Text);
    end else begin
        // pnlSearchFrequency.Caption := FormatFloat('.0000', SearchFrequency);
        rectProgressBar.Width := (SearchStep + 6) * rectProgressHolder.Width / 12;

        edtFrequency.Text := FormatFloat('0.000#', SearchCentreFrequency + SearchStep * 0.002);
        frmSources.SendParameterToSource(SERIAL_SOURCE, 'F', edtFrequency.Text);

        SearchPacketCount := 0;
        tmrSearch.Enabled := True;
    end;
end;

procedure TfrmLoRaSerialSettings.StopSearch;
begin
    edtFrequency.Text := FormatFloat('0.000#', StrToFloat(edtFrequency.Text) + frmSources.FrequencyError(SERIAL_SOURCE) / 1000);

    frmSources.SendParameterToSource(SERIAL_SOURCE, 'F', FormatFloat('0.000#', SearchCentreFrequency + SearchStep * 0.002));

    rectProgressBar.Width := 0;
    rectProgressHolder.Visible := False;

    Searching := False;
end;

end.
