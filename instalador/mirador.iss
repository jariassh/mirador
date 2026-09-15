; ---------------------------------------------------------------------------
;  Mirador — guion del instalador para Inno Setup 6
;
;  Produce "MiradorSetup.exe": un instalador de Windows normal, del que la
;  gente ya sabe qué esperar. Reemplaza al `powershell -ExecutionPolicy Bypass
;  -File .\instalar.ps1` de la instalación manual, que es la barrera real para
;  quien no es técnico.
;
;  Decisiones, para no volver a discutirlas:
;
;  - PrivilegesRequired=lowest y carpeta en {localappdata}. Mirador NO necesita
;    administrador, y pedirlo sin necesidad asusta y además es peor práctica.
;    Es la misma carpeta que usa instalar.ps1, así que las dos vías conviven.
;
;  - El acceso directo lanza PowerShell con -WindowStyle Hidden. Mirador no usa
;    consola: todo lo que pregunta lo pregunta en ventanas de Windows.
;
;  - NO se empaqueta scrcpy. Mirador lo instala solo la primera vez, desde su
;    fuente oficial, y de ahí sale también adb. Meterlo acá nos obligaría a
;    redistribuirlo y a mantenerlo actualizado a mano.
;
;  - Sin firma, Windows va a mostrar el aviso de SmartScreen. Es el diálogo
;    que cualquiera reconoce del software independiente y deja continuar; un
;    certificado cuesta ~$200 al año y para una herramienta gratuita no tiene
;    sentido. La vía a cero advertencias sin pagar es publicar en la Microsoft
;    Store, que firma gratis.
;
;  Para compilar:  iscc instalador\mirador.iss
; ---------------------------------------------------------------------------

#define Nombre     "Mirador"
#define Version    "1.1.0"
#define Autor      "Jonathan Arias"
#define Sitio      "https://github.com/jariassh/mirador"

[Setup]
AppId={{B7F2A4E1-9C3D-4A56-8E1F-2D6C5B3A9E70}
AppName={#Nombre}
AppVersion={#Version}
AppVerName={#Nombre} {#Version}
AppPublisher={#Autor}
AppPublisherURL={#Sitio}
AppSupportURL={#Sitio}/issues
AppUpdatesURL={#Sitio}/releases
DefaultDirName={localappdata}\Mirador
DefaultGroupName=Mirador
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=MiradorSetup
SetupIconFile=..\recursos\mirador.ico
UninstallDisplayIcon={app}\mirador.ico
UninstallDisplayName={#Nombre}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
LicenseFile=..\LICENSE
ArchitecturesAllowed=x64compatible
MinVersion=10.0

[Languages]
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "escritorio"; Description: "Crear un acceso directo en el Escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "..\mirador.ps1";           DestDir: "{app}"; Flags: ignoreversion
Source: "..\recursos\mirador.ico";  DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE";               DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md";             DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Mirador"; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\mirador.ps1"""; \
    WorkingDir: "{app}"; IconFilename: "{app}\mirador.ico"; \
    Comment: "Abre la pantalla de tu celular en el computador"

Name: "{userdesktop}\Mirador"; Tasks: escritorio; \
    Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\mirador.ps1"""; \
    WorkingDir: "{app}"; IconFilename: "{app}\mirador.ico"; \
    Comment: "Abre la pantalla de tu celular en el computador"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; \
    Parameters: "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""{app}\mirador.ps1"""; \
    Description: "Abrir Mirador ahora"; \
    Flags: nowait postinstall skipifsilent

[UninstallDelete]
; El registro y los teléfonos recordados viven en la misma carpeta. Se borran
; al desinstalar; scrcpy y adb NO se tocan, porque el usuario pudo instalarlos
; por su cuenta y los puede estar usando para otra cosa.
Type: files;      Name: "{app}\mirador.log"
Type: files;      Name: "{app}\dispositivos.json"
Type: dirifempty; Name: "{app}"
