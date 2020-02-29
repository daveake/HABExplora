unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, System.IOUtils,
  Math, Source, Miscellaneous, SourcesForm, Debug,
  Base, Splash, Map, Direction, Payloads,
{$IFDEF ANDROID}
  Androidapi.JNIBridge, AndroidApi.JNI.Media,
  Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText, Androidapi.Helpers, Androidapi.JNI.Net,
  FMX.Helpers.Android, FMX.Platform.Android, AndroidApi.Jni.App,
  AndroidAPI.jni.OS, FMX.TMSCustomEdit, FMX.TMSEdit, FMX.TMSBaseGroup,
  System.Permissions,
{$ENDIF}
  Settings;

type
  TPayload = record
      Previous:     THABPosition;
      Position:     THABPosition;
      Colour:       TAlphaColor;
      ColourName:   String;
  end;

type
  TSource = record
    Button:         TButton;
    LastPositionAt: TDateTime;
    Circle:         TCircle;
end;

type
  TfrmMain = class(TForm)
    pnlCentre: TRectangle;
    StyleBook1: TStyleBook;
    rectStatus: TRectangle;
    lblGPS: TLabel;
    btnLoRaSerial: TButton;
    btnHabHub: TButton;
    btnGPS: TButton;
    tmrUpdates: TTimer;
    tmrResize: TTimer;
    crcLoRaSerial: TCircle;
    crcGPS: TCircle;
    btnLoRaBluetooth: TButton;
    crcLoRaBluetooth: TCircle;
    tmrLoad: TTimer;
    rectMain: TRectangle;
    btnSettings: TButton;
    btnMap: TButton;
    btnDirection: TButton;
    btnPayloads: TButton;
    rectTopBar: TRectangle;
    crcTopRight: TCircle;
    rctTopRight: TRectangle;
    crcTopLeft: TCircle;
    rectTopLeft: TRectangle;
    recButtons: TRectangle;
    rectBottomBar: TRectangle;
    crcBottomRight: TCircle;
    rectBottomRight: TRectangle;
    crcBottomLeft: TCircle;
    rectBottomLeft: TRectangle;
    rectSources: TRectangle;
    btnUDP: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btnMapClick(Sender: TObject);
    procedure btnPayloadsClick(Sender: TObject);
    procedure btnDirectionClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure tmrUpdatesTimer(Sender: TObject);
    procedure btnSourcesClick(Sender: TObject);
    procedure tmrResizeTimer(Sender: TObject);
    procedure Circle1Click(Sender: TObject);
    procedure tmrLoadTimer(Sender: TObject);
    procedure pnlCentreResize(Sender: TObject);
    procedure rectTopBarResize(Sender: TObject);
    procedure rectBottomBarResize(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    DesignHeight: Single;
    Resized: Boolean;
    CurrentForm: TfrmBase;
    Payloads: Array[1..3] of TPayload;
    SelectedPayload: Integer;
    Sources: Array[0..5] of TSource;
    ChasePosition: THABPosition;
//    SelectedPayload: Integer;
    procedure LoadMapIfNotLoaded;
    procedure ShowSelectedButton(Button: TButton);
    function PlacePayloadInList(var Position: THABPosition): Integer;
    function FindOrAddPayload(Position: THABPosition): Integer;
    procedure DoPayloadCalcs(Previous: THabPosition; var Position: THABPosition);
    procedure UpdatePayloadList;
    procedure Navigate(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double; OffRoad: Boolean = False);
    procedure ShowRouteOnMap(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double);
    procedure ResizeFonts;
{$IF Defined(IOS) or Defined(ANDROID)}
    procedure PlaySound(Flag: Integer);
{$ENDIF}
  public
    { Public declarations }
    function LoadForm(Button: TButton; NewForm: TfrmBase): Boolean;
    procedure UploadStatus(SourceID: Integer; Active, OK: Boolean);
    procedure NewPosition(SourceID: Integer; Position: THABPosition);
    function BalloonIconName(PayloadIndex: Integer; Target: Boolean=False): String;
    procedure NavigateToPayload(PayloadIndex: Integer; UsePrediction: Boolean; OffRoad: Boolean = False);
    procedure ShowRouteToPayload(PayloadIndex: Integer; UsePrediction: Boolean);
    procedure ShowSourceStatus(SourceID: Integer; Active, Recent: Boolean);
    procedure SelectPayload(PayloadIndex: Integer);
    function GetChasePosition(var Latitude: Double; var Longitude: Double; var Altitude: Double): Boolean;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.btnDirectionClick(Sender: TObject);
begin
    LoadForm(TButton(Sender), frmDirection);
end;

procedure TfrmMain.btnMapClick(Sender: TObject);
begin
    LoadMapIfNotLoaded;

    LoadForm(TButton(Sender), frmMap);
end;

procedure TfrmMain.btnPayloadsClick(Sender: TObject);
begin
    if LoadForm(TButton(Sender), frmPayloads) then begin
        frmPayloads.NewSelection(SelectedPayload);
    end;
end;

procedure TfrmMain.btnSettingsClick(Sender: TObject);
begin
    if frmSettings = nil then begin
        frmSettings := TfrmSettings.Create(nil);
    end;

    LoadForm(TButton(Sender), frmSettings);
end;

procedure TfrmMain.Circle1Click(Sender: TObject);
begin
    LoadForm(nil, frmSplash);
end;

procedure TfrmMain.btnSourcesClick(Sender: TObject);
begin
    LoadForm(nil, frmSources);
end;

procedure TfrmMain.LoadMapIfNotLoaded;
begin
    if frmMap = nil then begin
        try
            frmMap := TfrmMap.Create(nil);
        except
            on E : Exception do begin
                if frmDebug <> nil then begin
                    frmDebug.Debug(E.ClassName + '/' + E.Message);
                end;
            end;
        end;
    end;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
const
    FirstTime: Boolean = True;
begin
    if FirstTime then begin
        FirstTime := False;

        // Debug form, but only if we're a debug build
{$IFDEF DEBUG}
        frmDebug := TfrmDebug.Create(nil);
{$ENDIF}

        // Splash form
        frmSplash := TfrmSplash.Create(nil);
        LoadForm(nil, frmSplash);

        tmrLoad.Enabled := True;
    end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
    INIFileName := TPath.Combine(DataFolder, 'HABExplora.ini');

    CurrentForm := nil;

//{$IFDEF IOS}
//    rectMain.Margins.Top := 18;
//{$ENDIF}

    Resized := False;
    DesignHeight := pnlCentre.Height;

    Payloads[1].Colour := TAlphaColorRec.Blue;
    Payloads[2].Colour := TAlphaColorRec.Red;
    Payloads[3].Colour := TAlphaColorRec.Lime;

    Payloads[1].ColourName := 'blue';
    Payloads[2].ColourName := 'red';
    Payloads[3].ColourName :='green';

    InitialiseSettings;

    // Source info
    Sources[GPS_SOURCE].Button := btnGPS;
    Sources[GPS_SOURCE].Circle := crcGPS;

    Sources[SERIAL_SOURCE].Button := btnLoRaSerial;
    Sources[SERIAL_SOURCE].Circle := crcLoRaSerial;

    Sources[BLUETOOTH_SOURCE].Button := btnLoRaBluetooth;
    Sources[BLUETOOTH_SOURCE].Circle := crcLoRaBluetooth;

    Sources[HABITAT_SOURCE].Button := btnHabHub;
    Sources[HABITAT_SOURCE].Circle := nil;

    Sources[UDP_SOURCE].Button := btnUDP;
    Sources[UDP_SOURCE].Circle := nil;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
    rectTopBar.Height := frmMain.Height / 15;
    rectBottomBar.Height := frmMain.Height / 15;
end;

function TfrmMain.LoadForm(Button: TButton; NewForm: TfrmBase): Boolean;
begin
    if NewForm <> nil then begin
        ShowSelectedButton(Button);

        if CurrentForm <> nil then begin
            CurrentForm.HideForm;
        end;

        CurrentForm := NewForm;

        NewForm.pnlMain.Parent := pnlCentre;
        NewForm.LoadForm;

        Result := True;
    end else begin
        Result := False;
    end;
end;

procedure TfrmMain.ShowSelectedButton(Button: TButton);
begin
    btnPayloads.TextSettings.Font.Style := btnPayloads.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnMap.TextSettings.Font.Style := btnMap.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnDirection.TextSettings.Font.Style := btnDirection.TextSettings.Font.Style - [TFontStyle.fsUnderline];
    btnSettings.TextSettings.Font.Style := btnSettings.TextSettings.Font.Style - [TFontStyle.fsUnderline];

    if Button <> nil then begin
        Button.TextSettings.Font.Style := Button.TextSettings.Font.Style + [TFontStyle.fsUnderline];
    end;
end;

{$IFDEF ANDROID}
procedure TfrmMain.PlaySound(Flag: Integer);
var
    Volume, ADuration: Integer;
    StreamType: Integer;
    ToneType: Integer;
    ToneGenerator: JToneGenerator;
begin
    Volume := TJToneGenerator.JavaClass.MAX_VOLUME;
    ADuration := 100 * Flag;

    StreamType := TJAudioManager.JavaClass.STREAM_ALARM;
    ToneType := TJToneGenerator.JavaClass.TONE_DTMF_0;

    ToneGenerator := TJToneGenerator.JavaClass.init(StreamType, Volume);
    ToneGenerator.startTone(ToneType, ADuration);
end;
{$ENDIF}

{$IFDEF IOS}
procedure TfrmMain.PlaySound(Flag: Integer);
begin
    Beep;
end;
{$ENDIF}

procedure TfrmMain.pnlCentreResize(Sender: TObject);
begin
    tmrResize.Enabled := True;
end;

procedure TfrmMain.rectBottomBarResize(Sender: TObject);
begin
    rectBottomBar.Margins.Left := rectBottomBar.Height / 2;
    rectBottomBar.Margins.Right := rectBottomBar.Height / 2;

    crcBottomLeft.Width := crcBottomLeft.Height;
    crcBottomLeft.Margins.Left := -crcBottomLeft.Height/2;
    crcBottomRight.Width := crcBottomRight.Height;
    crcBottomRight.Margins.Right := -crcBottomRight.Height/2;

    rectBottomLeft.Margins.Bottom := crcBottomLeft.Height / 2;
    rectBottomRight.Margins.Bottom := crcTopLeft.Height / 2;

    rectStatus.Width := rectBottomBar.Width / 4;
    rectStatus.Margins.Right := - rectStatus.Height / 2;
end;

procedure TfrmMain.rectTopBarResize(Sender: TObject);
begin
    rectTopBar.Margins.Left := rectTopBar.Height / 2;
    rectTopBar.Margins.Right := rectTopBar.Height / 2;

    crcTopLeft.Width := crcTopLeft.Height;
    crcTopLeft.Margins.Left := -crcTopLeft.Height/2;
    crcTopRight.Width := crcTopRight.Height;
    crcTopRight.Margins.Right := -crcTopRight.Height/2;

    rectTopLeft.Margins.Top := crcTopRight.Height / 2;
    rctTopRight.Margins.Top := crcTopRight.Height / 2;

    recButtons.Margins.Left := -crcTopRight.Height / 6;
    recButtons.Margins.Right := recButtons.Margins.Left;
end;

procedure TfrmMain.UploadStatus(SourceID: Integer; Active, OK: Boolean);
begin
    // Show status on screen
    if Sources[SourceID].Circle <> nil then begin
        if Active then begin
            if OK then begin
                Sources[SourceID].Circle.Fill.Color := TAlphaColorRec.Lime;
            end else begin
                Sources[SourceID].Circle.Fill.Color := TAlphaColorRec.Red;
            end;
        end else begin
            Sources[SourceID].Circle.Fill.Color := TAlphaColorRec.Silver;
        end;
    end;

    // Log errors in debug screen
    if Active and (not OK) and (frmDebug <> nil) then begin
        frmDebug.Debug(SourceName(SourceID) + ' failed to upload position');
    end;
end;

procedure TfrmMain.NewPosition(SourceID: Integer; Position: THABPosition);
var
    Index: Integer;
begin
    ShowSourceStatus(SourceID, True, True);

    Index := PlacePayloadInList(Position);

    if Position.IsChase or (Index > 0) then begin
        if Position.IsChase then begin
            // Chase car only
            ChasePosition := Position;
            lblGPS.Text := FormatDateTime('hh:nn:ss', Position.TimeStamp);
        end else begin
            // Payloads only

            if frmPayloads <> nil then begin
                try
                    frmPayloads.NewPosition(Index, Position);
                except
                    //
                end;
            end;
        end;

        // Payloads and Chase Car
        if frmDirection <> nil then begin
            try
                frmDirection.NewPosition(Index, Position);
            except
                //
            end;
        end;

        if frmMap <> nil then begin
            try
                frmMap.NewPosition(Index, Position);
            except
                //
            end;
        end;
    end;
end;

function TfrmMain.PlacePayloadInList(var Position: THABPosition): Integer;
var
    Index: Integer;
    PayloadChanged: Boolean;
begin
    Result := 0;

    if Position.InUse and not Position.IsChase then begin
        Index := FindOrAddPayload(Position);

        if Index > 0 then begin
            // Update forms with payload list, if it has changed
            if (not Payloads[Index].Position.InUse) or (Position.PayloadID <> Payloads[Index].Position.PayloadID) then begin
                PayloadChanged := True;
            end else begin
                PayloadChanged := False;
            end;

            // if (Position.TimeStamp - Payloads[Index].Previous.TimeStamp) >= 1/86400 then begin
            if (Position.TimeStamp > Payloads[Index].Position.TimeStamp) or (Position.PayloadID <> Payloads[Index].Position.PayloadID) then begin
                Position.FlightMode := Payloads[Index].Previous.FlightMode;

                // Calculate ascent rate etc
                DoPayloadCalcs(Payloads[Index].Previous, Position);

                // Update buttons
//                Payloads[Index].Button.Text := Position.PayloadID;
//                Payloads[Index].Button.Opacity := 1;

                // Store new position
                Payloads[Index].Previous := Payloads[Index].Position;
                Payloads[Index].Position := Position;
                Payloads[Index].Previous.FlightMode := Position.FlightMode;

                if PayloadChanged then begin
                    UpdatePayloadList;
                end;

                Result := Index;
            end;
        end;
    end;
end;

//procedure TfrmMain.ShowSelectedPayloadPosition;
//begin
//    with Payloads[SelectedPayload].Position do begin
//        frmMain.lblPayload.Text := FormatDateTime('hh:nn:ss', TimeStamp) + '  ' +
//                           Format('%2.6f', [Latitude]) + ',' +
//                           Format('%2.6f', [Longitude]) + ' at ' +
//                           Format('%.0f', [Altitude]) + 'm';
//    end;
//end;

procedure TfrmMain.tmrLoadTimer(Sender: TObject);
begin
    tmrLoad.Enabled := False;

    // Main forms
    frmPayloads := TfrmPayloads.Create(nil);

    frmDirection := TfrmDirection.Create(nil);

    LoadMapIfNotLoaded;

    // Sources Form
    frmSources := TfrmSources.Create(nil);

    // Ask for GPS permission
{$IFDEF ANDROID}
    frmSources.lblGPS.Text := 'No GPS Permission';

    PermissionsService.RequestPermissions([JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)],
        procedure(const APermissions: TArray<string>; const AGrantResults: TArray<TPermissionStatus>) begin
            if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then begin
                // activate or deactivate the location sensor }
                frmSources.EnableGPS;
            end else begin
                frmSources.lblGPS.Text := 'No GPS Permission';
            end;
        end);
{$ENDIF}

