@ECHO OFF
REM This script sets the Slack status depending on the wifi we are connected to currently
REM It requires cURL and jq (see: https://stedolan.github.io/jq/)
SET curl=curl-7.61.0-win64-mingw\bin\curl.exe
SET jq=jq-v1.5-win64\jq-win64.exe
SET timestamp=getTimestamp\getTimestamp.exe

REM Get UNIX timestamp
FOR /f "tokens=1-3 delims=." %%a in ('date /t') do (set mydate=%%a.%%b.%%c)
FOR /f "delims=" %%d in ('%timestamp% "%mydate%18:00"') do (set myts=%%d)
SET mycode=%%2C%%0A%%20%%20%%20%%20%%22status_expiration%%22%%3A%%20%myts%%%0A%%7D

REM EnableDelayedExpansion to be able to combine variables and names
SETLOCAL ENABLEDELAYEDEXPANSION

REM My Slack token is
SET TOKEN=xxxx-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

REM Set up all known wifi networks
REM Slack emojy names must be in English language
SET PROFIL_WIFI1==%%7B%%22status_text%%22%%3A%%22Working%%20%%40%%20Home%%22%%2C%%22status_emoji%%22%%3A%%22^
    %%3Ahouse_with_garden%%3A%%22%mycode%
SET PROFIL_WIFI2=%%7B%%0A%%20%%20%%20%%20%%22status_text%%22%%3A%%20%%22%%40%%20Anywhere%%20working%%22%%2C%%0A%%20^
    %%20%%20%%20%%22status_emoji%%22%%3A%%20%%22%%3Acityscape%%3A%%22%mycode%
SET DEFAULTPROFIL=%%7B%%0A%%20%%20%%20%%20%%22status_text%%22%%3A%%20%%22%%40%%20Anywhere%%20working%%22%%2C%%0A%%20^
    %%20%%20%%20%%22status_emoji%%22%%3A%%20%%22%%3Acityscape%%3A%%22%mycode%

REM Get wifi name
FOR /F "tokens=2 delims=: " %%s IN ('netsh wlan show interfaces ^| findstr SSID ^| findstr /V BSSID') DO (SET SSID=%%s)
echo Found wifi: "%SSID%"
SET PROFILE=!PROFIL_%SSID%!

REM Get IP address
FOR /F "tokens=2 delims=: " %%t IN ('netsh interface ip show address "Ethernet 4" ^| findstr "IP Address"') DO (SET IP=%%t)
IF "%IP%"=="" (
	FOR /F "tokens=2 delims=: " %%t IN ('netsh interface ip show address "Ethernet 3" ^| findstr "IP Address"') DO (SET IP=%%t)
)
echo Found IP: "%IP%"
SET PROFILE_IP=!PROFIL_%IP:~0,3%!

REM Slack status depending in WiFi
IF "%SSID%"=="WIFI1" (
    REM call Slack API and check return value
    FOR /F %%g IN ('%curl% https://slack.com/api/users.profile.set --silent --data "token=%TOKEN%&profile=%PROFILE%" ^| %jq% .ok') DO (SET retval=%%~g) > NUL
    IF "!retval!"=="true" (
        echo New Slack status: ok
    ) ELSE (
        echo New Slack status: failed
    )
) ELSE IF "%SSID%"=="WIFI2" (
    REM call Slack API and check return value
    FOR /F %%g IN ('%curl% https://slack.com/api/users.profile.set --silent --data "token=%TOKEN%&profile=%PROFILE%" ^| %jq% .ok') DO (SET retval=%%~g) > NUL
    IF "!retval!"=="true" (
        echo New Slack status: ok
    ) ELSE (
        echo New Slack status: failed
    )

REM In case we are not connected to a wi-fi
) ELSE IF "%SSID%"=="" (
    REM call Slack API and check return value
    FOR /F %%g IN ('%curl% https://slack.com/api/users.profile.set --silent --data "token=%TOKEN%&profile=%PROFILE%" ^| %jq% .ok') DO (SET retval=%%~g) > NUL
    IF "!retval!"=="true" (
        echo New Slack status: ok
    ) ELSE (
        FOR /F %%g IN ('%curl% https://slack.com/api/users.profile.set --silent --data "token=%TOKEN%&profile=%PROFILE_IP%" ^| %jq% .ok') DO (SET retval=%%~g) > NUL
        IF "!retval!"=="true" (
            echo New Slack status: ok
        ) ELSE (
            echo New Slack status: failed
        )
    )
) ELSE (
    REM echo "Anywhere"
    REM call Slack API and check return value
    FOR /F %%g IN ('%curl% https://slack.com/api/users.profile.set --silent --data "token=%TOKEN%&profile=%DEFAULTPROFIL%" ^| %jq% .ok') DO (SET retval=%%~g) > NUL
    IF "!retval!"=="true" (
        echo New Slack status: ok
    ) ELSE (
        echo New Slack status: failed
    )
)

REM wait 2 secs
ping 127.0.0.1 -n 2 > nul
exit 0