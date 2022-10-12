unit Androidapi.JNI.WiFiManager;

interface

{$IFDEF ANDROID}
uses
  Androidapi.JNIBridge, Androidapi.Jni,  androidapi.JNI.JavaTypes, androidapi.JNI.Net,
  androidapi.JNI.Os, FMX.Helpers.Android, Androidapi.JNI.GraphicsContentViewText, SysUtils,
  Androidapi.Helpers;

Type
  JWiFiManager = interface;   // android/net/wifi/WifiManager
  JMulticastLock = interface; // android/net/wifi/WifiManager$MulticastLock

  JWiFiManagerClass = interface(JObjectClass)
   ['{F69F53AE-BC63-436A-8F69-57389B30CAA8}']
    function getSystemService(Contex: JString): JWiFiManager; cdecl;
  end;

  [JavaSignature('android/net/wifi/WifiManager')]
  JWiFiManager = interface(JObject)
  ['{382E85F2-6BF8-4255-BA3C-03C696AA6450}']
    function createMulticastLock(tag: JString): JMulticastLock;
  end;

  TJWiFiManager = class(TJavaGenericImport<JWiFiManagerClass, JWiFiManager>) end;

  JMulticastLockClass = interface(JObjectClass)
  ['{C0546633-3DF2-46B0-8E2C-C14411674A6F}']
  end;

  [JavaSignature('android/net/wifi/WifiManager$MulticastLock')]
  JMulticastLock = interface(JObject)
  ['{CFA00D0C-097C-45E3-8B33-0E5A6C9FB9F1}']
    procedure acquire();
    function isHeld(): Boolean;
    procedure release();
    procedure setReferenceCounted(refCounted: boolean);
  end;

  TJMulticastLock = class(TJavaGenericImport<JMulticastLockClass, JMulticastLock>) end;

  function GetWiFiManager: JWiFiManager;

{$ENDIF}

implementation

{$IFDEF ANDROID}
function GetWiFiManager: JWiFiManager;
var
  Obj: JObject;
begin
    Obj := SharedActivityContext.getSystemService(TJContext.JavaClass.WIFI_SERVICE);
    if not Assigned(Obj) then
        raise Exception.Create('Could not locate Wifi Service');

    Result := TJWiFiManager.Wrap((Obj as ILocalObject).GetObjectID);

    if not Assigned(Result) then
        raise Exception.Create('Could not access Wifi Manager');
end;
{$ENDIF}

end.
