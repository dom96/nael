@echo off
cd %~dp0
SET LOCAL=%~dp0
SET SRC=%LOCAL%src
SET NIMPATH=C:\Program Files\nimrod\bin
cd %NIMPATH%
echo %LOCAL%
nimrod c --out:%LOCAL%\nael.exe %SRC%\main.nim 
pause