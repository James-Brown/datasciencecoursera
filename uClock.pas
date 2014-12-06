unit uClock;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, _GClass, AbClock, Buttons, AbLED, ExtCtrls, SDL_NumLab,
  AbNumEdit, AbSwitch, AbGradient, Registry, Menus, uSETITypes, ComCtrls;

const

  cr = #13;
  lf = #12;

type
  TCallBackProcedureName = procedure;

type
  TfrmClock = class(TForm)
    grpYearDay: TGroupBox;
    abclockLocalTime: TAbClock;
    lblDayOfMonth: TLabel;
    lblMonth: TLabel;
    lblYear: TLabel;
    lblDayLight: TLabel;
    grpGreenWich: TGroupBox;
    numlabJulian: TNumLab;
    lblGSTOut: TLabel;
    lbl2: TLabel;
    pnlGST: TPanel;
    lblGST: TLabel;
    pnlUTC: TPanel;
    lblUTC: TLabel;
    pnlStartClock: TPanel;
    ledRunning: TAbLED;
    grpStarFinder: TGroupBox;
    gradientStarFinder: TAbGradient;
    nlStarDEC: TNumLab;
    nlStarRa: TNumLab;
    nsStarDEC: TAbNumSpin;
    nsStarRA: TAbNumSpin;
    pnlAzEl: TPanel;
    Label6: TLabel;
    Label7: TLabel;
    nsStarAz: TAbNumSpin;
    gbObserver: TGroupBox;
    gradientObserver: TAbGradient;
    lblLongitude: TLabel;
    lblLSToutside: TLabel;
    lblLatitude: TLabel;
    Panel3: TPanel;
    lblLST: TLabel;
    nsLongitude: TAbNumSpin;
    nsLatitude: TAbNumSpin;
    btnMount: TBitBtn;
    MainMenu1: TMainMenu;
    mnuExit: TMenuItem;
    mnuConfig: TMenuItem;
    mnuMount: TMenuItem;
    mnuSkyMap: TMenuItem;
    N1: TMenuItem;
    mnuHelp: TMenuItem;
    HelpUsing1: TMenuItem;
    mnuAbout: TMenuItem;
    mnuHints: TMenuItem;
    Timer: TTimer;
    AbGradient1: TAbGradient;
    sbStatus: TStatusBar;
    btnSkyMap: TBitBtn;
    btnStart: TSpeedButton;
    nsStarEl: TAbNumSpin;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure nsLongitudeChange(Sender: TObject);
    procedure nsDECChange(Sender: TObject);
    procedure nsRAChange(Sender: TObject);
    procedure mnuHintsClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure nsLatitudeValueChanged(Sender: TObject);
    procedure nsLongitudeValueChanged(Sender: TObject);
    procedure HelpUsing1Click(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure btnMountClick(Sender: TObject);
    procedure btnSkyMapClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);

    procedure nsStarRAChange(Sender: TObject);
    procedure nsStarDECChange(Sender: TObject);
    procedure nsStarElValueChanged(Sender: TObject);
    procedure nsStarAzValueChanged(Sender: TObject);
    procedure mnuAboutClick(Sender: TObject);

  private
    { Private declarations }

    FStartStop: TStartStop;
    FStarAz, FStarEl: TDegrees; // Current Star Az and El
    FStarDEC: TDegrees;
    FStarRa: THours;

    Hints: Boolean;
    SETINetReg: TRegistry;

    FISOLocalTime: string;

    procedure setStarRa(value: THours);
    procedure setStarDEC(value: THours);
    procedure setStarAz(value: TDegrees);
    procedure setStarEl(value: TDegrees);

    procedure DisplayHint(Sender: TObject);
    property StarRa: THours read FStarRa write setStarRa;
    property StarDEC: TDegrees read FStarDEC write setStarDEC;
    property StarAz: TDegrees read FStarAz write setStarAz;
    property StarEl: TDegrees read FStarEl write setStarEl;
  public
    { Public declarations }
  end;

var
  frmClock: TfrmClock;
  CallBackProcedureName: TCallBackProcedureName;

implementation

uses uTime, uAbout, uMount, uSkyMap;
{$R *.dfm}

procedure frmAntennaParametersHasChanged;
(* Something in the Antenna Parameters has changed so reload all *)
begin

end;

(* C R E A T E *)
procedure TfrmClock.FormCreate(Sender: TObject);
var
  TimeSet: Ttimeset;
  strMonth: string;
