@echo off
:menu
echo SSH:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo 1. Install SSH Association
echo 2. Uninstall SSH Association
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
if not exist "C:\Windows\hyperlink-ssh.js" (
cls
echo SSH:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SSH:// HyperLink not installed - nothing to remove
echo.
pause
exit)

del "C:\Windows\hyperlink-ssh.js" /f
reg delete "HKCR\ssh" /f

cls
echo SSH:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SSH:// HyperLink uninstalled successfully
echo.
pause
exit

:install
if exist "C:\Windows\hyperlink-ssh.js" (
cls
echo SSH:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SSH:// HyperLink already installed - nothing to install
echo.
pause
exit)

echo var server=(WScript.Arguments(0))>>C:\Windows\hyperlink-ssh.js
echo var prefix='ssh://'>>C:\Windows\hyperlink-ssh.js
echo var app='"C:\\Program Files\\putty\\PUTTY.EXE"'>>C:\Windows\hyperlink-ssh.js
echo server=server.replace(prefix, '')>>C:\Windows\hyperlink-ssh.js
echo server=server.replace('/', '')>>C:\Windows\hyperlink-ssh.js
echo var shell = new ActiveXObject("WScript.Shell")>>C:\Windows\hyperlink-ssh.js
echo shell.Exec(app + " " + server)>>C:\Windows\hyperlink-ssh.js

reg add "HKCR\ssh" /f /v "" /t REG_SZ /d "URL:SSH Connection"
reg add "HKCR\ssh" /f /v "URL Protocol" /t REG_SZ /d ""
reg add "HKCR\ssh\DefaultIcon" /f /v "" /t REG_SZ /d ""C:\\Program Files\\putty\\PUTTY.EXE""
reg add "HKCR\ssh\shell\open\command" /f /v "" /t REG_SZ /d "wscript.exe C:\WINDOWS\hyperlink-ssh.js %%1"

cls
echo SSH:// HyperLink - James Clements - james@jjclements.co.uk
echo ----------------------------------------------------------
echo.
echo.
echo SSH:// HyperLink installed successfully
echo.
pause
exit
