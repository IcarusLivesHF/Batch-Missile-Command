if /i "%~1" equ "set" goto :_setWave
if /i "%~1" neq "init" exit /b 0

for %%w in (
	" 1 12 1232 0"
	" 2 15  736 0"
	" 3 18  448 0"
	" 4 12  264 0"
	" 5 16  160 0"
	" 6 14   96 1"
	" 7 17   64 1"
	" 8 10   32 2"
	" 9 13   16 3"
	"10 16   10 4"
	"11 19    5 4"
	"12 12    4 5"
	"13 14    2 5"
	"14 16    1 6"
	"15 18    0 6"
	"16 14    0 7"
	"17 17    0 7"
	"18 19    0 7"
	"19 22    0 7"
) do for /f "tokens=1-4" %%a in ("%%~w") do (
	set "wvIcbm_%%a=%%b"
	set "wvDelay_%%a=%%c"
	set "wvBomb_%%a=%%d"
)

for %%w in (
	"1   0   0   0   0"
	"2 148 195 240 128"
	"3 148 195 160  96"
	"4 132 163 128  64"
	"5 132 163 128  48"
	"6 100 131  96  32"
	"7 100 131  64  32"
	"8 100 131  32  16"
) do for /f "tokens=1-5" %%a in ("%%~w") do (
	set "flHiLo_%%a=%%b"
	set "flHiHi_%%a=%%c"
	set "flCool_%%a=%%d"
	set "flFire_%%a=%%e"
)

set "flSpdBomber=3"
set "flSpdSat=2"

set "maxAbm=8"
set "maxAtk=8"
set "maxExpl=20"
set "maxBombLive=3"
set "explGroups=5"

set "bombWeight=2"

set "siloCount=3"
set "abmPerSilo=10"
set "abmSpeedSide=3"
set "abmSpeedMid=7"

set "explRadius=13"
set "explFrames=5"
set "explSlope=3"

set "aimMargin=8"

set "collFloor=33"

set "mirvLo=128"
set "mirvHi=159"
set "mirvCeil=160"
set "mirvSpawn=3"

set "cityStart=6"
set "cityMaxLoss=3"
set "bonusEvery=10000"

set "ptIcbm=25"
set "ptSat=100"
set "ptBomber=100"
set "ptBomb=125"
set "ptAbmLeft=5"
set "ptCityLeft=100"

set "waveWrap=40"
set "waveWrapTo=20"
set "waveTableMax=19"

exit /b 0

:_setWave

set /a "_w=%~2"
if not defined _w set /a "_w=1"

set /a "_wi=_w-((_w-%waveTableMax%)&((%waveTableMax%-_w)>>31))",^
       "_wf=_w-((_w-8)&((8-_w)>>31))",^
       "_wi+=((_wi-1)>>31&1)*(1-_wi), _wf+=((_wf-1)>>31&1)*(1-_wf)"

for %%v in (!_wi!) do set /a "wIcbm=wvIcbm_%%v, wDelay=wvDelay_%%v, wBomb=wvBomb_%%v"
for %%v in (!_wf!) do set /a "wFlLo=flHiLo_%%v, wFlHi=flHiHi_%%v, wFlCool=flCool_%%v, wFlFire=flFire_%%v"

set /a "wFliers=1-(((_w-2)>>31)&1)"

set /a "wMult=(_w+1)/2, wMult-=((wMult-6)&((6-wMult)>>31))"

set /a "wGate=202-2*_w, wGate-=((wGate-180)&((wGate-180)>>31))"

set "_w=" & set "_wi=" & set "_wf="

if "%wIcbm%"=="0" (
	echo=waveTable: lookup returned 0 -- was  call init\waveTable init  run first?
	exit /b 1
)
exit /b 0
