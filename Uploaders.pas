unit Uploaders;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Base, FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.ListBox,
  FMX.Platform, FMX.Clipboard;

type
  TfrmUploaders = class(TfrmBase)
    rectSH: TRectangle;
    Rectangle8: TRectangle;
    Label4: TLabel;
    rectSSDV: TRectangle;
    Rectangle2: TRectangle;
    Label2: TLabel;
    lstSondehub: TListBox;
    lstSSDV: TListBox;
    lblClipboard: TLabel;
    lblSSDVClipboard: TLabel;
    Timer1: TTimer;
    Timer2: TTimer;
    Timer3: TTimer;
    procedure lblClipboardClick(Sender: TObject);
    procedure lblSSDVClipboardClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure lstSondehubMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure lstSSDVMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  private
    { Private declarations }
    procedure ShowSuccess(ALabel: TLabel);
    procedure WriteToLog(ListBox: TListBox; Scroll: Boolean; Msg: String);
  public
    { Public declarations }
    procedure WriteSondehubStatus(Msg: String);
    procedure WriteSSDVStatus(Msg: String);
  end;

var
  frmUploaders: TfrmUploaders;

implementation

{$R *.fmx}

procedure CopyListBoxTextToClipboard(ListBox: TListBox);
var
    I: Integer;
    Text: string;
    ClipboardService: IFMXClipboardService;
begin
  // Concatenate all list items' text into a single string
    for I := 0 to ListBox.Count - 1 do begin
        Text := Text + ListBox.ListItems[I].Text + sLineBreak;
    end;

  // Get the clipboard service
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService, IInterface(ClipboardService)) then begin
      // Copy the text to the clipboard
        ClipboardService.SetClipboard(Text);
    end;
end;

procedure TfrmUploaders.ShowSuccess(ALabel: TLabel);
begin
    if ALabel.Hint = '' then begin
        Timer1.Enabled := True;
        ALabel.Hint := ALabel.Text;
        ALabel.Text := 'Log copied to clipboard!';
        Timer1.Enabled := True;
    end;
end;


procedure TfrmUploaders.Timer1Timer(Sender: TObject);
begin
    Timer1.Enabled := False;
    if lblClipboard.Hint <> '' then lblClipboard.Text := lblClipboard.Hint;
    if lblSSDVClipboard.Hint <> '' then lblSSDVClipboard.Text := lblSSDVClipboard.Hint;
end;

procedure TfrmUploaders.Timer2Timer(Sender: TObject);
begin
    Timer2.Enabled := False;
end;

procedure TfrmUploaders.Timer3Timer(Sender: TObject);
begin
    Timer3.Enabled := False;
end;

procedure TfrmUploaders.lblClipboardClick(Sender: TObject);
begin
    CopyListBoxTextToClipboard(lstSondehub);
    ShowSuccess(lblClipboard);
end;

procedure TfrmUploaders.lblSSDVClipboardClick(Sender: TObject);
begin
    CopyListBoxTextToClipboard(lstSSDV);
    ShowSuccess(lblSSDVClipboard);
end;

procedure TfrmUploaders.lstSondehubMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    Timer2.Enabled := True;
end;

procedure TfrmUploaders.lstSSDVMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
    Timer3.Enabled := True;
end;

procedure TfrmUploaders.WriteSondehubStatus(Msg: String);
begin
    WriteToLog(lstSondehub, not Timer2.Enabled, Msg);
end;

procedure TfrmUploaders.WriteSSDVStatus(Msg: String);
begin
    WriteToLog(lstSSDV, not Timer3.Enabled, Msg);
end;

procedure TfrmUploaders.WriteToLog(ListBox: TListBox; Scroll: Boolean; Msg: String);
begin
    if ListBox.Items.Count > 9999 then begin
        ListBox.Items.Delete(0);
    end;

    ListBox.Items.Add(FormatDateTime('hh:nn:ss', Now) + ': ' + Msg);

    if Scroll then begin
        ListBox.ItemIndex := ListBox.Items.Count-1;
    end;
end;

end.
