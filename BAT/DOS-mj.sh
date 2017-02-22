#-------------------------------------------------------#
#  Make a Job Folder  script file for bash              #
#  JMS :: 07.02.2008 :: Edited 07.02.2008               #
#-------------------------------------------------------#

-> add bash start code

# mj.sh is bash for mj.bat
# Make a job folder in the correct location
@echo off
 IF (%1) EQU () GOTO :MISSING
 IF %1 LSS 20000 GOTO :MISSING
 IF %1 GEQ 90000 GOTO :SPEC
 IF %1 GEQ 70000 GOTO :MISC
 IF %1 GEQ 60000 GOTO :MTRCRAFT
 IF %1 GEQ 40000 GOTO :COMPHT
 IF %1 GEQ 30000 GOTO :FCS
 IF %1 GEQ 20000 GOTO :HTS
:SPEC
 mkdir g:\Jobs\SPEC\%1
 GOTO :FINISHED
:MISC
 mkdir g:\Jobs\MISC\%1
 GOTO :FINISHED
:MTRCRAFT
 mkdir g:\Jobs\MTRCRAFT\%1
 GOTO :FINISHED
:COMPHT
 mkdir g:\Jobs\COMPHT\%1
 GOTO :FINISHED
:FCS
 mkdir g:\Jobs\FCS\%1
 GOTO :FINISHED
:HTS
 mkdir g:\Jobs\HTS\%1
 GOTO :FINISHED
:MISSING
 @ECHO.
 @ECHO  Missing or innacurate job numer entered
 GOTO :END
:FINISHED
 @ECHO.
 @ECHO    Job Folder %1 Created
 @ECHO.
:END