begin

  (* REGISTRY ENTRIES *)
  SETINetReg := TRegistry.Create;
  SETINetReg.LazyWrite := False;
  try
    SETINetReg.RootKey := HKEY_CURRENT_User;
    if SETINetReg.KeyExists(SETINetClockKey) then
    begin // Key Exists
      if SETINetReg.OpenKey(SETINetClockKey, False) then
      // This one will NOT create the key
      begin // open key
        try
          with SETINetReg do
          begin
            SETINetReg.OpenKey(SETINetClockKey, False);

            Hints := ReadBool('Hints');
            StarDEC := ReadFloat('StarDEC');
            StarRa := ReadFloat('StarRa');
            StarAz := ReadFloat('StarAz');
            StarEl := ReadFloat('StarEl');
          end // with SETINetReg
        except // an exception is raised There is a problem
          SETINetReg.DeleteKey(SETINetClockKey); // If one of the entries (non-string) didn't exist delete the whole key
        end; // Open Key
      end; // key exists
    end; // SETINetClockKey exists
    if not SETINetReg.KeyExists(SETINetClockKey) then // D E F A U L T   R E G   E N T R I E S for error or New User
    begin
      with SETINetReg do
      begin
        OpenKey(SETINetClockKey, True);
        // OpenKey will create the key if the second parameter is true and the key does not already exist

        Hints := True;
        StarDEC := 0;
        StarRa := 12;
        StarAz := 90;
        StarEl := 45;
      end;
    end; // Key Exists
  finally
    SETINetReg.Free;
  end; // Finished with Reg

  TimeSet := GetLocalDateTime;
  with TimeSet do
  begin
    lblDayOfMonth.Caption := IntToStr(dy);
    case mo of
      1:
        strMonth := 'January';
      2:
        strMonth := 'Feburary';
      3:
        strMonth := 'March';
      4:
        strMonth := 'April';
      5:
        strMonth := 'May';
      6:
        strMonth := 'June';
      7:
        strMonth := 'July';
      8:
        strMonth := 'August';
      9:
        strMonth := 'September';
      10:
        strMonth := 'October';
      11:
        strMonth := 'November';
      12:
        strMonth := 'December';
    end; // case
    lblMonth.Caption := strMonth;
    lblYear.Caption := IntToStr(yr);
  end; // with TimeSet
  if DayLightSavingsInEffect then
    lblDayLight.Caption := 'Daylight Savings Time'
  else
    lblDayLight.Caption := 'Standard Time';
  // Set up StarFinder
  numlabJulian.value := GetCurrentJulian; // Get Julian time

  mnuHints.Checked := True;
  pnlAzEl.Enabled := True;

  // Assign the application’s OnHint event handler at runtime because the Application is not available in the Object Inspector at design time
  Application.OnHint := DisplayHint;

  begin // Start first time
    btnStart.Down := True;
    Timer.Enabled := True;
    btnStart.Caption := 'Stop';
    ledRunning.Checked := True;
    ledRunning.LED.ColorOff := clYellow;
  end;

end; { FormCreate }

(* G e t t e r s   and   S e t t e r s *)

procedure TfrmClock.setStarAz(value: TDegrees);
begin
  FStarAz := value;
  If Assigned(frmSkyMap) then
    frmSkyMap.StarAz := FStarAz;
  nsStarAz.value := FStarAz;
end;

procedure TfrmClock.setStarEl(value: TDegrees);
begin
  FStarEl := value;
  If Assigned(frmSkyMap) then
    frmSkyMap.StarEl := FStarEl;
  nsStarEl.value := FStarEl;
end;

procedure TfrmClock.setStarDEC(value: TDegrees);
begin
  FStarDEC := value;
  If Assigned(frmSkyMap) then
    frmSkyMap.StarDEC := FStarDEC;
  nsStarDEC.value := FStarDEC;
  nlStarDEC.value := nsStarDEC.value;
end;

procedure TfrmClock.setStarRa(value: THours);
begin
  FStarRa := value;
  If Assigned(frmSkyMap) then
    frmSkyMap.StarRa := FStarRa;
  nsStarRA.value := FStarRa;
  nlStarRa.value := nsStarRA.value;
end;

procedure TfrmClock.mnuAboutClick(Sender: TObject);
begin
  frmClock.Caption := frmClock.Caption + ' vers: ' + frmAbout.ShowVersion;
