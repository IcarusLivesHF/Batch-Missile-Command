@echo off & setlocal enableDelayedExpansion

cd /d "%~dp0"
if "%~1" neq "_" if "%~1" neq "" goto :%~1

set ".gridCols=256"
set ".gridRows=117"
if "%~1"=="" call lib\display font
if not defined $fontSize set "$fontSize=8"
call :Set_Font "consolas" !$fontSize! nomax %1 || exit

title Loading...
call lib\atlas 256 117
call lib\display cell
call lib\display center
call lib\radish
call lib\macros
call lib\geom init
call lib\palette init
set "cfgFile=%~dp0mc.cfg"
call init\mcCfg load
call lib\Sound
call lib\Sound preload
call init\waveTable init

if not defined explFrames set "explFrames=3"
if not defined explSlots  set "explSlots=14"
if %explSlots% gtr 20 set "explSlots=20"
if %explSlots% lss 1  set "explSlots=1"

set "bombSense=8"

set "atLead=16"
set "atSpeed=5"
set "atNear=4"
set "atMaxAbm=2"
set "attractIdle=1200"
call lib\geom oct ex %explRadius%
call lib\geom disc ex %explRadius%

set /a "tickMax=1", "wave=1"

rem PLAYFIELD 
set "siloX=16 128 240"
set "cityX=40 64 88 168 192 216"
set "groundY=16"
set "siloY=22"
set "aimOffX=1"
set "aimOffY=1"

rem FIRST WAVE 
call init\waveTable set !wave!
call lib\palette set !wave!

if not defined osc4 set "osc4=0"

if not defined fxFlash set "fxFlash=!cfg_fxflash!"

for /l %%s in (1,1,%explRadius%) do (
	set /a "_t=(%%s*100)/%explRadius%"
	set /a "_r=255-(155*_t)/100"
	set /a "_g=255-(235*_t)/100"
	set /a "_b=255-(245*_t)/100"
	if %%s leq 2 set /a "_r=255, _g=255, _b=255"
	set "exCol_%%s=48;2;!_r!;!_g!;!_b!"
)

for /l %%x in (0,1,19) do set /a "eGrp_%%x=%%x%%%explFrames%"

rem CROSSHAIR AND FLIERS 
set "xMark=%\e%[1A%\e%[1D %\e%[1C %\e%[1B%\e%[2D %\e%[1B%\e%[2D %\e%[1C "
set "xCol=48;2;255;200;60"

set "flG_0=%\e%[1D   %\e%[1B%\e%[5D       "
set "flG_1=%\e%[2D     %\e%[1B%\e%[4D   "
set "flSpd_0=%flSpdBomber%"
set "flSpd_1=%flSpdSat%"
set "flPts_0=%ptBomber%"
set "flPts_1=%ptSat%"

rem TERRAIN 
set "_row=  "
for /l %%d in (1,1,8) do set "_row=!_row!!_row!"

rem CITIES AND SILOS 
set /a "_n=0"
for %%c in (%siloX%) do (
	set /a "sX_!_n!=%%c"
	set /a "sAmmo_!_n!=%abmPerSilo%"
	set /a "sSpd_!_n!=%abmSpeedSide%"
	set /a "sBarC_!_n!=%%c+1-(%abmPerSilo%/2)"
	set /a "sAlive_!_n!=1"
	set /a "_n+=1"
)
set /a "sSpd_1=%abmSpeedMid%"

set /a "ammoFull=%abmPerSilo%*%siloCount%"

set /a "_n=0"
for %%c in (%cityX%) do (
	set /a "cX_!_n!=%%c"
	set /a "cAlive_!_n!=1"
	set /a "cTgt_!_n!=0"
	set /a "_n+=1"
)
set /a "cityLeft=%cityStart%, cLost=0"
set "gameOver="

rem SLOTS AND COUNTERS 
set /a "mFreeN=8, eFreeN=%explSlots%, aFreeN=8"
for /l %%n in (0,1,7)  do ( set "mOn_%%n=0" & set /a "mFree_%%n=%%n" )
for /l %%n in (0,1,7)  do ( set "aOn_%%n=0" & set /a "aFree_%%n=%%n" )
for /l %%x in (0,1,19) do ( set "eOn_%%x=0" & set /a "eFree_%%x=%%x" )

set /a "tickNo=0, icbmAcc=0, spawned=0, live=0, explLive=0, abmLive=0, fired=0"
set /a "score=0, killed=0, banked=0, ammoLeft=ammoFull"
set /a "mirvs=0, spawnAll=0"
set /a "nextBonus=%bonusEvery%"
set /a "flashPhase=0, lastFlash=-1"
set /a "tickAcc=0, frameCount=0"
set /a "mouseX=128, mouseY=58, aimU=127, aimV=114"
set /a "L_click=0, R_click=0, B_click=0"
set /a "last_l_click=0, last_r_click=0, last_b_click=0"
set /a "xhOld=0"
set "xhWas="
set "flashBg=!bg_wht!"
set "eDrawC=!bg_wht!"
if "!osc4!"=="1" set "eDrawC=%flashOn%"



set "radishPre="
for /f "skip=1 tokens=2 delims=," %%p in ('tasklist /fi "imagename eq radish.exe" /fo csv 2^>nul') do set "radishPre=!radishPre!%%~p,"
>nul 2>nul tasklist /fi "imagename eq radish.exe" && set "radishPre=,!radishPre!"

( %radish% "%~nx0" radish_wait ) & exit
:radish_wait
( %while% ( if exist "radish_ready" %endwhile% )) & del /f /q "radish_ready"

rem NEW GAME 
:newGame
call init\mainMenu
if "!menuChoice!" equ "quit" goto :quitAll

:startRun
set /a "wave=!cfg_startwave!"
if defined attract set /a "wave=1"

set /a "fxFlash=cfg_fxflash"
set /a "score=0, killed=0, banked=0, ammoLeft=ammoFull, nextBonus=%bonusEvery%"
set /a "mirvs=0, spawnAll=0, fired=0"
set /a "bestBlast=0, cleanWaves=0, fliersKilled=0, bombsKilled=0"
set /a "mirvStops=0, midUsed=0, noMidWaves=0, fullWaves=0, cLostAll=0"
set /a "cityLeft=%cityStart%, cLost=0"
set /a "atTgt=-1, atFire=-1, aimU=128, aimV=180"
set "demoTag=" & if defined attract set "demoTag=      -- DEMO, click to play --"
set "attractEnd=" & set "wantPause=" & set "quitRun="
set "demoPlay="
for /l %%z in (0,1,5) do set /a "cAlive_%%z=1, cTgt_%%z=0"
set "gameOver=" & set "waveDone="
%@setFxVol%

rem WAVE START
:waveStart
call init\waveTable set !wave!
call lib\palette set !wave!

