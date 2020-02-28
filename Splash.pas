unit Splash;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
{$IFDEF ANDROID}
  FMX.Helpers.Android, FMX.Platform.Android,
  Androidapi.JNI.JavaTypes, Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText,
{$ENDIF}
  Base, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox;

type
  TfrmSplash = class(TfrmBase)
    Image1: TImage;
    lblVersion: TLabel;
    rectLoading: TRectangle;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure LoadForm; override;
  end;

var
  frmSplash: TfrmSplash;

implementation

{$R *.fmx}

uses Main, Debug;

procedure TfrmSplash.FormCreate(Sender: TObject);
{$IFDEF ANDROID}
var
    PackageManager: JPackageManager;
    PackageInfo: JPackageInfo;
{$ENDIF}
begin
{$IFDEF ANDROID}
    try
        PackageManager := TAndroidHelper.Context.getPackageManager; //SharedActivityContext.getPackageManager;
        PackageInfo := PackageManager.getPackageInfo(TAndroidHelper.Context.getPackageName, 0);  //SharedActivityContext.getPackageName, 0);
        lblVersion.Text := JStringToString(PackageInfo.versionName);
    except
    end;
{$ENDIF}
end;

procedure TfrmSplash.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
    if frmDebug <> nil then begin
        frmMain.LoadForm(nil, frmDebug);
    end;
end;

procedure TfrmSplash.LoadForm;
begin
    inherited;

    rectLoading.Height := 160 * frmMain.pnlCentre.Height / 848;
end;



end.
