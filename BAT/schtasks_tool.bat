rem Found at: https://community.spiceworks.com/scripts/show/1474-export-and-import-all-scheduled-tasks-in-windows-server-2008-windows-7
rem Instructions
rem 1. Create and copy schtasks_tool.bat to root local drive on server you want to export scheduled tasks from.
rem 2. Change runas info to your own.
rem 3. From command prompt run c:\schtasks_tool.bat export
rem a. This will create a c:\tasks folder and a c:\tnlist.txt
rem 4. Copy c:\schtasks_tool.bat, c:\tasks, and c:\tnlist.txt to root volume on the server you want to add the tasks to.
rem 5. Login to new server, go to command prompt, and run c:\schtasks_tool.bat import
rem 6. All done!
rem Edited on: 07.25.2016
rem @echo off

cls
setlocal EnableDelayedExpansion
 
set runasUsername=domain\administrator	
set runasPassword=password
 
 
 
if %1. == export. call :export
if %1. == import. call :import
exit /b 0
 
 
:export
md tasks 2>nul
 
schtasks /query /fo csv | findstr /V /c:"TaskName" > tnlist.txt
 
for /F "delims=," %%T in (tnlist.txt) do (
  set tn=%%T
  set fn=!tn:\=#!
  echo  !tn!
  schtasks /query /xml /TN !tn! > tasks\!fn!.xml
)
 
rem Windows 2008 tasks which should not be imported.
del tasks\#Microsoft*.xml
exit /b 0
 
 
 
:import
for %%f in (tasks\*.xml) do (
	call :importfile "%%f"
)
exit /b 0
 
 
:importfile
  	set filename=%1
 
	rem replace out the # symbol and .xml to derived the task name
	set taskname=%filename:#=%
	set taskname=%taskname:tasks\=%
	set taskname=%taskname:.xml=%
 
	schtasks /create /ru %runasUsername% /rp %runasPassword% /tn %taskname% /xml %filename%
	echo.
	echo.