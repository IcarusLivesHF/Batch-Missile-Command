for /f "tokens=4-6 delims=. " %%i in ('ver') do set "winVERSION=%%i"

if %winversion% lss 10 (
	echo=This library must be run on windows versions 10 or later.
	echo=Some features may not work as intended
	pause
)

for /f "tokens=1 delims==" %%a in ('set') do (
	set "pre=true"
	for %%b in (cd Path ComSpec SystemRoot temp windir systemDrive) do (
		if /i "%%a" equ "%%b" set "pre="
	)
	if defined pre set "%%~a="
)
set "pre="

(set \n=^^^
%= This creates an escaped Line Feed - DO NOT ALTER       \n =%
)

for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a"

for /f "skip=2 tokens=2" %%a in ('mode') do (
		   if not defined hei ( set /a "hei=height=%%a"
	) else if not defined wid   set /a "wid=width=%%a"
)
if "%~2" neq "" (
	set /a "wid=width=%~1", "hei=height=%~2 - 1"
	mode %~1,%~2
) 2>nul

set /a "$32b=(1<<31)-1"

( for /l %%i in (0,1,6) do set "$s=!$s!!$s!  " ) & set "$q=!$s: =q!"

:_while 
set "while=for /l %%i in (1 1 16)do if defined do.while"
set "while=set do.while=1&!while! !while! !while! !while! !while! "
set "endWhile=set "do.while=""

chcp 65001 >nul
echo %\e%[2J%\e%[H%\e%[?25l
exit /b