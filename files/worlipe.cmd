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
echo Injecting drivers into winre...
echo;

mkdir B:\winre

dism /apply-image /imagefile:B:\Windows\System32\Recovery\winre.wim /index:1 /ApplyDir:B:\winre

dism /image:B:\winre /add-driver /driver:X:\drivers\ /recurse /forceunsigned

echo;
echo Restoring old RecEnv.exe...
echo;

del B:\winre\sources\recovery\RecEnv.exe

ren B:\winre\sources\recovery\RecEnv.exe.bak RecEnv.exe

echo;
echo Recapturing winre image...
echo;

del B:\Windows\System32\Recovery\winre.wim

del B:\winre\worlipe.cmd

dism /Capture-Image /ImageFile:B:\Windows\System32\Recovery\winre.wim /CaptureDir:B:\winre /Name:"Microsoft Windows Recovery Environment (arm64)" /Description:"Microsoft Windows Recover Environment (arm64)" /Bootable 

rmdir /S /Q B:\winre

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
