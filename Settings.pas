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
    pnlCentre: TPanel;
    btnLoRaBluetooth: TButton;
    pnlTop: TRectangle;
    crcBottomRight: TCircle;
    rectBottomRight: TRectangle;
    crcBottomLeft: TCircle;
    rectSources: TRectangle;
    rectBottomLeft: TRectangle;
    procedure FormCreate(Sender: TObject);
    procedure btnGPSClick(Sender: TObject);
    procedure btnLoRaSerialClick(Sender: TObject);
    procedure btnOtherClick(Sender: TObject);
    procedure btnLoRaBluetoothClick(Sender: TObject);
    procedure pnlMainResize(Sender: TObject);
  private
    { Private declarations }
    CurrentForm: TfrmSettingsBase;
    procedure ShowSelectedButton(Button: TButton);
    procedure LoadSettingsForm(Button: TButton; NewForm: TfrmSettingsBase);
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure LoadPage(PageIndex: Integer);
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
        CurrentForm.Free;
    end;

    NewForm.pnlMain.Parent := pnlCentre;

    CurrentForm := NewForm;

    NewForm.LoadForm;

    frmMain.ResizeFonts(NewForm);
end;

procedure TfrmSettings.pnlMainResize(Sender: TObject);
begin
    pnlTop.Height := frmMain.rectTopBar.Height;

    pnlTop.Margins.Left := pnlTop.Height / 2;
    pnlTop.Margins.Right := pnlTop.Height / 2;

    rectSources.Margins.Left := - pnlTop.Height / 2;

    crcBottomLeft.Width := crcBottomLeft.Height;
    crcBottomLeft.Margins.Left := -crcBottomLeft.Height/2;
    crcBottomRight.Width := crcBottomRight.Height;
    crcBottomRight.Margins.Right := -crcBottomRight.Height/2;

    rectBottomLeft.Margins.Bottom := crcBottomLeft.Height / 2;
    rectBottomRight.Margins.Bottom := crcBottomLeft.Height / 2;
end;

procedure TfrmSettings.btnGPSClick(Sender: TObject);
begin
    frmGPSSettings := TfrmGPSSettings.Create(nil);

    LoadSettingsForm(btnGPS, frmGPSSettings);
end;

procedure TfrmSettings.btnOtherClick(Sender: TObject);
begin
    frmOtherSettings := TfrmOtherSettings.Create(nil);

    LoadSettingsForm(btnOther, frmOtherSettings);
end;

procedure TfrmSettings.btnLoRaBluetoothClick(Sender: TObject);
begin
    frmBluetoothSettings := TfrmBluetoothSettings.Create(nil);

    LoadSettingsForm(btnLoRaBluetooth, frmBluetoothSettings);
end;

procedure TfrmSettings.btnLoRaSerialClick(Sender: TObject);
begin
    frmLoRaSerialSettings := TfrmLoRaSerialSettings.Create(nil);

    LoadSettingsForm(btnLoRaSerial, frmLoRaSerialSettings);
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
    inherited;

    {$IF Defined(MSWINDOWS) or Defined(ANDROID)}
    {$ELSE}
        btnLoRaSerial.Text := '';
        btnLoRaBluetooth.Text := 'BLE';
    {$ENDIF}
end;

procedure TfrmSettings.LoadForm;
begin
    inherited;

    frmGPSSettings := TfrmGPSSettings.Create(nil);

    LoadSettingsForm(btnGPS, frmGPSSettings);

//    btnGPS.Font.Size := btnGPS.Size.Height * 36/64;
//    btnLoRaSerial.Font.Size := btnGPS.Font.Size;
//    btnLoRaBluetooth.Font.Size := btnGPS.Font.Size;
end;

procedure TfrmSettings.ShowSelectedButton(Button: TButton);
begin
    btnGPS.TextSettings.Font.Style := btnGPS.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnLoRaSerial.TextSettings.Font.Style := btnLoRaSerial.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnLoRaBluetooth.TextSettings.Font.Style := btnLoRaBluetooth.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnOther.TextSettings.Font.Style := btnOther.TextSettings.Font.Style - [TFontStyle.fsUnderline];

    Button.TextSettings.Font.Style := Button.TextSettings.Font.Style + [TFontStyle.fsUnderline];
end;

procedure TfrmSettings.LoadPage(PageIndex: Integer);
begin
    case PageIndex of
        0:  btnGPSClick(nil);
        1:  btnLoRaSerialClick(nil);
        2:  btnLoRaBluetoothClick(nil);
    end;
end;

end.