end;

procedure TfrmClock.btnMountClick(Sender: TObject);
begin
  If frmMount.Visible = False then
  begin
    frmMount.Visible := True;
    frmMount.BringToFront;
  end
  else
    frmMount.Visible := False;
  nsLatitude.value := frmMount.Latitude;
  nsLongitude.value := frmMount.Longitude;
end;

procedure TfrmClock.DisplayHint(Sender: TObject);
begin
  sbStatus.Panels[2].Text := GetLongHint(Application.Hint);
end;

procedure TfrmClock.nsLongitudeChange(Sender: TObject);
begin
  frmMount.Longitude := nsLongitude.value;
end;

procedure TfrmClock.nsDECChange(Sender: TObject);
begin
  nlStarDEC.value := nsStarDEC.value;
  frmSkyMap.StarDEC := nsStarDEC.value;
end;

procedure TfrmClock.nsRAChange(Sender: TObject);
begin
  nlStarRa.value := nsStarRA.value;
  frmSkyMap.StarRa := nsStarRA.value;
end;

procedure TfrmClock.btnSkyMapClick(Sender: TObject);
begin
  frmSkyMap.StarAz := StarAz;
  frmSkyMap.StarEl := StarEl;
  frmSkyMap.StarDEC := StarDEC;
  frmSkyMap.StarRa := StarRa;
  If frmSkyMap.Visible = False then
  begin
    frmSkyMap.Visible := True;
    frmSkyMap.BringToFront;
  end
  else
    frmSkyMap.Visible := False;
end;

procedure TfrmClock.btnStartClick(Sender: TObject);
begin
  if btnStart.Down then

  begin // Start the clock
    Timer.Enabled := True;
    btnStart.Caption := 'Stop';
    ledRunning.Checked := True;
    ledRunning.LED.ColorOff := clYellow;
  end
  else
  begin // Stop the clock
    Timer.Enabled := False;
    btnStart.Caption := 'Start';
    ledRunning.Checked := False;
    ledRunning.LED.ColorOff := clSilver;
  end;
end;

procedure TfrmClock.mnuHintsClick(Sender: TObject);
begin
  if mnuHints.Checked then
  begin

    sbStatus.Panels[1].Text := 'Hints are on...';

    btnSkyMap.ShowHint := mnuHints.Checked;

    frmClock.ShowHint := mnuHints.Checked;
    Application.ShowHint := mnuHints.Checked;
    btnMount.ShowHint := mnuHints.Checked;
    btnSkyMap.ShowHint := mnuHints.Checked;
    grpStarFinder.ShowHint := mnuHints.Checked;
    gbObserver.ShowHint := mnuHints.Checked;
    grpYearDay.ShowHint := mnuHints.Checked;
    grpGreenWich.ShowHint := mnuHints.Checked;
    sbStatus.Visible := mnuHints.Checked;
  end
  else
  begin
    sbStatus.Panels[1].Text := 'Hints are off...';
  end;
end;

procedure TfrmClock.TimerTimer(Sender: TObject);
(* ===================================================================  T I M E R   T I C K ================================= *)
var
  TimeSet: Ttimeset;
  strYr, strMo, strDa, strHr, strMin, strSec: string;
  inscopeStarRA: THours;
  inscopeStarDEC: TDegrees;
  inscopeAz, inscopeEL: TDegrees; // Need to be able to pass as parameters.

begin
  Timer.Enabled := False; // while we process a tick
  lblUTC.Caption := HrsToSex(GetCurrentUTC); // Get UTC time
  lblGST.Caption := HrsToSex(GetGSiderealTime); // Get Greenwitch mean sidereal time (GST)
  lblLST.Caption := HrsToSex(GetLSiderealTime(frmMount.Longitude));
  // Get Local  Sidereal Time (LST)
  numlabJulian.value := GetCurrentJulian; // Get Julian time

  frmSkyMap.DrawSearchArea;
  TimeSet := GetLocalDateTime;
  strYr := FloatToStr(TimeSet.yr);

  strMo := FloatToStr(TimeSet.mo);
  if (length(strMo) < 2) then
    strMo := '0' + strMo;

  strDa := FloatToStr(TimeSet.dy);
  if (length(strDa) < 2) then
    strDa := '0' + strDa;

  strHr := FloatToStr(TimeSet.hr);
  if (length(strHr) < 2) then
    strHr := '0' + strHr;

  strMin := FloatToStr(TimeSet.mi);
  if (length(strMin) < 2) then
    strMin := '0' + strMin;

  strSec := FloatToStr(TimeSet.se);
  if (TimeSet.se < 10) then
    strSec := '0' + strSec;

  FISOLocalTime := strYr + '-' + strMo + '-' + strDa + 'T' + strHr + ':' + strMin + ':' + strSec + '.' + FloatToStr(TimeSet.hu);
  // UpdateSkyMap(Self);
  nsLongitude.value := frmMount.Longitude;
  nsLatitude.value := frmMount.Latitude;
  if frmSkyMap.NewStarAvailable then
  begin
    StarAz := frmSkyMap.StarAz;
    StarEl := frmSkyMap.StarEl;
    StarDEC := frmSkyMap.StarDEC;
    StarRa := frmSkyMap.StarRa;
  end;
  frmSkyMap.DrawSearchArea;
  Timer.Enabled := True; // back running
