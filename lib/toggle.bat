if "%~8"=="" (set "_togN=2") else set "_togN=%~8"
set /a "_togW=%~1+_togN+1"
set "_togRun=!$q:~0,%_togN%!"

if "%~7"=="" (set /a "$toggleState_%~6=0") else set /a "$toggleState_%~6=%~7"
set /a "$toggleState_%~6-=(($toggleState_%~6>>31)&1)*$toggleState_%~6"
set /a "$toggleState_%~6-=((%_togN%-1-$toggleState_%~6)>>31&1)*$toggleState_%~6"
set /a "$toggleLastClick_%~6=0"

set "@toggleDisplay_%~6=%\e%[38;5;%~3m%\e%[%~2;%~1H"
set "@toggleDisplay_%~6=!@toggleDisplay_%~6!%\e%(0%\e%[A%\e%7l%_togRun%k%\e%8%\e%[B"
set "@toggleDisplay_%~6=!@toggleDisplay_%~6!%\e%7t%_togRun%u%\e%8%\e%[B"
set "@toggleDisplay_%~6=!@toggleDisplay_%~6!m%_togRun%j%\e%(B%\e%[m"
set "@toggleDisplay_%~6=!@toggleDisplay_%~6!%\e%[48;5;#m%\e%[%~2;?H %\e%[m"

set @clickToggle_%~6=(%\n%
	set /a "a=%~1, b=%~2-1, c=%_togW%, d=%~2+1, hov=%@hovering%",^
	       "flip=hov&L_click&(~$toggleLastClick_%~6&1)",^
	       "$toggleState_%~6+=flip&1",^
	       "$toggleState_%~6-=((%_togN%-1-$toggleState_%~6)>>31&1)*$toggleState_%~6",^
	       "$toggleLastClick_%~6=L_click",^
	       "$togglePosition_%~6=(%~1+1)+^!$toggleState_%~6^!"%\n%
	if ^^!$toggleState_%~6^^!==0 (set /a "$toggleColor_%~6=%~5") else set /a "$toggleColor_%~6=%~4"%\n%
	for /f "tokens=1,2" %%a in ("^!$togglePosition_%~6^! ^!$toggleColor_%~6^!") do (%\n%
		set "toggleDisplay_%~6=^!@toggleDisplay_%~6:?=%%~a^!"%\n%
		set "toggleDisplay_%~6=^!toggleDisplay_%~6:#=%%~b^!"%\n%
	)%\n%
)

set "_togN="
set "_togW="
set "_togRun="
