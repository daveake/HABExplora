unit Map;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Base, TargetForm, System.IOUtils, FMX.Controls.Presentation,
  Source, FMX.Objects, FMX.TMSFNCTypes, FMX.TMSFNCUtils,
  FMX.TMSFNCGraphics, FMX.TMSFNCGraphicsTypes, FMX.TMSFNCMapsCommonTypes,
  FMX.TMSFNCCustomControl, FMX.TMSFNCWebBrowser, FMX.TMSFNCMaps;

type
  TMapFollowMode = (mmIdle, mmInit, mmHome, mmFree, mmCar, mmPayload);

type
  TDirections = record
    Active: Boolean;
    TargetLatitude: Double;
    TargetLongitude: Double;
    CurrentLatitude: Double;
    CurrentLongitude: Double;
  end;

type
  TMapPayload = record
      Markers:          Array[0..1] of TTMSFNCMapsMarker;
      MarkerNames:      Array[0..1] of String;
      Track:            TTMSFNCMapsPolyline;
  end;

type
  TfrmMap = class(TfrmTarget)
    pnlCentre: TPanel;
    tmrDirections: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure btnCarClick(Sender: TObject);
    procedure btnFreeClick(Sender: TObject);
    procedure btnPayloadClick(Sender: TObject);
    procedure tmrDirectionsTimer(Sender: TObject);
  private
    { Private declarations }
    Directions: TDirections;
    FollowMode: TMapFollowMode;
    Balloons: Array[0..3] of TMapPayload;
    procedure AddOrUpdateMapMarker(PayloadIndex: Integer; PayloadID: String; Latitude: Double; Longitude: Double; ImageName: String; IsTarget: Boolean);
    procedure DrawPath(PayloadIndex: Integer; Colour: TAlphaColor);
  protected
    function ProcessNewPosition(Index: Integer): Boolean; override;
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure HideForm; override;
    procedure ShowDirections(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double);
    procedure MapInitialized;
  end;

var
  frmMap: TfrmMap;

implementation

{$R *.fmx}

uses Main, Miscellaneous, Debug;

// IF THE FOLLOWING LINE GIVES AN ERROR

{$INCLUDE 'key.pas'}

(* THEN CREATE A FILE key.pas CONTAINING:

const GoogleMapsAPIKey = '<YOUR_GOOGLE_API_KEY>';

THIS FILE IS SPECIFICALLY EXCLUDED in .gitignore TO AVOID SHARING API KEYS
*)

procedure TfrmMap.FormCreate(Sender: TObject);
var
    i: Integer;
begin
    inherited;

    frmMain.FNCMap.APIKey := GoogleMapsAPIKey;

//    GMap.LocationAPIKey := GoogleMapsAPIKey;
//
//    GMap.APIKey := GMap.LocationAPIKey;
//
//    // GMap.ShowDebugConsole := True;
//
//    {$IFDEF ANDROID}
//        GMap.Visible := False;
//    {$ENDIF}
//
//    for i := 0 to 3 do begin
//        PolylineItems[i] := GMap.Polylines.Add;
//        PolylineItems[i].Polyline.Width := 2;
//        GMap.CreateMapPolyline(PolylineItems[i].Polyline);
//    end;
//
//    FollowMode := fmInit;
//
//    OKToUpdateMap := True;
end;

procedure TfrmMap.LoadForm;
begin
    inherited;

//    if not GMap.Visible then begin
//        GMap.Visible := True;
//    end;

//    btnCar.Font.Size := btnCar.Size.Height * 36/64;
//    btnFree.Font.Size := btnCar.Font.Size;
//    btnPayload.Font.Size := btnCar.Font.Size;
end;

procedure TfrmMap. MapInitialized;
begin
    if FollowMode = mmInit then begin
        if Positions[0].Position.InUse then begin
            frmMain.FNCMap.SetCenterCoordinate(Positions[0].Position.Latitude, Positions[0].Position.Longitude);
            btnFreeClick(nil);
        end;
    end;
end;


procedure TfrmMap.HideForm;
begin
//    {$IFDEF ANDROID}
//        GMap.Visible := False;
//    {$ENDIF}

    inherited;
end;

procedure TfrmMap.btnCarClick(Sender: TObject);
begin
    FollowMode := mmCar;
    frmMain.FNCMap.SetCenterCoordinate(Positions[0].Position.Latitude, Positions[0].Position.Longitude);
end;

procedure TfrmMap.btnFreeClick(Sender: TObject);
begin
    FollowMode := mmFree;
end;

