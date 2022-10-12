unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, System.IOUtils,
  Math, Source, Miscellaneous, SourcesForm, Debug,
  Base, Splash, Map, Direction, Payloads, Uplink,
{$IFDEF ANDROID}
  Androidapi.JNIBridge, AndroidApi.JNI.Media,
  Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText, Androidapi.Helpers, Androidapi.JNI.Net,
  FMX.Helpers.Android, FMX.Platform.Android, AndroidApi.Jni.App,
  AndroidAPI.jni.OS, FMX.TMSBaseGroup,
  System.Permissions,
{$ENDIF}
  Settings, Tawhiri, FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics,
  FMX.TMSFNCGraphicsTypes, FMX.TMSFNCHTMLImageContainer, FMX.TMSFNCRadioButton,
  FMX.TMSFNCPageControl, FMX.TMSFNCCustomControl, FMX.TMSFNCTabSet,
  FMX.TMSCustomEdit, FMX.TMSEdit, FMX.TMSFNCMapsCommonTypes,
  FMX.TMSFNCWebBrowser, FMX.TMSFNCMaps, FMX.TMSFNCGoogleMaps;

type
  TPayload = record
      Previous:         THABPosition;
      Position:         THABPosition;
      Colour:           TAlphaColor;
      ColourName:       String;
      SourceMask:       Integer;
      SSDVCount:        Integer;
      PredictionIndex:  Integer;
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
    btnSondehub: TButton;
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
    btnUplink: TButton;
    pnlMap: TRectangle;
    FNCMap: TTMSFNCGoogleMaps;
    btnHABHUB: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btnMapClick(Sender: TObject);
    procedure btnPayloadsClick(Sender: TObject);
    procedure btnDirectionClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure tmrUpdatesTimer(Sender: TObject);
    procedure btnSourcesClick(Sender: TObject);
    procedure tmrResizeTimer(Sender: TObject);
    procedure tmrLoadTimer(Sender: TObject);
    procedure pnlCentreResize(Sender: TObject);
    procedure rectTopBarResize(Sender: TObject);
    procedure rectBottomBarResize(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnUplinkClick(Sender: TObject);
    procedure rectTopLeftClick(Sender: TObject);
    procedure FNCMapMapInitialized(Sender: TObject);
    procedure FNCMapElementContainers0Actions0Execute(Sender: TObject;
      AEventData: TTMSFNCMapsEventData);
    procedure FNCMapElementContainers0Actions2Execute(Sender: TObject;
      AEventData: TTMSFNCMapsEventData);
    procedure FNCMapElementContainers0Actions1Execute(Sender: TObject;
      AEventData: TTMSFNCMapsEventData);
  private
    { Private declarations }
    DesignWidth: Double;
    CurrentForm: TfrmBase;
    Payloads: Array[1..3] of TPayload;
    SelectedPayload: Integer;
    Sources: Array[0..8] of TSource;
    PayloadIndex: Array[1..8] of Integer;
    ChasePosition: THABPosition;
    Predictor: TTawhiri;
    ScalingFactor: Double;
    procedure LoadMapIfNotLoaded;
    procedure ShowSelectedButton(Button: TButton);
    function PlacePayloadInList(SourceID: Integer; var Position: THABPosition): Integer;
    function FindOrAddPayload(Position: THABPosition): Integer;
    procedure DoPayloadCalcs(Previous: THabPosition; var Position: THABPosition);
    procedure UpdatePayloadList;
    procedure Navigate(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double; OffRoad: Boolean = False);
    procedure ShowRouteOnMap(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double);
    procedure WhereIsBalloon(PayloadIndex: Integer);
    procedure WhereAreBalloons;
    procedure ShowSelectedMapButton(ElementID: String);
{$IF Defined(IOS) or Defined(ANDROID)}
    procedure PlaySound(Flag: Integer);
{$ENDIF}
  public
    { Public declarations }
    function LoadForm(Button: TButton; NewForm: TfrmBase): Boolean;
    procedure UploadStatus(SourceID: Integer; Active, OK: Boolean);
    procedure NewPosition(SourceID: Integer; Position: THABPosition);
    function BalloonColour(PayloadIndex: Integer): TAlphaColor;
    function BalloonIconName(PayloadIndex: Integer; Target: Boolean=False): String;
    procedure NavigateToPayload(PayloadIndex: Integer; UsePrediction: Boolean; OffRoad: Boolean = False);
    procedure ShowRouteToPayload(PayloadIndex: Integer; UsePrediction: Boolean);
    procedure ShowSourceStatus(SourceID: Integer; Active, Recent: Boolean);
    procedure SelectPayload(PayloadIndex: Integer);
    function GetChasePosition(var Latitude: Double; var Longitude: Double; var Altitude: Double): Boolean;
    function GetSourceMask(PayloadIndex: Integer): Integer;
    procedure ResizeFonts(AForm: TForm);
    procedure LoadSettingsPage(PageIndex: Integer);
    procedure UpdateCarUploadSettings;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

function FontScale: Single;
{$IFDEF ANDROID}
var
  Resources: JResources;

  Configuration: JConfiguration;
{$ENDIF ANDROID}
{$IFDEF IOS}
var
  f: UIFontDescriptor;

{$ENDIF IOS}
begin

  Result := 1.0;

  {$IFDEF ANDROID}

  if TAndroidHelper.Context <> nil then

  begin

    Resources := TAndroidHelper.Context.getResources;
    if Resources <> nil then

    begin
      Configuration := Resources.getConfiguration;
      if Configuration <> nil then
        Result := Configuration.fontScale;

    end;

  end;

  {$ENDIF ANDROID}
  {$IFDEF IOS}
  f := TUIFontDescriptor.OCClass.preferredFontDescriptorWithTextStyle(
          UIFontTextStyleBody);
  Result := f.pointSize / 17.0;

  {$ENDIF IOS}
end;

procedure TfrmMain.btnDirectionClick(Sender: TObject);
begin
    LoadForm(TButton(Sender), frmDirection);
end;

procedure TfrmMain.btnMapClick(Sender: TObject);
begin
    LoadForm(TButton(Sender), nil);
end;

procedure TfrmMain.btnPayloadsClick(Sender: TObject);
begin
    if LoadForm(TButton(Sender), frmPayloads) then begin
        frmPayloads.NewSelection(SelectedPayload);
    end;
end;

procedure TfrmMain.btnSettingsClick(Sender: TObject);
begin
    LoadSettingsPage(0);
end;

procedure TfrmMain.btnSourcesClick(Sender: TObject);
begin
    LoadForm(nil, frmSources);
end;

procedure TfrmMain.btnUplinkClick(Sender: TObject);
begin
    if LoadForm(TButton(Sender), frmUplink) then begin
        frmUplink.NewSelection(SelectedPayload);
    end;
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

        ScalingFactor := 0.9 * pnlCentre.Width / DesignWidth;

        ResizeFonts(Self);
    end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
    INIFileName := TPath.Combine(DataFolder, 'HABExplora.ini');

    CurrentForm := nil;

//{$IFDEF IOS}
//    rectMain.Margins.Top := 18;
//{$ENDIF}

    DesignWidth := pnlCentre.Width;

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

    Sources[SONDEHUB_SOURCE].Button := btnSondehub;
    Sources[SONDEHUB_SOURCE].Circle := nil;

    Sources[HABHUB_SOURCE].Button := btnHABHUB;
    Sources[HABHUB_SOURCE].Circle := nil;

    Sources[UDP_SOURCE].Button := btnUDP;
    Sources[UDP_SOURCE].Circle := nil;

{$IFDEF MSWINDOWS}
    FullScreen := False;
{$ELSE}
    FullScreen := True;
{$ENDIF}

    Predictor := TTawhiri.Create;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
    rectTopBar.Height := frmMain.Height / 15;
    rectBottomBar.Height := frmMain.Height / 15;
end;

function TfrmMain.LoadForm(Button: TButton; NewForm: TfrmBase): Boolean;
begin
    if (Button <> btnSettings) and (frmSettings <> nil) then begin
        frmSettings.Free;
        frmSettings := nil;
    end;

    pnlCentre.Visible := NewForm <> nil;
    pnlMap.Visible := NewForm = nil;


    if NewForm <> nil then begin
        ShowSelectedButton(Button);

        if CurrentForm <> nil then begin
            CurrentForm.HideForm;
        end;

        CurrentForm := NewForm;

        NewForm.pnlMain.Parent := pnlCentre;
        NewForm.LoadForm;

        ResizeFonts(NewForm);

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
    btnUplink.TextSettings.Font.Style := btnUplink.TextSettings.Font.Style - [TFontStyle.fsUnderline];

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

    rectSources.Margins.Left := - rectBottomBar.Height / 2;

    rectStatus.Width := rectBottomBar.Width / 5;
    rectStatus.Margins.Right := -rectStatus.Height * 0.67;

    crcBottomLeft.Width := crcBottomLeft.Height;
    crcBottomLeft.Margins.Left := -crcBottomLeft.Height/2;
    crcBottomRight.Width := crcBottomRight.Height;
    crcBottomRight.Margins.Right := -crcBottomRight.Height/2;

    rectBottomLeft.Margins.Bottom := crcBottomLeft.Height / 2;
    rectBottomRight.Margins.Bottom := crcTopLeft.Height / 2;
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

    recButtons.Margins.Left := -crcTopRight.Height / 2;
    recButtons.Margins.Right := recButtons.Margins.Left;
end;

procedure TfrmMain.rectTopLeftClick(Sender: TObject);
begin
    LoadForm(nil, frmSplash);
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

procedure TfrmMain.WhereIsBalloon(PayloadIndex: Integer);
begin
    if ((ChasePosition.Latitude <> 0) or (ChasePosition.Longitude <> 0)) and Payloads[PayloadIndex].Position.InUse then begin
        Payloads[PayloadIndex].Position.DirectionValid := True;
        // Horizontal distance to payload
        Payloads[PayloadIndex].Position.Distance := CalculateDistance(Payloads[PayloadIndex].Position.Latitude,
                                                                      Payloads[PayloadIndex].Position.Longitude,
                                                                      ChasePosition.Latitude, ChasePosition.Longitude);
        // Direction to payload
        Payloads[PayloadIndex].Position.Direction := CalculateDirection(Payloads[PayloadIndex].Position.Latitude,
                                                                       Payloads[PayloadIndex].Position.Longitude,
                                                                       ChasePosition.Latitude, ChasePosition.Longitude);

        Payloads[PayloadIndex].Position.Elevation := CalculateElevation(ChasePosition.Latitude, ChasePosition.Longitude, ChasePosition.Altitude,
                                                                        Payloads[PayloadIndex].Position.Latitude, Payloads[PayloadIndex].Position.Longitude, Payloads[PayloadIndex].Position.Altitude);


        if Payloads[PayloadIndex].Position.PredictionType <> ptNone then begin
            // Horizontal distance to payload
            Payloads[PayloadIndex].Position.PredictionDistance := CalculateDistance(ChasePosition.Latitude, ChasePosition.Longitude,
                                                                                      Payloads[PayloadIndex].Position.PredictedLatitude,
                                                                                      Payloads[PayloadIndex].Position.PredictedLongitude);
            // Direction to payload
            Payloads[PayloadIndex].Position.PredictionDirection := CalculateDirection(Payloads[PayloadIndex].Position.PredictedLatitude,
                                                                                       Payloads[PayloadIndex].Position.PredictedLongitude,
                                                                                       ChasePosition.Latitude, ChasePosition.Longitude) -
                                                                                       ChasePosition.Direction;
        end;
    end else begin
        Payloads[PayloadIndex].Position.DirectionValid := False;
    end;
end;
procedure TfrmMain.WhereAreBalloons;
var
    PayloadIndex: Integer;
begin
    for PayloadIndex := Low(Payloads) to High(Payloads) do begin
        WhereIsBalloon(PayloadIndex);
    end;
end;

procedure TfrmMain.NewPosition(SourceID: Integer; Position: THABPosition);
var
    Index: Integer;
begin
    if Position.InUse then begin
        ShowSourceStatus(SourceID, True, True);

        Index := PlacePayloadInList(SourceID, Position);

        if Position.IsChase or (Index > 0) then begin
            if Position.IsChase then begin
                // Chase car only
                ChasePosition := Position;
                WhereAreBalloons;
                lblGPS.Text := FormatDateTime('hh:nn:ss', Position.TimeStamp);
            end else begin
                // Payloads only
                WhereIsBalloon(Index);

                Position := Payloads[Index].Position;       // Get updated position back

                if frmPayloads <> nil then begin
                    try
                        frmPayloads.NewPosition(Index, Position);
                    except
                        //
                    end;
                end;

                // Landing prediction needed ?
                if Position.PredictionType = ptNone then begin
                    if Payloads[Index].PredictionIndex <= 0 then begin
                        Payloads[Index].PredictionIndex := Predictor.AddPayload(Position.PayloadID);
                    end;

                    if Payloads[Index].PredictionIndex > 0 then begin
                        Predictor.UpdatePayload(Payloads[Index].PredictionIndex,
                                                Position.Latitude,
                                                Position.Longitude,
                                                Position.Altitude,
                                                30000,      // Burst
                                                Position.AscentRate,
                                                5);
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
                    if (Position.Latitude <> 0) or (Position.Longitude <> 0) then begin
                        frmMap.NewPosition(Index, Position);
                    end;
                except
                    //
                end;
            end;
        end;
    end else begin
        Index := PayloadIndex[SourceID];

        if (Index >= Low(Payloads)) and (Index <= High(Payloads)) then begin
            if Position.IsSSDV then begin
                Inc(Payloads[Index].SSDVCount);
                Position.SSDVCount := Payloads[Index].SSDVCount;
            end;

            // Update RSSI etc
            if frmPayloads <> nil then begin
                try
                    Position.FlightMode := Payloads[Index].Position.FlightMode;
                    frmPayloads.NewPosition(Index, Position);
                except
                    //
                end;
            end;
        end;
    end;
end;

function TfrmMain.PlacePayloadInList(SourceID: Integer; var Position: THABPosition): Integer;
var
    NewMask, Index: Integer;
    PayloadChanged: Boolean;
begin
    Result := 0;

    if Position.InUse and not Position.IsChase then begin
        Index := FindOrAddPayload(Position);

        PayloadIndex[SourceID] := Index;

        if Index > 0 then begin
            NewMask := Payloads[Index].SourceMask or ((1 shl (SourceID * 2)) shl Position.Channel);
            if NewMask <> Payloads[Index].SourceMask then begin
                Payloads[Index].SourceMask := NewMask;
                if frmUplink <> nil then frmUplink.NewSelection(SelectedPayload);
            end;

            // Update forms with payload list, if it has changed
            if (not Payloads[Index].Position.InUse) or (Position.PayloadID <> Payloads[Index].Position.PayloadID) then begin
                PayloadChanged := True;
            end else begin
                PayloadChanged := False;
            end;

            // if (Position.TimeStamp - Payloads[Index].Previous.TimeStamp) >= 1/86400 then begin
            if (Position.TimeStamp > Payloads[Index].Position.TimeStamp) or (Position.PayloadID <> Payloads[Index].Position.PayloadID) then begin
                // Retrieve previous flight mode
                Position.FlightMode := Payloads[Index].Previous.FlightMode;

                // Calculate ascent rate etc
                DoPayloadCalcs(Payloads[Index].Previous, Position);

                // Update buttons
//                Payloads[Index].Button.Text := Position.PayloadID;
//                Payloads[Index].Button.Opacity := 1;

                // Store new position
                Payloads[Index].Previous := Payloads[Index].Position;

                Position.TelemetryCount := Payloads[Index].Previous.TelemetryCount + 1;

                Payloads[Index].Position := Position;
                Payloads[Index].Previous.FlightMode := Position.FlightMode;

                if PayloadChanged and (SourceID <> 4) then begin
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

    frmUplink := TfrmUplink.Create(nil);

    LoadMapIfNotLoaded;

    // Sources Form
    frmSources := TfrmSources.Create(nil);

    // Ask for GPS permission
{$IFDEF ANDROID}
    frmSources.lblGPS.Text := 'No GPS Permission';

    (*
    PermissionsService.RequestPermissions([JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)],
        procedure(const APermissions: TArray<string>; const AGrantResults: TArray<TPermissionStatus>) begin
            if (Length(AGrantResults) = 1) and (AGrantResults[0] = TPermissionStatus.Granted) then begin
                // activate or deactivate the location sensor }
                frmSources.EnableGPS;
            end else begin
                frmSources.lblGPS.Text := 'No GPS Permission';
            end;
        end);
    *)

    PermissionsService.RequestPermissions([JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)],
        procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray) begin
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

    frmSplash.UnveilSplash;

    lblGPS.Text := '';
