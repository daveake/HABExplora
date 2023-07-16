unit Base;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo,
  FMX.TMSCustomEdit, FMX.TMSEdit;

type
  TfrmBase = class(TForm)
    pnlMain: TPanel;
    procedure pnlMainResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Resized: Boolean;
    DesignHeight: Single;
    procedure ResizeFonts;
  public
    { Public declarations }
    procedure LCARSLabelClick(Sender: TObject);
    procedure CheckLCARSLabel(Sender: TObject; Checked: Boolean);
    function LCARSLabelIsChecked(Sender: TObject): Boolean;

    procedure LoadForm; virtual;
    procedure HideForm; virtual;
  end;

var
  frmBase: TfrmBase;

implementation

{$R *.fmx}

procedure TfrmBase.LoadForm;
begin
    // virtual
end;

procedure TfrmBase.pnlMainResize(Sender: TObject);
begin
    ResizeFonts;
end;

procedure TfrmBase.FormCreate(Sender: TObject);
begin
    Resized := False;
    DesignHeight := pnlMain.Height;
end;

procedure TfrmBase.HideForm;
begin
    pnlMain.Parent := Self;
end;

procedure TfrmBase.LCARSLabelClick(Sender: TObject);
begin
    CheckLCARSLabel(Sender, not LCARSLabelIsChecked(Sender));
end;

procedure TfrmBase.CheckLCARSLabel(Sender: TObject; Checked: Boolean);
var
    Rectangle: TRoundRect;
    Text, Check: TText;
begin
    Rectangle := TRoundRect(TLabel(Sender).FindStyleResource('rectangle'));
    Text := TText(TLabel(Sender).FindStyleResource('text'));
    Check := TText(TLabel(Sender).FindStyleResource('check'));

    if (Rectangle <> nil) and (Text <> nil) then begin
        if Checked then begin
            Rectangle.Stroke.Color := TAlphaColorRec.Yellow;
            Rectangle.Fill.Color := TAlphaColorRec.Yellow;
            Check.Visible := True;
            Text.TextSettings.Font.Style := Text.TextSettings.Font.Style + [TFontStyle.fsBold];
            TLabel(Sender).Tag := 1;
        end else begin
            Rectangle.Stroke.Color := TAlphaColorRec.Gray;
            Rectangle.Fill.Color := TAlphaColorRec.Black;
            Check.Visible := False;
            Text.TextSettings.Font.Style := Text.TextSettings.Font.Style - [TFontStyle.fsBold];
            TLabel(Sender).Tag := 0;
        end;
    end;
end;

function TfrmBase.LCARSLabelIsChecked(Sender: TObject): Boolean;
begin
    Result := TLabel(Sender).Tag <> 0;
end;

procedure TfrmBase.ResizeFonts;
var
    i: Integer;
    Component: TComponent;
begin
    if not Resized then begin
        Resized := True;
        for i := 0 to pnlMain.ComponentCount-1 do begin
            Component := pnlMain.Components[i];

            if Component is TLabel then begin
                TLabel(Component).Font.Size := TLabel(Component).Font.Size * pnlMain.Height / DesignHeight;
            end else if Component is TMemo then begin
                TMemo(Component).TextSettings.Font.Size := TMemo(Component).TextSettings.Font.Size * pnlMain.Height / DesignHeight;
            end else if Component is TTMSFMXEdit then begin
                TTMSFMXEdit(Component).TextSettings.Font.Size := TTMSFMXEdit(Component).TextSettings.Font.Size * pnlMain.Height / DesignHeight;
            end;
        end;
    end;
end;

end.

