@echo off
setlocal enableextensions
setlocal enabledelayedexpansion
set "appname=Test RPG"
set "appdate=April 9, 2022"
set "appver=0.10.3-alpha"
::
::0.11.0 added code for different map tiles
::0.10.3 code optimization
::0.10.2 fixed pos detection
::0.10.1 tweaked world load code
::0.10.0 added map editor
::0.9.1 moved player hud based on new map
::0.9.0 new map engine / world definition
::
:init
title %appname% v%appver% - %appdate%
set rpg.init=true
for /f "delims=^=" %%i in ('set rpg.') do set %%i=
set "rpg.hud.color=color 07"
set /a "rpg.hud.cols=142"
set /a "rpg.hud.rows=36"
mode con cols=%rpg.hud.cols% lines=%rpg.hud.rows%
set /a "rpg.hud.lines=rpg.hud.rows-2"
set /a "rpg.hud.left=39"
set /a "rpg.hud.right=rpg.hud.cols-rpg.hud.left-5"
set /a "rpg.hud.barsize=(rpg.hud.left+1)/2"
set /a "rpg.inv.nullitem=0"
set /a "rpg.delay=3"
set "rpg.hud.adminkeys=GHKXVM"
set "rpg.hud.mapkeys=CLT"
set "rpg.hud.keys=WSADQERUI%rpg.hud.adminkeys%"
for /l %%b in (1,1,%rpg.hud.barsize%) do set "rpg.hud.bar=/!rpg.hud.bar!-"
for /l %%s in (1,1,%rpg.hud.left%) do set "rpg.hud.spacer=!rpg.hud.spacer! "
for /l %%f in (1,2,%rpg.hud.right%) do set "rpg.hud.filler=!rpg.hud.filler!.:"
for /l %%m in (1,1,200) do set /a "rpg.hud.xpm%%m=25*%%m*(%%m-1), rpg.hud.xpx%%m=25*%%m*(%%m+1)"

:load
for /f "delims=" %%m in (enemies.dat) do set "rpg.enemy.%%m"
for /f "delims=" %%e in (items.dat) do set "rpg.item.%%e"
for /f "delims=" %%w in (world.dat) do set "%%~w"

::look for saved game or create new
if exist user.sav (for /f "delims=" %%u in (user.sav) do set "%%u") else goto :create

:loop

:findlevel
::
if defined rpg.user.xpmax if %rpg.user.xp% LSS %rpg.user.xpmax% if %rpg.user.xp% GEQ %rpg.user.xpmin% goto :findlevelxp
set "rpg.user.level="
for /l %%l in (200,-1,1) do if defined rpg.user.level (goto :findlevelxp) else (if %rpg.user.xp% GEQ !rpg.hud.xpm%%l! set /a "rpg.user.level=%%l")

:findlevelxp
::calc XPMAX=25*L*(L+1) XPMIN=25*L*(L-1)
set /a "rpg.user.xpmax=rpg.hud.xpx%rpg.user.level%, rpg.user.xpmin=rpg.hud.xpm%rpg.user.level%"
set /a "rpg.user.xpcur=rpg.user.xp-rpg.user.xpmin"
set /a "rpg.user.xplev=rpg.user.xpmax-rpg.user.xpmin"

::calc STR=10+L/5 
if %rpg.user.class%==Warrior (set /a "rpg.user.str=10+rpg.user.level/5") else (set /a "rpg.user.str=10")

::calc CON=10+L/5
if %rpg.user.class%==Warrior (set /a "rpg.user.con=10+rpg.user.level/5") else (set /a "rpg.user.con=10")

::set other stats
set /a "rpg.user.dex=10"

::calc HPMAX=CON*20+L*50
set /a "rpg.user.hpmax=rpg.user.con*20+rpg.user.level*50"
if %rpg.user.hp% GTR %rpg.user.hpmax% set /a "rpg.user.hp=rpg.user.hpmax"

::calc PWMAX=DEX*15+L*25
set /a "rpg.user.pwmax=rpg.user.dex*15+rpg.user.level*25"
if %rpg.user.pw% GTR %rpg.user.pwmax% set /a "rpg.user.pw=rpg.user.pwmax"

::calc ARM=SUM(.arm)+L/10
set /a "rpg.user.arm=0+rpg.item.%rpg.user.head%.arm+rpg.item.%rpg.user.torso%.arm"
set /a "rpg.user.arm+=rpg.item.%rpg.user.arms%.arm+rpg.item.%rpg.user.legs%.arm"
set /a "rpg.user.arm+=rpg.item.%rpg.user.feet%.arm+rpg.user.level/10"

::calc DPS=weapon.dps
set /a "rpg.user.dps=0+rpg.item.%rpg.user.weapon%.dps"