end;

procedure TfrmMain.tmrResizeTimer(Sender: TObject);
//var
//    FontSize: Double;
begin
    tmrResize.Enabled := False;

    // FontSize := lblGPS.Size.Height * 36/64;

    // Source Buttons
    (*
    btnTablet.Font.Size := FontSize;
    lblGPS.Font.Size := FontSize;
    btnLoRaSerial.Font.Size := FontSize;
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
    PredictedAltitude: Double;
begin
    if frmPayloads <> nil then begin
        for Index := Low(Payloads) to High(Payloads) do begin
            if Payloads[Index].Position.InUse and (Payloads[Index].Position.ReceivedAt > 0) then begin
                frmPayloads.ShowTimeSinceUpdate(Index, Now - Payloads[Index].Position.ReceivedAt, Payloads[Index].Position.Repeated);

                // Prediction done ?
                if Payloads[Index].Position.PredictionType = ptNone then begin
                    if Payloads[Index].PredictionIndex > 0 then begin
                        if Predictor.PredictionUpdated(Payloads[Index].PredictionIndex) then begin
                            Predictor.GetPrediction(Index, Payloads[Index].Position.PredictedLatitude, Payloads[Index].Position.PredictedLongitude, PredictedAltitude);
                            Payloads[Index].Position.PredictionType := ptTawhiri;

                            // Move marker on map
                            if frmMap <> nil then frmMap.NewPosition(Index, Payloads[Index].Position);

                            // Updated in payload box
                            if frmPayloads <> nil then frmPayloads.NewPosition(Index, Payloads[Index].Position);
                        end;
                    end;
                end;
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

procedure TfrmMain.ShowSelectedMapButton(ElementID: String);
begin
    FNCMap.ExecuteJavaScript('document.getElementById("btnCar").disabled = false');
    FNCMap.ExecuteJavaScript('document.getElementById("btnHAB").disabled = false');
    FNCMap.ExecuteJavaScript('document.getElementById("btnFree").disabled = false');

    FNCMap.ExecuteJavaScript('document.getElementById("' + ElementID + '").disabled = true');
end;

procedure TfrmMain.FNCMapElementContainers0Actions0Execute(Sender: TObject;
  AEventData: TTMSFNCMapsEventData);
begin
    ShowSelectedMapButton('btnCar');
    frmMap.btnCarClick(Sender);
end;

procedure TfrmMain.FNCMapElementContainers0Actions1Execute(Sender: TObject;
  AEventData: TTMSFNCMapsEventData);
begin
    ShowSelectedMapButton('btnHAB');
    frmMap.btnPayloadClick(Sender);
end;

procedure TfrmMain.FNCMapElementContainers0Actions2Execute(Sender: TObject;
  AEventData: TTMSFNCMapsEventData);
begin
    ShowSelectedMapButton('btnFree');
    frmMap.btnFreeClick(Sender);
end;

procedure TfrmMain.FNCMapMapInitialized(Sender: TObject);
begin
    frmMap.MapInitialized;
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

    if Position.FlightMode = fmDescending then begin
        Position.DescentTime := CalculateDescentTime(Position.Altitude, -Position.AscentRate, ChasePosition.Altitude) / 86400;
    end;

end;

function TfrmMain.BalloonColour(PayloadIndex: Integer): TAlphaColor;
begin
    if (PayloadIndex >= Low(Payloads)) and (PayloadIndex <= High(Payloads)) then begin
        Result := Payloads[PayloadIndex].Colour;
    end else begin
        Result := Payloads[Low(Payloads)].Colour;
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
            PayloadList := PayloadList + ',' + Payloads[i].Position.PayloadID;
        end;
    end;

    PayloadList := Copy(PayloadList, 2, 999);

    frmSources.UpdatePayloadList(PayloadList);

    for i := Low(Payloads) to High(Payloads) do begin
        if frmUplink <> nil then frmUplink.UpdatePayloadID(i, Payloads[i].Position.PayloadID);
    end;
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
        if frmPayloads <> nil then frmPayloads.NewSelection(PayloadIndex);
        if frmUplink <> nil then frmUplink.NewSelection(PayloadIndex);
        if frmDirection <> nil then frmDirection.NewSelection(PayloadIndex);
    end;
end;

procedure TfrmMain.ResizeFonts(AForm: TForm);
var
    i: Integer;
    Component: TComponent;

begin
    if AForm.Tag = 0 then begin
        // Not resized yet
        AForm.Tag := 1;

        for i := 0 to AForm.ComponentCount-1 do begin
            Component := AForm.Components[i];

            if Component is TButton then begin
                TButton(Component).Font.Size := TButton(Component).Font.Size * ScalingFactor;
            end else if Component is TLabel then begin
                TLabel(Component).Font.Size := TLabel(Component).Font.Size * ScalingFactor;
            end else if Component is TTMSFMXEdit then begin
                TTMSFMXEdit(Component).Font.Size := TTMSFMXEdit(Component).Font.Size * ScalingFactor;
            end else if Component is TTMSFNCRadioButton then begin
                TTMSFNCRadioButton(Component).Font.Size := TTMSFNCRadioButton(Component).Font.Size * ScalingFactor;
            end else if Component is TTMSFNCPageControl then begin
                TTMSFNCPageControl(Component).TabAppearance.Font.Size := TTMSFNCPageControl(Component).TabAppearance.Font.Size * ScalingFactor;
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

function TfrmMain.GetSourceMask(PayloadIndex: Integer): Integer;
begin
    Result := Payloads[PayloadIndex].SourceMask;
end;

procedure TfrmMain.LoadSettingsPage(PageIndex: Integer);
begin
    if frmSettings = nil then begin
        frmSettings := TfrmSettings.Create(nil);
    end;

    LoadForm(btnSettings, frmSettings);

    frmSettings.LoadPage(PageIndex);
end;

procedure TfrmMain.UpdateCarUploadSettings;
begin
    frmSources.UpdateCarUploadSettings;
end;

end.
