@ECHO OFF
ECHO =========================================================================================
ECHO File Name  : ipset.bat
ECHO Author     : Solomio S. Sisante
ECHO Created    : October 19, 2024
ECHO Purpose    : To import and run IPSet Network Tools modules.
ECHO =========================================================================================
ECHO %~dp0  

powershell -ExecutionPolicy UnRestricted -File %~dp0ipset.ps1

pause