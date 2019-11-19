ECHO =================================================
ECHO ThreatAnalytics Agent Installation started 
ECHO =================================================

SET /P _inputname= Please enter an Downloading path for Interceptor-Agent Packages :%1
SET /P manager_IP= Please enter an Interceptor Manager-ip adddress :%2

cd "%_inputname%"

bitsadmin /transfer debjob /download /priority normal https://interceptor-storage.s3-us-west-1.amazonaws.com/Windows_Agents.zip %_inputname%\Windows_Agents.zip

@echo off
setlocal
cd /d %~dp0
Call :UnZipFile "%_inputname%" "%_inputname%\Windows_Agents.zip"
exit /b

:UnZipFile <ExtractTo> <newzipfile>
set vbs="%temp%\_.vbs"
if exist %vbs% del /f /q %vbs%
>%vbs%  echo Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% echo If NOT fso.FolderExists(%1) Then
>>%vbs% echo fso.CreateFolder(%1)
>>%vbs% echo End If
>>%vbs% echo set objShell = CreateObject("Shell.Application")
>>%vbs% echo set FilesInZip=objShell.NameSpace(%2).items
>>%vbs% echo objShell.NameSpace(%1).CopyHere(FilesInZip)
>>%vbs% echo Set fso = Nothing
>>%vbs% echo Set objShell = Nothing
cscript //nologo %vbs%
if exist %vbs% del /f /q %vbs%

cd "%_inputname%"

Interceptor-agent-3.8.2.msi /q ADDRESS="%manager_IP%" /q

ECHO =================================================
ECHO  32-bit(x86) or 64-bit(x64) selection process 
ECHO =================================================

FOR /F "tokens=3" %%x in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V PROCESSOR_ARCHITECTURE') do set CPU=%%x
echo CPU Architecture: %CPU%

if "%CPU:~-2%"=="64" (
  cd "C:\Program Files (x86)\ossec-agent"            
) else (
  cd "C:\Program Files\ossec-agent" 
)

cd "C:\Program Files(x86)\ossec-agent"
agent-auth.exe -m "%manager_IP%" -p 1515



net STOP ThreatAnalytics
net START ThreatAnalytics

ECHO =================================================
ECHO ThreatAnalytics-3.8.2 Agent Installation Completed 
ECHO =================================================

cls

ECHO =================================================
ECHO RealTimeMonitoring Agent Installation Started 
ECHO =================================================

ECHO ======================================================================================
ECHO   32-bit(x86) or 64-bit(x64) selection process 
ECHO ======================================================================================

FOR /F "tokens=3" %%x in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V PROCESSOR_ARCHITECTURE') do set CPU=%%x
echo CPU Architecture: %CPU%

cd "%_inputname%"

  ECHO "It's entering RealTimeMonitoring installation path"

if "%CPU:~-2%"=="64" (
  NSCP-0.5.0.62-x64.msi CONF_CAN_CHANGE=1 MONITORING_TOOL=none ALLOWED_HOSTS=%manager_IP% CONF_NSCLIENT=1 NSCLIENT_PWD=password CONF_CHECKS=1 /q
) else (
 NSCP-0.5.0.62-Win32.msi  CONF_CAN_CHANGE=1 MONITORING_TOOL=none ALLOWED_HOSTS=%manager_IP%" CONF_NSCLIENT=1 NSCLIENT_PWD=password CONF_CHECKS=1 /q 
)

cd "C:\Program Files\NSClient++"

nscp settings --activate-module CheckExternalScripts

nscp settings --activate-module CheckHelpers

nscp settings --activate-module CheckEventLog

nscp settings --activate-module CheckNSCP

nscp settings --activate-module CheckDisk

nscp settings --activate-module CheckSystem

nscp service --stop

cls

nscp service --start

cls

ECHO =================================================
ECHO RealTimeMonitoring Agent Installation Finished 
ECHO =================================================

cd "%_inputname%"
del /f Windows_Agents.zip
del /f Interceptor-agent-3.8.2.msi
del /f NSCP-0.5.0.62-Win32.msi
del /f NSCP-0.5.0.62-x64.msi

exit
