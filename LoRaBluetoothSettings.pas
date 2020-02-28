unit LoRaBluetoothSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SettingsBase, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Controls.Presentation,
  FMX.TMSCustomEdit, FMX.TMSEdit, Miscellaneous, Math, System.Bluetooth,
  FMX.ListBox, System.Bluetooth.Components;

type
  TfrmBluetoothSettings = class(TfrmSettingsBase)
    chkHabitat: TLabel;
    chkSSDV: TLabel;
    Label2: TLabel;
    edtFrequency: TTMSFMXEdit;
    btnModeDown: TLabel;
    Label3: TLabel;
    edtMode: TTMSFMXEdit;
    btnModeUp: TLabel;
    Label1: TLabel;
    edtCallsign: TTMSFMXEdit;
    edtDevice: TTMSFMXEdit;
    Label4: TLabel;
    cmbDevices: TComboBox;
    BluetoothLE1: TBluetoothLE;
    procedure FormCreate(Sender: TObject);
    procedure chkHabitatClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnModeDownClick(Sender: TObject);
    procedure btnModeUpClick(Sender: TObject);
    procedure cmbDevicesClosePopup(Sender: TObject);
    procedure edtDeviceClick(Sender: TObject);
    procedure BluetoothLE1DiscoverLEDevice(const Sender: TObject;
      const ADevice: TBluetoothLEDevice; Rssi: Integer;
      const ScanResponse: TScanResponse);
    procedure edtFrequencyExit(Sender: TObject);
  private
    { Private declarations }
    procedure SendSettingsToDevice;
    procedure UpdateBluetoothList;
  protected
    procedure ApplyChanges; override;
    procedure CancelChanges; override;
  public
    { Public declarations }
    procedure LoadForm; override;
  end;

var
  frmBluetoothSettings: TfrmBluetoothSettings;

implementation

uses SourcesForm;

{$R *.fmx}

procedure TfrmBluetoothSettings.ApplyChanges;
begin
    SetSettingString(Group, 'Device', edtDevice.Text);

    SetSettingString(Group, 'Frequency', edtFrequency.Text);
    SetSettingString(Group, 'Mode', edtMode.Text);
    SetSettingString(Group, 'Callsign', edtCallsign.Text);

    SetSettingBoolean(Group, 'Habitat', LCARSLabelIsChecked(chkHabitat));
    SetSettingBoolean(Group, 'SSDV', LCARSLabelIsChecked(chkSSDV));

    inherited;
end;

procedure TfrmBluetoothSettings.BluetoothLE1DiscoverLEDevice(
  const Sender: TObject; const ADevice: TBluetoothLEDevice; Rssi: Integer;
  const ScanResponse: TScanResponse);
var
    i, Index: Integer;
    ShortLine, LongLine: String;
begin
    for i := 0 to BluetoothLE1.DiscoveredDevices.Count-1 do begin
//        {$IFDEF IOS}
//            ShortLine := Copy(BluetoothLE1.DiscoveredDevices.Items[i].Identifier, 26, 2) + ':' +
//                                   Copy(BluetoothLE1.DiscoveredDevices.Items[i].Identifier, 28, 2) + ':' +
//                                   Copy(BluetoothLE1.DiscoveredDevices.Items[i].Identifier, 30, 2) + ':' +
//                                   Copy(BluetoothLE1.DiscoveredDevices.Items[i].Identifier, 32, 2) + ':' +
//                                   Copy(BluetoothLE1.DiscoveredDevices.Items[i].Identifier, 34, 2) + ':' +
//                                   Copy(BluetoothLE1.DiscoveredDevices.Items[i].Identifier, 36, 2);
//        {$ELSE}
//            ShortLine := BluetoothLE1.DiscoveredDevices.Items[i].Identifier;      // Address
//        {$ENDIF}

//        if Length(BluetoothLE1.DiscoveredDevices.Items[i].DeviceName) > 2 then begin
//            LongLine := ShortLine + ': ' + BluetoothLE1.DiscoveredDevices.Items[i].DeviceName;
//        end else begin
//            LongLine := ShortLine;
//        end;

//        Index := cmbDevices.Items.IndexOf(LongLine);
//        if Index < 0 then begin
//            // Now try short version
//            Index := cmbDevices.Items.IndexOf(ShortLine);
//            if Index < 0 then begin
//                Index := cmbDevices.Items.Add(LongLine);
//            end else begin
//                cmbDevices.Items[Index] := LongLine;
//            end;
//        end;

        ShortLine := BluetoothLE1.DiscoveredDevices.Items[i].DeviceName;
        Index := cmbDevices.Items.IndexOf(ShortLine);
        if Index < 0 then begin
            Index := cmbDevices.Items.Add(ShortLine);
        end;

        cmbDevices.ItemIndex := cmbDevices.Items.IndexOf(edtDevice.Text);
    end;