{$IFDEF IOS}
    btnLoRaBluetooth.Text := 'BLE';
    btnLoRaSerial.Text := '';
    crcLoRaSerial.Visible := False;
    frmSources.EnableGPS;
{$ENDIF}

    frmSources.EnableCompass;

    frmSplash.rectLoading.Visible := False;
    lblGPS.Text := '';
end;

procedure TfrmMain.tmrResizeTimer(Sender: TObject);
//var
//    FontSize: Double;
begin
    tmrResize.Enabled := False;

    // ResizeFonts;

//    FontSize := lblGPS.Size.Height * 36/64;

    // Source Buttons
    (*
    btnTablet.Font.Size := FontSize;
    lblGPS.Font.Size := FontSize;
    btnLoRaSerial.Font.Size := FontSize;
    btnHabHub.Font.Size := FontSize;
    btnGPS.Font.Size := FontSize;
    lblGPS.Font.Size := FontSize;

    // Menu buttons
    btnPayloads.Font.Size := FontSize;
    btnMap.Font.Size := FontSize;
    btnDirection.Font.Size := FontSize;
    btnSettings.Font.Size := FontSize;
    *)
end;

procedure TfrmMain.tmrUpdatesTimer(Sender: TObject);
var
    SourceID, Index: Integer;
begin
    if frmPayloads <> nil then begin
        for Index := Low(Payloads) to High(Payloads) do begin
            if Payloads[Index].Position.InUse and (Payloads[Index].Position.ReceivedAt > 0) then begin
                frmPayloads.ShowTimeSinceUpdate(Index, Now - Payloads[Index].Position.ReceivedAt);
            end;
        end;
    end;

    for SourceID := Low(Sources) to High(Sources) do begin
        if (Now - Sources[SourceID].LastPositionAt) > 60/86400 then begin
            ShowSourceStatus(SourceID, Sources[SourceID].LastPositionAt > 0, False);
        end;
    end;
