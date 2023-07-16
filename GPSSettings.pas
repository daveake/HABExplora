unit GPSSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SettingsBase, FMX.TMSCustomEdit, FMX.TMSEdit, FMX.Objects, Miscellaneous,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, Soap.InvokeRegistry,
  Soap.Rio, Soap.SOAPHTTPClient, System.Net.URLClient, FMX.Memo.Types;

type
  TfrmGPSSettings = class(TfrmSettingsBase)
    Label2: TLabel;
    edtPeriod: TTMSFMXEdit;
    Label3: TLabel;
    edtCallsign: TTMSFMXEdit;
    Label1: TLabel;
    edtOffset: TTMSFMXEdit;
    HTTPRIO1: THTTPRIO;
    chkSondehubUpload: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure chkSettingsClick(Sender: TObject);
    procedure edtPortChangeTracking(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure ApplyChanges; override;
    procedure CancelChanges; override;
  public
    { Public declarations }
    procedure LoadForm; override;
  end;

var
  frmGPSSettings: TfrmGPSSettings;

implementation

uses Main, Debug;

{$R *.fmx}

procedure TfrmGPSSettings.FormCreate(Sender: TObject);
begin
    inherited;
    Group := 'GPS';
end;

procedure TfrmGPSSettings.ApplyChanges;
begin
    inherited;

    SetSettingString('CHASE', 'Callsign', edtCallsign.Text);

    SetSettingBoolean('CHASE', 'Upload', LCARSLabelIsChecked(chkSondehubUpload));

    SetSettingInteger('CHASE', 'Period', edtPeriod.Text.ToInteger);
    SetSettingInteger('CHASE', 'Offset', edtOffset.Text.ToInteger);

    frmMain.UpdateCarUploadSettings;
end;

procedure TfrmGPSSettings.CancelChanges;
begin
    inherited;

    edtCallsign.Text := GetSettingString('CHASE', 'Callsign', '');

    CheckLCARSLabel(chkSondehubUpload, GetSettingBoolean('CHASE', 'Upload', False));

    edtPeriod.Text := GetSettingInteger('CHASE', 'Period', 0).ToString;
    edtOffset.Text := GetSettingInteger('CHASE', 'Offset', 0).ToString;

    inherited;
end;

procedure TfrmGPSSettings.chkSettingsClick(Sender: TObject);
begin
    SetingsHaveChanged;
    LCARSLabelClick(Sender);
end;

procedure TfrmGPSSettings.edtPortChangeTracking(Sender: TObject);
begin
    SetingsHaveChanged;
end;

procedure TfrmGPSSettings.LoadForm;
begin
    inherited;

end;


end.
