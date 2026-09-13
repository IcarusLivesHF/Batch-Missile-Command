if /i "%~1" equ "oct"     goto :_buildOct
if /i "%~1" equ "disc"    goto :_buildDisc
if /i "%~1" neq "init"    exit /b 0

set "romW=256"
set "romH=231"
set "romTop=230"
set "gridCols=256"
set "gridRows=116"

set "@u2c=(sCol=ux+1, sRow=((230-uy)>>1)+1)"

set "@c2u=(ux=sCol-1, uy=230-((sRow-1)<<1))"

set "@dist2=(dx=ax-bx, dy=ay-by, d2=dx*dx+dy*dy)"

set "@approxDist=(ax_=(dx>>31|1)*dx, ay_=(dy>>31|1)*dy, hi=ax_-((ax_-ay_)&((ax_-ay_)>>31)), lo=ay_+((ax_-ay_)&((ax_-ay_)>>31)), ad=hi+(lo>>1), ad-=((ad-255)&((255-ad)>>31)), ad+=((ad-1)>>31&1)*(1-ad))"

set "@step88=(ix=(dx<<8)/ad, iy=(dy<<8)/ad)"

if not defined \e (
	echo=geom init: \e is not defined -- call lib\atlas first.
	exit /b 1
)
for /l %%d in (-32,1,32) do (
	set /a "_i=%%d+32"
	set /a "_a=_i-32"
	set /a "_a=(_a>>31|1)*_a"
	if %%d lss 0 (
		set "mvR_!_i!=%\e%[!_a!A"
		set "mvC_!_i!=%\e%[!_a!D"
	) else if %%d gtr 0 (
		set "mvR_!_i!=%\e%[!_a!B"
		set "mvC_!_i!=%\e%[!_a!C"
	) else (
		set "mvR_!_i!="
		set "mvC_!_i!="
	)
)
set "mvBias=32"

for /l %%r in (-4,1,4) do (
	for /l %%c in (-4,1,4) do (
		set /a "_i=(%%r+4)*9+(%%c+4), _ir=%%r+32, _ic=%%c+32"
		for /f "tokens=1,2" %%a in ("!_ir! !_ic!") do set "mvRC_!_i!=!mvR_%%a!!mvC_%%b!"
	)
)
set "mvRCBias=4"
set "mvRCStride=9"

for /l %%r in (-4,1,4) do (
	for /l %%c in (-7,1,7) do (
		set /a "_sr=%%r, _sc=%%c, _si=(%%r+4)*15+(%%c+7)"
		set /a "_ar=(_sr>>31|1)*_sr, _ac=(_sc>>31|1)*_sc"
		set /a "_sn=_ar-((_ar-_ac)&((_ar-_ac)>>31))"
		set "_sbuf="
		set /a "_pr=0, _pc=0"
		if !_sn! gtr 0 for /l %%k in (1,1,7) do if %%k leq !_sn! (
			set /a "_qr=(_sr*%%k)/_sn, _qc=(_sc*%%k)/_sn"
			set /a "_mi=(_qr-_pr+4)*9+(_qc-_pc-1+4)"
			for %%a in (!_mi!) do set "_sbuf=!_sbuf!!mvRC_%%a! "
			set /a "_pr=_qr, _pc=_qc"
		)
		set "segG_!_si!=!_sbuf!"
	)
)
set "segBiasR=4"
set "segBiasC=7"
set "segStride=15"
for %%v in (_sr _sc _si _ar _ac _sn _sbuf _pr _pc _qr _qc _mi) do set "%%v="

for /l %%d in (0,1,64) do ( set "mvR_%%d=" & set "mvC_%%d=" )
set "_i=" & set "_a=" & set "_ir=" & set "_ic="
set "_i=" & set "_a="
exit /b 0

rem =====================================================================
:_buildOct

set "_oPfx=%~2"
set /a "_oMax=%~3"

if not defined _oPfx set "_oMax=0"
if !_oMax! lss 1 (
	echo=geom oct: bad arguments -- prefix "%~2" radius "%~3"
	echo=         usage:  call lib\geom oct ^<prefix^> ^<rMax^>
	exit /b 1
)
if not defined \e (
	echo=geom oct: \e is not defined -- call lib\atlas first.
	exit /b 1
)

set "_oS="
for /l %%n in (0,1,80) do (
	set "_oSpc_%%n=!_oS!"
	set "_oS=!_oS! "
)

set /a "_oTotal=0"

