unit Direction;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TargetForm, FMX.Controls.Presentation, FMX.TMSBaseControl, FMX.TMSGauge,
  Source, Math, FMX.Objects,
{$IFDEF ANDROID}
  Androidapi.JNIBridge, AndroidApi.JNI.Media, AndroidAPI.jni.OS,
  Androidapi.JNI.JavaTypes, Androidapi.JNI.GraphicsContentViewText, Androidapi.Helpers, Androidapi.JNI.Net,
  FMX.Helpers.Android, FMX.Platform.Android, AndroidApi.Jni.App,
{$ENDIF}
{$IFDEF IOS}
  iOSapi.Foundation, FMX.Helpers.iOS, Macapi.Helpers,
{$ENDIF}
  Miscellaneous;

type
  TfrmDirection = class(TfrmTarget)
    lblPosition: TLabel;
    btnNavigate: TButton;
    btnRoute: TButton;
    btnOffRoad: TButton;
    chkUsePrediction: TLabel;
    TMSFMXCompass1: TTMSFMXCompass;
    lblDistance: TLabel;
    lblCompass: TLabel;
    lblMode: TLabel;
    lblAltitude: TLabel;
    StyleBook1: TStyleBook;
    procedure chkPredictionClick(Sender: TObject);
    procedure btnNavigateClick(Sender: TObject);
    procedure btnRouteClick(Sender: TObject);
    procedure pnlMainResize(Sender: TObject);
    procedure btnOffRoadClick(Sender: TObject);
    procedure chkUsePredictionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmrUpdatesTimer(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure ProcessNewDirection(Index: Integer); override;
    procedure NewPosition(Index: Integer; Position: THABPosition); override;
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure HideForm; override;
  end;

var
  frmDirection: TfrmDirection;

implementation

uses Main;

{$R *.fmx}

procedure TfrmDirection.LoadForm;
begin
    inherited;

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
{$ENDIF}

{$IFDEF IOS}
function OpenURL(const URL: string): Boolean;
var
  NSU: NSUrl;
begin
    Result := False;

    // iOS doesn't like spaces, so URL encode is important.
    // NSU := StrToNSUrl(TIdURI.URLEncode(URL));
    NSU := StrToNSUrl(URL);
    if SharedApplication.canOpenURL(NSU) then begin
        SharedApplication.openUrl(NSU);
        Result := True;
    end;
end;
{$ENDIF}

procedure TfrmDirection.btnNavigateClick(Sender: TObject);
var
    TargetLocation: String;
begin
    if LCARSLabelIsChecked(chkUsePrediction) and (Positions[SelectedIndex].Position.PredictionType <> ptNone) then begin
        TargetLocation := Positions[SelectedIndex].Position.PredictedLatitude.ToString + ',' + Positions[SelectedIndex].Position.PredictedLongitude.ToString
    end else begin
        TargetLocation := Positions[SelectedIndex].Position.Latitude.ToString + ',' + Positions[SelectedIndex].Position.Longitude.ToString
    end;

    {$IFDEF IOS}
        if not OpenURL('comgooglemaps://?daddr=' + TargetLocation) then begin
            OpenURL('http://maps.apple.com/?daddr=' + TargetLocation);
        end;
    {$ENDIF}

    {$IFDEF ANDROID}
        OpenURL('google.navigation:q=' + TargetLocation);
    {$ENDIF}
end;

procedure TfrmDirection.btnOffRoadClick(Sender: TObject);
begin
{$IF Defined(IOS) or Defined(ANDROID)}
    if LCARSLabelIsChecked(chkUsePrediction) and (Positions[SelectedIndex].Position.PredictionType <> ptNone) then begin
        OpenURL('geo:' + Positions[SelectedIndex].Position.PredictedLatitude.ToString + ',' + Positions[SelectedIndex].Position.PredictedLongitude.ToString);
    end else begin
        OpenURL('geo:' + Positions[SelectedIndex].Position.Latitude.ToString + ',' + Positions[SelectedIndex].Position.Longitude.ToString);
    end;
{$ENDIF}
end;

procedure TfrmDirection.btnRouteClick(Sender: TObject);
begin
    frmMain.ShowRouteToPayload(SelectedIndex, LCARSLabelIsChecked(chkUsePrediction) and (Positions[SelectedIndex].Position.PredictionType <> ptNone));
end;

procedure TfrmDirection.chkPredictionClick(Sender: TObject);
begin
    LCARSLabelClick(Sender);
end;

procedure TfrmDirection.chkUsePredictionClick(Sender: TObject);
begin
    if Positions[SelectedIndex].Position.PredictionType <> ptNone then begin
        LCARSLabelClick(Sender);
    end;
end;

procedure TfrmDirection.FormCreate(Sender: TObject);
begin
  inherited;

    {$IFDEF IOS}
        btnOffRoad.Visible := False;
    {$ENDIF}
end;

procedure TfrmDirection.HideForm;
begin
    inherited;
end;

procedure TfrmDirection.ProcessNewDirection(Index: Integer);
var
    Distance, VerticalDistance, Direction: Double;
begin
    inherited;

    TMSFMXCompass1.NeedStyleLookup;
    TMSFMXCompass1.ApplyStyleLookup;

    if LCARSLabelIsChecked(chkUsePrediction) and (Positions[SelectedIndex].Position.PredictionType <> ptNone) then begin
        Distance := Positions[SelectedIndex].Position.PredictionDistance;
        Direction := Positions[SelectedIndex].Position.PredictionDirection;
    end else begin
        Distance := Positions[SelectedIndex].Position.Distance;
        Direction := Positions[SelectedIndex].Position.Direction;
    end;

    TMSFMXCompass1.GetNeedle.RotationAngle := Direction * 180 / Pi;

    if LCARSLabelIsChecked(chkUsePrediction) and (Positions[SelectedIndex].Position.PredictionType <> ptNone) then begin
        // Use prediction
        if Distance >= 1000 then begin
            lblDistance.Text := 'Dist: ' + MyFormatFloat('0.0', Distance / 1000) + 'km, ' +
                                'Dir: ' +  MyFormatFloat('0', Direction) + '°,';
        end else begin
            lblDistance.Text := 'Dist: ' + MyFormatFloat('0.0', Distance) + 'm, ' +
                                'Dir: ' +  MyFormatFloat('0', Direction * 180 / Pi) + '°,';
        end;
    end else begin
        if Distance >= 100000 then begin
            lblDistance.Text := 'Dist: ' + MyFormatFloat('0', Distance / 1000) + 'km, ' +
                                'Dir: ' +  MyFormatFloat('0', Direction * 180 / Pi) + '°, ' +
                                'Elev: ' + MyFormatFloat('0.0', Positions[SelectedIndex].Position.Elevation) + '°';
        end else if Distance >= 1000 then begin
            lblDistance.Text := 'Dist: ' + MyFormatFloat('0.0', Distance / 1000) + 'km, ' +
                                'Dir: ' +  MyFormatFloat('0', Direction * 180 / Pi) + '°, ' +
                                'Elev: ' + MyFormatFloat('0.0', Positions[SelectedIndex].Position.Elevation) + '°';
        end else begin
            lblDistance.Text := 'Dist: ' + MyFormatFloat('0.0', Distance) + 'm, ' +
                                'Dir: ' +  MyFormatFloat('0', Direction) + '°, ' +
                                'Elev: ' + MyFormatFloat('0.0', Positions[SelectedIndex].Position.Elevation) + '°';
        end;
    end;

    VerticalDistance := Positions[SelectedIndex].Position.Altitude - Positions[0].Position.Altitude;

    if VerticalDistance <= -1 then begin
        // lblRelativeAltitude.Text := MyFormatFloat('0', -VerticalDistance) + 'm below';
    end else if (VerticalDistance >= 1) and (VerticalDistance < 1000) then begin
        // lblRelativeAltitude.Text := MyFormatFloat('0', VerticalDistance) + 'm above';
    end else begin
        // lblRelativeAltitude.Text := '';
    end;


//    Radius := Min(crcCompass.Width, crcCompass.Height) / 2;
//    Radius := Radius * (1 - crcCompass.Stroke.Thickness * 0.5 / Radius);

//    crcDot.Position.X := ((crcCompass.Width / 2) - crcDot.Width / 2) + Radius * sin(Direction);
//    crcDot.Position.Y := ((crcCompass.Height / 2) - crcDot.Height / 2) - Radius * cos(Direction);


    if Positions[0].Position.DirectionValid then begin
        // crcDot.Fill.Color := TAlphaColorRec.Lime;
    end else begin
        // crcDot.Fill.Color := TAlphaColorRec.Red;
    end;
end;


procedure TfrmDirection.tmrUpdatesTimer(Sender: TObject);
begin
    inherited;

    if TMSFMXCompass1.RotationAngle <> -Positions[0].Position.Direction then begin
        TMSFMXCompass1.RotationAngle := -Positions[0].Position.Direction;          // minus because we need to orientate the screen compass so it correctly shows North
        TMSFMXCompass1.Repaint;
    end;
end;

procedure TfrmDirection.NewPosition(Index: Integer; Position: THABPosition);
begin
    inherited;

    if (SelectedIndex > 0) and (Index = SelectedIndex) then begin
        lblPosition.Text := MyFormatFloat('0.00000', Positions[SelectedIndex].Position.Latitude) + ', ' +
                            MyFormatFloat('0.00000', Positions[SelectedIndex].Position.Longitude);

        lblAltitude.Text := MyFormatFloat('0', Positions[SelectedIndex].Position.Altitude) + ' m, ' +
                            MyFormatFloat('0.0', Positions[SelectedIndex].Position.AscentRate) + ' m/s';

        if Positions[SelectedIndex].Position.FlightMode = fmLanded then begin
            lblMode.Text := 'Landed';
        end else if Positions[SelectedIndex].Position.FlightMode = fmDescending then begin
            if Positions[SelectedIndex].Position.DescentTime > 0 then begin
                lblMode.Text := 'Desc: ' + FormatDateTime('nn:ss', Positions[SelectedIndex].Position.DescentTime);
            end;
        end else if Positions[SelectedIndex].Position.FlightMode = fmLaunched then begin
            lblMode.Text := 'Ascending';
        end else begin
            lblMode.Text := '';
        end;
    end else if Index = 0 then begin
        if Positions[0].Position.UsingCompass then begin
            lblCompass.Text := 'MAG';
        end else begin
            lblCompass.Text := 'GPS';
        end;
    end;
end;



procedure TfrmDirection.pnlMainResize(Sender: TObject);
begin
    inherited;

    // Label1.Font.Size := Label1.Height * 48 / 55;
    // lblDistance.Font.Size := lblDistance.Height * 64 / 512;

    // Compass

    TMSFMXCompass1.Width := min(pnlMain.Width, lblPosition.Position.Y * 0.95) * 0.95;
    TMSFMXCompass1.Height := TMSFMXCompass1.Width;

    TMSFMXCompass1.Position.X := (pnlMain.Width - TMSFMXCompass1.Width) / 2;
    TMSFMXCompass1.Position.Y := (lblPosition.Position.Y * 0.95 - TMSFMXCompass1.Height) / 2;
end;

end.
