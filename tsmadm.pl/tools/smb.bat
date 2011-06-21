@echo off
:menu
echo SMB:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo 1. Install SMB Association
echo 2. Uninstall SMB Association
echo 3. Quit
echo.
set choice=
set /p choice=[1,2,3]? 
echo.
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto install
if '%choice%'=='2' goto uninstall
if '%choice%'=='3' goto quit
echo.
echo.
echo "%choice%" is not a valid option - please try again
echo.
pause
cls
goto MENU

:quit
cls
exit

:uninstall
if not exist "C:\Windows\hyperlink-smb.js" (
cls
echo SMB:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SMB:// HyperLink not installed - nothing to remove
echo.
pause
exit)

del "C:\Windows\hyperlink-smb.js" /f
reg delete "HKCR\smb" /f

cls
echo SMB:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SMB:// HyperLink uninstalled successfully
echo.
pause
exit

:install
if exist "C:\Windows\hyperlink-smb.js" (
cls
echo SMB:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SMB:// HyperLink already installed - nothing to install
echo.
pause
exit)

echo var server=(WScript.Arguments(0))>>C:\Windows\hyperlink-smb.js
echo var prefix='smb://'>>C:\Windows\hyperlink-smb.js
echo var app='"explorer"'>>C:\Windows\hyperlink-smb.js
echo server=server.replace(prefix, '')>>C:\Windows\hyperlink-smb.js
echo server=server.replace('/', '')>>C:\Windows\hyperlink-smb.js
echo var shell = new ActiveXObject("WScript.Shell")>>C:\Windows\hyperlink-smb.js
echo shell.Exec(app + " " + server)>>C:\Windows\hyperlink-smb.js

reg add "HKCR\smb" /f /v "" /t REG_SZ /d "URL:SSH Connection"
reg add "HKCR\smb" /f /v "URL Protocol" /t REG_SZ /d ""
reg add "HKCR\smb\DefaultIcon" /f /v "" /t REG_SZ /d ""C:\\WINDOWS\\EXPLORER.EXE""
reg add "HKCR\smb\shell\open\command" /f /v "" /t REG_SZ /d "wscript.exe C:\WINDOWS\hyperlink-smb.js %%1"

cls
echo SMB:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SMB:// HyperLink installed successfully
echo.
pause
exit
