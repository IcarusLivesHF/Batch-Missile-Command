rem =====================================================================
rem =====================================================================

title MISSILE COMMAND

if defined mcMenuBuilt goto :_run

call lib\Shivtanium-Phenomenal-VGA "MISSILE COMMAND" mcTitle
call lib\Shivtanium-Phenomenal-VGA "SOUND" mcSound
call lib\Shivtanium-Phenomenal-VGA "WAVE"  mcWave
call lib\Shivtanium-Phenomenal-VGA "BLAST" mcBlast
call lib\Shivtanium-Phenomenal-VGA "PLAY"  mcPlay
call lib\Shivtanium-Phenomenal-VGA "QUIT"  mcQuit

set /a "slX=100, slW=56, labR=92, valX=162"
set /a "rowSnd=44, rowWav=58, rowBla=72"
set /a "btnRow=92, playCol=100, quitCol=136"
set /a "playR=playCol+19, quitR=quitCol+19, btnBot=btnRow+4"
set /a "statRow=112, statHit=111, statL=115, statR=141"
set /a "cSub=111, cHint1=108, cHint2=104"

set /a "labSnd=rowSnd-2, labWav=rowWav-2, labBla=rowBla-2"

set /a "cTitle=128-15*5/2, cSound=labR-5*5"
set /a "cWave=labR-4*5, cBlast=labR-5*5"

call lib\slider !slX! !rowSnd! !slW! 0 100 240 45 sfxvol !cfg_sfxvol!
call lib\slider !slX! !rowWav! !slW! 1 19  240 45 wave   !cfg_startwave!

call lib\toggle !slX! !rowBla! 240 45 236 fxflash !cfg_fxflash! 2

if not defined mcFrame (
	%@roundRect% 2 2 252 113 8 15
	set "mcFrame=!$roundRect!"
	set "$roundRect="
)

set "mcCorner=%\e%[48;5;15m"
set "mcCorner=!mcCorner!%\e%[7;7H %\e%[C %\e%[2B%\e%[3D "
set "mcCorner=!mcCorner!%\e%[7;248H %\e%[C %\e%[2B%\e%[3D%\e%[2C "
set "mcCorner=!mcCorner!%\e%[109;7H %\e%[2B%\e%[D %\e%[C "
set "mcCorner=!mcCorner!%\e%[109;248H%\e%[2C %\e%[2B%\e%[3D %\e%[C "
set "mcCorner=!mcCorner!%\e%[m"

set "mcMenuBuilt=1"

:_run
set "menuChoice="

set "mcStatic=!mcFrame!!mcCorner!"
set "mcStatic=!mcStatic!%\e%[38;2;255;80;80m%\e%[10;!cTitle!H!icon_mcTitle!%\e%[m"
set "mcStatic=!mcStatic!%\e%[38;5;244m%\e%[19;!cSub!Hbatch port of the 1980 Atari arcade%\e%[m"
set "mcStatic=!mcStatic!%\e%[38;5;250m"
set "mcStatic=!mcStatic!%\e%[!labSnd!;!cSound!H!icon_mcSound!"
set "mcStatic=!mcStatic!%\e%[!labWav!;!cWave!H!icon_mcWave!"
set "mcStatic=!mcStatic!%\e%[!labBla!;!cBlast!H!icon_mcBlast!%\e%[m"
set "mcStatic=!mcStatic!%\e%[38;5;244m%\e%[104;!cHint1!Hleft and right mouse fire the outer silos%\e%[m"
set "mcStatic=!mcStatic!%\e%[38;5;244m%\e%[106;!cHint2!Hboth together fire the centre one, twice as fast%\e%[m"
if !cfg_plays! gtr 0 (
	set "_bs=BEST !cfg_hiscore!    reached wave !cfg_hiwave!"
	%@getlen% _bs
	set /a "cBest=128-$len/2"
	set "mcStatic=!mcStatic!%\e%[38;5;250m%\e%[24;!cBest!H!_bs!%\e%[m"
)

