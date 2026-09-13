rem =====================================================================
rem =====================================================================

if /i "%~1" equ "set"   goto :_setWave
if /i "%~1" equ "probe" goto :_probe
if /i "%~1" neq "init"  exit /b 0

for %%c in (
	"blk 0 0 0"
	"red 255 0 0"
	"grn 0 255 0"
	"yel 255 255 0"
	"blu 0 0 255"
	"mag 255 0 255"
	"cyn 0 255 255"
	"wht 255 255 255"
) do for /f "tokens=1-4" %%a in ("%%~c") do (
	set "rgb_%%a=%%b;%%c;%%d"
	set "fg_%%a=38;2;%%b;%%c;%%d"
	set "bg_%%a=48;2;%%b;%%c;%%d"
)

set "flashSeq=blk red grn yel blu mag cyn wht"
set "flashLen=8"
set /a "_i=0"
for %%c in (%flashSeq%) do ( set "flashCol_!_i!=%%c" & set /a "_i+=1" )
set "_i="

set "flashIdx=200"
set "flashOn=48;5;%flashIdx%"

set "flashDiv=2"

for %%s in (
	"0 blk yel red blk_cyn blu blu"
	"1 blk yel grn blk_cyn blu blu"
	"2 blk blu red yel     grn grn"
	"3 blk red yel yel     blu blu"
	"4 blu yel red mag     blk blk"
	"5 cyn yel red blk     blu blu"
	"6 mag grn blk blk     yel yel"
	"7 yel grn blk wht     red red"
	"8 wht red mag yel     grn grn"
	"9 red yel blk grn     blu blu"
) do for /f "tokens=1-7" %%a in ("%%~s") do (
	set "palBk_%%a=%%b"
	set "palCityBk_%%a=%%c"
	set "palIcbm_%%a=%%d"
	set "palCity1_%%a=%%e"
	set "palAbm_%%a=%%f"
	set "palCity2_%%a=%%g"
)
for %%s in (0 1) do set "palCity1_%%s=cyn"

set "palSets=10"
exit /b 0

rem =====================================================================
:_setWave

set /a "_p=((%~2-1)/2)%%%palSets%"

for %%p in (!_p!) do (
	for %%n in (Bk CityBk Icbm City1 Abm City2) do (
		for /f %%v in ("!pal%%n_%%p!") do (
			set "c%%n=!bg_%%v!"
			set "f%%n=!fg_%%v!"
		)
	)
)
set "_p="
exit /b 0

rem =====================================================================
:_probe

cls
echo=
echo=  Colour test.  The LEFT block should be flashing through eight
echo=  colours.  The RIGHT block should be sitting still and grey.
echo=
echo=

set "_row=6"
for /l %%i in (1,1,40) do (
	set /a "_c=%%i%%%flashLen%"
	for %%c in (!_c!) do for /f %%v in ("!flashCol_%%c!") do (
		<nul set /p "=%\e%]4;%flashIdx%;rgb:!rgb_%%v!%\e%\"
	)
	<nul set /p "=%\e%[!_row!;6H%\e%[%flashOn%m          %\e%[m    %\e%[48;5;244m          %\e%[m"
	for /l %%a in (1,1,60000) do rem
)

echo=
echo=
set /p "_a=  Was the left block changing colour?  (y/n)  "
if /i "!_a:~0,1!"=="y" ( set "osc4=1" ) else ( set "osc4=0" )
set "_a=" & set "_row=" & set "_c="

echo=
if "!osc4!"=="1" (
	echo=  OSC 4 works.  Explosions can flash the way the arcade did.
) else (
	echo=  No OSC 4.  Explosions will use a fixed radial gradient and only
	echo=  the outermost ring will cycle.  Heads still flash normally.
)
echo=
pause
exit /b 0
