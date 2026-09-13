set        "@onClick="^^!?_click^^!.^^!last_?_click^^!" equ "1.0""
set "@onClickRelease="^^!?_click^^!.^^!last_?_click^^!" equ "0.1""
set   "@holdingClick="^^!?_click^^!.^^!last_?_click^^!" equ "1.1""

set "@saveLastClicks=last_l_click=l_click, last_r_click=r_click, last_b_click=b_click"

set "@ifClickingPoint=(_t=(mouseX^x)|(mouseY^y)|(L_click^1), (~(_t|-_t)>>31)&1)"

set "@hovering=((~(mouseY-b)>>31)&1) & ((~(d-mouseY)>>31)&1) & ((~(mouseX-a)>>31)&1) & ((~(c-mouseX)>>31)&1)"

set "@clickingInsideBox=$clickingInsideBox=^!@hovering^! & ?_click"

set "@asyncKeys=if NOT "^^!keysPressed^^!" == "^^!keysPressed:-?-=^^!""

set @clickAndDrag=for %%# in (1 2) do if %%#==2 (for /f "tokens=1-5" %%1 in ("^!args^!") do (%\n%
	set /a "$clickingInsideBox=((~((mouseX - %%~1 + 1) | (%%~1 + %%~3 - mouseX - 1) | (mouseY - %%~2 + 1) | (%%~2 + %%~4 - mouseY - 2)) >> 31) & 1) & %%~5_click"%\n%
	if ^^!$clickingInsideBox^^! equ 1 ( %\n%
		if defined dragging ( set /a "%%~1=mouseX - offsetX, %%~2=mouseY - offsetY"%\n%
		)        else       ( set /a "offsetX=mouseX - %%~1, offsetY=mouseY - %%~2, dragging=1" )%\n%
	) else set "dragging="%\n%
)) else set args=