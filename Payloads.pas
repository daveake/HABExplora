unit Payloads;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TargetForm, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, Source,
  FMX.Colors, FMX.Objects;

type
  TfrmPayloads = class(TfrmTarget)
    ListBox2: TListBox;
    ListBox3: TListBox;
    Rectangle1: TRectangle;
    Rectangle2: TRectangle;
    Rectangle3: TRectangle;
    ListBox1: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure pnlMainResize(Sender: TObject);
    procedure ListBox1Enter(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
  private
    { Private declarations }
    ListBoxes: Array[1..3] of TListBox;
    Rectangles: Array[1..3] of TRectangle;
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure NewPosition(Index: Integer; HABPosition: THABPosition); override;
    procedure NewSelection(Index: Integer); override;
    procedure ShowTimeSinceUpdate(Index: Integer; TimeSinceUpdate: TDateTime);
  end;

var
  frmPayloads: TfrmPayloads;

implementation

{$R *.fmx}

uses Main, Miscellaneous;

procedure TfrmPayloads.FormCreate(Sender: TObject);
var
    i, j: Integer;
begin
    inherited;

    ListBoxes[1] := ListBox1;
    ListBoxes[2] := ListBox2;
    ListBoxes[3] := ListBox3;

    Rectangles[1] := Rectangle1;
    Rectangles[2] := Rectangle2;
    Rectangles[3] := Rectangle3;

    for i := Low(ListBoxes) to High((ListBoxes)) do begin
        ListBoxes[i].Items.Clear;
        for j := 1 to 6 do begin
            ListBoxes[i].Items.Add('');
        end;
    end;
end;

procedure TfrmPayloads.NewPosition(Index: Integer; HABPosition: THABPosition);
begin
    if (Index >= Low(ListBoxes)) and (Index <= High(ListBoxes)) then begin
        with ListBoxes[Index] do begin
            Items[0] := HABPosition.PayloadID;
            Items[1] := '00:00';
            Items[2] := FormatDateTime('hh:mm:ss', HABPosition.TimeStamp);
            Items[3] := MyFormatFloat('0.00000', HABPosition.Latitude) + ', ' + MyFormatFloat('0.00000', HABPosition.Longitude);
            if HABPosition.ContainsPrediction then begin
                Items[4] := MyFormatFloat('0', HABPosition.Altitude) + 'm (' + MyFormatFloat('0', HABPosition.MaxAltitude) + 'm) @ ' + MyFormatFloat('0.0', HABPosition.AscentRate) + ' m/s';
                Items[5] := MyFormatFloat('0.00000', HABPosition.PredictedLatitude) + ',' + MyFormatFloat('0.00000', HABPosition.PredictedLongitude);
            end else begin
                Items[4] := MyFormatFloat('0', HABPosition.Altitude) + 'm (' + MyFormatFloat('0', HABPosition.MaxAltitude) + 'm)';
                Items[5] := MyFormatFloat('0.0', HABPosition.AscentRate) + ' m/s';
            end;
        end;
    end;
end;

procedure TfrmPayloads.pnlMainResize(Sender: TObject);
var
    i: Integer;
begin
    if ListBoxes[1] <> nil then begin
        for i := 1 to 3 do begin
            ListBoxes[i].ItemHeight := (ListBoxes[i].Height - 24) / ListBoxes[i].Items.Count;
        end;
    end;
end;

procedure TfrmPayloads.ShowTimeSinceUpdate(Index: Integer; TimeSinceUpdate: TDateTime);
begin
    if (Index >= Low(ListBoxes)) and (Index <= High(ListBoxes)) then begin
        ListBoxes[Index].Items[1] := FormatDateTime('nn:ss', TimeSinceUpdate);
    end;
end;

procedure TfrmPayloads.ListBox1Click(Sender: TObject);
begin
    TListBox(Sender).ItemIndex := -1;
end;

procedure TfrmPayloads.ListBox1Enter(Sender: TObject);
begin
    frmMain.SelectPayload(TListBox(Sender).Tag);
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
        end else begin
            Rectangles[i].Stroke.Color := TAlphaColorRec.Black;
        end;
    end;
end;

end.
