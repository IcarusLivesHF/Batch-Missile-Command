set @hoverButton=for %%# in (1 2) do if %%#==2 ( for /f "tokens=1-10" %%a in ("^!args^!") do (%\n%
	set /a "_lastHover_%%~g=$hovering_%%~g",^
		   "a=%%~a - 1", "b=%%~b - 1", "c=%%~a + %%~c - 1", "d=%%~b + %%~d - 2",^
	       "$hovering_%%~g=%@hovering%", "_hoverSound=$hovering_%%~g & ~_lastHover_%%~g & 1",^
		   "$clicked=$hovering_%%~g & ~%%~i_click & last_%%~i_click & 1"%\n%
	if "^!_hoverSound^!" equ "1" set "fxWant=%%~j"%\n%
	if "^!$hovering_%%~g^!" equ "0" ( %\n%
		     set "_%%~g_highlight=%%~e"%\n%
	) else ( set "_%%~g_highlight=%%~f")%\n%
	set "%%~gDisplay=%\e%[^!_%%~g_highlight^!m%\e%[%%~b;%%~aH^!%%~h^!%\e%[m"%\n%
)) else set args=

:_roundRect
set @roundrect=for %%# in (1 2) do if %%#==2 ( for /f "tokens=1-6" %%1 in ("^!args^!") do (%\n%
    if "%%~6" neq "" ( set "$roundrect=%\e%[48;5;%%~6m" ) else set "$roundrect=%\e%[48;5;15m"%\n%
    set /a "$rw=%%~3/2, $rh=%%~4/2, $r=%%~5",^
	       "$d=$r-$rw, $r=$rw+($d&($d>>31))",^
		   "$d=$r-$rh, $r=$rh+($d&($d>>31))"%\n%
    set /a "$s1=%%~1 + $r",^
	       "$t1=%%~1 + %%~3 - $r",^
		   "$s2=%%~2 + $r",^
		   "$t2=%%~2 + %%~4 - $r",^
		   "$e=$r * $r",^
		   "$s1t1=$t1 - $s1 + 1"%\n%
    set "$roundrect=^!$roundrect^!%\e%[%%~2;^!$s1^!H%\e%[^!$s1t1^!X%\e%[%%~4B%\e%[^!$s1t1^!X"%\n%
    for /l %%i in (^^!$s2^^!,1,^^!$t2^^!) do set "$roundrect=^!$roundrect^!%\e%[%%~i;%%~1H %\e%[%%~3C "%\n%
    for /l %%i in (1,1,^^!$r^^!) do (%\n%
		set /a "$i=%%i-1, dy=($e - $i*$i)/$r, $x1=$s1 - %%i,$y1=$s2 - dy,$x2=$t1 + %%i,$y2=$t2 + dy"%\n%
		set "$roundrect=^!$roundrect^!%\e%[^!$y1^!;^!$x1^!H %\e%[^!$y1^!;^!$x2^!H %\e%[^!$y2^!;^!$x1^!H %\e%[^!$y2^!;^!$x2^!H "%\n%
    )%\n%
    set "$roundrect=^!$roundrect^!%\e%[0m"%\n%
)) else set args=

set "PointRect=(((~(px-rx)>>31)&1) & ((~((rx+rw)-px+1)>>31)&1) & ((~(py-ry)>>31)&1) & ((~((ry+rh)-py+1)>>31)&1))"

set "@getlen=for %%# in (1 2) do if %%#==2 ( for /f %%1 in ("^^!args^^!") do (set "$=A^^!%%~1^^!" & set "$len=" &  ( for %%] in (4096 2048 1024 512 256 128 64 32 16) do if "^^!$:~%%]^^!" NEQ "" set /a "$len+=%%]" & set "$=^^!$:~%%]^^!" ) & set "$=^^!$:~1^^!FEDCBA9876543210" & set /a $len+=0x^!$:~15,1^! ) ) else set args="
