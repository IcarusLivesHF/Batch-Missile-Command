rem =====================================================================
rem =====================================================================

set "cmdwiz=%~dp03rdParty\cmdwiz.exe"

if not defined .gridCols set ".gridCols=400"
if not defined .gridRows set ".gridRows=100"

set ".chromeW=16"
set ".chromeH=39"
set ".taskbar=48"

set ".minCellMM10=18"

set ".fontMin=4"
set ".fontMax=40"

if /i "%~1"=="cell" goto :_measureCell
if /i "%~1"=="center" goto :_centreWindow

rem =========================================================== FONT ====
:_pickFont
call :_displayDim
call :_monitorMM

set /a "usableW=.dispW-.chromeW",^
       "usableH=.dispH-.chromeH-.taskbar",^
       "byW=(usableW*2)/.gridCols",^
       "byH=usableH/.gridRows",^
       "f=byW",^
       "f-=((byH-f)>>31&1)*(f-byH)",^
       "f-=f%%2",^
       "f-=((.fontMax-f)>>31&1)*(f-.fontMax)",^
       "f+=((f-.fontMin)>>31&1)*(.fontMin-f)"

if "%~2" neq "" set /a "f=%~2"

set "$fontSize=!f!"
set /a ".winW=(.gridCols*$fontSize)/2+.chromeW",^
       ".winH=.gridRows*$fontSize+.chromeH"

set /a ".dpi=0, .diag10=0, .cellMM10=0"
set ".fontWarn="
if !.monMM_W! gtr 0 if !.monMM_H! gtr 0 (
	set /a ".dpi=(.dispW*254)/(.monMM_W*10)",^
	       ".cellMM10=($fontSize*.monMM_H*10)/.dispH",^
	       "_n=.monMM_W*.monMM_W+.monMM_H*.monMM_H, _r=.monMM_W+.monMM_H"
	for /l %%i in (1,1,12) do set /a "_r=(_r+_n/_r)/2"
	set /a ".diag10=(_r*10)/254"
	if !.cellMM10! lss !.minCellMM10! set ".fontWarn=1"
)

set ".displayInfo=!.dispW!x!.dispH!  font !$fontSize!  window !.winW!x!.winH!"
if !.diag10! gtr 0 (
	set /a "_di=.diag10/10, _df=.diag10%%10, _ci=.cellMM10/10, _cf=.cellMM10%%10"
	set ".displayInfo=!.displayInfo!  !_di!.!_df!in  !.dpi!dpi  cell !_ci!.!_cf!mm"
)
exit /b 0

:_displayDim
set /a ".dispW=0, .dispH=0"
if not exist "%cmdwiz%" goto :_dimFallback
"%cmdwiz%" getdisplaydim w
set /a ".dispW=%errorlevel%"
"%cmdwiz%" getdisplaydim h
set /a ".dispH=%errorlevel%"
:_dimFallback
if !.dispW! lss 640 set /a ".dispW=1920, .dispH=1080"
if !.dispW! gtr 16000 set /a ".dispW=1920, .dispH=1080"
if !.dispH! lss 480 set /a ".dispW=1920, .dispH=1080"
goto :eof

:_monitorMM
set /a ".monMM_W=0, .monMM_H=0"
set "_key="
for /f "usebackq delims=" %%L in (`reg query "HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY" /s /v EDID 2^>nul`) do (
	set "_line=%%L"
	if "!_line:~0,5!"=="HKEY_" (
		set "_key=%%L"
	) else if defined _key if !.monMM_W! equ 0 (
		for /f "tokens=3" %%V in ("!_line!") do set "_edid=%%V"
		set "_dev=!_key:\Device Parameters=!"
		>nul 2>&1 reg query "!_dev!\Control" && (
			set /a "_w=0x!_edid:~42,2!, _h=0x!_edid:~44,2!" 2>nul
			if !_w! gtr 0 if !_h! gtr 0 set /a ".monMM_W=_w*10, .monMM_H=_h*10"
		)
	)
)
if !.monMM_W! equ 0 (
	for /f "usebackq tokens=1,2" %%a in (`powershell -nop -c ".m=@(Get-CimInstance -N root\wmi -Cl WmiMonitorBasicDisplayParams)[0];[string].m.MaxHorizontalImageSize+' '+[string].m.MaxVerticalImageSize" 2^>nul`) do (
		set /a ".monMM_W=%%a*10, .monMM_H=%%b*10" 2>nul
	)
)
goto :eof

:_measureCell
if defined width  set /a ".gridCols=width"
if defined height set /a ".gridRows=height+1"

mode 40,10 >nul
"%cmdwiz%" getwindowbounds w
set /a "w1=%errorlevel%"
"%cmdwiz%" getwindowbounds h
set /a "h1=%errorlevel%"

mode 100,30 >nul
"%cmdwiz%" getwindowbounds w
set /a "w2=%errorlevel%"
"%cmdwiz%" getwindowbounds h
set /a "h2=%errorlevel%"

mode !.gridCols!,!.gridRows! >nul

set /a ".cellW=(w2-w1)/60, .cellH=(h2-h1)/20"
if !.cellW! lss 1 set /a ".cellW=4, .cellH=8"
if !.cellH! lss 1 set /a ".cellW=4, .cellH=8"
set /a ".cellAspect=(.cellH*100)/.cellW"

if defined \e <nul set /p "=%\e%[2J%\e%[H%\e%[?25l"
exit /b 0

:_centreWindow
if not exist "%cmdwiz%" exit /b 1

"%cmdwiz%" getwindowbounds w
set /a "_ww=%errorlevel%"
"%cmdwiz%" getwindowbounds h
set /a "_wh=%errorlevel%"
if !_ww! lss 1 exit /b 1

call :_displayDim

set /a "_x=(.dispW-_ww)/2",^
       "_y=((.dispH-.taskbar)-_wh)/2",^
       "_x-=(_x>>31&1)*_x",^
       "_y-=(_y>>31&1)*_y"

"%cmdwiz%" setwindowpos !_x! !_y!
exit /b 0