end;

function TfrmMain.FindOrAddPayload(Position: THABPosition): Integer;
var
    i: Integer;
begin
    // Look for same payload
    for i := Low(Payloads) to High(Payloads) do begin
        if Payloads[i].Position.InUse then begin
            if Position.PayloadID = Payloads[i].Position.PayloadID then begin
                Result := i;
                Exit;
            end;
        end;
    end;

    // Look for empty slot
    for i := Low(Payloads) to High(Payloads) do begin
        if not Payloads[i].Position.InUse then begin
            Result := i;
            Payloads[i].Position.InUse := True;
            SelectPayload(i);
            Exit;
        end;
    end;

    // Look for oldest payload
    Result := Low(Payloads);
    for i := Low(Payloads)+1 to High(Payloads) do begin
        if Payloads[i].Position.TimeStamp < Payloads[Result].Position.TimeStamp then begin
            // This one is older than oldest so far
            Result := i;
        end;
    end;
end;

procedure TfrmMain.DoPayloadCalcs(Previous: THabPosition; var Position: THABPosition);
const
    FlightModes: Array[0..8] of String = ('Idle', 'Launched', 'Descending', 'Homing', 'Direct To Target', 'Downwind', 'Upwind', 'Landing', 'Landed');
begin
    Position.AscentRate := (Position.Altitude - Previous.Altitude) / (86400 * (Position.TimeStamp - Previous.TimeStamp));
    Position.MaxAltitude := max(Position.Altitude, Previous.MaxAltitude);

    // Flight mode
    case Previous.FlightMode of
        fmIdle: begin
            if ((Position.AscentRate > 2.0) and (Position.Altitude > 100)) or
               (Position.Altitude > 5000) or
               (Abs(Position.AscentRate) > 20) or
               ((Position.AscentRate > 1.0) and (Position.Altitude > 300)) then begin
                Position.FlightMode := fmLaunched;
            end;
        end;

        fmLaunched: begin
            if Position.AscentRate < -4 then begin
                Position.FlightMode := fmDescending;
            end;
        end;

        fmDescending: begin
            if Position.AscentRate > -1 then begin
                Position.FlightMode := fmLanded;
            end;
        end;

        fmLanded: begin
            if ((Position.AscentRate > 3.0) and (Position.Altitude > 100)) or
               ((Position.AscentRate > 2.0) and (Position.Altitude > 500)) then begin
                Position.FlightMode := fmLaunched;
            end;
        end;
    end;
