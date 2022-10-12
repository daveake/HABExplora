unit SettingsBase;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Base, FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  Miscellaneous, FMX.TMSCustomEdit, FMX.TMSEdit, FMX.Memo.Types;

type
  TfrmSettingsBase = class(TfrmBase)
    Panel1: TPanel;
    Rectangle3: TRectangle;
    Panel3: TPanel;
    Rectangle1: TRectangle;
    Memo1: TMemo;
    Panel2: TPanel;
    btnApply: TLabel;
    btnCancel: TLabel;
    tmrLoadSettings: TTimer;
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure tmrLoadSettingsTimer(Sender: TObject);
  private
    { Private declarations }
  protected
    Loading: Boolean;
    Group: String;
    procedure ApplyChanges; virtual;
    procedure CancelChanges; virtual;
    procedure SetingsHaveChanged;
  public
    { Public declarations }
    procedure LoadForm; override;
    procedure FixFloatEditBox(EditBox: TTMSFMXEdit);
  end;

implementation

{$R *.fmx}

uses Main;

procedure TfrmSettingsBase.btnApplyClick(Sender: TObject);
begin
    ApplyChanges;
end;

procedure TfrmSettingsBase.btnCancelClick(Sender: TObject);
begin
    CancelChanges;
end;

procedure TfrmSettingsBase.ApplyChanges;
begin
    SetGroupChangedFlag(Group, True);
    btnApply.Enabled := False;
    btnCancel.Enabled := False;
end;

procedure TfrmSettingsBase.CancelChanges;
begin
    btnApply.Enabled := False;
    btnCancel.Enabled := False;
end;

procedure TfrmSettingsBase.LoadForm;
begin
    Loading := True;

    inherited;

    tmrLoadSettings.Enabled := True;

    Loading := False;
end;

procedure TfrmSettingsBase.SetingsHaveChanged;
begin
    if not Loading then begin
        btnApply.Enabled := True;
        btnCancel.Enabled := True;
    end;
end;


procedure TfrmSettingsBase.tmrLoadSettingsTimer(Sender: TObject);
begin
    tmrLoadSettings.Enabled := False;

    CancelChanges;
end;

procedure TfrmSettingsBase.FixFloatEditBox(EditBox: TTMSFMXEdit);
var
    Before, After: String;
    Character: Char;
    i: Integer;
begin
    Before := EditBox.Text;
    After := '';

    for i := Low(Before) to High(Before) do begin
        Character := Before[i]; // Copy(Before, i, 1);

        if Character in [',', '.'] then begin
            After := After + '.';
        end else if Character in ['0'..'9'] then begin
            After := After + Character;
        end;
    end;

    if After <> Before then begin
        EditBox.Text := After;
    end;
end;

end.