for /l %%n in (0,1,2) do set /a "sAmmo_%%n=%abmPerSilo%, sAlive_%%n=1"

set "cGaugeOk=48;2;150;240;190"
set "cGaugeLow=48;2;255;170;0"
set "cGaugeTrough=48;2;28;28;28"
set "cGaugeOut=48;2;125;20;20"
set "fWarnLow=38;2;255;190;60"
set "fWarnOut=38;2;255;235;190"

set /a "ammoLow=%abmPerSilo%/3"
if !ammoLow! lss 1 set /a "ammoLow=1"
set /a "ammoWarn=ammoLow+1"

set "txtLow=LOW AMMO" & set /a "_lw=8"
set "txtOut=NO AMMO"  & set /a "_ow=7"
if %abmPerSilo% lss 8 ( set "txtLow=LOW" & set "txtOut=OUT" & set /a "_lw=3, _ow=3" )
set /a "_l1=(%abmPerSilo%-_lw)/2, _l2=%abmPerSilo%-_lw-_l1"
set /a "_o1=(%abmPerSilo%-_ow)/2, _o2=%abmPerSilo%-_ow-_o1"
for %%p in (!_l1!) do for %%q in (!_l2!) do set "capLow=!_row:~0,%%p!!txtLow!!_row:~0,%%q!"
for %%p in (!_o1!) do for %%q in (!_o2!) do set "capOut=!_row:~0,%%p!!txtOut!!_row:~0,%%q!"

for /l %%a in (0,1,%abmPerSilo%) do (
	set /a "_e=%abmPerSilo%-%%a"
	if %%a equ 0 (
		set "_gB=%\e%[!cGaugeOut!m!_row:~0,%abmPerSilo%!"
		set "_gC=%\e%[!cGaugeOut!;!fWarnOut!m!capOut!"
	) else if %%a leq !ammoLow! (
		for %%f in (!_e!) do set "_gB=%\e%[!cGaugeLow!m!_row:~0,%%a!%\e%[!cGaugeTrough!m!_row:~0,%%f!"
		set "_gC=%\e%[!cGaugeTrough!;!fWarnLow!m!capLow!"
	) else (
		for %%f in (!_e!) do set "_gB=%\e%[!cGaugeOk!m!_row:~0,%%a!%\e%[!cGaugeTrough!m!_row:~0,%%f!"
		set "_gC=%\e%[!cCityBk!m!_row:~0,%abmPerSilo%!"
	)
	set "ammoBar_%%a=!_gB!%\e%[m%\e%[2B%\e%[%abmPerSilo%D!_gC!%\e%[m"
)

for %%v in (cGaugeOk cGaugeLow cGaugeTrough cGaugeOut fWarnLow fWarnOut
            txtLow txtOut capLow capOut ammoLow
            _lw _ow _l1 _l2 _o1 _o2 _e _gB _gC) do set "%%v="

set /a "mFreeN=8, eFreeN=%explSlots%, aFreeN=8"
for /l %%n in (0,1,7)  do ( set "mOn_%%n=0" & set /a "mFree_%%n=%%n" )
for /l %%n in (0,1,7)  do ( set "aOn_%%n=0" & set /a "aFree_%%n=%%n" )
for /l %%x in (0,1,19) do ( set "eOn_%%x=0" & set /a "eFree_%%x=%%x" )
for /l %%z in (0,1,5)  do set /a "cTgt_%%z=0"
set /a "spawned=0, live=0, abmLive=0, explLive=0, icbmAcc=0, cLost=0, xhOld=0"
set /a "flOn=0, flAcc=0, flCool=!wFlCool!, flFireT=0"
set /a "bombFired=0, bombLive=0"
set "waveDone="
set "fxBlast="

cls
<nul set /p "=%\e%[?25l"
set "out=%\e%[!cCityBk!m"
for /l %%r in (108,1,116) do set "out=!out!%\e%[%%r;1H!_row:~0,256!"
set "out=!out!%\e%[m"
for %%z in (0 1 2 3 4 5) do if !cAlive_%%z! equ 1 (
	set /a "_c=cX_%%z+1"
	set "out=!out!%\e%[!cCity1!m%\e%[105;!_c!H%\e%[1D   %\e%[106;!_c!H%\e%[2D     %\e%[107;!_c!H%\e%[2D     %\e%[m"
)
for %%z in (0 1 2) do (
	set /a "_c=sX_%%z+1"
	set "out=!out!%\e%[!cAbm!m%\e%[105;!_c!H %\e%[106;!_c!H%\e%[2D   %\e%[107;!_c!H%\e%[3D     %\e%[m"
)
for %%z in (0 1 2) do for %%a in (!sAmmo_%%z!) do set "out=!out!%\e%[110;!sBarC_%%z!H!ammoBar_%%a!"
for %%z in (0 1 2 3 4 5) do if !cAlive_%%z! equ 0 (
	set /a "_c=cX_%%z+1"
	set "out=!out!%\e%[m%\e%[108;!_c!H%\e%[2D     "
)
echo=!out!

if !wave! leq 3 (
	set /a "_r=%gridRows%/2"
	set "out=%\e%[38;2;255;255;255m%\e%[!_r!;121HDEFEND CITIES%\e%[m"
	echo=!out!
	ping -n 2 127.0.0.1 >nul
	set "out=%\e%[m%\e%[!_r!;121H             "
	echo=!out!
)
set "out="