end;

procedure TfrmBluetoothSettings.btnApplyClick(Sender: TObject);
begin
    inherited;

    FixFloatEditBox(edtFrequency);

    SendSettingsToDevice;
end;

procedure TfrmBluetoothSettings.SendSettingsToDevice;
begin
    frmSources.SendParameterToSource(BLUETOOTH_SOURCE, 'F', edtFrequency.Text);
    frmSources.SendParameterToSource(BLUETOOTH_SOURCE, 'M', edtMode.Text);
end;

procedure TfrmBluetoothSettings.btnCancelClick(Sender: TObject);
begin
    inherited;
    //
end;

procedure TfrmBluetoothSettings.btnModeDownClick(Sender: TObject);
begin
    edtMode.Text := IntToStr(Max(0,Min(7,StrToIntDef(edtMode.Text, 0)-1)));
end;

procedure TfrmBluetoothSettings.btnModeUpClick(Sender: TObject);
begin
    edtMode.Text := IntToStr(Max(0,Min(7,StrToIntDef(edtMode.Text, 0)+1)));
end;

procedure TfrmBluetoothSettings.CancelChanges;
begin
    inherited;

    edtDevice.Text := GetSettingString(Group, 'Device', '');

    edtFrequency.Text := GetSettingString(Group, 'Frequency', '');
    edtMode.Text := GetSettingString(Group, 'Mode', '');
    edtCallsign.Text := GetSettingString(Group, 'Callsign', '');
    CheckLCARSLabel(chkHabitat, GetSettingBoolean(Group, 'Habitat', False));
    CheckLCARSLabel(chkSSDV, GetSettingBoolean(Group, 'SSDV', False));

    SendSettingsToDevice;
end;

procedure TfrmBluetoothSettings.chkHabitatClick(Sender: TObject);
begin
    SetingsHaveChanged;
    LCARSLabelClick(Sender);
end;

procedure TfrmBluetoothSettings.cmbDevicesClosePopup(Sender: TObject);
begin
    if cmbDevices.ItemIndex >= 0 then begin
        if edtDevice.Text <> cmbDevices.Items[cmbDevices.ItemIndex] then begin
            edtDevice.Text := cmbDevices.Items[cmbDevices.ItemIndex];
            SetingsHaveChanged;
        end;
    end;
end;

procedure TfrmBluetoothSettings.edtDeviceClick(Sender: TObject);
begin
    cmbDevices.DropDown;
end;

procedure TfrmBluetoothSettings.edtFrequencyExit(Sender: TObject);
begin
    FixFloatEditBox(edtFrequency);
end;

procedure TfrmBluetoothSettings.FormCreate(Sender: TObject);
begin
    inherited;
    Group := 'LoRaBluetooth';
end;

procedure TfrmBluetoothSettings.LoadForm;
begin
    inherited;
    UpdateBluetoothList;
end;

procedure TfrmBluetoothSettings.UpdateBluetoothList;
var
    i: Integer;
{$IF Defined(MSWINDOWS) or Defined(ANDROID)}
    Bluetooth1: TBluetooth;
{$ENDIF}
begin
    cmbDevices.Items.Clear;

{$IF Defined(MSWINDOWS) or Defined(ANDROID)}
    try
        Bluetooth1 := TBluetooth.Create(nil);
        Bluetooth1.Enabled := True;

        if Bluetooth1.LastPairedDevices <> nil then begin
            for i := 0 to Bluetooth1.LastPairedDevices.Count-1 do begin
                // cmbDevices.Items.Add(IntToStr(Ord(Bluetooth1.LastPairedDevices[i].State)) + ': ' + Bluetooth1.LastPairedDevices[i].DeviceName + ' - ' + Bluetooth1.LastPairedDevices[i].Address);
                cmbDevices.Items.Add(Bluetooth1.LastPairedDevices[i].DeviceName);
            end;
        end;
        Bluetooth1.Free;
    finally
    end;
{$ELSE}
    BluetoothLE1.Enabled := True;
    BluetoothLE1.DiscoverDevices(5000);
{$ENDIF}

    cmbDevices.ItemIndex := cmbDevices.Items.IndexOf(edtDevice.Text);
end;

end.
