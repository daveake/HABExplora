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
{$IFDEF MSWINDOWS}
    Windows,
{$ENDIF}
  Base, FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, Math;

type
  TfrmSplash = class(TfrmBase)
    Image1: TImage;
    rectLoading: TRectangle;
    Label1: TLabel;
    lblVersion: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure Image1Resized(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure UnveilSplash;
  end;

var
  frmSplash: TfrmSplash;

implementation

{$R *.fmx}

uses Main, Misc, Debug;

procedure TfrmSplash.FormCreate(Sender: TObject);
var
    Bits: Integer;
{$IFDEF ANDROID}
    PackageManager: JPackageManager;
    PackageInfo: JPackageInfo;
{$ENDIF}
{$IFDEF MSWINDOWS}
    verblock:PVSFIXEDFILEINFO;
    versionMS,versionLS:cardinal;
    verlen:cardinal;
    rs:TResourceStream;
    m:TMemoryStream;
    p:pointer;
    s:cardinal;
{$ENDIF}
begin
    ApplicationName := 'HAB Explora';
    ApplicationVersion := '';
    Bits := SizeOf(Pointer) * 8;

{$IFDEF ANDROID}
    try
        PackageManager := TAndroidHelper.Context.getPackageManager; //SharedActivityContext.getPackageManager;
        PackageInfo := PackageManager.getPackageInfo(TAndroidHelper.Context.getPackageName, 0);  //SharedActivityContext.getPackageName, 0);
        ApplicationVersion := JStringToString(PackageInfo.versionName);
    except
    end;
{$ENDIF}
{$IFDEF MSWINDOWS}
    m:=TMemoryStream.Create;
    try
        rs:=TResourceStream.CreateFromID(HInstance,1,RT_VERSION);
        try
            m.CopyFrom(rs,rs.Size);
        finally
            rs.Free;
        end;

        m.Position:=0;

        if VerQueryValue(m.Memory,'\',pointer(verblock),verlen) then begin
            VersionMS:=verblock.dwFileVersionMS;
            VersionLS:=verblock.dwFileVersionLS;
            ApplicationVersion := 'V' +
                                  IntToStr(versionMS shr 16)+'.'+
                                  IntToStr(versionMS and $FFFF)+'.'+
                                  IntToStr(VersionLS shr 16)+'.'+
                                  IntToStr(VersionLS and $FFFF);
        end;

        if VerQueryValue(m.Memory,PChar('\\StringFileInfo\\'+
          IntToHex(GetThreadLocale,4)+IntToHex(GetACP,4)+'\\FileDescription'),p,s) or
            VerQueryValue(m.Memory,'\\StringFileInfo\\040904E4\\FileDescription',p,s) then begin
            ApplicationName := pChar(p);
        end else begin
            ApplicationName := Application.Title;
        end;

   finally
        m.Free;
    end;
{$ENDIF}

    lblVersion.Text := ApplicationName + ' ' + ApplicationVersion + ' ' + IntToStr(Bits) + ' bits';
end;

procedure TfrmSplash.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
    if frmDebug <> nil then begin
        frmMain.LoadForm(nil, frmDebug);
    end;
end;


procedure TfrmSplash.Image1Resized(Sender: TObject);
var
    UsedHeight, BlockHeight: Double;
begin
    UsedHeight := Min(Image1.Height, Image1.Width * Image1.Bitmap.Height / Image1.Bitmap.Width);

    BlockHeight := Image1.Height / 2 - UsedHeight * 0.34;

    rectLoading.Height := BlockHeight;

    // lblVersion.Height := BlockHeight;
end;

procedure TfrmSplash.UnveilSplash;
begin
    rectLoading.Visible := False;
end;

end.
