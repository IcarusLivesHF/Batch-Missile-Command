set "radish=lib\3rdparty\radish"

set "equ=(~(((Rmeta-x)>>31)|((x-Rmeta)>>31)))&1"
set @radish=(%\n%
	for /f "tokens=1-4 delims=." %%1 in ("^!CMDCMDLINE^!") do (%\n%
		set /a "mouseX=%%~1", "mouseY=%%~2", "Rmeta=%%~3", "L_click=%equ:x=1%", "R_click=%equ:x=2%", "B_click=%equ:x=3%", "scrollUp=%equ:x=6%", "scrollDown=%equ:x=-6%"%\n%
		set "keysPressed=%%~4"%\n%
	)%\n%
)
set "equ="

set "endRadish=(taskkill /f /im "radish.exe")>nul"

call lib\mouseAndKeys