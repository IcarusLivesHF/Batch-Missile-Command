chcp 65001>nul
set /a "_sliderX=%~1",^
       "_sliderxmi=%~1",^
       "_sliderY=%~2",^
       "_sliderxma=%~1+%~3-1",^
       "_sliderymi=%~2-2",^
       "_slideryma=%~2+1",^
       "_slidermi=%~4",^
       "_sliderma=%~5",^
       "_sliderSC=%~6",^
       "_sliderPC=%~7",^
       "$sliderValue_%~8=%~9",^
       "$sliderPosition_%~8=%~1+1+($sliderValue_%~8-%~4)*(%~3-1)/(%~5-%~4)",^
       "$sliderEnable_%~8=1"
set "_sliderB=!$q:~0,%~3!"
set "_sliderB=!_sliderB:q=═!"

set "_sliderD=%\e%[38;5;%_sliderSC%m%\e%[%_sliderY%;%_sliderX%H"
set "_sliderD=%_sliderD%▐%_sliderB%▌%\e%[m"
set "_sliderD=%_sliderD%%\e%[48;5;%_sliderPC%m%\e%[%_sliderY%;?H %\e%[D%\e%[A %\e%[2B%\e%[D %\e%[m"
set "@sliderDisplay_%~8=%_sliderD%"

set "_sliderA=( m=(~((mouseX-%_sliderxmi%)|(%_sliderxma%-mouseX)|(mouseY-%_sliderymi%)|(%_slideryma%-mouseY))>>31)&1 & L_click & $sliderEnable_%~8,"
set "_sliderA=%_sliderA%$sliderValue_%~8^=-m&($sliderValue_%~8^(%_slidermi%+(%_sliderma%-%_slidermi%)*(mouseX-%_sliderxmi%)/(%_sliderxma%-%_sliderxmi%))),"
set "_sliderA=%_sliderA%$sliderPosition_%~8^=-m&($sliderPosition_%~8^(mouseX+1)) )"
set "@sliderAPI_%~8=%_sliderA%"

set @dragSlider_%~8=(%\n%
    set /a "^!@sliderAPI_%~8^!"%\n%
    for %%i in (^^!$sliderPosition_%~8^^!) do (%\n%
        set "sliderDisplay_%~8=^!@sliderDisplay_%~8:?=%%i^!"%\n%
    )%\n%
)

for /f "tokens=1 delims==" %%i in ('set _slider') do set "%%i="