::calculate bars
call :barcalc hpbar %rpg.user.hp% %rpg.user.hpmax%
call :barcalc pwbar %rpg.user.pw% %rpg.user.pwmax%
call :barcalc xpbar %rpg.user.xpcur% %rpg.user.xplev%
if %rpg.user.status%==fight call :barcalc foebar %rpg.enemy.hp% %rpg.enemy.hpmax%

::clear hud lines exept map
set /a "rpg.hud.clear=rpg.map.height+1"
for /l %%l in (%rpg.hud.clear%,1,%rpg.hud.lines%) do set "rpg.hud.l%%l="
set "rpg.hud.invkeys="

::define position
set "rpg.user.pos=x%rpg.user.x%y%rpg.user.y%"
set "rpg.map.height=11"
if not defined rpg.map.edit set "rpg.map.edit=off"

::print new location if moved
if not defined rpg.hud.input set "rpg.hud.input=W"
for %%d in (W,S,A,D) do if [%rpg.hud.input%]==[%%d] if %rpg.map.edit%==on (
	call :addline X:%rpg.user.x% Y:%rpg.user.y% Name: !rpg.world.%rpg.user.pos%.name!
	call :addline Job: !rpg.world.%rpg.user.pos%.job! Type: !rpg.world.%rpg.user.pos%.type! Enc: !rpg.world.%rpg.user.pos%.enc!
	call :addline Desc: !rpg.world.%rpg.user.pos%.desc!
	call :addline
	set "rpg.map.update=yes"
) else (
	if defined rpg.world.%rpg.user.pos%.desc call :addline "!rpg.world.%rpg.user.pos%.desc!"
	call :addline Location: !rpg.world.%rpg.user.pos%.name!
	call :addline Directions: %rpg.hud.mov%
	call :addline
	if defined rpg.world.%rpg.user.pos%.job (set "rpg.hud.inventory=open" & set "rpg.hud.equipment=closed") else (set "rpg.hud.inventory=closed" & set "rpg.hud.equipment=closed")
	set "rpg.map.update=yes"
)

::map update
if defined rpg.map.update (
	set /a "rpg.hud.l=1"
	set /a "rpg.map.ymin=rpg.user.y-(rpg.map.height-1)/2, rpg.map.ymax=rpg.user.y+(rpg.map.height-1)/2"
	set /a "rpg.map.xmin=rpg.user.x-6, rpg.map.xmax=rpg.user.x+6"
	for /l %%y in (!rpg.map.ymax!,-1,!rpg.map.ymin!) do (
		set "rpg.map.line="
		for /l %%x in (!rpg.map.xmin!,1,!rpg.map.xmax!) do (
			if defined rpg.world.x%%xy%%y.name (set "rpg.map.tile=[_]") else (set "rpg.map.tile=-.-")
			if defined rpg.world.x%%xy%%y.job set "rpg.map.tile=[$]"
			if defined rpg.world.x%%xy%%y.enc set "rpg.map.tile=[^!]"
			if defined rpg.world.x%%xy%%y.type (
				if !rpg.world.x%%xy%%y.type!==water 	set "rpg.map.tile=~~~"
				if !rpg.world.x%%xy%%y.type!==grass 	set "rpg.map.tile=wWw"
				if !rpg.world.x%%xy%%y.type!==forest 	set "rpg.map.tile=\V/"
				if !rpg.world.x%%xy%%y.type!==mountain 	set "rpg.map.tile=/Y\"
				if !rpg.world.x%%xy%%y.type!==woman 	set "rpg.map.tile=\@/"
			)
			if x%%xy%%y==%rpg.user.pos% if defined rpg.world.x%%xy%%y.name (set "rpg.map.tile=[o]") else (set "rpg.map.tile=\o/")
			set "rpg.map.line=!rpg.map.line!!rpg.map.tile!"
		)
		set "rpg.hud.l!rpg.hud.l!=!rpg.map.line!"
		set /a "rpg.hud.l+=1"
	)
)
set "rpg.map.update="

::set hud directions
set rpg.hud.mov=
set /a "rpg.map.n=rpg.user.y+1, rpg.map.s=rpg.user.y-1, rpg.map.w=rpg.user.x-1, rpg.map.e=rpg.user.x+1"
if defined rpg.world.x%rpg.user.x%y%rpg.map.n%.name set "rpg.hud.mov=!rpg.hud.mov![N] !rpg.world.x%rpg.user.x%y%rpg.map.n%.name! "
if defined rpg.world.x%rpg.user.x%y%rpg.map.s%.name set "rpg.hud.mov=!rpg.hud.mov![S] !rpg.world.x%rpg.user.x%y%rpg.map.s%.name! "
if defined rpg.world.x%rpg.map.w%y%rpg.user.y%.name set "rpg.hud.mov=!rpg.hud.mov![W] !rpg.world.x%rpg.map.w%y%rpg.user.y%.name! "
if defined rpg.world.x%rpg.map.e%y%rpg.user.y%.name set "rpg.hud.mov=!rpg.hud.mov![E] !rpg.world.x%rpg.map.e%y%rpg.user.y%.name! "
)

