unit OtherSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SettingsBase, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Controls.Presentation,
  Miscellaneous, FMX.TMSCustomEdit, FMX.TMSEdit, FMX.Memo.Types;

type
  TfrmOtherSettings = class(TfrmSettingsBase)
    chkEnableSondehub: TLabel;
    Label2: TLabel;
    edtUDPTxPort: TTMSFMXEdit;
    edtWhiteList: TTMSFMXEdit;
    Label1: TLabel;
    Label3: TLabel;
    edtUDPRxPort: TTMSFMXEdit;
    chkEnableHABHUB: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure chkEnableSondehubClick(Sender: TObject);
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

    SetSettingBoolean('Habitat', 'Enabled', LCARSLabelIsChecked(chkEnableHABHUB));
    SetSettingBoolean('Sondehub', 'Enabled', LCARSLabelIsChecked(chkEnableSondehub));

    SetSettingString('Habitat', 'WhiteList', edtWhiteList.Text);
    SetSettingString('Sondehub', 'WhiteList', edtWhiteList.Text);

    SetSettingString('UDP', 'Port', edtUDPRxPort.Text);

    inherited;
end;

procedure TfrmOtherSettings.CancelChanges;
begin
    inherited;

    edtUDPTxPort.Text := IntToStr(GetSettingInteger(Group, 'UDPTxPort', 0));

    CheckLCARSLabel(chkEnableHABHUB, GetSettingBoolean('Habitat', 'Enabled', False));
    CheckLCARSLabel(chkEnableSondehub, GetSettingBoolean('Sondehub', 'Enabled', False));

    edtWhiteList.Text := GetSettingString('Habitat', 'WhiteList', '');

    edtUDPRxPort.Text := GetSettingString('UDP', 'Port', '');
end;

procedure TfrmOtherSettings.chkEnableSondehubClick(Sender: TObject);
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
