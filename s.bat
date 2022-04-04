@echo off
setlocal enableextensions
setlocal enabledelayedexpansion
set "spacer=                    "

:menu
cls
echo [1] world
echo [2] enemies
echo [3] items
choice /c:123 /n /m:"Choose file:"
goto menu%errorlevel%

:menu1 world
set rpg.list=
for /f "delims=" %%w in (world.dat) do set "rpg.world.%%w"
for /f "tokens=3-4 delims=.^=" %%m in ('set rpg.world') do if %%n==name set "rpg.list=!rpg.list! %%m"
:list1
cls
echo world       job       dirn        dirs        dirw        dire        name
for %%e in (%rpg.list%) do (
    set "world=%%e%spacer%"
    set "job=!rpg.world.%%e.job!%spacer%"
    set "dirn=!rpg.world.%%e.dirn!%spacer%"
    set "dirs=!rpg.world.%%e.dirs!%spacer%"
    set "dirw=!rpg.world.%%e.dirw!%spacer%"
    set "dire=!rpg.world.%%e.dire!%spacer%"
    set "name=!rpg.world.%%e.name!%spacer%"
    set "desc=!rpg.world.%%e.desc!%spacer%"
    echo !world:~0,12!!job:~0,10!!dirn:~0,12!!dirs:~0,12!!dirw:~0,12!!dire:~0,12!!name:~0,20!
    )
echo.
echo Commands: [2][3][Q][S] [E][C][A]
echo Input location id:
set newworld=
set /p newworld=
if "%newworld%"=="2" goto :menu2
if "%newworld%"=="3" goto :menu3
if "%newworld%"=="" goto :menu1
if "%newworld%"=="q" goto :eof
if "%newworld%"=="s" goto :save1
if "%newworld%"=="e" goto :edit1
if "%newworld%"=="c" goto :complete1
if "%newworld%"=="a" goto :add1
set "rpg.list=%newworld%" & goto :list1
goto :menu1

:complete1
for %%e in (%rpg.list%) do (
    for /f "tokens=3-5 delims=.^=" %%m in ('set rpg.world') do (
        if %%o==%%e (
            if %%n==dirn set rpg.world.%%e.dirs=%%m
            if %%n==dirs set rpg.world.%%e.dirn=%%m
            if %%n==dirw set rpg.world.%%e.dire=%%m
            if %%n==dire set rpg.world.%%e.dirw=%%m
        )
    )
)
goto :list1

:add1
set /p newworldid="New id:"
set /p rpg.world.%newworldid%.name="Enter name:"
set /p newdir="Enter cardinal direction (NSWE):"
set /p rpg.world.%newworldid%.dir%newdir%="Enter relative id:"
set rpg.list=%rpg.list% %newworldid%
goto :list1

:edit1
for %%e in (job dirn dirs dirw dire name enc desc) do call set /p rpg.world.!rpg.list!.%%e=(%%e) "%%rpg.world.!rpg.list!.%%e%%":
goto :list1

:save1
set rpg.world > world.dat
goto :clear

:menu2 enemies
set rpg.list=
for /f "delims=" %%m in (enemies.dat) do set "rpg.enemy.%%m"
for /f "tokens=3-4 delims=.^=" %%m in ('set rpg.enemy') do if %%n==name set "rpg.list=!rpg.list! %%m"
:list2
cls
echo id                       max            arm            name
for %%e in (%rpg.list%) do (
    set "enemy=%%e%spacer%"
    set "max=!rpg.enemy.%%e.max!%spacer%"
    set "arm=!rpg.enemy.%%e.arm!%spacer%"
    set "name=!rpg.enemy.%%e.name!%spacer%"
    echo !enemy:~0,20!!max:~0,10!!arm:~0,10!!name:~0,20!
)
echo.
echo Commands: [1][3][Q][S]
echo Full name,max,arm:
set newenemy=
set /p newenemy=
if "%newenemy%"=="1" goto :menu1
if "%newenemy%"=="3" goto :menu3
if "%newenemy%"=="" goto :menu2
if "%newenemy%"=="q" goto :eof
if "%newenemy%"=="s" goto :save2
for /f "tokens=1-3 delims=," %%n in ("%newenemy%") do (
    set "name=%%n"
    set "max=%%o"
    set "arm=%%p"
    set "id=%%n"
    for %%l in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do set "id=!id:%%l=%%l!"
    set "id=!id: =!"
)
set "rpg.enemy.!id!.max=!max!"
set "rpg.enemy.!id!.arm=!arm!"
set "rpg.enemy.!id!.name=!name!"
goto :menu2

:save2
set rpg.enemy > enemies.dat
goto :clear

:menu3 items
set rpg.list=
for /f "delims=" %%m in (items.dat) do set "rpg.item.%%m"
for /f "tokens=3-4 delims=.^=" %%m in ('set rpg.item') do if %%n==name set "rpg.list=!rpg.list! %%m"
:list3
cls
echo id                       slot        dps/arm  val   name
for %%e in (%rpg.list%) do (
    set "item=%%e%spacer%"
    set "slot=!rpg.item.%%e.slot!%spacer%"
    if !rpg.item.%%e.slot!==weapon (set "dpsarm=!rpg.item.%%e.dps!%spacer%") else (set "dpsarm=!rpg.item.%%e.arm!%spacer%")
    set "val=!rpg.item.%%e.val!%spacer%"
    set "name=!rpg.item.%%e.name!%spacer%"
    echo !item:~0,20!     !slot:~0,10!  !dpsarm:~0,5!    !val:~0,5! !name:~0,25!
)
echo.
echo Commands: [1][2][Q][S]
echo Full name,slot,dps/arm,val:
set newitem=
set /p newitem=
if "%newitem%"=="1" goto :menu1
if "%newitem%"=="2" goto :menu2
if "%newitem%"=="" goto :menu3
if "%newitem%"=="q" goto :eof
if "%newitem%"=="s" goto :save3
for /f "tokens=1-4 delims=," %%n in ("%newitem%") do (
    set "name=%%n"
    set "slot=%%o"
    set "dpsarm=%%p"
    set "val=%%q"
    set "id=%%n"
    for %%l in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do set "id=!id:%%l=%%l!"
    set "id=!id: =!"
)
set "rpg.item.!id!.slot=!slot!"
if !slot!==weapon (set "rpg.item.!id!.dps=!dpsarm!") else (set "rpg.item.!id!.arm=!dpsarm!")
set "rpg.item.!id!.val=!val!"
set "rpg.item.!id!.name=!name!"
goto :menu3

:save3
set rpg.item > items.dat
goto :clear

:clear
for /f "delims=^=" %%s in ('set rpg.') do set %%s=