::set controls description
set "rpg.hud.cont= [U] Equipment [I] Inventory"
set "rpg.hud.cont2= [Q] Quit"
if %rpg.user.status%==fight (set "rpg.hud.cont2=%rpg.hud.cont2% [E] Fight") else (set "rpg.hud.cont2=%rpg.hud.cont2% [E] Wait")

::set hud info
set "rpg.hud.l12=!rpg.world.%rpg.user.pos%.name! (%rpg.user.x%,%rpg.user.y%) Gold: %rpg.user.gold% \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\"
if %rpg.map.edit%==on set "rpg.hud.l12=*Editing* %rpg.hud.l12%"
set "rpg.hud.l14=Str:%rpg.user.str% Con:%rpg.user.con% Dex:%rpg.user.dex% Arm:%rpg.user.arm% Dps:%rpg.user.dps%"

::set player/enemy hud (this is skipped if inventory or equipment are open)
if "%rpg.hud.inventory%"=="open" goto :hudinventoryopen
if "%rpg.hud.equipment%"=="open" goto :hudequipmentopen
set "rpg.hud.l16=%rpg.user.name%, %rpg.user.class% [%rpg.user.level%]"
set "rpg.hud.l17= HP %rpg.hud.hpbar% %rpg.user.hp%/%rpg.user.hpmax%"
set "rpg.hud.l18= PW %rpg.hud.pwbar% %rpg.user.pw%/%rpg.user.pwmax%"
set "rpg.hud.l19= XP %rpg.hud.xpbar% %rpg.user.xp%/%rpg.user.xpmax%"
if %rpg.user.status%==fight set "rpg.hud.l21=%rpg.enemy.name% [%rpg.enemy.level%]"
if %rpg.user.status%==fight set "rpg.hud.l22= HP %rpg.hud.foebar% %rpg.enemy.hp%/%rpg.enemy.hpmax%"

::set interface (this is skipped if inventory is NOT open)
if not "%rpg.hud.inventory%"=="open" goto :hudinventoryclosed
:hudinventoryopen

::set actions based on job type
set "rpg.hud.l16=Inventory:" & set "rpg.hud.invaction=Use"
if defined rpg.world.%rpg.user.pos%.job (
	set "rpg.hud.l16=Choose an item to buy:" & set "rpg.hud.invaction=Buy"
	if !rpg.world.%rpg.user.pos%.job!==merchant set "rpg.hud.l16=Choose an item to sell:" & set "rpg.hud.invaction=Sell"
)

::set item list
if defined rpg.hud.inv[1] for /f "delims=^=" %%c in ('set rpg.hud.inv[') do set %%c=
set /a "rpg.hud.invslot=0"
set "rpg.hud.invtype=owned"
if defined rpg.world.%rpg.user.pos%.job if not !rpg.world.%rpg.user.pos%.job!==merchant set "rpg.hud.invtype=shop"
::list owned items
if %rpg.hud.invtype%==owned (
	for /f "tokens=3-4 delims=.^=" %%k in ('set rpg.inv.') do (
		::item=%%k quantity=%%l
		if %%l GEQ 1 set /a "rpg.hud.invslot+=1"
		if %%l GEQ 1 set "rpg.hud.inv[!rpg.hud.invslot!]=%%k"
	)
) else (
	if !rpg.world.%rpg.user.pos%.job!==weaponsm set "rpg.hud.invslots=weapon"
	if !rpg.world.%rpg.user.pos%.job!==armorsm set "rpg.hud.invslots=head torso arms belt legs feet shield"
	if !rpg.world.%rpg.user.pos%.job!==tavern set "rpg.hud.invslots="
	::list shop items based on slot
	for /f "tokens=3-5 delims=.^=" %%k in ('set rpg.item.') do (
		::item=%%k property=%%l value=%%m
		for %%s in (!rpg.hud.invslots!) do (
			if %%l==slot if %%m==%%s set /a "rpg.hud.invslot+=1" 
			if %%l==slot if %%m==%%s set "rpg.hud.inv[!rpg.hud.invslot!]=%%k"
		)
	)
)

::set page number
if not defined rpg.hud.invpage set rpg.hud.invpage=1
set /a "rpg.hud.invpages=1+(rpg.hud.invslot-1)/10"
if !rpg.hud.invpage! GTR %rpg.hud.invpages% set /a "rpg.hud.invpage=1"

