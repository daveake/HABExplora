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
    crcCompass: TCircle;
    crcDot: TCircle;
    Label1: TLabel;
    lblDistance: TLabel;
    lblRelativeAltitude: TLabel;
    btnOffRoad: TButton;
    chkUsePrediction: TLabel;
    procedure chkPredictionClick(Sender: TObject);
    procedure btnNavigateClick(Sender: TObject);
    procedure btnRouteClick(Sender: TObject);
    procedure pnlMainResize(Sender: TObject);
    procedure btnOffRoadClick(Sender: TObject);
    procedure chkUsePredictionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
    if LCARSLabelIsChecked(chkUsePrediction) and Positions[SelectedIndex].Position.ContainsPrediction then begin
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
    if LCARSLabelIsChecked(chkUsePrediction) and Positions[SelectedIndex].Position.ContainsPrediction then begin
        OpenURL('geo:' + Positions[SelectedIndex].Position.PredictedLatitude.ToString + ',' + Positions[SelectedIndex].Position.PredictedLongitude.ToString);
    end else begin
        OpenURL('geo:' + Positions[SelectedIndex].Position.Latitude.ToString + ',' + Positions[SelectedIndex].Position.Longitude.ToString);
    end;
{$ENDIF}
end;

procedure TfrmDirection.btnRouteClick(Sender: TObject);
begin
    frmMain.ShowRouteToPayload(SelectedIndex, LCARSLabelIsChecked(chkUsePrediction) and Positions[SelectedIndex].Position.ContainsPrediction);
end;

procedure TfrmDirection.chkPredictionClick(Sender: TObject);
begin
    LCARSLabelClick(Sender);
end;

procedure TfrmDirection.chkUsePredictionClick(Sender: TObject);
begin
    if Positions[SelectedIndex].Position.ContainsPrediction then begin
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
    Distance, VerticalDistance, Direction, Radius: Double;
begin
    inherited;

    if LCARSLabelIsChecked(chkUsePrediction) and Positions[SelectedIndex].Position.ContainsPrediction then begin
        Distance := Positions[SelectedIndex].Position.PredictionDistance;
        Direction := Positions[SelectedIndex].Position.PredictionDirection;
    end else begin
        Distance := Positions[SelectedIndex].Position.Distance;
        Direction := Positions[SelectedIndex].Position.Direction;
    end;

    if Distance >= 1000 then begin
        lblDistance.Text := MyFormatFloat('0.0', Distance/1000) + ' km';
    end else begin
        lblDistance.Text := MyFormatFloat('0', Distance) + ' m';
    end;

    VerticalDistance := Positions[SelectedIndex].Position.Altitude - Positions[0].Position.Altitude;

    if VerticalDistance <= -1 then begin
        lblRelativeAltitude.Text := MyFormatFloat('0', -VerticalDistance) + 'm below';
    end else if (VerticalDistance >= 1) and (VerticalDistance < 1000) then begin
        lblRelativeAltitude.Text := MyFormatFloat('0', VerticalDistance) + 'm above';
    end else begin
        lblRelativeAltitude.Text := '';
    end;


    Radius := Min(crcCompass.Width, crcCompass.Height) / 2;
    Radius := Radius * (1 - crcCompass.Stroke.Thickness * 0.5 / Radius);

    crcDot.Position.X := ((crcCompass.Width / 2) - crcDot.Width / 2) + Radius * sin(Direction);
    crcDot.Position.Y := ((crcCompass.Height / 2) - crcDot.Height / 2) - Radius * cos(Direction);

    if Positions[0].Position.DirectionValid then begin
        crcDot.Fill.Color := TAlphaColorRec.Lime;
    end else begin
        crcDot.Fill.Color := TAlphaColorRec.Red;
    end;
end;


procedure TfrmDirection.NewPosition(Index: Integer; Position: THABPosition);
var
    Temp: String;
begin
    inherited;

    if Index = SelectedIndex then begin
        Temp := MyFormatFloat('0.00000', Positions[SelectedIndex].Position.Latitude) + ', ' +
                MyFormatFloat('0.00000', Positions[SelectedIndex].Position.Longitude) + ', ';
        if Positions[SelectedIndex].Position.Altitude > 1000 then begin
            Temp := Temp + MyFormatFloat('0.0', Positions[SelectedIndex].Position.Altitude/1000) + ' km';
        end else begin
            Temp := Temp + MyFormatFloat('0', Positions[SelectedIndex].Position.Altitude) + ' m';
        end;
        lblPosition.Text := Temp + ', ' + FormatFloat('0.0', Positions[SelectedIndex].Position.Elevation) + '°';
    end;
end;



procedure TfrmDirection.pnlMainResize(Sender: TObject);
begin
    inherited;
    // Label1.Font.Size := Label1.Height * 48 / 55;
    lblDistance.Font.Size := lblDistance.Height * 64 / 512;
end;

end.
