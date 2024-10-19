@ECHO OFF
ECHO =========================================================================================
ECHO File Name  : rwp.bat
ECHO Author     : Solomio S. Sisante
ECHO Created    : October 19, 2024
ECHO =========================================================================================
ECHO %~dp0  
 
:: powershell.exe -WindowStyle Hidden -ExecutionPolicy Unrestricted -File %~dp0\workplay.ps1
powershell.exe -ExecutionPolicy Unrestricted -File %~dp0\workplay.ps1
pause