::set inventory list and pages
set /a "rpg.hud.invmin=1+10*(rpg.hud.invpage-1)"
set /a "rpg.hud.invmax=rpg.hud.invmin+9"
for /l %%l in (%rpg.hud.invmin%,1,%rpg.hud.invmax%) do (
	set /a "rpg.hud.invfirstline=17 , rpg.hud.invlastline=rpg.hud.invfirstline+9"
	set /a "rpg.hud.invslot=%%l , rpg.hud.invline=%%l+rpg.hud.invfirstline-1"
	::tweak inventory line to be used on next page
	if !rpg.hud.invline! GTR !rpg.hud.invlastline! set /a "rpg.hud.invline-=10*(rpg.hud.invpage-1)"
	::set item bonuses for description
	if %rpg.hud.invaction%==Sell set /a "rpg.hud.bonus=rpg.item.!rpg.hud.inv[%%l]!.val*75/100" & set rpg.hud.bonus=!rpg.hud.bonus!g
	if %rpg.hud.invaction%==Buy set /a "rpg.hud.bonus=rpg.item.!rpg.hud.inv[%%l]!.val*125/100" & set rpg.hud.bonus=!rpg.hud.bonus!g
	if %rpg.hud.invaction%==Use for %%b in (arm dps str con dex hp pw) do (
		if defined rpg.item.!rpg.hud.inv[%%l]!.%%b call set "rpg.hud.bonus=+%%rpg.item.!rpg.hud.inv[%%l]!.%%b%% %%b"
	)
	::set hud line if item is set
	if defined rpg.hud.inv[%%l] (
		::set slot and name first
		call set "rpg.hud.l!rpg.hud.invline!= [!rpg.hud.invslot:~-1!] %%rpg.item.!rpg.hud.inv[%%l]!.name%%"
		if %rpg.hud.invaction%==Buy (
			::add buying details
			call set "rpg.hud.l!rpg.hud.invline!=%%rpg.hud.l!rpg.hud.invline!%% (+%%rpg.item.!rpg.hud.inv[%%l]!.arm%%%%rpg.item.!rpg.hud.inv[%%l]!.dps%%) !rpg.hud.bonus!"
		) else (
			::add selling details
			call set "rpg.hud.l!rpg.hud.invline!=%%rpg.hud.l!rpg.hud.invline!%% (%%rpg.inv.!rpg.hud.inv[%%l]!%%) !rpg.hud.bonus!"
		)
		::add invenory key to choose
		set "rpg.hud.invkeys=!rpg.hud.invkeys!!rpg.hud.invslot:~-1!"
	)
)

::set inventory controls
set "rpg.hud.cont2=%rpg.hud.cont2% [0-9] %rpg.hud.invaction%"

::set page indicators
if %rpg.hud.invpages% GTR 1 (
	set "rpg.hud.invbar="
	for /l %%p in (1,1,%rpg.hud.invpages%) do if %rpg.hud.invpage% EQU %%p (set "rpg.hud.invbar=!rpg.hud.invbar!#") else (set "rpg.hud.invbar=!rpg.hud.invbar!-")
	set "rpg.hud.l28= Page %rpg.hud.invpage% of %rpg.hud.invpages%"
	set "rpg.hud.l29= [!rpg.hud.invbar!]"
	set "rpg.hud.invkeys=%rpg.hud.invkeys%P"
	set "rpg.hud.cont2=%rpg.hud.cont2% [P] Page"
	)

::set equipment (this is skipped if equipment is NOT open)
if not "%rpg.hud.equipment%"=="open" goto :hudequipmentclosed
:hudequipmentopen
set "rpg.hud.l16=Equipment:"
if defined rpg.user.head set "rpg.hud.l17= Head [1] !rpg.item.%rpg.user.head%.name! (+!rpg.item.%rpg.user.head%.arm!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%1" & set "rpg.hud.unequip[1]=head"
if defined rpg.user.torso set "rpg.hud.l18= Torso [2] !rpg.item.%rpg.user.torso%.name! (+!rpg.item.%rpg.user.torso%.arm!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%2" & set "rpg.hud.unequip[2]=torso"
if defined rpg.user.arms set "rpg.hud.l19= Arms [3] !rpg.item.%rpg.user.arms%.name! (+!rpg.item.%rpg.user.arms%.arm!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%3" & set "rpg.hud.unequip[3]=arms"
if defined rpg.user.legs set "rpg.hud.l20= Legs [4] !rpg.item.%rpg.user.legs%.name! (+!rpg.item.%rpg.user.legs%.arm!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%4" & set "rpg.hud.unequip[4]=legs"
if defined rpg.user.feet set "rpg.hud.l21= Feet [5] !rpg.item.%rpg.user.feet%.name! (+!rpg.item.%rpg.user.feet%.arm!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%5" & set "rpg.hud.unequip[5]=feet"
if defined rpg.user.neck set "rpg.hud.l23= Legs [6] !rpg.item.%rpg.user.neck%.name! (+!rpg.item.%rpg.user.neck%.val!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%6" & set "rpg.hud.unequip[6]=neck"
if defined rpg.user.jewel set "rpg.hud.l24= Jewel [7] !rpg.item.%rpg.user.jewel%.name! (+!rpg.item.%rpg.user.jewel%.val!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%7" & set "rpg.hud.unequip[7]=jewel"
if defined rpg.user.belt set "rpg.hud.l25= Belt [8] !rpg.item.%rpg.user.belt%.name! (+!rpg.item.%rpg.user.belt%.val!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%8" & set "rpg.hud.unequip[8]=belt"
if defined rpg.user.weapon set "rpg.hud.l27= Weapon [9] !rpg.item.%rpg.user.weapon%.name! (+!rpg.item.%rpg.user.weapon%.dps!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%9" & set "rpg.hud.unequip[9]=weapon"
if defined rpg.user.shield set "rpg.hud.l28= Shield [0] !rpg.item.%rpg.user.shield%.name! (+!rpg.item.%rpg.user.shield%.arm!)" & set "rpg.hud.invkeys=%rpg.hud.invkeys%0" & set "rpg.hud.unequip[0]=shield"
set "rpg.hud.cont2=%rpg.hud.cont2% [0-9] Unequip"

