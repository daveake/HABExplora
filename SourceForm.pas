unit SourceForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Base, FMX.Controls.Presentation, FMX.Objects, Log;

type
  TfrmSource = class(TfrmBase)
    lblFrequencyError: TLabel;
    lblPacketInfo: TLabel;
    lblValue: TLabel;
    lblRSSI: TLabel;
    Rectangle5: TRectangle;
    lblCaption: TLabel;
    rectMain: TRectangle;
    lblLog: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure lblLogClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    frmLog: TfrmLog;
    procedure WriteToLog(Msg: String);
  end;

implementation

uses Main;

{$R *.fmx}

procedure TfrmSource.FormCreate(Sender: TObject);
begin
    inherited;
    frmLog := TfrmLog.Create(Self);
end;

procedure TfrmSource.lblLogClick(Sender: TObject);
begin
    frmMain.LoadForm(nil, frmLog);
end;

procedure TfrmSource.WriteToLog(Msg: String);
begin
    frmLog.WriteToLog(Msg);
end;

end.
