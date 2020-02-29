unit OtherSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SettingsBase, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Controls.Presentation,
  Miscellaneous, FMX.TMSCustomEdit, FMX.TMSEdit;

type
  TfrmOtherSettings = class(TfrmSettingsBase)
    ChkEnable: TLabel;
    Label2: TLabel;
    edtUDPTxPort: TTMSFMXEdit;
    edtWhiteList: TTMSFMXEdit;
    Label1: TLabel;
    Label3: TLabel;
    edtUDPRxPort: TTMSFMXEdit;
    procedure FormCreate(Sender: TObject);
    procedure ChkEnableClick(Sender: TObject);
    procedure edtUDPTxPortChangeTracking(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  protected
    procedure ApplyChanges; override;
    procedure CancelChanges; override;
  end;

var
  frmOtherSettings: TfrmOtherSettings;

implementation

{$R *.fmx}

procedure TfrmOtherSettings.ApplyChanges;
begin
    SetSettingInteger(Group, 'UDPTxPort', StrToIntDef(edtUDPTxPort.Text, 0));

    SetSettingBoolean('Habitat', 'Enable', LCARSLabelIsChecked(chkEnable));
    SetSettingString('Habitat', 'WhiteList', edtWhiteList.Text);

    SetSettingString('UDP', 'Port', edtUDPRxPort.Text);

    inherited;
end;

procedure TfrmOtherSettings.CancelChanges;
begin
    inherited;

    edtUDPTxPort.Text := IntToStr(GetSettingInteger(Group, 'UDPTxPort', 0));

    edtWhiteList.Text := GetSettingString('Habitat', 'WhiteList', '');
    CheckLCARSLabel(chkEnable, GetSettingBoolean('Habitat', 'Enable', False));

    edtUDPRxPort.Text := GetSettingString('UDP', 'Port', '');
end;

procedure TfrmOtherSettings.ChkEnableClick(Sender: TObject);
begin
    SetingsHaveChanged;
    LCARSLabelClick(Sender);
end;

procedure TfrmOtherSettings.edtUDPTxPortChangeTracking(Sender: TObject);
begin
    SetingsHaveChanged;
end;

procedure TfrmOtherSettings.FormCreate(Sender: TObject);
begin
    inherited;
    Group := 'General';
end;

end.