::set general controls
:hudinventoryclosed
:hudequipmentclosed
set "rpg.hud.l31=Controls:"
set "rpg.hud.l32=%rpg.hud.cont:~0,40%"
set "rpg.hud.l33=%rpg.hud.cont2:~0,40%"

::fill hud rows
for /l %%l in (1,1,%rpg.hud.lines%) do set "rpg.hud.l%%l=!rpg.hud.l%%l!%rpg.hud.spacer%"
for /l %%l in (1,1,%rpg.hud.lines%) do if not defined rpg.hud.r%%l set "rpg.hud.r%%l=%rpg.hud.filler%"

::print screen
:display
%rpg.hud.color%
cls
for /l %%l in (1,1,%rpg.hud.lines%) do echo  !rpg.hud.l%%l:~0,%rpg.hud.left%! # !rpg.hud.r%%l:~0,%rpg.hud.right%!

::set map controls
set "rpg.hud.choice=%rpg.hud.keys%%rpg.hud.invkeys%"
if "%rpg.map.edit%"=="on" (
	set "rpg.hud.choice=%rpg.hud.choice%%rpg.hud.mapkeys%"
) else (
	::remove unset directions
	if not defined rpg.world.x%rpg.user.x%y%rpg.map.n%.name set "rpg.hud.choice=!rpg.hud.choice:W=!"
	if not defined rpg.world.x%rpg.user.x%y%rpg.map.s%.name set "rpg.hud.choice=!rpg.hud.choice:S=!"
	if not defined rpg.world.x%rpg.map.w%y%rpg.user.y%.name set "rpg.hud.choice=!rpg.hud.choice:A=!"
	if not defined rpg.world.x%rpg.map.e%y%rpg.user.y%.name set "rpg.hud.choice=!rpg.hud.choice:D=!"
)

::get total execution time
if defined rpg.time set /a "rpg.time+=1%time:~-10,1%%time:~-8,2%%time:~-5,2%%time:~-2,2%"
set "rpg.hud.message=Tick (%rpg.time%0ms)%rpg.hud.spacer%"

::choice
choice /n /c %rpg.hud.choice% /d E /t %rpg.delay% /m "!rpg.hud.message:~0,%rpg.hud.left%!  #"