set "clock=!time: =0!"
set /a "t1=(((1!clock:~0,2!-100)*60+(1!clock:~3,2!-100))*60+(1!clock:~6,2!-100))*100+(1!clock:~9,2!-100)"
%while% ( set "clock=!time: =0!"
	set /a "t2=(((1!clock:~0,2!-100)*60+(1!clock:~3,2!-100))*60+(1!clock:~6,2!-100))*100+(1!clock:~9,2!-100)",^
	       "frameCS=t2-t1, frameCS+=(frameCS>>31&1)*8640000, t1=t2",^
	       "frameCount+=1"

	if defined gameOver %endwhile%
	if defined attractEnd %endwhile%

	if !frameCS! gtr 0 (

		set "out="
		%@radish%

		rem PAUSE
		if defined keysPressed if not defined attract if not "!keysPressed!" == "!keysPressed:-27-=!" set "wantPause=1"
		if defined attract if defined keysPressed if not "!keysPressed!" == "!keysPressed:-27-=!" %endwhile%

		if defined wantPause (
			set "wantPause="
			set /a "_pr=%gridRows%/2-2, _pr2=_pr+3, _pr3=_pr+5"
			set "out=%\e%[38;5;15m%\e%[!_pr!;120HPAUSED%\e%[m"
			set "out=!out!%\e%[38;5;250m%\e%[!_pr2!;106Hclick or press Esc to resume%\e%[m"
			set "out=!out!%\e%[38;5;244m%\e%[!_pr3!;110HQ abandons the run%\e%[m"
			echo=!out!
			set "out="

			set "do.while=1"
			%while% ( %@radish%
				if not defined keysPressed %endwhile%
				ping -n 1 -w 20 127.0.0.1 >nul
			)

			set "do.while=1"
			set /a "%@saveLastClicks%"
			%while% ( %@radish%
				if defined keysPressed (
					if not "!keysPressed!" == "!keysPressed:-27-=!" %endwhile%
					if not "!keysPressed!" == "!keysPressed:-81-=!" ( set "gameOver=1" & set "quitRun=1" & %endwhile% )
				)
				if "!L_click!!last_L_click!" equ "10" %endwhile%
				set /a "%@saveLastClicks%"
				ping -n 1 -w 20 127.0.0.1 >nul
			)

			set "do.while=1"
			set /a "tickAcc=0"
			set "clock=!time: =0!"
			set /a "t1=(((1!clock:~0,2!-100)*60+(1!clock:~3,2!-100))*60+(1!clock:~6,2!-100))*100+(1!clock:~9,2!-100)"
			set "out=%\e%[m%\e%[2J"

			set "out=!out!%\e%[!cCityBk!m"
			for /l %%r in (108,1,116) do set "out=!out!%\e%[%%r;1H!_row:~0,256!"
			set "out=!out!%\e%[m"
			for %%z in (0 1 2 3 4 5) do if !cAlive_%%z! equ 1 (
				set /a "_c=cX_%%z+1"
				set "out=!out!%\e%[!cCity1!m%\e%[105;!_c!H%\e%[1D   %\e%[106;!_c!H%\e%[2D     %\e%[107;!_c!H%\e%[2D     %\e%[m"
			)
			for %%z in (0 1 2) do (
				set /a "_c=sX_%%z+1"
				set "out=!out!%\e%[!cAbm!m%\e%[105;!_c!H %\e%[106;!_c!H%\e%[2D   %\e%[107;!_c!H%\e%[3D     %\e%[m"
			)
			for %%z in (0 1 2) do for %%a in (!sAmmo_%%z!) do set "out=!out!%\e%[110;!sBarC_%%z!H!ammoBar_%%a!"
			echo=!out!
			set "out="
			set /a "xhOld=0"
			set "xhWas="
		)

		if not defined attract set /a "aimU=mouseX-%aimOffX%, aimV=230-((mouseY-%aimOffY%)<<1)"
		set /a "aimU=aimU",^
		       "aimU-=((aimU-(255-%aimMargin%))&(((255-%aimMargin%)-aimU)>>31))",^
		       "aimU-=((aimU-%aimMargin%)&((aimU-%aimMargin%)>>31))",^
		       "aimV-=((aimV-222)&((222-aimV)>>31))",^
		       "aimV-=((aimV-34)&((aimV-34)>>31))"

		rem CROSSHAIR
		set /a "ux=aimU, uy=aimV, %@u2c%, _xh=sRow*512+sCol"
		if "!_xh!/!flashBg!" neq "!xhOld!/!xhWas!" (
			set "xh="
			if !xhOld! neq 0 if !_xh! neq !xhOld! (
				set /a "_or=xhOld/512, _oc=xhOld%%512"
				set "xh=%\e%[m%\e%[!_or!;!_oc!H%\e%[2D %\e%[3C %\e%[1A%\e%[3D %\e%[2B%\e%[1D "
			)
			set "xh=!xh!%\e%[!flashBg!m%\e%[!sRow!;!sCol!H%\e%[2D %\e%[3C %\e%[1A%\e%[3D %\e%[2B%\e%[1D %\e%[m"
			<nul set /p "=!xh!"
			set /a "xhOld=_xh"
			set "xhWas=!flashBg!"
		)

		set "fireSilo="
		if defined attract (
			if "!L_click!!last_L_click!" equ "10" ( set "attractEnd=1" & set "demoPlay=1" )
			if "!R_click!!last_R_click!" equ "10" ( set "attractEnd=1" & set "demoPlay=1" )
			if defined keysPressed set "attractEnd=1"
			if !atFire! geq 0 ( set "fireSilo=!atFire!" & set /a "atFire=-1" )
		) else (
			if %@onClick:?=L% set "fireSilo=0"
			if %@onClick:?=B% set "fireSilo=1"
			if %@onClick:?=R% set "fireSilo=2"
		)
		set /a "%@saveLastClicks%"

		if defined fireSilo if !aFreeN! leq 0 ( %@playFx:?=nofire% )
		if defined fireSilo if !aFreeN! gtr 0 (
			for %%f in (!fireSilo!) do set /a "_am=sAmmo_%%f, _sx=sX_%%f, _sp=sSpd_%%f"
			if !_am! leq 0 ( %@playFx:?=nofire% )
			if !_am! gtr 0 (
				for %%f in (!fireSilo!) do set /a "sAmmo_%%f-=1"
				if !_am! equ !ammoWarn! ( %@playFx:?=lowammo% )
				for %%f in (!fireSilo!) do for %%a in (!sAmmo_%%f!) do set "out=!out!%\e%[110;!sBarC_%%f!H!ammoBar_%%a!"
				set /a "aFreeN-=1"
				for %%f in (!aFreeN!) do set "asl=!aFree_%%f!"

				set /a "sx=_sx, sy=%siloY%, tx=aimU, ty=aimV",^
				       "dx=tx-sx, dy=ty-sy, %@approxDist%, %@step88%",^
				       "ux=sx, uy=sy, %@u2c%"

				for %%f in (!asl!) do (
					set /a "aX_%%f=sx<<8, aY_%%f=sy<<8, aIX_%%f=ix, aIY_%%f=iy",^
					       "aTX_%%f=tx, aTY_%%f=ty",^
					       "aSX_%%f=(dx>>31|1), aSY_%%f=(dy>>31|1), aSp_%%f=_sp",^
					       "aZX_%%f=1-((dx|-dx)>>31&1), aZY_%%f=1-((dy|-dy)>>31&1)",^
					       "aOR_%%f=sRow, aOC_%%f=sCol, aCR_%%f=0, aCC_%%f=0",^
					       "aLR_%%f=sRow, aLC_%%f=sCol"
					set "aGeo_%%f=" & set "aOn_%%f=1"
				)
				set /a "ux=tx, uy=ty, %@u2c%"
				for %%f in (!asl!) do set /a "aXR_%%f=sRow, aXC_%%f=sCol"
				set "out=!out!%\e%[!xCol!m%\e%[!sRow!;!sCol!H!xMark!%\e%[m"
				set /a "abmLive+=1, fired+=1"
				if "!fireSilo!"=="1" set /a "midUsed+=1"
				%@playFx:?=launch%
			)
		)

		set /a "tickAcc+=frameCS*3"

		if !tickAcc! gtr 10 set "tickAcc=10"

		for /l %%t in (1,1,%tickMax%) do if !tickAcc! geq 5 (
		set /a "tickAcc-=5, tickNo+=1"

		rem PALETTE FLASH
		set /a "flashPhase=(tickNo/%flashDiv%)%%%flashLen%"
		if !flashPhase! neq !lastFlash! (
			set /a "lastFlash=flashPhase"
			for %%p in (!flashPhase!) do for /f %%v in ("!flashCol_%%p!") do (
				set "flashBg=!bg_%%v!"
				if "!osc4!"=="0" set "eDrawC=!bg_%%v!"
				if "!osc4!"=="1" set "out=!out!%\e%]4;%flashIdx%;rgb:!rgb_%%v!%\e%\"
			)
			if !fxFlash! equ 1 if "!osc4!"=="0" (
				set "fx="
				for %%x in (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19) do (
					if !eOn_%%x! equ 1 for %%s in (!eStep_%%x!) do set "fx=!fx!%\e%[!eRow_%%x!;!eCol_%%x!H!exFull_%%s!"
				)
				if defined fx set "out=!out!%\e%[!flashBg!m!fx!%\e%[m"
			)
		)

		rem TICK
		set /a "icbmAcc+=256"
		set "moves=0"
		if !icbmAcc! geq !wDelay! set /a "moves=1, icbmAcc-=wDelay"
		if !icbmAcc! gtr 1488 set /a "icbmAcc=1488"

		rem SPAWN GATE
		set /a "topY=0"
		for %%n in (0 1 2 3 4 5 6 7) do if !mOn_%%n! equ 1 (
			set /a "_y=mY_%%n>>8, topY-=((topY-_y)&((topY-_y)>>31))"
		)

		if !spawned! lss !wIcbm! if !topY! lss !wGate! (
			set /a "_want=wIcbm-spawned, _want-=((_want-4)&((4-_want)>>31))",^
			       "_want-=((_want-mFreeN)&((mFreeN-_want)>>31))"

			for /l %%q in (1,1,4) do if %%q leq !_want! (
				set /a "mFreeN-=1"
				for %%f in (!mFreeN!) do set "sl=!mFree_%%f!"

				set /a "_atk=live+bombLive, _isB=0"
				if !bombFired! lss !wBomb! if !bombLive! lss %maxBombLive% if !_atk! lss %maxAtk% set /a "_isB=1"
				set /a "sx=(!random!%%240)+8, sy=%romTop%, ty=%groundY%"

				set /a "_allow=3-cLost, _allow-=(_allow&(_allow>>31)), _dist=0"
				for %%z in (0 1 2 3 4 5) do if !cTgt_%%z! gtr 0 set /a "_dist+=1"

				set /a "_pick=!random!%%9, tt=0, ti=_pick"
				if !_pick! geq 6 set /a "tt=1, ti=_pick-6"

				if !tt! equ 0 for %%z in (!ti!) do (
					if !cAlive_%%z! equ 0 set /a "tt=1"
					if !cTgt_%%z! equ 0 if !_dist! geq !_allow! set /a "tt=1"
				)
				if !tt! equ 1 set /a "ti=!random!%%3"

				if !tt! equ 0 ( for %%z in (!ti!) do set /a "tx=cX_%%z, cTgt_%%z+=1"
				) else           for %%z in (!ti!) do set /a "tx=sX_%%z"

				set /a "dx=tx-sx, dy=ty-sy, %@approxDist%, %@step88%",^
				       "ux=sx, uy=sy, %@u2c%"

				for %%f in (!sl!) do (
					set /a "mX_%%f=sx<<8, mY_%%f=sy<<8, mIX_%%f=ix, mIY_%%f=iy",^
					       "mTX_%%f=tx, mTY_%%f=ty",^
					       "mSY_%%f=(dy>>31|1)",^
					       "mTT_%%f=tt, mTI_%%f=ti, mSpl_%%f=0",^
					       "mBomb_%%f=_isB, mEva_%%f=0",^
					       "mPts_%%f=%ptIcbm%+_isB*(%ptBomb%-%ptIcbm%)",^
					       "mOR_%%f=sRow, mOC_%%f=sCol, mCR_%%f=0, mCC_%%f=0",^
					       "mLR_%%f=sRow, mLC_%%f=sCol"
					set "mGeo_%%f=" & set "mOn_%%f=1"
					if !_isB! equ 1 ( set "mCol_%%f=!bg_wht!" ) else set "mCol_%%f=!cIcbm!"
				)
				set /a "spawned+=1, spawnAll+=1, live+=1"
				if !_isB! equ 1 set /a "bombFired+=1, bombLive+=1"
			)
		)

		rem ICBMS
		if !moves! gtr 0 for %%n in (0 1 2 3 4 5 6 7) do if !mOn_%%n! equ 1 (

			set /a "mX_%%n+=mIX_%%n*moves, mY_%%n+=mIY_%%n*moves",^
			       "ux=mX_%%n>>8, uy=mY_%%n>>8, %@u2c%",^
			       "_lr=mLR_%%n, _lc=mLC_%%n",^
			       "_hit=1-(((uy-mTY_%%n)*mSY_%%n)>>31&1)",^
			       "_dr=sRow-_lr, _dc=sCol-_lc",^
			       "_dr-=((_dr-4)&((4-_dr)>>31)), _dr-=((_dr+4)&((_dr+4)>>31))",^
			       "_dc-=((_dc-7)&((7-_dc)>>31)), _dc-=((_dc+7)&((_dc+7)>>31))",^
			       "_si=(_dr+4)*15+(_dc+7), _mvd=(_dr|-_dr)|(_dc|-_dc), _mv=(_mvd|-_mvd)>>31&1"

			if !_hit! equ 1 (

				set /a "_eo=mOC_%%n+1"
				set "out=!out!%\e%[m%\e%[!mOR_%%n!;!_eo!H!mGeo_%%n!"
				set "mGeo_%%n=" & set "mOn_%%n=0"
				set /a "live-=1, bombLive-=mBomb_%%n"
				if !mTT_%%n! equ 0 for %%z in (!mTI_%%n!) do set /a "cTgt_%%z-=1"
				for %%f in (!mFreeN!) do set /a "mFree_%%f=%%n"
				set /a "mFreeN+=1"

				for %%z in (0 1 2 3 4 5) do if !cAlive_%%z! equ 1 (
					set /a "_dd=mTX_%%n-cX_%%z, _dd=(_dd>>31|1)*_dd"
					if !_dd! leq %explRadius% if !banked! gtr 0 (
						set /a "banked-=1"
					) else if !_dd! leq %explRadius% (
						set "cAlive_%%z=0"
						set /a "cityLeft-=1, cLost+=1, cLostAll+=1, _c=cX_%%z+1"
						set "out=!out!%\e%[m%\e%[105;!_c!H%\e%[2D     %\e%[106;!_c!H%\e%[2D     %\e%[107;!_c!H%\e%[2D     %\e%[108;!_c!H%\e%[2D     "
						%@playFx:?=city%
					)
				)
				for %%z in (0 1 2) do if !sAlive_%%z! equ 1 (
					set /a "_dd=mTX_%%n-sX_%%z, _dd=(_dd>>31|1)*_dd"
					if !_dd! leq %explRadius% (
						set "sAlive_%%z=0"
						set /a "sAmmo_%%z=0, _c=sX_%%z+1"
						set "out=!out!%\e%[110;!sBarC_%%z!H!ammoBar_0!"
						set "out=!out!%\e%[m%\e%[105;!_c!H %\e%[106;!_c!H%\e%[2D   %\e%[107;!_c!H%\e%[3D     %\e%[108;!_c!H%\e%[3D     "
					)
				)
				if !cityLeft! leq 0 set "gameOver=1"

				if !eFreeN! gtr 0 (
					set /a "eFreeN-=1, ux=mTX_%%n, uy=mTY_%%n, %@u2c%"
					for %%f in (!eFreeN!) do set "es=!eFree_%%f!"
					for %%f in (!es!) do (
						set /a "eRow_%%f=sRow, eCol_%%f=sCol, eUX_%%f=ux, eUY_%%f=uy, eStep_%%f=1, eDir_%%f=1, eKil_%%f=0"
						set "eOn_%%f=1"
					)
					set /a "explLive+=1"
				)
				set "fxBlast=1"

			) else if !_mv! equ 1 (

				for %%a in (!_si!) do (
					set "out=!out!%\e%[!mCol_%%n!m%\e%[!_lr!;!_lc!H !segG_%%a!%\e%[!sRow!;!sCol!H%\e%[!flashBg!m %\e%[m"
					set "mGeo_%%n=!mGeo_%%n!!segG_%%a!"
				)
				set /a "mLR_%%n=sRow, mLC_%%n=sCol"
			)
		)

		rem ATTRACT
		if defined attract (
			if !atTgt! geq 0 for %%n in (!atTgt!) do if !mOn_%%n! equ 0 set /a "atTgt=-1"
			if !atTgt! lss 0 for %%n in (7 6 5 4 3 2 1 0) do if !mOn_%%n! equ 1 set /a "atTgt=%%n"

			if !atTgt! geq 0 (
				for %%n in (!atTgt!) do set /a "_lx=(mX_%%n+mIX_%%n*%atLead%)>>8, _ly=(mY_%%n+mIY_%%n*%atLead%)>>8"

				set /a "_dx=_lx-aimU, _dy=_ly-aimV",^
				       "_ax=(_dx>>31|1)*_dx, _ay=(_dy>>31|1)*_dy",^
				       "_sx=(_dx>>31|1)*%atSpeed%, _sy=(_dy>>31|1)*%atSpeed%",^
				       "_sx=_sx*(1-((_ax-%atSpeed%)>>31&1))+_dx*((_ax-%atSpeed%)>>31&1)",^
				       "_sy=_sy*(1-((_ay-%atSpeed%)>>31&1))+_dy*((_ay-%atSpeed%)>>31&1)"
				set /a "aimU+=_sx, aimV+=_sy"
				set /a "_ax=(_dx>>31|1)*_dx, _ay=(_dy>>31|1)*_dy"

				if !_ax! leq %atNear% if !_ay! leq %atNear% if !abmLive! lss %atMaxAbm% (
					set /a "_bd=9999, atFire=-1"
					for %%z in (0 1 2) do if !sAmmo_%%z! gtr 0 (
						set /a "_d=sX_%%z-aimU, _d=(_d>>31|1)*_d"
						if !_d! lss !_bd! set /a "_bd=_d, atFire=%%z"
					)
				)
			)
		)

		rem SMART BOMBS
		if !bombLive! gtr 0 for %%n in (0 1 2 3 4 5 6 7) do if !mOn_%%n! equ 1 if !mBomb_%%n! equ 1 (
			if !mEva_%%n! equ 1 ( set /a "mEva_%%n=0"
			) else (
				set /a "_ux=mX_%%n>>8, _uy=mY_%%n>>8",^
				       "dx=mTX_%%n-_ux, dy=mTY_%%n-_uy, %@approxDist%, %@step88%",^
				       "mIX_%%n=ix, mIY_%%n=iy"
			)
		)

		rem MIRV
		if !spawned! lss !wIcbm! if !mFreeN! gtr 0 (
			set /a "_mx=0, _cand=-1"
			for %%n in (0 1 2 3 4 5 6 7) do if !mOn_%%n! equ 1 (
				set /a "_ay=mY_%%n>>8"
				if !_cand! lss 0 if !mSpl_%%n! equ 0 if !_mx! geq %mirvLo% if !_mx! leq %mirvHi% if !_ay! lss %mirvCeil% set /a "_cand=%%n"
				set /a "_mx-=((_mx-_ay)&((_mx-_ay)>>31))"
			)

			if !_cand! geq 0 (
				set /a "_nh=wIcbm-spawned",^
				       "_nh-=((_nh-%mirvSpawn%)&((%mirvSpawn%-_nh)>>31))",^
				       "_nh-=((_nh-mFreeN)&((mFreeN-_nh)>>31))"
				for %%p in (!_cand!) do set /a "mSpl_%%p=1, _hx=mX_%%p>>8, _hy=mY_%%p>>8"

				for /l %%q in (1,1,3) do if %%q leq !_nh! (
					set /a "mFreeN-=1"
					for %%f in (!mFreeN!) do set "sl=!mFree_%%f!"

					set /a "_allow=3-cLost, _allow-=(_allow&(_allow>>31)), _dist=0"
					for %%z in (0 1 2 3 4 5) do if !cTgt_%%z! gtr 0 set /a "_dist+=1"
					set /a "_pick=!random!%%9, tt=0, ti=_pick"
					if !_pick! geq 6 set /a "tt=1, ti=_pick-6"
					if !tt! equ 0 for %%z in (!ti!) do (
						if !cAlive_%%z! equ 0 set /a "tt=1"
						if !cTgt_%%z! equ 0 if !_dist! geq !_allow! set /a "tt=1"
					)
					if !tt! equ 1 set /a "ti=!random!%%3"
					if !tt! equ 0 ( for %%z in (!ti!) do set /a "tx=cX_%%z, cTgt_%%z+=1"
					) else           for %%z in (!ti!) do set /a "tx=sX_%%z"

					set /a "sx=_hx, sy=_hy, ty=%groundY%",^
					       "dx=tx-sx, dy=ty-sy, %@approxDist%, %@step88%",^
					       "ux=sx, uy=sy, %@u2c%"
					for %%f in (!sl!) do (
						set /a "mX_%%f=sx<<8, mY_%%f=sy<<8, mIX_%%f=ix, mIY_%%f=iy",^
						       "mTX_%%f=tx, mTY_%%f=ty",^
						       "mSY_%%f=(dy>>31|1)",^
						       "mTT_%%f=tt, mTI_%%f=ti, mSpl_%%f=1",^
					       "mBomb_%%f=0, mEva_%%f=0, mPts_%%f=%ptIcbm%",^
						       "mOR_%%f=sRow, mOC_%%f=sCol, mCR_%%f=0, mCC_%%f=0",^
						       "mLR_%%f=sRow, mLC_%%f=sCol"
						set "mGeo_%%f=" & set "mOn_%%f=1"
						set "mCol_%%f=!cIcbm!"
					)
					set /a "spawned+=1, spawnAll+=1, live+=1, mirvs+=1"
				)
			)
		)

		rem FLIERS
		if !flOn! equ 0 (
			set /a "flCool-=1"
			if !flCool! leq 0 if !wFliers! equ 1 if !spawned! lss !wIcbm! (
				set /a "flType=!random!%%2, flDir=(!random!%%2)*2-1",^
				       "flY=wFlLo+(!random!%%(wFlHi-wFlLo+1))",^
				       "flAcc=0, flFireT=wFlFire, flOn=1"
				set /a "flX=4+((1-flDir)/2)*247"
				set /a "ux=flX, uy=flY, %@u2c%, flRow=sRow, flCol=sCol"
				for %%y in (!flType!) do set /a "flSpd=flSpd_%%y"
			)
		) else (
			set /a "flAcc+=1"
			if !flAcc! geq !flSpd! (
				set /a "flAcc=0, flX+=flDir"
				for %%y in (!flType!) do set "out=!out!%\e%[m%\e%[!flRow!;!flCol!H!flG_%%y!"
				set /a "ux=flX, uy=flY, %@u2c%, flRow=sRow, flCol=sCol"
				if !flX! lss 4 ( set /a "flOn=0, flCool=wFlCool"
				) else if !flX! gtr 251 ( set /a "flOn=0, flCool=wFlCool"
				) else for %%y in (!flType!) do set "out=!out!%\e%[!cIcbm!m%\e%[!flRow!;!flCol!H!flG_%%y!%\e%[m"
			)

			set /a "flFireT-=1"
			if !flOn! equ 1 if !flFireT! leq 0 if !mFreeN! gtr 0 if !spawned! lss !wIcbm! (
				set /a "flFireT=wFlFire, mFreeN-=1"
				for %%f in (!mFreeN!) do set "sl=!mFree_%%f!"

				set /a "_allow=3-cLost, _allow-=(_allow&(_allow>>31)), _dist=0"
				for %%z in (0 1 2 3 4 5) do if !cTgt_%%z! gtr 0 set /a "_dist+=1"
				set /a "_pick=!random!%%9, tt=0, ti=_pick"
				if !_pick! geq 6 set /a "tt=1, ti=_pick-6"
				if !tt! equ 0 for %%z in (!ti!) do (
					if !cAlive_%%z! equ 0 set /a "tt=1"
					if !cTgt_%%z! equ 0 if !_dist! geq !_allow! set /a "tt=1"
				)
				if !tt! equ 1 set /a "ti=!random!%%3"
				if !tt! equ 0 ( for %%z in (!ti!) do set /a "tx=cX_%%z, cTgt_%%z+=1"
				) else           for %%z in (!ti!) do set /a "tx=sX_%%z"

				set /a "sx=flX, sy=flY, ty=%groundY%",^
				       "dx=tx-sx, dy=ty-sy, %@approxDist%, %@step88%",^
				       "ux=sx, uy=sy, %@u2c%"
				for %%f in (!sl!) do (
					set /a "mX_%%f=sx<<8, mY_%%f=sy<<8, mIX_%%f=ix, mIY_%%f=iy",^
					       "mTX_%%f=tx, mTY_%%f=ty",^
					       "mSY_%%f=(dy>>31|1)",^
					       "mTT_%%f=tt, mTI_%%f=ti, mSpl_%%f=0",^
					       "mBomb_%%f=0, mEva_%%f=0, mPts_%%f=%ptIcbm%",^
					       "mOR_%%f=sRow, mOC_%%f=sCol, mCR_%%f=0, mCC_%%f=0",^
					       "mLR_%%f=sRow, mLC_%%f=sCol"
					set "mGeo_%%f=" & set "mOn_%%f=1"
					set "mCol_%%f=!cIcbm!"
				)
				set /a "spawned+=1, spawnAll+=1, live+=1"
			)
		)

		rem ABMS
		for %%n in (0 1 2 3 4 5 6 7) do if !aOn_%%n! equ 1 (
		set "_det="
		set /a "_ax=aX_%%n+aIX_%%n*aSp_%%n, _ay=aY_%%n+aIY_%%n*aSp_%%n",^
		       "ux=_ax>>8, uy=_ay>>8, %@u2c%",^
		       "_lr=aLR_%%n, _lc=aLC_%%n, _or=aOR_%%n, _oc=aOC_%%n",^
		       "_cr=aCR_%%n, _cc=aCC_%%n",^
		       "_hit=1-(((((ux-aTX_%%n)*aSX_%%n)>>31&1)|aZX_%%n)&((((uy-aTY_%%n)*aSY_%%n)>>31&1)|aZY_%%n))",^
		       "_dr=sRow-_lr, _dc=sCol-_lc",^
		       "_dr-=((_dr-4)&((4-_dr)>>31)), _dr-=((_dr+4)&((_dr+4)>>31))",^
		       "_dc-=((_dc-7)&((7-_dc)>>31)), _dc-=((_dc+7)&((_dc+7)>>31))",^
		       "_si=(_dr+4)*15+(_dc+7), _mvd=(_dr|-_dr)|(_dc|-_dc), _mv=(_mvd|-_mvd)>>31&1"

		set "_seg=" & set "_dseg="
		if !_hit! equ 1 ( set "_det=1"
		) else if !_mv! equ 1 (
			for %%a in (!_si!) do (
				set "_dseg=%\e%[!_lr!;!_lc!H !segG_%%a!"
				set "_seg=!segG_%%a!"
			)
			set /a "_cr=sRow-_or, _cc=sCol-_oc+1, _lr=sRow, _lc=sCol"
		)

		set /a "aX_%%n=_ax, aY_%%n=_ay, aLR_%%n=_lr, aLC_%%n=_lc, aCR_%%n=_cr, aCC_%%n=_cc"

		if defined _det (
			set "aOn_%%n=0"
			set /a "_eo=aOC_%%n+1"
			set "out=!out!%\e%[m%\e%[!aOR_%%n!;!_eo!H!aGeo_%%n!"
			set "out=!out!%\e%[m%\e%[!aXR_%%n!;!aXC_%%n!H!xMark!"
			set "aGeo_%%n="
			set /a "abmLive-=1"
			set "fxBlast=1"
			for %%f in (!aFreeN!) do set /a "aFree_%%f=%%n"
			set /a "aFreeN+=1"
			if !eFreeN! gtr 0 (
				set /a "eFreeN-=1, ux=aTX_%%n, uy=aTY_%%n, %@u2c%"
				for %%f in (!eFreeN!) do set "es=!eFree_%%f!"
				for %%f in (!es!) do (
					set /a "eRow_%%f=sRow, eCol_%%f=sCol, eUX_%%f=ux, eUY_%%f=uy, eStep_%%f=1, eDir_%%f=1, eKil_%%f=0"
					set "eOn_%%f=1"
				)
				set /a "explLive+=1"
			)
		) else (
			set "out=!out!%\e%[!xCol!m%\e%[!aXR_%%n!;!aXC_%%n!H!xMark!%\e%[m"
			if defined _seg  set "aGeo_%%n=!aGeo_%%n!!_seg!"
			if defined _dseg set "out=!out!%\e%[!cAbm!m!_dseg!%\e%[m"
			set "out=!out!%\e%[!aLR_%%n!;!aLC_%%n!H%\e%[!flashBg!m %\e%[m"
		)
		)

		rem EXPLOSION STEP
		set /a "_g=tickNo%%%explFrames%"

		rem COLLISION
		if !explLive! gtr 0 (
		for %%x in (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19) do if !eOn_%%x! equ 1 if !eGrp_%%x! equ !_g! (

		if !flOn! equ 1 (
			set /a "_kx=flX-eUX_%%x, _ky=flY-eUY_%%x",^
			       "_k=(((_kx*_kx+_ky*_ky)-eStep_%%x*eStep_%%x)>>31)&1"
			if !_k! equ 1 (
				for %%y in (!flType!) do (
					set "out=!out!%\e%[m%\e%[!flRow!;!flCol!H!flG_%%y!"
					set /a "score+=flPts_%%y*wMult"
				)
				set /a "fliersKilled+=1"
				if !score! geq !nextBonus! set /a "banked+=1, nextBonus+=%bonusEvery%"
				set /a "flOn=0, flCool=wFlCool"
			)
		)

		for %%n in (0 1 2 3 4 5 6 7) do if !mOn_%%n! equ 1 (

			set /a "_ux=mX_%%n>>8, _uy=mY_%%n>>8, _kx=_ux-eUX_%%x, _ky=_uy-eUY_%%x",^
			       "_k=((((_kx*_kx+_ky*_ky)-eStep_%%x*eStep_%%x)>>31)&1)&(1-((_uy-%collFloor%)>>31&1))"

			if !_k! equ 0 if !mBomb_%%n! equ 1 (
				set /a "_bx=eUX_%%x-_ux, _by=eUY_%%x-_uy",^
				       "_sr=eStep_%%x+%bombSense%",^
				       "_near=((_bx*_bx+_by*_by-_sr*_sr)>>31)&1",^
				       "_cl=mIX_%%n*_bx+mIY_%%n*_by"
				if !_near! equ 1 if !_cl! gtr 0 (
					set /a "_tx=mTX_%%n-_ux, _ty=mTY_%%n-_uy",^
					       "_p1=(0-_by)*_tx+_bx*_ty, _p2=_by*_tx+(0-_bx)*_ty"
					if !_p1! geq !_p2! ( set /a "dx=0-_by, dy=_bx"
					) else               set /a "dx=_by, dy=0-_bx"
					set /a "%@approxDist%, %@step88%, mIX_%%n=ix, mIY_%%n=iy, mEva_%%n=1"
				)
			)

			if !_k! equ 1 (
				set /a "_eo=mOC_%%n+1"
				set "out=!out!%\e%[m%\e%[!mOR_%%n!;!_eo!H!mGeo_%%n!"
				set "mGeo_%%n=" & set "mOn_%%n=0"
				set /a "live-=1, killed+=1, score+=mPts_%%n*wMult, bombLive-=mBomb_%%n"
				set /a "eKil_%%x+=1, bombsKilled+=mBomb_%%n"
				if !mSpl_%%n! equ 0 if !_uy! geq %mirvLo% if !_uy! leq %mirvHi% set /a "mirvStops+=1"
				if !eKil_%%x! gtr !bestBlast! set /a "bestBlast=eKil_%%x"
				if !score! geq !nextBonus! set /a "banked+=1, nextBonus+=%bonusEvery%"
				if !mTT_%%n! equ 0 for %%z in (!mTI_%%n!) do set /a "cTgt_%%z-=1"
				for %%f in (!mFreeN!) do set /a "mFree_%%f=%%n"
				set /a "mFreeN+=1"

				set "fxBlast=1"
				if !eFreeN! gtr 0 (
					set /a "eFreeN-=1, ux=_ux, uy=_uy, %@u2c%"
					for %%f in (!eFreeN!) do set "es=!eFree_%%f!"
					for %%f in (!es!) do (
						set /a "eRow_%%f=sRow, eCol_%%f=sCol, eUX_%%f=ux, eUY_%%f=uy, eStep_%%f=1, eDir_%%f=1, eKil_%%f=0"
						set "eOn_%%f=1"
					)
					set /a "explLive+=1"
				)
			)
		)))

		for %%x in (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19) do (
		if !eOn_%%x! equ 1 if !eGrp_%%x! equ !_g! (

			if !eDir_%%x! equ 1 (
				set /a "eStep_%%x+=1"
				if !eStep_%%x! gtr %explRadius% set /a "eStep_%%x=%explRadius%, eDir_%%x=-1"
				if !fxFlash! equ 1 (
					for %%s in (!eStep_%%x!) do set "out=!out!%\e%[!eDrawC!m%\e%[!eRow_%%x!;!eCol_%%x!H!exFull_%%s!%\e%[m"
				) else (
					for %%s in (!eStep_%%x!) do set "out=!out!%\e%[!exCol_%%s!m%\e%[!eRow_%%x!;!eCol_%%x!H!exGeo_%%s!%\e%[m"
				)
			) else (
				for %%s in (!eStep_%%x!) do set "out=!out!%\e%[m%\e%[!eRow_%%x!;!eCol_%%x!H!exGeo_%%s!"
				set /a "eStep_%%x-=1"
				if !eStep_%%x! lss 1 (
					set "eOn_%%x=0"
					for %%f in (!eFreeN!) do set /a "eFree_%%f=%%x"
					set /a "eFreeN+=1, explLive-=1"
				)
			)
		))

		if defined out echo=!out!
		set "out="

		)

		rem AUDIO
		if defined fxBlast ( %@playFx:?=blast% & set "fxBlast=" )

		rem WAVE END
		set /a "ammoLeft=sAmmo_0+sAmmo_1+sAmmo_2, _busy=live+abmLive+explLive+flOn"
		if !spawned! geq !wIcbm! if !_busy! equ 0 set "waveDone=1"
		if !cLost! geq 3 if !ammoLeft! equ 0 if !abmLive! equ 0 set "waveDone=1"
		if defined waveDone %endwhile%

		rem FLUSH
		if defined out echo=!out!

		rem TITLE
		set /a "_ft=frameCount%%15"
		if !_ft! equ 0 title MISSILE COMMAND      wave !wave!      score !score!      cities !cityLeft!!demoTag!
	)
)

