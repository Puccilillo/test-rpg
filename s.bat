@echo off
setlocal enableextensions
setlocal enabledelayedexpansion
set "spacer=                    "

:menu
echo [1] world
echo [2] enemies
echo [3] items
choice /c:123 /n /m:"Choose file:"
goto menu%errorlevel%

:menu1 world
for /f "delims=" %%w in (world.dat) do set "rpg.world.%%w"
cls
goto :clear

:menu2 enemies
set rpg.list=
for /f "delims=" %%m in (enemies.dat) do set "rpg.enemy.%%m"
for /f "tokens=3-4 delims=.^=" %%m in ('set rpg.enemy') do if %%n==name set "rpg.list=!rpg.list! %%m"
cls
echo id                       max            arm            name
for %%e in (%rpg.list%) do (
    set "enemy=%%e%spacer%"
    set "max=!rpg.enemy.%%e.max!%spacer%"
    set "arm=!rpg.enemy.%%e.arm!%spacer%"
    set "name=!rpg.enemy.%%e.name!%spacer%"
    echo !enemy:~0,20!     !max:~0,10!     !arm:~0,10!     !name:~0,20!
)
echo.
set /p newenemy="Full name,max,arm:"
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
cls
echo id                       slot           dps       arm       val       name
for %%e in (%rpg.list%) do (
    set "item=%%e%spacer%"
    set "slot=!rpg.item.%%e.slot!%spacer%"
    set "dps=!rpg.item.%%e.dps!%spacer%"
    set "arm=!rpg.item.%%e.arm!%spacer%"
    set "val=!rpg.item.%%e.val!%spacer%"
    set "name=!rpg.item.%%e.name!%spacer%"
    echo !item:~0,20!     !slot:~0,10!     !dps:~0,5!     !arm:~0,5!     !val:~0,5!     !name:~0,20!
)
echo.
set /p newitem="Full name,slot,dps,arm,val:"
if "%newitem%"=="" goto :menu3
if "%newitem%"=="q" goto :eof
if "%newitem%"=="s" goto :save3
for /f "tokens=1-5 delims=," %%n in ("%newitem%") do (
    set "name=%%n"
    set "slot=%%o"
    set "dps=%%p"
    set "arm=%%q"
    set "val=%%r"
    set "id=%%n"
    for %%l in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do set "id=!id:%%l=%%l!"
    set "id=!id: =!"
)
set "rpg.item.!id!.slot=!slot!"
set "rpg.item.!id!.dps=!dps!"
set "rpg.item.!id!.arm=!arm!"
set "rpg.item.!id!.val=!val!"
set "rpg.item.!id!.name=!name!"
goto :menu3

:save3
set rpg.item > items.dat
goto :clear

:clear
for /f "delims=^=" %%s in ('set rpg.') do set %%s=