::parse player input
set /a "rpg.hud.input=%errorlevel%-1"
set "rpg.hud.input=!rpg.hud.choice:~%rpg.hud.input%,1!"
set "rpg.hud.action=loop"
if [%rpg.hud.input%]==[W] set /a "rpg.user.y+=1"
if [%rpg.hud.input%]==[S] set /a "rpg.user.y-=1"
if [%rpg.hud.input%]==[A] set /a "rpg.user.x-=1"
if [%rpg.hud.input%]==[D] set /a "rpg.user.x+=1"
if [%rpg.hud.input%]==[Q] set "rpg.hud.action=quit"
if [%rpg.hud.input%]==[E] if defined rpg.world.%rpg.user.pos%.enc (set "rpg.hud.action=engage") else (set "rpg.hud.action=wait")
if [%rpg.hud.input%]==[R] set "rpg.hud.action=init"
if [%rpg.hud.input%]==[U] set "rpg.hud.action=equipment"
if [%rpg.hud.input%]==[I] set "rpg.hud.action=inventory"
if [%rpg.hud.input%]==[P] if "%rpg.hud.inventory%"=="open" set /a "rpg.hud.invpage+=1"
if [%rpg.hud.input%]==[G] set /p rpg.give="Give item:" & if defined rpg.item.!rpg.give!.name set /a "rpg.inv.!rpg.give!+=1"
if [%rpg.hud.input%]==[H] set /p rpg.user.hp="New hp (%rpg.user.hp%):"
if [%rpg.hud.input%]==[K] set "rpg.enemy.hp=0"
if [%rpg.hud.input%]==[X] set /p rpg.user.xp="New XP (%rpg.user.xp%)"
if [%rpg.hud.input%]==[V] set /p rpg.delay="New delay (%rpg.delay%):" & if !rpg.delay! LSS 1 set "rpg.delay=1"
if [%rpg.hud.input%]==[M] if %rpg.map.edit%==on (set "rpg.map.edit=off") else (set "rpg.map.edit=on" & call :addline Map editor: [L] List enemies [T] Edit/Add [C] Save map)
if [%rpg.hud.input%]==[C] set rpg.world > world.dat
if [%rpg.hud.input%]==[L] for /f "tokens=3-5 delims=.^=" %%e in ('set rpg.enemy') do if %%f==name call :addline Lev: !rpg.enemy.%%e.max! %%e (!rpg.enemy.%%e.name!)
if [%rpg.hud.input%]==[T] set "rpg.hud.action=maptune"
if [%rpg.hud.input%]==[1] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[2] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[3] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[4] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[5] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[6] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[7] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[8] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[9] set "rpg.hud.action=use"
if [%rpg.hud.input%]==[0] set /a "rpg.hud.input=10" & set "rpg.hud.action=use"

::start new timer
set /a "rpg.time=-1%time:~-10,1%%time:~-8,2%%time:~-5,2%%time:~-2,2%"

goto :%rpg.hud.action%
goto :eof

:: #################################### ACTIONS ##########################################::

::Character creation.... here!
:create
cls
set /p "rpg.user.name=Enter you name:"
set "rpg.user.class=Warrior"
set /a "rpg.user.xp=0, rpg.user.hp=1, rpg.user.gold=0, rpg.user.pw=0"
set /a "rpg.user.x=0, rpg.user.y=0"
set "rpg.user.status=idle"
goto:loop

::Saving user and whatelse?
:quit
cls
set rpg.user > user.sav
set rpg.inv. >> user.sav
echo %date% %time% > debug.log
set rpg. >> debug.log
goto :eof

::pick random enemy (this is skipped if user is already in fight)
:engage
if defined rpg.enemy.id goto :fight
::chance to fight is 1 over 8
set /a "rpg.enemy.chance=8"
set /a "rpg.enemy.rnd=%random% %%rpg.enemy.chance"
if %rpg.enemy.rnd% GTR 0 goto :wait
::fight is on
set "rpg.user.status=fight"
::pick rnd enemy
set /a rpg.enemy.count=0
for %%e in (!rpg.world.%rpg.user.pos%.enc!) do (
	set rpg.enemy.id!rpg.enemy.count!=%%e
	set /a rpg.enemy.count+=1
	)
set /a "rpg.enemy.rnd=%random% %%rpg.enemy.count"
::set enemy id
set "rpg.enemy.id=!rpg.enemy.id%rpg.enemy.rnd%!"
set "rpg.enemy.name=!rpg.enemy.%rpg.enemy.id%.name!"
set /a "rpg.enemy.arm=rpg.enemy.%rpg.enemy.id%.arm"
set /a "rpg.enemy.max=rpg.enemy.%rpg.enemy.id%.max"
set /a "rpg.enemy.min=rpg.enemy.max*9/11"
if %rpg.enemy.min% LEQ 0 set /a "rpg.enemy.min=1"
set /a "rpg.enemy.rng=1+rpg.enemy.max-rpg.enemy.min"
set /a "rpg.enemy.level=(%random% %%rpg.enemy.rng)+rpg.enemy.min"
if not defined rpg.enemy.str set /a "rpg.enemy.str=10"
if not defined rpg.enemy.con set /a "rpg.enemy.con=10"
set /a "rpg.enemy.hpmax=rpg.enemy.con*20+rpg.enemy.level*50"
set /a "rpg.enemy.hp=rpg.enemy.hpmax"
call :addline You encounter a %rpg.enemy.name%.
goto :loop

:: rest (need to implement hp and pw regen bonuses)
:wait
if %rpg.user.hp% LSS %rpg.user.hpmax% set /a "rpg.user.hp+=rpg.user.hpmax*3/100"
if %rpg.user.pw% LSS %rpg.user.pwmax% set /a "rpg.user.pw+=rpg.user.pwmax*3/100"
goto :loop

::opening equipment
:equipment
if "%rpg.hud.equipment%"=="open" (set "rpg.hud.equipment=closed") else (set "rpg.hud.equipment=open" & set "rpg.hud.inventory=closed")
goto :loop