%@radish%
set /a "%@saveLastClicks%", "$toggleLastClick_fxflash=L_click"
set /a "sfxTickWas=$sliderValue_sfxvol/5"
set /a "idleN=0, idleMX=mouseX, idleMY=mouseY"

%while% (
	%@radish%

	if defined keysPressed (
		if not "!keysPressed!" == "!keysPressed:-27-=!" ( set "menuChoice=quit" & %endwhile% )
		if not "!keysPressed!" == "!keysPressed:-13-=!" ( set "menuChoice=play" & %endwhile% )
	)

	set /a "_act=L_click|R_click|(mouseX-idleMX)|(mouseY-idleMY)"
	if defined keysPressed set /a "_act=1"
	if !_act! neq 0 ( set /a "idleN=0, idleMX=mouseX, idleMY=mouseY"
	) else           set /a "idleN+=1"
	if !idleN! geq %attractIdle% ( set "attract=1" & set "menuChoice=play" & %endwhile% )

	%@dragSlider_sfxvol%
	%@dragSlider_wave%
	%@clickToggle_fxflash%
	if !flip! equ 1 ( %@playFx:?=hover_click% )

	set /a "_sTick=$sliderValue_sfxvol/5"
	if !_sTick! neq !sfxTickWas! ( set /a "sfxTickWas=_sTick" & %@setFxVol% & %@previewSfx% )

	set /a "_inRow=(1-((mouseY-btnRow)>>31&1))&(1-((btnBot-mouseY)>>31&1))",^
	       "_inP=_inRow&(1-((mouseX-playCol)>>31&1))&(1-((playR-mouseX)>>31&1))",^
	       "_inQ=_inRow&(1-((mouseX-quitCol)>>31&1))&(1-((quitR-mouseX)>>31&1))",^
	       "_inS=(1-((mouseY-statHit)>>31&1))&(1-((statHit-mouseY)>>31&1))",^
	       "_inS&=(1-((mouseX-statL)>>31&1))&(1-((statR-mouseX)>>31&1))"

	if "!L_click!!last_L_click!" equ "10" (
		if !_inP! equ 1 ( %@playFx:?=bright_confirm% & set "menuChoice=play" & %endwhile% )
		if !_inQ! equ 1 ( %@playFx:?=hover_click%    & set "menuChoice=quit" & %endwhile% )
		if !_inS! equ 1 (
			%@playFx:?=hover_click%
			call init\mcStats show
			set "do.while=1"
			set /a "%@saveLastClicks%"
		)
	)

	set "out=%\e%[2J!mcStatic!"
	set "out=!out!!sliderDisplay_sfxvol!!sliderDisplay_wave!!toggleDisplay_fxflash!"

	set "_fx=gradient" & set /a "_fxC=124"
	if "!$toggleState_fxflash!"=="1" ( set "_fx=arcade flash" & set /a "_fxC=122" )
	set "out=!out!%\e%[38;5;250m%\e%[!rowBla!;!_fxC!H!_fx!%\e%[m"

	set /a "_wvC=125-((10-$sliderValue_wave)>>31&1)"
	set "out=!out!%\e%[38;5;250m%\e%[!rowWav!;!_wvC!Hwave !$sliderValue_wave!%\e%[m"

	set "_pc=38;5;245" & if !_inP! equ 1 set "_pc=38;2;120;255;120"
	set "_qc=38;5;245" & if !_inQ! equ 1 set "_qc=38;2;255;120;120"
	set "out=!out!%\e%[!_pc!m%\e%[!btnRow!;!playCol!H!icon_mcPlay!%\e%[m"
	set "out=!out!%\e%[!_qc!m%\e%[!btnRow!;!quitCol!H!icon_mcQuit!%\e%[m"
	set "_sc=38;5;244" & if !_inS! equ 1 set "_sc=38;5;255"
	set "out=!out!%\e%[!_sc!m%\e%[!statRow!;!statL!Hstatistics and achievements%\e%[m"

	set /a "%@saveLastClicks%"

	echo=!out!
	ping -n 1 -w 16 127.0.0.1 >nul
)

call init\mcCfg save
cls
exit /b 0