end;

function TfrmMain.BalloonIconName(PayloadIndex: Integer; Target: Boolean=False): String;
begin
    Result := 'balloon-' + Payloads[PayloadIndex].ColourName;

    if Target then begin
        Result := 'x-' + Payloads[PayloadIndex].ColourName;
    end else begin
        case Payloads[PayloadIndex].Position.FlightMode of
            fmIdle:         Result := 'payload-' + Payloads[PayloadIndex].ColourName;
            fmLaunched:     Result := 'balloon-' + Payloads[PayloadIndex].ColourName;
            fmDescending:   Result := 'parachute-' + Payloads[PayloadIndex].ColourName;
            fmLanded:       Result := 'payload-' + Payloads[PayloadIndex].ColourName;
        end;
    end;
end;

{$IFDEF ANDROID}
procedure OpenURL(const URL: string);
var
    Intent: JIntent;
begin
  Intent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW, TJnet_Uri.JavaClass.parse(StringToJString(URL)));
  try
    SharedActivity.startActivity(Intent);
  except
  end;
end;
{$ENDIF ANDROID}

procedure TfrmMain.Navigate(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double; OffRoad: Boolean = False);
begin
{$IFDEF ANDROID}
    if OffRoad then begin
        // This offers us Backcountry Navigator etc.
        OpenURL('geo:' + TargetLatitude.ToString + ',' + TargetLongitude.ToString);
    end else begin
        // This offers us Sygic etc.
        OpenURL('google.navigation:q=' + TargetLatitude.ToString + ',' + TargetLongitude.ToString);
    end;
{$ELSE}
    ShowRouteOnMap(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude);
{$ENDIF ANDROID}
end;