::opening inventory
:inventory
if "%rpg.hud.inventory%"=="open" (set "rpg.hud.inventory=closed") else (set "rpg.hud.inventory=open" & set "rpg.hud.equipment=closed")
goto :loop

::using/equipping an item
:use
if "%rpg.hud.equipment%"=="open" goto :unequip
if %rpg.hud.invaction%==Sell goto :sell
if %rpg.hud.invaction%==Buy goto :buy
set /a rpg.hud.input+=10*(rpg.hud.invpage-1)
set rpg.hud.use=!rpg.hud.inv[%rpg.hud.input%]!
::equip or switch
if defined rpg.item.%rpg.hud.use%.slot (
	if defined rpg.user.!rpg.item.%rpg.hud.use%.slot! call set /a rpg.inv.%%rpg.user.!rpg.item.%rpg.hud.use%.slot!%%+=1
	set "rpg.user.!rpg.item.%rpg.hud.use%.slot!=%rpg.hud.use%"
	set /a "rpg.inv.%rpg.hud.use%-=1"
	call :addline You are now using !rpg.item.%rpg.hud.use%.name!.
)
goto :loop

:maptune
for %%t in (name job type enc desc) do (
	set /p "rpg.world.%rpg.user.pos%.%%t=%%t (!rpg.world.%rpg.user.pos%.%%t!):"
	if "!rpg.world.%rpg.user.pos%.%%t!"=="-" set "rpg.world.%rpg.user.pos%.%%t="
)
goto :loop

:: #################################### REACTIONS ####################################### ::

::combat turn
:fight
if not defined rpg.user.action set "rpg.user.action=defend"
if %rpg.user.hp% EQU 0 goto :death
if %rpg.enemy.hp% EQU 0 goto :victory
if %rpg.user.action%==attack (set "rpg.user.action=defend") else (set "rpg.user.action=attack")
if %rpg.user.action%==attack (call :dmgcalc %rpg.user.level% %rpg.enemy.str% %rpg.user.dps% %rpg.enemy.arm% %rpg.enemy.level%) else (call :dmgcalc %rpg.enemy.level% %rpg.user.str% 0 %rpg.user.arm% %rpg.user.level%)
if %rpg.dmg.val% GTR 0 if %rpg.user.action%==attack (call :addline You hit %rpg.enemy.name% for %rpg.dmg.val% damage.) else (color C7 & call :addline %rpg.enemy.name% hits you for %rpg.dmg.val% damage.)
if %rpg.user.action%==attack (set /a "rpg.enemy.hp-=rpg.dmg.val") else (set /a "rpg.user.hp-=rpg.dmg.val")
if %rpg.user.hp% LEQ 0 set /a "rpg.user.hp=0"
if %rpg.enemy.hp% LEQ 0 set /a "rpg.enemy.hp=0"
goto :loop

::you died (need to fix death display then reset)
:death
ping -n %rpg.delay% localhost > nul
echo You died.
ping -n %rpg.delay% localhost > nul
echo Press any key...
pause > nul
call :clear
goto :init

::enemy died
:victory
call :addline %rpg.enemy.name% died.
call :reward
call :addline You gain %rpg.drop.xp% XP (%rpg.drop.xpratio%%%%% of cap) and %rpg.drop.gold% gold.
if defined rpg.drop.id call :addline *** You found a !rpg.item.%rpg.drop.id%.name! ***
call :addline
call :clear
goto :loop

::unequipping items
:unequip
set rpg.hud.unequip=!rpg.hud.unequip[%rpg.hud.input%]!
set rpg.hud.unequipitem=!rpg.user.%rpg.hud.unequip%!
call :addline You remove !rpg.item.%rpg.hud.unequipitem%.name! and put it in your inventory.
if defined rpg.user.%rpg.hud.unequip% set /a "rpg.inv.%rpg.hud.unequipitem%+=1"
set "rpg.user.%rpg.hud.unequip%="
goto :loop

::selling items
:sell
set /a rpg.hud.input+=10*(rpg.hud.invpage-1)
set rpg.hud.sell=!rpg.hud.inv[%rpg.hud.input%]!
set /a "rpg.hud.sellprice=rpg.item.%rpg.hud.sell%.val*75/100"
set /a "rpg.user.gold+=rpg.hud.sellprice"
set /a "rpg.inv.%rpg.hud.sell%-=1"
call :addline You sold !rpg.item.%rpg.hud.sell%.name! for %rpg.hud.sellprice% gold.
goto :loop

::buying items
:buy
set /a rpg.hud.input+=10*(rpg.hud.invpage-1)
set rpg.hud.buy=!rpg.hud.inv[%rpg.hud.input%]!
set /a "rpg.hud.buyprice=rpg.item.%rpg.hud.buy%.val*125/100"
if %rpg.user.gold% LSS %rpg.hud.buyprice% (
	call :addline You need %rpg.hud.buyprice%g to buy !rpg.item.%rpg.hud.buy%.name!.
) else (
	set /a "rpg.user.gold-=rpg.hud.buyprice, rpg.inv.%rpg.hud.buy%+=1"
	call :addline You bought !rpg.item.%rpg.hud.buy%.name! for %rpg.hud.buyprice% gold.
)
goto :loop

