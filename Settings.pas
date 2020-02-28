unit Settings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Base, FMX.Controls.Presentation, FMX.Edit, FMX.Layouts, FMX.ListBox,
  FMX.TMSCustomEdit, FMX.TMSEdit, FMX.Objects, SettingsBase, LoRaBluetoothSettings;

type
  TSettingType = (stString, stInteger, stBoolean, stSerialPort, stBluetooth);

type
  TfrmSettings = class(TfrmBase)
    btnGPS: TButton;
    btnOther: TButton;
    btnLoRaSerial: TButton;
    Circle1: TCircle;
    Circle2: TCircle;
    Rectangle1: TRectangle;
    Rectangle5: TRectangle;
    pnlTop: TPanel;
    pnlCentre: TPanel;
    Rectangle2: TRectangle;
    Rectangle3: TRectangle;
    btnLoRaBluetooth: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnGPSClick(Sender: TObject);
    procedure btnLoRaSerialClick(Sender: TObject);
    procedure btnOtherClick(Sender: TObject);
    procedure btnLoRaBluetoothClick(Sender: TObject);
  private
    { Private declarations }
    CurrentForm: TfrmSettingsBase;
    procedure ShowSelectedButton(Button: TButton);
    procedure LoadSettingsForm(Button: TButton; NewForm: TfrmSettingsBase);
  public
    { Public declarations }
    procedure LoadForm; override;
  end;

var
  frmSettings: TfrmSettings;

implementation

{$R *.fmx}

uses Main, GPSSettings, OtherSettings, LoRaSerialSettings;

procedure TfrmSettings.LoadSettingsForm(Button: TButton; NewForm: TfrmSettingsBase);
begin
    ShowSelectedButton(Button);

    if CurrentForm <> nil then begin
        CurrentForm.pnlMain.Parent := CurrentForm;
        CurrentForm.HideForm;
    end;

    NewForm.pnlMain.Parent := pnlCentre;
    CurrentForm := NewForm;
    NewForm.LoadForm;
end;

procedure TfrmSettings.btnGPSClick(Sender: TObject);
begin
    LoadSettingsForm(TButton(Sender), frmGPSSettings);
end;

procedure TfrmSettings.btnOtherClick(Sender: TObject);
begin
    LoadSettingsForm(TButton(Sender), frmOtherSettings);
end;

procedure TfrmSettings.btnLoRaBluetoothClick(Sender: TObject);
begin
    LoadSettingsForm(TButton(Sender), frmBluetoothSettings);
end;

procedure TfrmSettings.btnLoRaSerialClick(Sender: TObject);
begin
    if frmLoRaSerialSettings <> nil then begin
        LoadSettingsForm(TButton(Sender), frmLoRaSerialSettings);
    end;
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
    inherited;

    frmGPSSettings := TfrmGPSSettings.Create(nil);
    frmOtherSettings := TfrmOtherSettings.Create(nil);
    frmBluetoothSettings := TfrmBluetoothSettings.Create(nil);

    {$IF Defined(MSWINDOWS) or Defined(ANDROID)}
        frmLoRaSerialSettings := TfrmLoRaSerialSettings.Create(nil);
    {$ELSE}
        btnLoRaSerial.Text := '';
        btnLoRaBluetooth.Text := 'BLE';
    {$ENDIF}
end;

procedure TfrmSettings.LoadForm;
begin
    inherited;

    LoadSettingsForm(btnGPS, frmGPSSettings);

//    btnGPS.Font.Size := btnGPS.Size.Height * 36/64;
//    btnLoRaSerial.Font.Size := btnGPS.Font.Size;
//    btnLoRaBluetooth.Font.Size := btnGPS.Font.Size;
//    btnHabitat.Font.Size := btnGPS.Font.Size;
end;

procedure TfrmSettings.ShowSelectedButton(Button: TButton);
begin
    btnGPS.TextSettings.Font.Style := btnGPS.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnLoRaSerial.TextSettings.Font.Style := btnLoRaSerial.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnLoRaBluetooth.TextSettings.Font.Style := btnLoRaBluetooth.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnOther.TextSettings.Font.Style := btnOther.TextSettings.Font.Style - [TFontStyle.fsUnderline];

    Button.TextSettings.Font.Style := Button.TextSettings.Font.Style + [TFontStyle.fsUnderline];
end;

end.