procedure TfrmMain.ShowRouteOnMap(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double);
begin
    if frmMap <> nil then begin
        if LoadForm(btnMap, frmMap) then begin
            frmMap.ShowDirections(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude);
        end;
    end;
end;

procedure TfrmMain.NavigateToPayload(PayloadIndex: Integer; UsePrediction: Boolean; Offroad: Boolean = False);
begin
    if PayloadIndex > 0 then begin
        if UsePrediction then begin
            Navigate(Payloads[PayloadIndex].Position.PredictedLatitude,
                     Payloads[PayloadIndex].Position.PredictedLongitude,
                     ChasePosition.Latitude,
                     ChasePosition.Longitude,
                     OffRoad);
        end else begin
            Navigate(Payloads[PayloadIndex].Position.Latitude,
                     Payloads[PayloadIndex].Position.Longitude,
                     ChasePosition.Latitude,
                     ChasePosition.Longitude,
                     OffRoad);
        end;
    end;
end;

procedure TfrmMain.ShowRouteToPayload(PayloadIndex: Integer; UsePrediction: Boolean);
begin
    if PayloadIndex > 0 then begin
        if UsePrediction then begin
            ShowRouteOnMap(Payloads[PayloadIndex].Position.PredictedLatitude,
                           Payloads[PayloadIndex].Position.PredictedLongitude,
                           ChasePosition.Latitude,
                           ChasePosition.Longitude);
        end else begin
            ShowRouteOnMap(Payloads[PayloadIndex].Position.Latitude,
                           Payloads[PayloadIndex].Position.Longitude,
                           ChasePosition.Latitude,
                           ChasePosition.Longitude);
        end;
    end;
