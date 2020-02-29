program HABExplora;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {frmMain},
  Base in 'Base.pas' {frmBase},
  Splash in 'Splash.pas' {frmSplash},
  Map in 'Map.pas' {frmMap},
  Direction in 'Direction.pas',
  TargetForm in 'TargetForm.pas' {frmTarget},
  Payloads in 'Payloads.pas' {frmPayloads},
  Settings in 'Settings.pas' {frmSettings},
  SettingsBase in 'SettingsBase.pas' {frmSettingsBase},
  GPSSettings in 'GPSSettings.pas' {frmGPSSettings},
  LoRaBluetoothSettings in 'LoRaBluetoothSettings.pas' {frmBluetoothSettings},
  OtherSettings in 'OtherSettings.pas' {frmOtherSettings},
  Uplink in 'Uplink.pas' {frmUplink},
  SourcesForm in 'SourcesForm.pas' {frmSources},
  Debug in 'Debug.pas' {frmDebug},
  BluetoothSource in '..\HABRx\BluetoothSource.pas',
  Androidapi.JNI.WiFiManager in '..\HABRx\Androidapi.JNI.WiFiManager.pas',
  CarUpload in '..\HABRx\CarUpload.pas',
  GatewaySource in '..\HABRx\GatewaySource.pas',
  GPSSource in '..\HABRx\GPSSource.pas',
  Habitat in '..\HABRx\Habitat.pas',
  HabitatSource in '..\HABRx\HabitatSource.pas',
  HABTypes in '..\HABRx\HABTypes.pas',
  Miscellaneous in '..\HABRx\Miscellaneous.pas',
  SerialSource in '..\HABRx\SerialSource.pas',
  Source in '..\HABRx\Source.pas',
  UDPSource in '..\HABRx\UDPSource.pas',
  LoRaSerialSettings in 'LoRaSerialSettings.pas' {frmLoRaSerialSettings},
  Androidapi.JNI.Interfaces.JGeomagneticField in '..\HABRx\Androidapi.JNI.Interfaces.JGeomagneticField.pas',
  BLESource in '..\HABRx\BLESource.pas',
  SocketSource in '..\HABRx\SocketSource.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait];
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.