rem END OF WAVE
if defined waveDone if not defined gameOver (
	set /a "ammoLeft=sAmmo_0+sAmmo_1+sAmmo_2"
	set /a "_bA=ammoLeft*%ptAbmLeft%*wMult, _bC=cityLeft*%ptCityLeft%*wMult"
	set /a "_r=%gridRows%/2-3"

	set "out=%\e%[38;2;255;255;255m%\e%[!_r!;118HBONUS POINTS%\e%[m"
	echo=!out!
	ping -n 2 127.0.0.1 >nul

	set /a "_n=0"
	for /l %%q in (1,1,!ammoLeft!) do (
		set /a "_n+=1, score+=%ptAbmLeft%*wMult, _r2=_r+2"
		set "out=%\e%[!fAbm!m%\e%[!_r2!;114HABM  !_n! x %ptAbmLeft% x !wMult!   %\e%[m"
		echo=!out!
		%@playFx:?=bright_confirm%
		ping -n 1 -w 60 127.0.0.1 >nul
	)
	set /a "_n=0"
	for /l %%q in (1,1,!cityLeft!) do (
		set /a "_n+=1, score+=%ptCityLeft%*wMult, _r2=_r+4"
		set "out=%\e%[!fCity1!m%\e%[!_r2!;114HCITY !_n! x %ptCityLeft% x !wMult!   %\e%[m"
		echo=!out!
		%@playFx:?=bright_confirm%
		ping -n 1 -w 120 127.0.0.1 >nul
	)

	if !score! geq !nextBonus! set /a "banked+=1, nextBonus+=%bonusEvery%"

	set /a "_r3=_r+6"
	set "out=%\e%[38;2;255;255;255m%\e%[!_r3!;114HSCORE !score!    %\e%[m"
	echo=!out!
	ping -n 3 127.0.0.1 >nul

	if !cLost! equ 0 set /a "cleanWaves+=1"
	if !midUsed! equ 0 set /a "noMidWaves+=1"
	if !ammoLeft! equ !ammoFull! set /a "fullWaves+=1"
	set /a "midUsed=0"
	set /a "wave+=1"
	if !wave! geq %waveWrap% set /a "wave=%waveWrapTo%"
	goto :waveStart
)

