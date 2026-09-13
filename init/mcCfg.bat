rem =====================================================================
rem =====================================================================

if /i "%~1" equ "save" goto :_save

set "cfg_sfxvol=60"
set "cfg_fxflash=0"
set "cfg_startwave=1"
set "cfg_explframes=3"
set "cfg_explslots=14"
set "cfg_hiscore=0"
set "cfg_hiwave=0"
set "cfg_plays=0"

for %%t in (games score kills fired mirv stops fliers bombs cities waves bestblast) do set "tot_%%t=0"
for %%a in (band triple steady frugal spotter cunning banked deep intact) do set "ach_%%a="

if not exist "%cfgFile%" goto :_apply
for /f "usebackq eol=# tokens=1,2 delims==" %%a in ("%cfgFile%") do (
	set "_k=%%a"
	set "_v=%%b"
	if defined _v (
		if "!_k:~0,4!"=="tot_" ( set "!_k!=!_v!"
		) else if "!_k:~0,4!"=="ach_" ( set "!_k!=!_v!"
		) else set "cfg_!_k!=!_v!"
	)
)

:_apply
set "fxFlash=!cfg_fxflash!"
set "explFrames=!cfg_explframes!"
set "explSlots=!cfg_explslots!"
set "_k=" & set "_v="
exit /b 0

:_save
if defined $sliderValue_sfxvol set /a "cfg_sfxvol=$sliderValue_sfxvol"
if defined $sliderValue_wave   set /a "cfg_startwave=$sliderValue_wave"
if defined $toggleState_fxflash set /a "cfg_fxflash=$toggleState_fxflash"

>"%cfgFile%"  echo # Missile Command settings.  Delete this file to reset.
>>"%cfgFile%" echo sfxvol=!cfg_sfxvol!
>>"%cfgFile%" echo fxflash=!cfg_fxflash!
>>"%cfgFile%" echo startwave=!cfg_startwave!
>>"%cfgFile%" echo explframes=!cfg_explframes!
>>"%cfgFile%" echo explslots=!cfg_explslots!
>>"%cfgFile%" echo hiscore=!cfg_hiscore!
>>"%cfgFile%" echo hiwave=!cfg_hiwave!
>>"%cfgFile%" echo plays=!cfg_plays!

for %%t in (games score kills fired mirv stops fliers bombs cities waves bestblast) do (
	>>"%cfgFile%" echo tot_%%t=!tot_%%t!
)
for %%a in (band triple steady frugal spotter cunning banked deep intact) do (
	if defined ach_%%a >>"%cfgFile%" echo ach_%%a=1
)
exit /b 0