for /l %%k in (1,1,%_oMax%) do (
	set /a "_oK=%%k"
	set /a "_oKP=%%k-1"
	set /a "_oRN=%%k/2"
	set /a "_oRO=(%%k-1)/2"
	set /a "_oCurR=0"
	set /a "_oCurC=0"
	set /a "_oCnt=0"
	set "_oBuf="

	for /l %%j in (0,1,%_oMax%) do (
		set /a "_oDr=%%j-_oRN"
		if !_oDr! leq !_oRN! (
			set /a "_oA=(_oDr>>31|1)*_oDr"
			set /a "_oY=_oA*2"

			set /a "_oW1=_oK-(3*_oY+4)/8"
			set /a "_oW2=(8*(_oK-_oY)+1)/3"
			set /a "_oWN=_oW2+((((_oY*11-8*_oK)-1)>>31)&1)*(_oW1-_oW2)"

			set /a "_oV1=_oKP-(3*_oY+4)/8"
			set /a "_oV2=(8*(_oKP-_oY)+1)/3"
			set /a "_oWO=_oV2+((((_oY*11-8*_oKP)-1)>>31)&1)*(_oV1-_oV2)"

			set /a "_oNew=(((_oRO-_oA)>>31)&1)|(((_oK-2)>>31)&1)"
			set /a "_oWO=_oWO*(1-_oNew)-_oNew"
			set /a "_oG=_oWN-_oWO"

			if !_oG! gtr 0 (
				for %%p in (1 2) do (
					if "%%p"=="1" (
						set /a "_oC=0-_oWN"
					) else (
						set /a "_oC=_oWO+1"
					)
					set /a "_oMR=_oDr-_oCurR"
					set /a "_oMC=_oC-_oCurC"
					set /a "_oAR=(_oMR>>31|1)*_oMR"
					set /a "_oAC=(_oMC>>31|1)*_oMC"
					set "_oMV="
					if !_oMR! lss 0 set "_oMV=%\e%[!_oAR!A"
					if !_oMR! gtr 0 set "_oMV=%\e%[!_oAR!B"
					if !_oMC! lss 0 set "_oMV=!_oMV!%\e%[!_oAC!D"
					if !_oMC! gtr 0 set "_oMV=!_oMV!%\e%[!_oAC!C"
					for %%n in (!_oG!) do set "_oBuf=!_oBuf!!_oMV!!_oSpc_%%n!"
					set /a "_oCurR=_oDr"
					set /a "_oCurC=_oC+_oG"
					set /a "_oCnt+=1"
				)
			)
		)
	)

	for %%n in (!_oCnt!) do set /a "_oTotal+=%%n"
	set "!_oPfx!Geo_%%k=!_oBuf!"
)

for %%n in (!_oMax!) do if not defined !_oPfx!Geo_%%n (
	echo=geom oct: built nothing for "!_oPfx!Geo_%%n" -- !_oTotal! runs emitted overall.
	exit /b 1
)

set "_oS=" & set "_oPfx=" & set "_oTotal=" & set "_oCnt="
for %%v in (_oMax _oK _oKP _oRN _oRO _oCurR _oCurC _oBuf _oDr _oA _oY
            _oW1 _oW2 _oWN _oV1 _oV2 _oWO _oNew _oG _oC
            _oMR _oMC _oAR _oAC _oMV) do set "%%v="
for /l %%n in (0,1,80) do set "_oSpc_%%n="
exit /b 0

rem =====================================================================
:_buildDisc

set "_dPfx=%~2"
set /a "_dMax=%~3"

if not defined _dPfx set "_dMax=0"

set "_dS="
for /l %%n in (0,1,80) do (
	set "_dSpc_%%n=!_dS!"
	set "_dS=!_dS! "
)

for /l %%k in (1,1,%_dMax%) do (
	set /a "_dK=%%k"
	set /a "_dRN=%%k/2"
	set /a "_dCurR=0"
	set /a "_dCurC=0"
	set "_dBuf="

	for /l %%j in (0,1,%_dMax%) do (
		set /a "_dDr=%%j-_dRN"
		if !_dDr! leq !_dRN! (
			set /a "_dA=(_dDr>>31|1)*_dDr"
			set /a "_dY=_dA*2"
			set /a "_dW1=_dK-(3*_dY+4)/8"
			set /a "_dW2=(8*(_dK-_dY)+1)/3"
			set /a "_dW=_dW2+((((_dY*11-8*_dK)-1)>>31)&1)*(_dW1-_dW2)"
			set /a "_dN=2*_dW+1"
			set /a "_dC=0-_dW"
			set /a "_dMR=_dDr-_dCurR"
			set /a "_dMC=_dC-_dCurC"
			set /a "_dAR=(_dMR>>31|1)*_dMR"
			set /a "_dAC=(_dMC>>31|1)*_dMC"
			set "_dMV="
			if !_dMR! lss 0 set "_dMV=%\e%[!_dAR!A"
			if !_dMR! gtr 0 set "_dMV=%\e%[!_dAR!B"
			if !_dMC! lss 0 set "_dMV=!_dMV!%\e%[!_dAC!D"
			if !_dMC! gtr 0 set "_dMV=!_dMV!%\e%[!_dAC!C"
			for %%n in (!_dN!) do set "_dBuf=!_dBuf!!_dMV!!_dSpc_%%n!"
			set /a "_dCurR=_dDr"
			set /a "_dCurC=_dC+_dN"
		)
	)

	set "!_dPfx!Full_%%k=!_dBuf!"
)

for %%n in (!_dMax!) do if not defined !_dPfx!Full_%%n (
	echo=geom disc: built nothing for "!_dPfx!Full_%%n".
	exit /b 1
)

set "_dS=" & set "_dPfx="
for %%v in (_dMax _dK _dRN _dCurR _dCurC _dBuf _dDr _dA _dY _dW1 _dW2 _dW
            _dN _dC _dMR _dMC _dAR _dAC _dMV) do set "%%v="
for /l %%n in (0,1,80) do set "_dSpc_%%n="
exit /b 0