rem GAME OVER
if defined gameOver (
	set /a "_r=%gridRows%/2"
	set "out=%\e%[m%\e%[2J"
	set "out=!out!%\e%[!bg_red!m%\e%[!_r!;120H                 %\e%[m"
	set "out=!out!%\e%[38;2;255;255;255m%\e%[!_r!;124HTHE END%\e%[m"
	echo=!out!
	ping -n 4 127.0.0.1 >nul
)

if defined attract (
	set "attract=" & set "attractEnd="
	if defined demoPlay ( set "demoPlay=" & goto :startRun )
	goto :newGame
)

if defined quitRun (
	set "quitRun=" & set "gameOver="
	goto :newGame
)

rem RESULTS
set "_best="
if !score! gtr !cfg_hiscore! ( set /a "cfg_hiscore=score" & set "_best=1" )
if !wave!  gtr !cfg_hiwave!    set /a "cfg_hiwave=wave"
set /a "cfg_plays+=1"
call init\mcStats fold
call init\mcCfg save

set /a "_r=%gridRows%/2-4"
set "out=%\e%[m%\e%[2J"
set "out=!out!%\e%[38;5;15m%\e%[!_r!;112HFINAL SCORE !score!%\e%[m"
set /a "_r2=_r+3, _r3=_r+5, _r4=_r+7, _r5=_r+11"
set "out=!out!%\e%[38;5;250m%\e%[!_r2!;108Hreached wave !wave!   !killed! of !spawnAll! intercepted%\e%[m"
set "out=!out!%\e%[38;5;244m%\e%[!_r3!;108H!fired! ABMs fired   !mirvs! MIRV warheads%\e%[m"
if defined _best set "out=!out!%\e%[38;2;255;200;80m%\e%[!_r4!;116HNEW BEST%\e%[m"
if defined newAch (
	set /a "_r6=_r4+2"
	set "out=!out!%\e%[38;2;255;200;80m%\e%[!_r6!;104HUNLOCKED:!newAch!%\e%[m"
)
set "out=!out!%\e%[38;5;250m%\e%[!_r5!;110Hclick to continue%\e%[m"
echo=!out!
%@playFx:?=bright_confirm%