end;

{ TimerTick }

procedure TfrmClock.nsStarDECChange(Sender: TObject);
begin
  frmSkyMap.StarDEC := nsStarDEC.value;
end;

procedure TfrmClock.nsStarElValueChanged(Sender: TObject);
var
  newStarRa: THours;
  newStarDEC: TDegrees;
begin
  if Assigned(frmSkyMap) then
  begin
    newStarRa := frmSkyMap.StarRa;
    newStarDEC := frmSkyMap.StarDEC;
    // procedure AzElToRADec(Azdeg, Eldeg, ObsLat, ObsLon: TDegrees; var RAStarHrs, StarDeclinationdeg: TDegrees); {&26}
    AzElToRaDEC(frmSkyMap.StarAz, nsStarEl.value, frmMount.Latitude, frmMount.Longitude, newStarRa, newStarDEC);
    frmSkyMap.StarDEC := newStarDEC;
    frmSkyMap.StarRa := newStarRa;
  end;
end;

procedure TfrmClock.nsStarRAChange(Sender: TObject);
begin
  frmSkyMap.StarRa := nsStarRA.value;
end;

procedure TfrmClock.nsStarAzValueChanged(Sender: TObject);
var
  newStarRa: THours;
  newStarDEC: TDegrees;
begin
  if Assigned(frmSkyMap) then
  begin
    newStarRa := frmSkyMap.StarRa;
    newStarDEC := frmSkyMap.StarDEC;
    // procedure AzElToRADec(Azdeg, Eldeg, ObsLat, ObsLon: TDegrees; var RAStarHrs, StarDeclinationdeg: TDegrees); {&26}
    AzElToRaDEC(nsStarAz.value, frmSkyMap.StarEl, frmMount.Latitude, frmMount.Longitude, newStarRa, newStarDEC);
    frmSkyMap.StarDEC := newStarDEC;
    frmSkyMap.StarRa := newStarRa;
  end;
end;

procedure TfrmClock.nsLatitudeValueChanged(Sender: TObject);
begin
  frmMount.Latitude := nsLatitude.value;
end;

procedure TfrmClock.nsLongitudeValueChanged(Sender: TObject);
begin
  frmMount.Longitude := nsLongitude.value;
end;

procedure TfrmClock.HelpUsing1Click(Sender: TObject);
begin
  ShowMessage('http://www.seti.net/html/SETINet/Engineering/Clock/clock.htm for online help.' + cr + lf +
    ' For your Lat/Lon check www.arrl.org/locate/locate.html ');
end;

procedure TfrmClock.mnuExitClick(Sender: TObject);
begin
  close;
end;

procedure TfrmClock.FormClose(Sender: TObject; var Action: TCloseAction);
(* C l o s e   F o r m *)
begin
  Timer.Enabled := False;
  // frmSkyMap.close;
  frmMount.close;
  SETINetReg := TRegistry.Create;
  try
    with SETINetReg do
    begin
      RootKey := HKEY_CURRENT_User;
      DeleteKey(SETINetClockKey); // Kill the whole key every time.
      OpenKey(SETINetClockKey, True); // OpenKey will create the key

      WriteBool('Hints', Hints);
      WriteFloat('StarAz', StarAz);
      WriteFloat('StarEl', StarEl);
      WriteFloat('StarDEC', StarDEC);
      WriteFloat('StarRA', StarRa);
      CloseKey;
    end; // SETINetReg
  finally
    SETINetReg.Free;
  end; // try..finally
end;

end.
