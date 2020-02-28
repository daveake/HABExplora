unit LoRaGatewaySettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SettingsBase, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Controls.Presentation,
  FMX.TMSCustomEdit, FMX.TMSEdit, Miscellaneous, Source;

type
  TfrmLoRaGatewaySettings = class(TfrmSettingsBase)
    Label1: TLabel;
    edtHost: TTMSFMXEdit;
    Label3: TLabel;
    edtPort: TTMSFMXEdit;
    procedure FormCreate(Sender: TObject);
    procedure edtHostChangeTracking(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure ApplyChanges; override;
    procedure CancelChanges; override;
  public
    { Public declarations }
  end;

var
  frmLoRaGatewaySettings: TfrmLoRaGatewaySettings;

implementation

{$R *.fmx}

uses Main;

procedure TfrmLoRaGatewaySettings.ApplyChanges;
begin
    SetSettingString(Group, 'Host', edtHost.Text);
    SetSettingString(Group, 'Port', edtPort.Text);

    inherited;
end;

procedure TfrmLoRaGatewaySettings.CancelChanges;
begin
    inherited;

    edtHost.Text := GetSettingString(Group, 'Host', '');
    edtPort.Text := GetSettingInteger(Group, 'Port', 0).ToString;
end;

procedure TfrmLoRaGatewaySettings.edtHostChangeTracking(Sender: TObject);
begin
    SetingsHaveChanged;
end;

procedure TfrmLoRaGatewaySettings.FormCreate(Sender: TObject);
begin
    inherited;
    Group := 'LoRaGateway';
end;

end.