set /a "%@saveLastClicks%"
%while% (
	%@radish%
	if "!L_click!!last_L_click!" equ "10" %endwhile%
	if defined keysPressed if not "!keysPressed!" == "!keysPressed:-27-=!" %endwhile%
	set /a "%@saveLastClicks%"
	ping -n 1 -w 30 127.0.0.1 >nul
)
%@playFx:?=hover_click%
goto :newGame

rem QUIT
:quitAll
<nul set /p "=%\e%[m%\e%[2J%\e%[H%\e%[?25h"
call init\mcCfg save
%@stopFx%
if defined radishPre (
	for /f "skip=1 tokens=2 delims=," %%p in ('tasklist /fi "imagename eq radish.exe" /fo csv 2^>nul') do (
		if "!radishPre!" equ "!radishPre:,%%~p,=!" >nul 2>nul taskkill /f /pid %%~p
	)
) else %endRadish%
exit

rem FONT
:Set_Font FontName FontSize max/nomax dummy
if "%4"=="" (
	for /f "tokens=1,2 delims=x" %%a in ("%~2") do (
		if "%%b"=="" (set /a "FontSize=%~2*65536"
		) else        set /a "FontSize=%%a+%%b*65536")
	reg add "HKCU\Console\%~nx0" /v FontSize /t reg_dword /d !FontSize! /f
	reg add "HKCU\Console\%~nx0" /v FaceName /t reg_sz /d "%~1" /f
	set "m=" & if /I "%~3"=="max" set "m=/max"
	set "_conhost="
	if exist "%SystemRoot%\System32\conhost.exe" set "_conhost=%SystemRoot%\System32\conhost.exe"
	if defined _conhost (
		start "%~nx0" !m! "!_conhost!" "%ComSpec%" /c "%~f0" _
	) else start "%~nx0" !m! "%ComSpec%" /c "%~f0" _
	exit /b 1
) else ( >nul reg delete "HKCU\Console\%~nx0" /f )
goto:eof