procedure TfrmMap.btnPayloadClick(Sender: TObject);
begin
    FollowMode := mmPayload;
    if Positions[SelectedIndex].Position.InUse then begin
        frmMain.FNCMap.SetCenterCoordinate(Positions[SelectedIndex].Position.Latitude, Positions[SelectedIndex].Position.Longitude);
    end;
end;

procedure TfrmMap.AddOrUpdateMapMarker(PayloadIndex: Integer; PayloadID: String; Latitude: Double; Longitude: Double; ImageName: String; IsTarget: Boolean);
var
    MarkerIndex: Integer;
    FileName: String;
begin
    if IsTarget then MarkerIndex := 1 else MarkerIndex := 0;

    if Balloons[PayloadIndex].Markers[MarkerIndex] = nil then begin
        Balloons[PayloadIndex].Markers[MarkerIndex] := frmMain.FNCMap.Markers.Add;
        Balloons[PayloadIndex].Markers[MarkerIndex].Title := PayloadID;
    end;

    Balloons[PayloadIndex].Markers[MarkerIndex].Latitude := Latitude;
    Balloons[PayloadIndex].Markers[MarkerIndex].Longitude := Longitude;

    FileName := System.IOUtils.TPath.Combine(ImageFolder, ImageName + '.png');

    if FileName <> Balloons[PayloadIndex].MarkerNames[MarkerIndex] then begin
        Balloons[PayloadIndex].MarkerNames[MarkerIndex] := FileName;
        if FileExists(FileName) then begin
            Balloons[PayloadIndex].Markers[MarkerIndex].IconURL := StringReplace('File://' + FileName, '\', '/',[rfReplaceAll, rfIgnoreCase]);
        end;
    end;
end;

procedure TfrmMap.DrawPath(PayloadIndex: Integer; Colour: TAlphaColor);
begin
    if Balloons[PayloadIndex].Track = nil then begin
        Balloons[PayloadIndex].Track := frmMain.FNCMap.Polylines.Add;
        Balloons[PayloadIndex].Track.StrokeColor := Colour;
    end;

    with Balloons[PayloadIndex].Track.Coordinates.Add do begin
        Latitude := Positions[PayloadIndex].Position.Latitude;
        Longitude := Positions[PayloadIndex].Position.Longitude;
    end;

    Balloons[PayloadIndex].Track.Visible := False;
    Balloons[PayloadIndex].Track.Visible := True;
end;


function TfrmMap.ProcessNewPosition(Index: Integer): Boolean;
begin
    Result := False;

    // Find or create marker for this payload
    if Index = 0 then begin
        // Update chase car marker
        AddOrUpdateMapMarker(Index, 'Car', Positions[0].Position.Latitude, Positions[0].Position.Longitude, 'car-blue', False);
        if FollowMode = mmCar then begin
            frmMain.FNCMap.SetCenterCoordinate(Positions[Index].Position.Latitude, Positions[Index].Position.Longitude);
        end;
    end else begin
        // Update balloon marker
        AddOrUpdateMapMarker(Index,
                             Positions[Index].Position.PayloadID,
                             Positions[Index].Position.Latitude,
                             Positions[Index].Position.Longitude,
                             frmMain.BalloonIconName(Index, False), False);

        DrawPath(Index, frmMain.BalloonColour(Index));

        if (FollowMode = mmPayload) and (Index = SelectedIndex) then begin
            frmMain.FNCMap.SetCenterCoordinate(Positions[Index].Position.Latitude, Positions[Index].Position.Longitude);
        end;

        if Positions[Index].Position.PredictionType <> ptNone then begin
            AddOrUpdateMapMarker(Index, Positions[Index].Position.PayloadID + '-X', Positions[Index].Position.PredictedLatitude, Positions[Index].Position.PredictedLongitude, frmMain.BalloonIconName(Index, True), True);
        end;
    end;

    Result := True;
end;

procedure TfrmMap.tmrDirectionsTimer(Sender: TObject);
begin
    tmrDirections.Enabled := False;
    with Directions do begin
        frmMain.FNCMap.AddDirections(CurrentLatitude, CurrentLongitude, TargetLatitude, TargetLongitude);   // , tmDriving);
    end;
end;

procedure TfrmMap.ShowDirections(TargetLatitude, TargetLongitude, CurrentLatitude, CurrentLongitude: Double);
begin
    Directions.TargetLatitude := TargetLatitude;
    Directions.TargetLongitude := TargetLongitude;
    Directions.CurrentLatitude := CurrentLatitude;
    Directions.CurrentLongitude := CurrentLongitude;
    Directions.Active := True;
end;

end.

