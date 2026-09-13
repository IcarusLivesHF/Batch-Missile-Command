rem =====================================================================
rem =====================================================================

if /i "%~1" equ "show" goto :_show
if /i "%~1" neq "fold" exit /b 0

set /a "tot_games+=1"
set /a "tot_score+=score, tot_kills+=killed, tot_fired+=fired"
set /a "tot_mirv+=mirvs, tot_fliers+=fliersKilled, tot_bombs+=bombsKilled"
set /a "_wc=wave-1, _wc-=(_wc&(_wc>>31))"
set /a "tot_stops+=mirvStops, tot_cities+=cLostAll, tot_waves+=_wc"
set "_wc="
if !bestBlast! gtr !tot_bestblast! set /a "tot_bestblast=bestBlast"

set "newAch="
call :_earn band   "!mirvStops!"   1
call :_earn triple "!bestBlast!"   3
call :_earn steady "!noMidWaves!"  1
call :_earn frugal "!fullWaves!"   1
call :_earn spotter "!fliersKilled!" 1
call :_earn cunning "!bombsKilled!"  1
call :_earn banked "!banked!"      1
call :_earn deep   "!wave!"        11
call :_earn intact "!cleanWaves!"  3
exit /b 0

:_earn
if defined ach_%~1 exit /b 0
set /a "_v=%~2, _t=%~3"
if !_v! lss !_t! exit /b 0
set "ach_%~1=1"
set "newAch=!newAch! %~1"
exit /b 0

:_show
set "achName_band=INTERCEPT      warhead killed before it could MIRV"
set "achName_triple=TRIPLE         three warheads in one blast"
set "achName_steady=STEADY HAND    a wave cleared without the centre silo"
set "achName_frugal=UNTOUCHED      a wave survived without firing"
set "achName_spotter=SPOTTER        a bomber or satellite shot down"
set "achName_cunning=OUTFOXED       a smart bomb caught despite the dodge"
set "achName_banked=RESERVE        a bonus city earned at 10,000"
set "achName_deep=DEEP            reached wave 11, multiplier pinned at 6"
set "achName_intact=UNSCATHED      three waves without losing a city"

set "out=%\e%[m%\e%[2J"
set "out=!out!%\e%[38;5;15m%\e%[8;108HSTATISTICS%\e%[m"

set /a "_r=14"
for %%L in (
	"games played        !tot_games!"
	"best score          !cfg_hiscore!"
	"best wave           !cfg_hiwave!"
	"waves cleared       !tot_waves!"
	"total score         !tot_score!"
	"warheads down       !tot_kills!"
	"ABMs fired          !tot_fired!"
	"MIRVs seen          !tot_mirv!"
	"MIRVs prevented     !tot_stops!"
	"fliers destroyed    !tot_fliers!"
	"smart bombs caught  !tot_bombs!"
	"best single blast   !tot_bestblast!"
	"cities lost         !tot_cities!"
) do (
	set "out=!out!%\e%[38;5;250m%\e%[!_r!;96H%%~L%\e%[m"
	set /a "_r+=2"
)

set /a "_r+=3"
set "out=!out!%\e%[38;5;15m%\e%[!_r!;104HACHIEVEMENTS%\e%[m"
set /a "_r+=3"
for %%A in (band triple steady frugal spotter cunning banked deep intact) do (
	set "_c=38;5;238"
	set "_m= "
	if defined ach_%%A ( set "_c=38;2;255;200;80" & set "_m=*" )
	for /f %%N in ("%%A") do set "out=!out!%\e%[!_c!m%\e%[!_r!;90H!_m! !achName_%%N!%\e%[m"
	set /a "_r+=2"
)

set /a "_r+=3"
set "out=!out!%\e%[38;5;250m%\e%[!_r!;110Hclick to go back%\e%[m"
echo=!out!

set /a "%@saveLastClicks%"
%while% (
	%@radish%
	if "!L_click!!last_L_click!" equ "10" %endwhile%
	if defined keysPressed if not "!keysPressed!" == "!keysPressed:-27-=!" %endwhile%
	set /a "%@saveLastClicks%"
	ping -n 1 -w 30 127.0.0.1 >nul
)
%@playFx:?=hover_click%
exit /b 0