:: #################################### SUBS ############################################ ::

::create bar
:barcalc <bar name> <value> <max value>
set /a "progress=rpg.hud.barsize-(rpg.hud.barsize*%2/%3)"
set "rpg.hud.%1=[!rpg.hud.bar:~%progress%,%rpg.hud.barsize%!]"
exit /b

::damage calculator
:dmgcalc <attlev> <attstr> <wepdps> <defarm> <deflev>
set /a "rpg.dmg.rnd=(%random% %%50)+100"
set /a "rpg.dmg.attlev=%1"
set /a "rpg.dmg.attstr=%2"
set /a "rpg.dmg.wepdps=%3"
set /a "rpg.dmg.defarm=%4"
set /a "rpg.dmg.deflev=%5"
set /a "rpg.dmg.attdps=1+%rpg.dmg.attlev%/3"
set /a "rpg.dmg.attdmg=rpg.dmg.attlev*(rpg.dmg.attdps+rpg.dmg.wepdps)*rpg.dmg.attstr"
set /a "rpg.dmg.val=rpg.dmg.attdmg*rpg.dmg.rnd/100*(100-rpg.dmg.defarm)/rpg.dmg.deflev/100"
exit /b

::player reward (xp+gold+item)
:reward
::get xp
set /a "rpg.drop.xp=25*(rpg.enemy.level+1)*rpg.enemy.level/(rpg.enemy.level+10)*rpg.enemy.level/rpg.user.level"
set /a "rpg.drop.xpcap=25*(rpg.user.level+2)*(rpg.user.level+1)/(rpg.user.level+11)"
if %rpg.drop.xp% GTR %rpg.drop.xpcap% set /a "rpg.drop.xp=rpg.drop.xpcap"
set /a "rpg.drop.xpratio=rpg.drop.xp*100/rpg.drop.xpcap"
set /a "rpg.drop.gold=(%random% %%rpg.enemy.level)+1+(rpg.enemy.level/10)"
::parse drop vals
set /a "rpg.drop.count=0"
set /a "rpg.drop.max=rpg.enemy.level*3"
for /f "tokens=3,4 delims=.^=" %%a in ('set rpg.item.') do if "%%b"=="val" set "rpg.drop[!rpg.drop.count!].id=%%a" & set /a "rpg.drop.count+=1"
::picking rnd from count and saving id
set /a "rpg.drop.rnd=(%random% %%rpg.drop.count)"
set "rpg.drop.id=!rpg.drop[%rpg.drop.rnd%].id!"
::adding rewards
if !rpg.item.%rpg.drop.id%.val! LEQ %rpg.drop.max% (set /a "rpg.inv.%rpg.drop.id%+=1") else (set "rpg.drop.id=")
set /a "rpg.user.xp+=rpg.drop.xp"
set /a "rpg.user.gold+=rpg.drop.gold"
exit /b

::add a new text line in memory
:addline <new line text>
if not defined rpg.hud.text set "rpg.hud.text=%*"
set /a "rpg.hud.last=1"
for /l %%s in (2,1,%rpg.hud.lines%) do (
	set "rpg.hud.r!rpg.hud.last!=!rpg.hud.r%%s!"
	set /a "rpg.hud.last+=1"
	)
set "rpg.hud.r%rpg.hud.lines%=%rpg.hud.text%"
set "rpg.hud.text=!rpg.hud.text:~%rpg.hud.right%!"
if defined rpg.hud.text if "!rpg.hud.text:~1,2!"=="%rpg.hud.right%" (set rpg.hud.text=) else (goto :addline)
exit /b

::clear variables used for calculation
:clear
if defined rpg.drop.id for /f "delims=^=" %%a in ('set rpg.drop') do set %%a=
if defined rpg.dmg.val for /f "delims=^=" %%c in ('set rpg.dmg') do set %%c=
if defined rpg.enemy.id set rpg.enemy.id=
set "rpg.user.status=idle"
set "rpg.user.action="
exit /b

::get execution time from last call
:gettime
if not defined rpg.timer set /a "rpg.time=-1%time:~-10,1%%time:~-8,2%%time:~-5,2%%time:~-2,2%"
set /a "rpg.timer+=1%time:~-10,1%%time:~-8,2%%time:~-5,2%%time:~-2,2%"
echo %time%;!rpg.timer!;%* >> time.log
set /a "rpg.timer=-1%time:~-10,1%%time:~-8,2%%time:~-5,2%%time:~-2,2%"
exit /b