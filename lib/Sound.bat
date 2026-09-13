rem =====================================================================
rem =====================================================================

if /i "%~1" equ "preload" goto :preload

pushd "%~dp0.."
set "gameDir=%CD%"
popd

for /d %%d in ("%temp%\mcfx_*") do rd /s /q "%%~d" 2>nul
del /f /q "%temp%\mcfx_*.stop" 2>nul

set "fxDir=%temp%\mcfx_%random%%random%"
set "fxStop=%fxDir%.stop"
md "%fxDir%" 2>nul

set "@playFx=break>"%fxDir%\?""

set "@setFxVol=>"%fxDir%\_vol" echo ^!$sliderValue_sfxvol^!"

set "@previewSfx=>"%fxDir%\preview" echo ^!$sliderValue_sfxvol^!"

set "@stopFx=(break>"%fxStop%") & rd /s /q "%fxDir%" 2>nul"

exit /b 0

:preload

start "" /B cscript //NOLOGO //B "%~dp0audio.wsf" //JOB:Sfx ^
	"%fxDir%" "!cfg_sfxvol!" "%fxStop%" ^
	"launch=!gameDir!\sfx\launch.wav" ^
	"blast=!gameDir!\sfx\blast.wav" ^
	"city=!gameDir!\sfx\city.wav" ^
	"nofire=!gameDir!\sfx\noFire.wav" ^
	"lowammo=!gameDir!\sfx\lowammo.wav" ^
	"bright_confirm=!gameDir!\sfx\bright_confirm.wav" ^
	"hover_click=!gameDir!\sfx\hover_click.wav" ^
	"preview=!gameDir!\sfx\hover_click.wav"
set "volWas=!cfg_sfxvol!"

exit /b 0