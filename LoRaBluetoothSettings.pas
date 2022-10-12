unit LoRaBluetoothSettings;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  SettingsBase, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Controls.Presentation,
  FMX.TMSCustomEdit, FMX.TMSEdit, Miscellaneous, Math, System.Bluetooth,
  FMX.ListBox, System.Bluetooth.Components, FMX.Memo.Types;

type
  TfrmBluetoothSettings = class(TfrmSettingsBase)
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
    chkAFC: TLabel;
    rectProgressHolder: TRectangle;
    rectProgressBar: TRectangle;
    btnSearch: TButton;
    tmrReceive: TTimer;
    tmrSearch: TTimer;
    rectRx: TRectangle;
    lblRx: TLabel;
    chkSondehub: TLabel;
    chkHabitat: TLabel;
    procedure FormCreate(Sender: TObject);
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
    procedure tmrReceiveTimer(Sender: TObject);
    procedure tmrSearchTimer(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure edtCallsignChangeTracking(Sender: TObject);
    procedure edtDeviceChangeTracking(Sender: TObject);
    procedure chkSondehubClick(Sender: TObject);
  private
    { Private declarations }
    Searching: Boolean;
    SearchCentreFrequency: Double;
    SearchPacketCount, SearchStep: Integer;
    procedure SendSettingsToDevice;
    procedure UpdateBluetoothList;
    procedure NextSearch;
    procedure StopSearch;
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
    SetSettingBoolean(Group, 'AFC', LCARSLabelIsChecked(chkAFC));

    SetSettingBoolean(Group, 'Habitat', LCARSLabelIsChecked(chkHabitat));
    SetSettingBoolean(Group, 'Sondehub', LCARSLabelIsChecked(chkSondehub));

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

procedure TfrmBluetoothSettings.tmrReceiveTimer(Sender: TObject);
var
    PacketCount: Integer;
begin
    PacketCount := frmSources.GetPacketCount(BLUETOOTH_SOURCE);

    Inc(SearchPacketCount, PacketCount);

    if PacketCount > 0 then begin
        rectRx.Visible := True;
        frmSources.ResetPacketCount(BLUETOOTH_SOURCE);
    end else begin
        rectRx.Visible := False;
    end;
end;

procedure TfrmBluetoothSettings.tmrSearchTimer(Sender: TObject);
begin
    tmrSearch.Enabled := False;

    if SearchPacketCount > 1 then begin
        StopSearch;
    end else begin
        NextSearch;
    end;
end;

procedure TfrmBluetoothSettings.btnCancelClick(Sender: TObject);
begin
    inherited;
    //
end;

procedure TfrmBluetoothSettings.btnModeDownClick(Sender: TObject);
begin
    edtMode.Text := IntToStr(Max(0,Min(7,StrToIntDef(edtMode.Text, 0)-1)));
    SetingsHaveChanged;
end;

procedure TfrmBluetoothSettings.btnModeUpClick(Sender: TObject);
begin
    edtMode.Text := IntToStr(Max(0,Min(7,StrToIntDef(edtMode.Text, 0)+1)));
    SetingsHaveChanged;
end;

procedure TfrmBluetoothSettings.btnSearchClick(Sender: TObject);
begin
    btnSearch.Enabled := False;
    rectProgressBar.Width := 0;
    // rectProgressHolder.Visible := True;
    SearchCentreFrequency := StrToFloat(edtFrequency.Text);
    SearchStep := -6;
    Searching := True;
    NextSearch;
end;

procedure TfrmBluetoothSettings.CancelChanges;
begin
    edtDevice.Text := GetSettingString(Group, 'Device', '');

    edtFrequency.Text := GetSettingString(Group, 'Frequency', '');
    edtMode.Text := GetSettingString(Group, 'Mode', '');
    edtCallsign.Text := GetSettingString(Group, 'Callsign', '');

    CheckLCARSLabel(chkHabitat, GetSettingBoolean(Group, 'Habitat', False));
    CheckLCARSLabel(chkSondehub, GetSettingBoolean(Group, 'Sondehub', False));

    CheckLCARSLabel(chkSSDV, GetSettingBoolean(Group, 'SSDV', False));
    CheckLCARSLabel(chkAFC, GetSettingBoolean(Group, 'AFC', False));

    SendSettingsToDevice;

    inherited;
end;

procedure TfrmBluetoothSettings.chkSondehubClick(Sender: TObject);
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

procedure TfrmBluetoothSettings.edtCallsignChangeTracking(Sender: TObject);
begin
    SetingsHaveChanged;
end;

procedure TfrmBluetoothSettings.edtDeviceChangeTracking(Sender: TObject);
begin
    SetingsHaveChanged;
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

procedure TfrmBluetoothSettings.NextSearch;
begin
    Inc(SearchStep);

    if SearchStep > 5 then begin
        // pnlSearchFrequency.Caption := '';
        rectProgressBar.Width := 0;
        // rectProgressHolder.Visible := False;
        Searching := False;
        frmSources.SendParameterToSource(BLUETOOTH_SOURCE, 'F', edtFrequency.Text);
        btnSearch.Enabled := True;
    end else begin
        // pnlSearchFrequency.Caption := FormatFloat('.0000', SearchFrequency);
        rectProgressBar.Width := (SearchStep + 6) * rectProgressHolder.Width / 12;

        edtFrequency.Text := FormatFloat('0.000#', SearchCentreFrequency + SearchStep * 0.002);
        frmSources.SendParameterToSource(BLUETOOTH_SOURCE, 'F', edtFrequency.Text);

        SearchPacketCount := 0;
        tmrSearch.Enabled := True;
    end;
end;

procedure TfrmBluetoothSettings.StopSearch;
begin
    edtFrequency.Text := FormatFloat('0.000#', StrToFloat(edtFrequency.Text) + frmSources.FrequencyError(BLUETOOTH_SOURCE) / 1000);

    frmSources.SendParameterToSource(BLUETOOTH_SOURCE, 'F', FormatFloat('0.000#', SearchCentreFrequency + SearchStep * 0.002));

    rectProgressBar.Width := 0;
    // rectProgressHolder.Visible := False;

    btnSearch.Enabled := True;

    Searching := False;
end;

end.