end;

procedure TfrmMain.UpdatePayloadList;
var
    PayloadList: String;
    i: Integer;
begin
    PayloadList := '';

    for i := Low(Payloads) to High(Payloads) do begin
        if Payloads[i].Position.InUse then begin
            PayloadList := PayloadList + ';' + Payloads[i].Position.PayloadID;
        end;
    end;

    PayloadList := Copy(PayloadList, 2, 999);

    frmSources.UpdatePayloadList(PayloadList);
end;

procedure TfrmMain.ShowSourceStatus(SourceID: Integer; Active, Recent: Boolean);
begin
    if Sources[SourceID].Button <> nil then begin
        if Active then begin
            Sources[SourceID].Button.Opacity := 1.0;
            if Recent then begin
                Sources[SourceID].Button.TextSettings.FontColor := TAlphaColorRec.Green;
                Sources[SourceID].LastPositionAt := Now;
            end else begin
                Sources[SourceID].Button.TextSettings.FontColor := TAlphaColorRec.Red;
            end;
        end else begin
            Sources[SourceID].Button.Opacity := 0.7;
            Sources[SourceID].Button.TextSettings.FontColor := TAlphaColorRec.Black;
        end;
    end;
end;

procedure TfrmMain.SelectPayload(PayloadIndex: Integer);
begin
    if Payloads[PayloadIndex].Position.InUse then begin
        SelectedPayload := PayloadIndex;

        // if frmMap <> nil then frmMap.NewSelection(PayloadIndex);
        frmPayloads.NewSelection(PayloadIndex);
        frmDirection.NewSelection(PayloadIndex);
    end;
end;

procedure TfrmMain.ResizeFonts;
var
    i: Integer;
    Component: TComponent;
begin
    if not Resized then begin
        Resized := True;
        for i := 0 to ComponentCount-1 do begin
            Component := Components[i];

            if Component is TLabel then begin
                TLabel(Component).Font.Size := TLabel(Component).Font.Size * pnlCentre.Height / DesignHeight;
            end;
        end;
    end;
end;

function TfrmMain.GetChasePosition(var Latitude: Double; var Longitude: Double; var Altitude: Double): Boolean;
begin
    Result := ChasePosition.InUse;

    if Result then begin
        Latitude := ChasePosition.Latitude;
        Longitude := ChasePosition.Longitude;
        Altitude := ChasePosition.Altitude;
    end;
end;

end.
