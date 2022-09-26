@echo off

echo;
echo Welcome to worlipe
echo;
echo Loading drivers...
echo;

for /f "tokens=*" %%a in (X:\drivers\critical) do call :processline %%a

goto :next

:processline
SET drivpath=%*

if "%drivpath:~0,1%"=="?" (

    setlocal EnableDelayedExpansion

    echo;
    echo loading driver "%drivpath:~1%" without /install...
    echo;

    pnputil /add-driver X:\drivers\%drivpath:~1%

    setlocal DisableDelayedExpansion

) ELSE (

    echo;
    echo loading driver "%drivpath%"...
    echo;

    pnputil /add-driver X:\drivers\%drivpath% /install

)

goto :end

:next

echo;
echo Drivers loaded
echo;
echo Mounting disk...
echo;
echo Note: may take some time for diskpart to start, please wait...
echo;

(
echo select disk 0
echo select partition 1
echo assign letter=A
exit
)  | diskpart

(
echo select disk 0
echo select partition 2
echo assign letter=B
exit
)  | diskpart

echo;
echo Installing drivers to windows install with DISM...
echo;

dism /image:B:\ /add-driver /driver:X:\drivers\ /recurse /forceunsigned

echo;
echo Creating proper boot entries and BCD...
echo;

rmdir /S /Q A:\EFI

rmdir /S /Q B:\EFI

bcdboot B:\Windows /s A: /f UEFI

echo;
echo Creating msr partition...
echo;

(
echo select disk 0
echo create partition msr size=16
exit
)  | diskpart

echo;
echo Setting boot permeters...
echo;

bcdedit /store A:\EFI\Microsoft\Boot\bcd /set {bootloadersettings} testsigning on

bcdedit /store A:\EFI\Microsoft\Boot\bcd /set {bootloadersettings} nointegritychecks on

bcdedit /store A:\EFI\Microsoft\Boot\bcd /set {default} recoveryenabled No

echo;
echo Coverting boot partition to an ESP one...
echo;

(
echo select disk 0
echo select partition 1
echo set id=C12A7328-F81F-11D2-BA4B-00A0C93EC93B override
exit
)  | diskpart

echo;
echo Configuring finnished, rebooting...
echo;

:end
