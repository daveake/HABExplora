unit Payloads;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TargetForm, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, Miscellaneous, Source,
  FMX.Colors, FMX.Objects;

type
  TfrmPayloads = class(TfrmTarget)
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    Rectangle3: TRectangle;
    procedure pnlMainResized(Sender: TObject);
    procedure Label1Click(Sender: TObject);
  private
    { Private declarations }
    Rectangles: Array[1..3] of TRectangle;
    Labels: Array[1..3, 0..12] of TLabel;
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure NewPosition(Index: Integer; HABPosition: THABPosition); override;
    procedure NewSelection(Index: Integer); override;
    procedure ShowTimeSinceUpdate(Index: Integer; TimeSinceUpdate: TDateTime; Repeated: Boolean);
  end;

var
  frmPayloads: TfrmPayloads;

implementation

{$R *.fmx}

uses Main;

function RepeatString(Repeated: Boolean): String;
begin
    if Repeated then begin
        Result := ' (R)';
    end else begin
        Result := '';
    end;
end;

procedure TfrmPayloads.NewPosition(Index: Integer; HABPosition: THABPosition);
begin
    if (Index >= 1) and (Index <= 2) then begin
        if HABPosition.InUse then begin
            if HABPosition.Device = '' then begin
                Labels[Index,0].Text := HABPosition.PayloadID + ' (00:00)';
            end else begin
                Labels[Index,0].Text := HABPosition.Device + ': ' + HABPosition.PayloadID;
            end;

            if HABPosition.Counter > 0 then begin
                Labels[Index,1].Text := '(' + IntToStr(HABPosition.Counter) + ') ' + FormatDateTime('hh:mm:ss', HABPosition.TimeStamp);
            end else begin
                Labels[Index,1].Text := FormatDateTime('hh:mm:ss', HABPosition.TimeStamp);
            end;

            // lat and lon
            Labels[Index,2].Text := MyFormatFloat('0.00000', HABPosition.Latitude) + ', ' + MyFormatFloat('0.00000', HABPosition.Longitude);

            // alt and max alt
            if HABPosition.MaxAltitude > HABPosition.Altitude then begin
                Labels[Index,3].Text := MyFormatFloat('0', HABPosition.Altitude) + 'm (' + MyFormatFloat('0', HABPosition.MaxAltitude) + 'm)';
            end else begin
                Labels[Index,3].Text := MyFormatFloat('0', HABPosition.Altitude) + 'm';
            end;

            // Prediction
            if HABPosition.PredictionType <> ptNone then begin
                Labels[Index,4].Text := 'Pred: ' + MyFormatFloat('0.00000', HABPosition.PredictedLatitude) + ', ' + MyFormatFloat('0.00000', HABPosition.PredictedLongitude);
            end;

            // Ascent rate
            Labels[Index,5].Text := MyFormatFloat('0.0', HABPosition.AscentRate) + ' m/s';
        end;

        if HABPosition.TelemetryCount > 0 then begin
            Labels[Index,6].Text := 'Telem: ' + HABPosition.TelemetryCount.ToString;
        end;

        if HABPosition.HasFrequency then begin
            Labels[Index,7].Text := 'FreqErr: ' + MyFormatFloat('0', HABPosition.FrequencyError*1000) + ' Hz';
        end;

        if HABPosition.HasPacketRSSI then begin
            Labels[Index,8].Text := 'RSSI: ' + HABPosition.PacketRSSI.ToString + ' dB';
        end;

        if HABPosition.SSDVCount > 0 then begin
            Labels[Index,9].Text := 'SSDV: ' + HABPosition.SSDVCount.ToString;
        end;

        if HABPosition.IsSSDV then begin
            Labels[Index,10].Text :=  'Img: ' + HABPosition.SSDVFileNumber.ToString + ' Pkt: ' + HABPosition.SSDVPacketNumber.ToString;
        end;

        if HABPosition.FlightMode = fmLanded then begin
            Labels[Index,11].Text := 'Landed';
        end else if HABPosition.FlightMode = fmDescending then begin
            if HABPosition.DescentTime > 0 then begin
                Labels[Index,11].Text := 'Desc: ' + FormatDateTime('nn:ss', HABPosition.DescentTime);
            end;
        end else if HABPosition.FlightMode = fmLaunched then begin
            Labels[Index,11].Text := 'Ascending';
        end else begin
            Labels[Index,11].Text := '';
        end;
    end;
