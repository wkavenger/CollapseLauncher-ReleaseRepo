@echo off
set name=Collapse
set version=1.69.5

:: set channel=stable
set channel=preview

set squirrelPath=squirrel
set buildPath=%squirrelPath%\buildKitchen
set latestPath=%squirrelPath%\latestKitchen
set releasePath=%squirrelPath%\specs\%channel%
set app=%userprofile%\.nuget\packages\clowd.squirrel\2.9.42\tools\squirrel.exe
set brotli=brotli.exe
set sevenzip="C:\Program Files\7-Zip\7z.exe"

:: Remove old folders and old fileindex.json
if exist "%channel%\fileindex.json" del %channel%\fileindex.json
if exist "%channel%\ApplyUpdate.exe" del %channel%\ApplyUpdate.exe
if exist "%latestPath%" rmdir /S /Q %latestPath%
if exist "%buildPath%" rmdir /S /Q %buildPath%
mkdir "%buildPath%"
if not exist "%releasePath%" mkdir "%releasePath%"

xcopy %channel%\ %buildPath% /S /H /C 
%app% pack --packId="%name%" --packVersion="%version%" --includePDB --packDir="%buildPath%" --releaseDir="%releasePath%"

:: Build latest package file
mkdir %latestPath%\app-%version%
move %buildPath% %latestPath%
move %latestPath%\buildKitchen %latestPath%\app-%version%

:: Copy the update and entry launch executable
copy Update.exe %latestPath%
copy CollapseLauncher.exe %latestPath%

:: Start archiving the latest package
cd %latestPath%
%sevenzip% a -ttar ..\latest.tar .
cd ..\..\
rmdir /S /Q %latestPath%
brotli -q 11 --verbose -o %squirrelPath%\latest %squirrelPath%\latest.tar
del %squirrelPath%\latest.tar
if not exist "%squirrelPath%\%channel%" mkdir %squirrelPath%\%channel%
move %squirrelPath%\latest %squirrelPath%\%channel%

:: Copy the ApplyUpdate tool to channel folder
rmdir /S /Q %channel% && mkdir %channel%
copy ApplyUpdate.exe %channel%
:: Get the size of ApplyUpdate tool
FOR /F "usebackq" %%A IN ('%channel%\ApplyUpdate.exe') DO set applyupdatesize=%%~zA
:: Get the MD5 hash of ApplyUpdate tool
FOR /F %%B IN ('certutil -hashfile %channel%\ApplyUpdate.exe MD5 ^| find /v "hash"') DO set applyupdatehash=%%B
:: Get current Unix timestamp
call :GetUnixTime unixtime
:: Print out the fileindex.json file
echo ^{"ver":"%version%.0","time":%unixtime%,"f":^[^{"p":"ApplyUpdate.exe","crc":"%applyupdatehash%","s":%applyupdatesize%^}^]^} > %channel%\fileindex.json

goto :EOF


:GetUnixTime
setlocal enableextensions
for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do (
    set %%x)
set /a z=(14-100%Month%%%100)/12, y=10000%Year%%%10000-z
set /a ut=y*365+y/4-y/100+y/400+(153*(100%Month%%%100+12*z-3)+2)/5+Day-719469
set /a ut=ut*86400+100%Hour%%%100*3600+100%Minute%%%100*60+100%Second%%%100
endlocal & set "%1=%ut%" & goto :EOF