end;

procedure TfrmPayloads.ShowTimeSinceUpdate(Index: Integer; TimeSinceUpdate: TDateTime; Repeated: Boolean);
var
    Line: String;
begin
    if (Index >= 1) and (Index <= 3) then begin
        // ListBoxes[Index].Items[1] := FormatDateTime('nn:ss', TimeSinceUpdate) + RepeatString(Repeated);
        Line := Labels[Index,0].Text;
        Labels[Index,0].Text := GetString(Line, ' (') + ' (' + FormatDateTime('nn:ss', TimeSinceUpdate) + RepeatString(Repeated) + ')';
    end;
end;

procedure TfrmPayloads.Label1Click(Sender: TObject);
begin
    frmMain.SelectPayload(TLabel(Sender).Tag);
end;

procedure TfrmPayloads.LoadForm;
begin
    inherited;
    pnlMainResize(nil);
end;

procedure TfrmPayloads.NewSelection(Index: Integer);
var
    i: Integer;
begin
    inherited;

    for i := Low(Rectangles) to High(Rectangles) do begin
        if i = Index then begin
            Rectangles[i].Stroke.Color := TAlphaColorRec.Yellow;
            //Rectangles[i].Stroke.Thickness := 4;
        end else begin
            Rectangles[i].Stroke.Color := TAlphaColorRec.Gray; // $FFF1DF6F;
            //Rectangles[i].Stroke.Thickness := 1;
        end;
    end;
end;

procedure TfrmPayloads.pnlMainResized(Sender: TObject);
var
    i, j: Integer;
    LabelHeight, Top: Double;
begin
    inherited;

    LabelHeight := (Rectangle1.Height - 16) / 6;

    Rectangle1.Height := pnlMain.Height / 3;
    Rectangle2.Height := pnlMain.Height / 3;

    if Rectangles[1] = nil then begin
        Rectangles[1] := Rectangle1;
        Rectangles[2] := Rectangle2;
        Rectangles[3] := Rectangle3;

        // Create labels
        for i := 1 to 3 do begin
            Top := 0;
            for j := 0 to 12 do begin
                Labels[i,j] := TLabel.Create(nil);
                Labels[i,j].Parent := Rectangles[i];
                Labels[i,j].Height := LabelHeight;

                if j = 6 then begin
                    Top := 0;
                end;

                if j < 6 then begin
                    Labels[i,j].Position.X := 0;
                    Labels[i,j].Width := Rectangles[i].Width * 0.66;
                end else begin
                    Labels[i,j].Position.X := Rectangles[i].Width * 0.66;
                    Labels[i,j].Width := Rectangles[i].Width * 0.33;
                end;

                Labels[i,j].Position.Y := Round(Top);
                Labels[i,j].TextSettings.Font.Family := 'Arial';    // Swiss911 XCm BT';
                Labels[i,j].TextSettings.FontColor := TAlphaColorRec.Yellow;
                Labels[i,j].TextSettings.HorzAlign := TTextAlign.Center;
                Labels[i,j].Align := TAlignLayout.Scale;
                Labels[i,j].StyledSettings := [];
                Labels[i,j].Visible := True;
                Labels[i,j].Tag := j;
                Labels[i,j].OnClick := Label1Click;
                Top := Top + Labels[i,j].Height;
            end;
        end;
    end;

    // Resize labels
    for i := 1 to 3 do begin
        for j := 0 to 12 do begin
            // Labels[i,j].TextSettings.Font.Size := min(LabelHeight * 0.95, Labels[i,j].Width / 6.5);
            Labels[i,j].TextSettings.Font.Size := LabelHeight * 0.5;
        end;
    end;
end;

end.
