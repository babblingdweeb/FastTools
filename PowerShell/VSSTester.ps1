#################################################################################
# 
# The sample scripts are not supported under any Microsoft standard support 
# program or service. The sample scripts are provided AS IS without warranty 
# of any kind. Microsoft further disclaims all implied warranties including, without 
# limitation, any implied warranties of merchantability or of fitness for a particular 
# purpose. The entire risk arising out of the use or performance of the sample scripts 
# and documentation remains with you. In no event shall Microsoft, its authors, or 
# anyone else involved in the creation, production, or delivery of the scripts be liable 
# for any damages whatsoever (including, without limitation, damages for loss of business 
# profits, business interruption, loss of business information, or other pecuniary loss) 
# arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages
#
#################################################################################

#Authors : Michael Barta <mbarta@microsoft.com> , Muralidharan Natarajan <munatara@microsoft.com>

#################################################################################
# This script will allow you to test VSS functionality with Exchange 2010 using DiskShadow.
# The script will automatically detect active and passive database copies running on the server.
# It will create a script file required by diskshadow for the selected database.
# Depending on the options selected it can enable a transcript log, enabled diagnostics logging, enable ExTRA Tracing, VSS tracing and expose the snapshot while testing a backup using diskshadow.
#################################################################################

#Declaring Varibles

[bool]$enableTransLog | out-null
[bool]$enableDiagLog| out-null
[bool]$enableExTRATracing| out-null
[bool]$enableVSSTracing| out-null
[bool]$enableDiskshadowBackup| out-null
[bool]$exposeSnapshot| out-null
[bool]$getItAll| out-null
[bool]$loggingOnly| out-null


Clear-host


Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

write-host "****************************************************************************************"
write-host "****************************************************************************************"
write-host "**                                                                                    **"-backgroundcolor darkgreen
write-host "**                          VSSTESTER SCRIPT VERSION 1.0                              **" -backgroundcolor darkgreen -foregroundcolor yellow
write-host "**                                                                                    **" -backgroundcolor darkgreen
write-host "****************************************************************************************"
write-host "****************************************************************************************"
" "
#newLine shortcut
$script:nl = "`r`n"
$nl

#start time
$startInfo = Get-Date
get-date

$nl
$nl
Write-Host "Please select the operation you would like to perform from the following options" -foregroundcolor Green
$nl
Write-Host "  1." -foregroundcolor Yellow -nonewline; Write-host "Test backup using built-in Diskshadow"
$nl
Write-Host "  2." -foregroundcolor Yellow -nonewline; Write-Host "Enable logging to troubleshoot backkup issues"
$nl
Write-Host "  3." -foregroundcolor Yellow -nonewline; Write-Host "Custom"
$nl
$nl


Do
{
Write-host "Selection" -foregroundcolor Yellow -nonewline; $Selection = Read-Host " "
if($Selection -notmatch "^([1-3]|[1][0])$") 
{
Write-host "Error! Please enter a number between 1 and 3!" -ForegroundColor Red
}
}
while ($Selection -notmatch "^([1-3]|[1][0])$") 


#=======================================
#Function to check VSSAdmin List Writers status
function listVSSWritersBefore
{
	" "
	Write-host "Checking VSS Writer Status: (All Writers must be in a Stable state before running this script)" -foregroundcolor Green $nl
			   "-----------------------------------------------------------------------------------------------"
" "
	$writers = (vssadmin list writers)
	$writers > $path\vssWritersBefore.txt

	foreach ($line in $writers)
	{
		if ($line -like "Writer name:*")
		{
		"$line"
		}
		elseif ($line -like "   State:*")
		{
			if ($line -ne "   State: [1] Stable")
			{
			$nl
			write-host "!!!!!!!!!!!!!!!!!!!!!!!!!!   WARNING   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -foregroundcolor red
			$nl
			Write-Host "One or more writers are NOT in a 'Stable' state, STOPPING SCRIPT." -foregroundcolor red
			$nl
			Write-Host "Review the vssWritersBefore.txt file in '$path' for more information." -ForegroundColor Red
			write-host "You can also used the Exchange Management Shell or a Command Prompt to run: 'vssadmin list writers'" -foregroundcolor red
			$nl
			write-host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -foregroundcolor red
			$nl
			stopTransLog
			do
			{
				Write-Host
				$continue = Read-Host "Please use the <Enter> key to exit..."
			}
			While ($continue -notmatch $null)
			exit
			}
			else
			{
			"$line" + $nl
			}
		}
	}
	" " + $nl
}

function listVSSWritersAfter
{
	" "
		Write-host "Checking VSS Writer Status: (after backup)" -foregroundcolor Green $nl
			  "------------------------------------------" 
			  " "
			   get-Date
	" "
	$writers = (vssadmin list writers)
	$writers1 = (vssadmin list writers)
	$writers > $path\vssWritersAfter.txt

	foreach ($line in $writers)
	{
		if ($line -like "Writer name:*")
		{
		"$line"
		}
		elseif ($line -like "   State:*")
		{
		"$line" + $nl		
		}
	}
	}
	
#==============================
#function to start a transcript log
function startTransLog
{
	$transFileExists = (Test-Path -Path "$path\vssTranscript.log") |out-null
	if ($transFileExists -eq $true)
	{	
	" " + $nl
	Write-host "Starting transcript..." -foregroundcolor Green $nl
	           "----------------------"
    start-transcript -path "$path\vssTranscript.log" -Append
    " " + $nl
		}
	else 
	{
	" " + $nl
    start-transcript -path "$path\vssTranscript.log"
    " " + $nl
	}
	
} 


#==============================
#4. function to stop a transcript log
function stopTransLog
{
    " " + $nl 
	write-host "Stopping transcript log..." -foregroundcolor Green $nl
	"--------------------------" 
	" "
	get-Date
	" "
    stop-transcript
    " " + $nl
	 do
			{
				Write-Host
				$continue = Read-Host "Please use the <Enter> key to exit..."
			}
			While ($continue -notmatch $null)
		exit
} 


#==============================
#5. function to enable diagnostics logging
function enableDiagLogging
{
	" "
   	write-host "Enabling Diagnostics Logging..." -foregroundcolor green $nl
    "-------------------------------" 
	" "
	get-Date
	" "    
   set-eventloglevel 'MSExchange Repl\Service' -level expert 
    $getReplSvc = get-eventloglevel 'MSExchange Repl\Service'
    write-host $getReplSvc.Identity " - " $getReplSvc.eventlevel  $nl

    set-eventloglevel 'MSExchange Repl\Exchange VSS Writer' -level expert
    $getReplVSSWriter = get-eventloglevel 'MSExchange Repl\Exchange VSS Writer'
    write-host $getReplVSSWriter.identity " - " $getReplVSSWriter.eventlevel  $nl

    set-eventloglevel 'MSExchangeIS\9002 System\Backup Restore' -level expert
    $getBackRest = get-eventloglevel 'MSExchangeIS\9002 System\Backup Restore'
    write-host $getBackRest.identity " - " $getBackRest.eventlevel  $nl
}



#===============================
#6. function to disable diagnostics logging
function disableDiagLogging
{
	
    write-host " "  $nl
    write-host "Disabling Diagnostics Logging..." -foregroundcolor green $nl
	"-------------------------------" 
	" "
	get-Date
	" "
    set-eventloglevel 'MSExchange Repl\Service' -level lowest
    $disgetReplSvc = get-eventloglevel 'MSExchange Repl\Service'
    write-host $disgetReplSvc.Identity " - " $disgetReplSvc.eventlevel $nl  

    set-eventloglevel 'MSExchange Repl\Exchange VSS Writer' -level lowest
    $disgetReplVSSWriter = get-eventloglevel 'MSExchange Repl\Exchange VSS Writer'
    write-host $disgetReplVSSWriter.identity " - " $disgetReplVSSWriter.eventlevel $nl

    set-eventloglevel 'MSExchangeIS\9002 System\Backup Restore' -level lowest
    $disgetBackRest = get-eventloglevel 'MSExchangeIS\9002 System\Backup Restore'
    write-host $disgetBackRest.identity " - " $disgetBackRest.eventlevel $nl
}



#==============================
#7. function to get the server name
function getLocalServerName
{   
	Write-host "Getting Server name..." -foregroundcolor Green $nl
	"--------------------" 
	" "
    $script:serverName = Hostname
	Write-Host $serverName
	Write-Host " " $nl
}


#==============================
#8. function to get Exchange version
function exchVersion
{
	" "
	Write-host "Verifying Exchange version..." -foregroundcolor Green $nl
	"---------------------------" 
	" "
    $script:exchVer = (get-exchangeserver $serverName).admindisplayversion.major

    if ($exchVer -eq "14")
        {
	       write-host "$serverName is an Exchange 2010 server." $nl
	       $script:exchVer = "2010"	
        }
   
    else
        {
	       write-host "This script is only for Exchange 2010 servers." -foregroundcolor red $nl
		   do
			{
				Write-Host
				$continue = Read-Host "Please use the <Enter> key to exit..."
			}
			While ($continue -notmatch $null)
		exit
        }

}


#==============================
#9. function to get list of databases
function getDatabases
{		
    [array]$script:databases = get-mailboxdatabase -server $serverName
	if ((Get-PublicFolderDatabase -Server $serverName) -ne $null)
	{
    $script:databases += get-publicfolderdatabase -server $serverName
	}


    write-host "Getting databases on server:" $serverName -foregroundcolor Green $nl
    write-host "-----------------------------------------" 
	" "
    write-host "Database Name:`t`t Mounted: `t`t Mounted On Server:" -foregroundcolor Yellow $nl
    $script:dbID = 0
    
    foreach ($script:db in $databases)
    {
        $dbID++
		if ((($db).ismailboxdatabase) -eq "True")
			{
			$dbInfo = (get-mailboxdatabase "$db" -status)
			write-host "$dbID. " ($db).name  "`t`t" $dbInfo.mounted "`t`t`t" $dbInfo.server.name  $nl
			}
		else
		{
		$dbInfo = (get-publicfolderdatabase "$db" -status)
        write-host "$dbID. " ($db).name  "`t`t`t" $dbInfo.mounted "`t`t`t`t" $dbInfo.server.name $nl	
		}
    }
	write-host "--------------------------------" $nl
	write-host "Type 'X' to cancel"
    	write-host " " $nl
}


#============================================

#function to check database copy status
#Function runs agains the selected database to see if the copies of mailbox database are in healthy state.
function copystatus
{
	if ((($databases[$dbValue]).ismailboxdatabase) -eq "True")
	{
		Write-host "Status of $selDB and its replicas(if any)" -foregroundcolor Green $nl
		write-host "-----------------------------------------" 
		" "
		[array]$copystatus =(get-mailboxdatabasecopystatus -identity ($databases[$dbValue]).name)
		($copystatus|fl) | Out-File -filepath "$path\copystatus.txt"
			for($i = 0; $i -lt ($copystatus).length; $i++ )
			{
				if (($copystatus[$i].status -eq "Healthy") -or ($copystatus[$i].status -eq "Mounted"))
				{
				write-host $copystatus[$i].name is $copystatus[$i].status
				}
				else
				{
				write-host $copystatus[$i].name is $copystatus[$i].status
				write-host "One of the copies of the seelected database is not healthy. Please run backup after ensuring that the database copy is healthy" -Foregroundcolor Yellow
				stopTransLog
				do
			{
				Write-Host
				$continue = Read-Host "Please use the <Enter> key to exit..."
			}
			While ($continue -notmatch $null)
				exit
				}
			}
	}
	Else
		{
		Write-host "Not Checking Database copy status since this is a Public Folder Database"
		}
" "
}
   
   
#==============================
#10. function to select the database to backup
function getDBtoBackup
{
	Write-host "Select the number of the database to backup" -foregroundcolor Yellow -nonewline;$script:dbtoBackup=Read-Host " "
	$noselection = $null
	if ($dbtoBackup -eq "x")
	{
		Stop-Transcript
		do
			{
				Write-Host
				$continue = Read-Host "Please use the <Enter> key to exit..."
			}
			While ($continue -notmatch $null)
		exit
	}
	else
	{
	    $script:dbValue = $dbtoBackup-1    
        
		if ((($databases[$dbValue]).ismailboxdatabase) -eq "True")
		{

		$script:dbGuid = (get-mailboxdatabase ($databases[$dbValue])).guid
	    $script:selDB = (get-mailboxdatabase ($databases[$dbValue])).name
		" "
	    "The database guid for '$selDB' is: $dbGuid"
		" "
	    $script:dbMountedOn = (get-mailboxdatabase ($databases[$dbValue])).server.name
		}
		else
		{
	    $script:dbGuid = (get-publicfolderdatabase ($databases[$dbValue])).guid
	    $script:selDB = (get-publicfolderdatabase ($databases[$dbValue])).name
	    "The database guid for '$selDB' is: $dbGuid"
		" "
	    $script:dbMountedOn = (get-publicfolderdatabase ($databases[$dbValue])).server.name
		}
	    write-host "The database is mounted on server: $dbMountedOn" $nl
	    
		if ($dbMountedOn -eq "$serverName")
		{
			$script:dbStatus = "active"
	    }
	    else
	    {
	            $script:dbStatus = "passive"
	    }        		
	
	" "
	}     
}

function Out-DHSFile 
{ 
param ([string]$fileline) 
$fileline | Out-File -filepath "$path\diskshadow.dsh" -Encoding ASCII -Append 
}


function Out-removeDHSFile 
{ 
param ([string]$fileline) 
$fileline | Out-File -filepath "$path\removeSnapshot.dsh" -Encoding ASCII -Append 
}


#============================
#12. function to create diskshadow file
function createDiskShadowFile
{
	
#	creates the diskshadow.dsh file that will be written to below
#	-------------------------------------------------------------
	" "
	Write-host "Creating diskshadow file..." -foregroundcolor Green $nl
			   "---------------------------" 
			   " "
	get-Date
	" "	
	new-item -path $path\diskshadow.dsh -type file -force | Out-Null

#	beginning lines of file
#	-----------------------
	Out-DHSFile "set verbose on"
	Out-DHSFile "set context persistent"
	Out-DHSFile " "

#	writers to exclude
#	------------------
	Out-DHSFile "writer exclude {e8132975-6f93-4464-a53e-1050253ae220}"
	Out-DHSFile "writer exclude {2a40fd15-dfca-4aa8-a654-1f8c654603f6}"
	Out-DHSFile "writer exclude {35E81631-13E1-48DB-97FC-D5BC721BB18A}"
	Out-DHSFile "writer exclude {be000cbe-11fe-4426-9c58-531aa6355fc4}"
	Out-DHSFile "writer exclude {4969d978-be47-48b0-b100-f328f07ac1e0}"
	Out-DHSFile "writer exclude {a6ad56c2-b509-4e6c-bb19-49d8f43532f0}"
	Out-DHSFile "writer exclude {afbab4a2-367d-4d15-a586-71dbb18f8485}"
	Out-DHSFile "writer exclude {59b1f0cf-90ef-465f-9609-6ca8b2938366}"
	Out-DHSFile "writer exclude {542da469-d3e1-473c-9f4f-7847f01fc64f}"
	Out-DHSFile "writer exclude {4dc3bdd4-ab48-4d07-adb0-3bee2926fd7f}"
	Out-DHSFile "writer exclude {41e12264-35d8-479b-8e5c-9b23d1dad37e}"
	Out-DHSFile "writer exclude {12ce4370-5bb7-4C58-a76a-e5d5097e3674}"
	Out-DHSFile "writer exclude {cd3f2362-8bef-46c7-9181-d62844cdc062}"
	Out-DHSFile "writer exclude {dd846aaa-A1B6-42A8-AAF8-03DCB6114BFD}"
	Out-DHSFile "writer exclude {B2014C9E-8711-4C5C-A5A9-3CF384484757}"
	Out-DHSFile "writer exclude {BE9AC81E-3619-421F-920F-4C6FEA9E93AD}"	
	Out-DHSFile "writer exclude {F08C1483-8407-4A26-8C26-6C267A629741}"
	Out-DHSFile "writer exclude {6F5B15B5-DA24-4D88-B737-63063E3A1F86}"
	Out-DHSFile "writer exclude {368753EC-572E-4FC7-B4B9-CCD9BDC624CB}"
	Out-DHSFile "writer exclude {5382579C-98DF-47A7-AC6C-98A6D7106E09}"
	Out-DHSFile "writer exclude {d61d61c8-d73a-4eee-8cdd-f6f9786b7124}"
	Out-DHSFile "writer exclude {75dfb225-e2e4-4d39-9ac9-ffaff65ddf06}"
	Out-DHSFile "writer exclude {0bada1de-01a9-4625-8278-69e735f39dd2}"
	Out-DHSFile " "

#	add databases to exclude
#	------------------------
	foreach ($db in $databases)
		{
		$dbg = ($db.guid)
		
		if (($db).guid -ne $dbGuid)
			{
			if (($db.ismailboxdatabase) -eq "True")
			{				
			$mountedOnServer = (get-mailboxdatabase $db).server.name
			}
			else
			{
			$mountedOnServer = (get-publicfolderdatabase $db).server.name
			}
			if ($mountedOnServer -eq $serverName)
			{
			$script:activeNode = $true
			
			Out-DHSFile "writer exclude `"Microsoft Exchange Writer:\Microsoft Exchange Server\Microsoft Information Store\$serverName\$dbg`""
			}
		#if passive copy, add it with replica in the string
		else
		{
		$script:activeNode = $false
		Out-DHSFile "writer exclude `"Microsoft Exchange Replica Writer:\Microsoft Exchange Server\Microsoft Information Store\Replica\$serverName\$dbg`""
		}			
			}
#	add database to include
#	-----------------------		
		else 
			{			
			if (($db.ismailboxdatabase) -eq "True")
			{
			$mountedOnServer = (get-mailboxdatabase $db).server.name
			}
			else
			{
			$mountedOnServer = (get-publicfolderdatabase $db).server.name
			}
			
						
				
			}
		}
		Out-DHSFile " "
	
#	-------------
	Out-DHSFile "Begin backup"

#	add the volumes for the included database
#	-----------------------------------------
	#gets a list of mount points on local server
	$mpvolumes = get-wmiobject -query "select name, deviceid from win32_volume where drivetype=3 AND driveletter=NULL" 
	$deviceIDs = @()
	
	#if selected database is a mailbox database, get mailbox paths
	if ((($databases[$dbValue]).ismailboxdatabase) -eq "True")
	{
		$getDB = (get-mailboxdatabase $selDB)
	    
   		$dbMP = $false
		 $logMP = $false
		
		#if no mountpoints ($mpvolumes) causes null-valued error, need to handle
		if ($mpvolumes -ne $null)
		{ 
		foreach ($mp in $mpvolumes)
		{
		$mpname=(($mp.name).substring(0,$mp.name.length -1))
			#if following mount point path exists in database path use deviceID in diskshadow config file
			 if ($getDB.edbFilePath.pathname.ToString().ToLower().StartsWith($mpname.ToString().ToLower()))
			 {
			 Write-Host " "
			 write-host "Mount point: " $mp.name " in use for database path: "
			 #Write-host "Yes. I am a database in mountpoint"
			 "The current database path is: " + $getDB.edbFilePath.pathname
			 Write-Host "adding deviceID to file: "
			 $dbEdbVol = $mp.deviceid
			 Write-Host $dbEdbVol
	
			 #add device ID to array
			  $deviceID1 = $mp.DeviceID
			 $dbMP = $true
			}
		
			#if following mount point path exists in log path use deviceID in diskshadow config file
			 if ($getDB.logFolderPath.pathname.ToString().ToLower().contains($mpname.ToString().ToLower()))
			 {
			 Write-Host " "
			 write-host "Mount point: " $mp.name " in use for log path: "
			 #Write-host "Yes. My logs are in a mountpoint"
			 "The log folder path of selected database is: " + $getDB.logfolderPath.pathname
			 Write-Host "adding deviceID to file: "
			 $dbLogVol = $mp.deviceid
			 write-host $dbLogVol
			 $deviceID2 =$mp.DeviceID
			 $logMP = $true	
			 }
			
		}
		$deviceIDs = $deviceID1,$deviceID2
		}
	}	
	
	#if not a mailbox database, assume its a public folder database, get public folder paths
	
	if ((($databases[$dbValue]).ispublicfolderdatabase) -eq "True")
	{
	$getDB = (get-publicfolderdatabase $selDB)
	
	$dbMP = $false
	$logMP = $false
	
	if ($mpvolumes -ne $null)
	{
	foreach ($mp in $mpvolumes)
			{
$mpname=(($mp.name).substring(0,$mp.name.length -1))	
	#if following mount point path exists in database path use deviceID in diskshadow config file
			
			if ($getDB.edbFilePath.pathname.ToString().ToLower().StartsWith($mpname.ToString().ToLower()))
			{
			Write-Host " "
			write-host "Mount point: " $mp.name " in use for database path: "
			"The current database path is: " + $getDB.edbFilePath.pathname
			Write-Host "adding deviceID to file: "
			$dbEdbVol = $mp.deviceid
			Write-Host $dbvol
	
			#add device ID to array
			$deviceID1 = $mp.DeviceID
			$dbMP = $true
			}
		
			#if following mount point path exists in log path use deviceID in diskshadow config file
			
			 if ($getDB.logFolderPath.pathname.ToString().ToLower().contains($mpname.ToString().ToLower()))
			 {
			 Write-Host " "
			 write-host "Mount point: " $vol.name " in use for log path: "
			"The log folder path of selected database is: " + $getDB.logfolderPath.pathname
			 Write-Host "adding deviceID to file "
			 $dbLogVol = $mp.deviceid
			 write-host $dblogvol
	
			 $deviceID2 =$mp.DeviceID
			 $logMP = $true	
			 }
		}
	$deviceIDs = $deviceID1,$deviceID2
	}
	}
			
	if ($dbMP -eq $false)
	{
	$dbEdbVol = ($getDB.edbfilepath.pathname).substring(0,2)
	Write-Host " "
	write-host "Volume: " $dbEdbVol " in use for database path: "
	
	"The current database path is: " + $getDB.edbFilePath.pathname
	Write-Host "adding volume" $dbEdbVol " to file"
	$deviceID1 = $dbEdbVol	
	}
	
	if ($logMP -eq $false)
	{
	$dbLogVol = ($getDB.logFolderpath.pathname).substring(0,2)
	Write-Host " "
	write-host "Volume: " $dbLogVol " in use for log path: "
	
	"The log folder path of selected database is: " + $getDB.logFolderpath.pathname
	Write-Host "adding volume" $dbLogVol " to file"
	$deviceID2 = $dbLogVol
	}
	
#Here is whwre we start adding the appropriate volume or mountpoint to the disk shadow file
#We are making sure , that we add only one Logical volume when we detect databases and log files are in same volume 
	
	$deviceIDs = $deviceID1,$deviceID2 
	$comp = [string]::Compare($deviceID1, $deviceID2, $True)
	If($comp -eq 0)
	{
	$dID = $deviceIDs[0]
	#Write-host "$dID"	
	" "
	Write-host "Making sure we add the volume once since Database and Log files are in the same volume"
	if ($dID.length -gt "2")
	 {
	 Write-Host "add volume $dID alias vss_test_"($dID).tostring().substring(11,8)
	 $addVol = "add volume $dID alias vss_test_" + ($dID).tostring().substring(11,8)
	 Out-DHSFile $addVol
	 }
	 else
	{
	
	Write-Host "add volume $dID alias vss_test_"($dID).tostring().substring(0,1)
	$addVol = "add volume $dID alias vss_test_" + ($dID).tostring().substring(0,1)
	Out-DHSFile $addVol
	}
	
	}

	
	else
	 {
	Write-Host " "
	foreach ($device in $deviceIDs)
	{
	if ($device.length -gt "2")
	 {
	 Write-Host "Adding the Mount Point for DSH file"
	 Write-Host "add volume $device alias vss_test_"($device).tostring().substring(11,8)
	 $addVol = "add volume $device alias vss_test_" + ($device).tostring().substring(11,8)
	 Out-DHSFile $addVol
	 }
	 else
	{
	Write-Host "Adding the volume for DSH file"
	Write-Host "add volume $device alias vss_test_"($device).tostring().substring(0,1)
	$addVol = "add volume $device alias vss_test_" + ($device).tostring().substring(0,1)
	Out-DHSFile $addVol
	}
	}
	 }
	Out-DHSFile "create"	
	Out-DHSFile " "


#expose each volume needed
#-----------------------------
# add exposed drives IF $exposeSnapshot is equal to true or $getitall is set to true
# ------------------------------------------------------

if (($exposeSnapshot -eq $true) -or ($getItAll -eq $true))
{
# check to see if the drives are the same for both database and logs
# if the same drives are used, only one drive is needed for exposure
	
	if ($dbEdbVol -eq $dbLogVol)
		{
		$nl
		"The database and transaction log path are on the same volume: $dbLogVol"
		" "
		# prompt for a drive letter to use
		"A drive letter is needed to expose the snapshot of the DATABASE and TRANSACTION LOG drive. (Examples X:,Y:,Z:,)"	
		Write-host "Enter a drive letter (with colon) that is NOT currently in use"-foregroundcolor Yellow -nonewline;$script:dbsnapvol = read-host " "
		if (!($dbsnapvol.endswith(":")))
		{
		"Please use a colon (X:) with the drive letter."
		$script:dbsnapvol = read-host "Enter a drive letter (with colon) that is NOT currently in use"
		}
		if (($dbsnapvol).count -gt "2")
		{
		"Please use a single letter and colon, Example: X: "
		$script:dbsnapvol = read-host "Enter a drive letter (with colon) that is NOT currently in use"
		}
		}
	   else
		{
		#prompt for a drive letter to use
		#check if multiple drives needed
		" "
		Write-host "Getting Drive letters to expose snapshots " -foregroundcolor Green $nl
		"----------------------------------------- " + $nl
		" "
		"The current database path is: " + $getDB.edbFilePath.pathname
		" "
		"A drive letter is needed to expose the snapshot of the DATABASE drive. (Examples X:,Y:,Z:,)"	
		write-host "Enter a drive letter (with colon) that is NOT currently in use" -foregroundcolor Yellow -nonewline;$script:dbsnapvol = read-host " "

		" "
		"The current transaction log path is: " + $getDB.logFolderPath.pathname
		" "
		"A drive letter is needed to expose the snapshot of the TRANSACTION LOG drive.Please specify a drive letter other than what you have already specified for exposing snapshot database drive"
		Write-host "Enter a drive letter (with colon) that is NOT currently in use" -foregroundcolor Yellow -nonewline;$script:logsnapvol = read-host " "
		if($dbsnapvol -eq $logsnapvol)
		{
		Write-Host " "
		Write-host "You need to specify two differnt drive letters" -foregroundcolor Yellow
		$script:logsnapvol = read-host "Enter a drive letter (with colon) that is NOT currently in use"
		}
		
		" "
		}
	


#	expose the drives
#	if volumes are the same only one entry is needed
	if ($dbEdbVol -eq $dbLogVol)
	{
		if ($dbEdbVol.length -gt "2")
		{
		$dbvolstr = "expose %vss_test_" + ($dbEdbVol).substring(11,8) + "% $dbsnapvol"
		Out-DHSFile $dbvolstr
		}
		else
		{
		$dbvolstr = "expose %vss_test_" + ($dbEdbVol).substring(0,1) + "% $dbsnapvol"
		Out-DHSFile $dbvolstr
		}
	}
#	volumes are different, getting both
	else
	{
		#if mountpoint use first part of string, if not use first letter
		if ($dbEdbVol.length -gt "2")
		{
		$dbvolstr = "expose %vss_test_" + ($dbEdbVol).substring(11,8) + "% $dbsnapvol"
		Out-DHSFile $dbvolstr
		}
		Else
		{
		$dbvolstr = "expose %vss_test_" + ($dbEdbVol).substring(0,1) + "% $dbsnapvol"
		Out-DHSFile $dbvolstr
		}
		
		#if mountpoint use first part of string, if not use first letter
		if ($dbLogVol.length -gt "2")
		{
		$logvolstr = "expose %vss_test_" + ($dbLogVol).substring(11,8) + "% $logsnapvol"	
		Out-DHSFile $logvolstr
		}
		else
		{
		$logvolstr = "expose %vss_test_" + ($dbLogVol).substring(0,1) + "% $logsnapvol"	
		Out-DHSFile $logvolstr
		}
	}
}

#	ending data of file
#	-------------------
	Out-DHSFile "end backup"

}

#Funciton to remove exposed snapshots
#====================================

function removeExposedDrives
{
	" "
	Write-host "Diskshadow Snapshots" -foregroundcolor Green $nl
			   "-------------------"
	" "
	get-Date
	Write-Host " "
	"If the snapshot was successful, the snapshot should be exposed. You should be able to see and navigate them with Windows Explorer. How would you like to proceed?"
	Write-host " "
	Write-host "When ready, choose from options below" -foregroundcolor Yellow
	" "
	write-host "1.Remove Snapshots" 
	write-host "2.Expose Snapshots in Windows Explorer"
	Write-host " "
	Write-Warning "Selecting option 1 will permanently delete the snapshot created.Please be very sure before selecting the option"
	" "
	Write-host "Selection" -foregroundcolor Yellow -nonewline; $removeExpose = read-host " "
	
	if ($removeExpose -eq "1")
	{
	#	creates the removeSnapshot.dsh file that will be written to below
	#	-------------------------------------------------------------
	
	new-item -path $path\removeSnapshot.dsh -type file -force

	if ($logsnapvol -eq $null)
	{
	Out-removeDHSFile "delete shadows exposed $dbsnapvol"
	}
	else
	{
	Out-removeDHSFile "delete shadows exposed $dbsnapvol"
	Out-removeDHSFile "delete shadows exposed $logsnapvol"
	}
	Out-removeDHSFile "exit"

	invoke-expression "&'C:\Windows\System32\diskshadow.exe' /s $path\removeSnapshot.dsh"
	
	}
	elseif ($removeExpose -eq "2")
	{
	"You can remove the snapshots at a later time using the diskshadow command from a command prompt. Run Diskshadow, followed by 'delete shadows exposed <volume>'"
	"Example: 'delete shadows exposed z:'"
	}
	
	else
	{
	" "
	Write-host "You entered an invalid option. Select between option '1' and '2'" -foregroundcolor Red
	removeExposedDrives
	}	
}

function runDiskShadow
{
	write-host " " $nl
	write-host " " $nl
	write-host "Starting DiskShadow copy of Exchange database: $selDB" -foregroundcolor Green $nl
	" "
	get-Date
	" "
	write-host "Running the following command:" $nl
	write-host "`"C:\Windows\System32\diskshadow.exe /s $path\diskshadow.dsh /l $path\diskshadow.log`"" $nl
	write-host " "
	
	diskshadow.exe /s $path\diskshadow.dsh /l $path\diskshadow.log
}

function Out-ExTRAConfigFile 
{ 
param ([string]$fileline) 
$fileline | Out-File -filepath "C:\EnabledTraces.Config" -Encoding ASCII -Append 
}

function create-ExTRATracingConfig
{
	" "
	Write-host "Enabling ExTRA Tracing" -foregroundcolor Green $nl
			   "----------------------"
	" "
	get-Date
	" "
new-item -path "C:\EnabledTraces.Config" -type file -force
	Out-ExTRAConfigFile "TraceLevels:Debug,Warning,Error,Fatal,Info,Performance,Function,Pfd"
	Out-ExTRAConfigFile "Store:tagEseBack,tagVSS,tagJetBackup,tagJetRestore"
	Out-ExTRAConfigFile "Cluster.Replay:ReplicaVssWriterInterop,ReplicaInstance,LogTruncater"
	Out-ExTRAConfigFile "FilteredTracing:No"
	Out-ExTRAConfigFile "InMemoryTracing:No"	
	" "
}

#if the user runs the script on passive node to monitor /perform passive copy backup ExTRA will be turned on in active node and at end of the backup, output ETL will be copied over to the active node

function enable-ExTRATracing
{
	
	#active server, only get tracing from active node
	if ($dbMountedOn -eq $serverName)
	{
	" "
	"Creating Exchange Trace data collector set..."
	logman create trace VSSTester -p "Microsoft Exchange Server 2010" -o $path\vsstester.etl 
	"Starting Exchange Trace data collector..."
	logman start VSSTester
	" "
	}
	#passive server, get tracing from both active and passive nodes
	else
	{
	" "
	"Copying the ExTRA config file 'EnabledTraces.config' file to $dbMountedOn..."
	#copy enabledtraces.config from current passive copy to active copy server
	copy "c:\EnabledTraces.Config" "\\$dbMountedOn\c$\enabledtraces.config"
	
	#create trace on passive copy
	"Creating Exchange Trace data collector set on $serverName..."
	logman create trace VSSTester-Passive -p "Microsoft Exchange Server 2010" -o $path\vsstester-passive.etl -s $serverName
	#create trace on active copy
	"Creating Exchange Trace data collector set on $dbMountedOn..."
	logman create trace VSSTester-Active -p "Microsoft Exchange Server 2010" -o $path\vsstester-active.etl -s $dbMountedOn
	#start trace on passive copy	
	"Starting Exchange Trace data collector on $serverName..."
	logman start VSSTester-Passive -s $serverName
	#start trace on active copy
	"Starting Exchange Trace data collector on $dbMountedOn..."
	logman start VSSTester-Active -s $dbMountedOn
	" "
	}
	
	
}

function disable-ExTRATracing
{
	" "
	Write-host "Disabling ExTRA Tracing" -foregroundcolor Green $nl
				"-----------------------" 
	" "
	get-Date
	" "
	if ($dbMountedOn -eq "$serverName")
	{
	#stop active copy
	Write-Host " "
	"Stopping Exchange Trace data collector on $serverName..." 
	logman stop vssTester -s $serverName
	"Deleting Exchange Trace data collector on $serverName..." 
	logman delete vssTester -s $serverName
	" "
	}
	
	else
	{
	#stop passive copy
	"Stopping Exchange Trace data collector on $serverName..." 
	logman stop vssTester-Passive -s $serverName
	"Deleting Exchange Trace data collector on $serverName..." 
	logman delete vssTester-Passive -s $serverName
	#stop active copy
	"Stopping Exchange Trace data collector on $dbMountedOn..." 
	logman stop vssTester-Active -s $dbMountedOn
	"Deleting Exchange Trace data collector on $dbMountedOn..." 
	logman delete vssTester-Active -s $dbMountedOn
	" "
	"Moving ETL file from $dbMountedOn to $serverName..."
	" "
	$etlPath = $path -replace ":\\", "$\"
	move "\\$dbMountedOn\$etlPath\vsstester-active_000001.etl" "\\$servername\$etlPath\vsstester-active_000001.etl"
	}

}

#Function to get the path - save config files for diskshadow and output logs.

function get-Path
{
   $pathexists=$null
	" " 
	Write-host "Please specify a location other than root of a volume to save the configuration and output files" -foregroundcolor Green
	" "
	Write-host "Enter a directory to save the configuration and output files" -foregroundcolor Yellow -nonewline; $script:path = Read-Host " "
	" "
#checking path provided
	if(($path -notmatch ":") -or ($path -notlike "*\*"))
	{
	Write-host "Error! Please enter a valid path" -foregroundcolor Red
	" "
	get-path
	}
	$pathExists = Test-Path -Path "$path"
	#"Current Path: $path"
	if ($pathExists -eq $true)
	{
	"The path exists continuing..."
	}
	else
	{
	Write-host "The path does not exist, would you like to create it now?" -Nonewline; Write-host " (Y/N)" -foregroundcolor Yellow -nonewline; $pathCreate = read-host " "
		if (($pathCreate -eq "Y") -or ($pathCreate -eq  "y") -or ($pathCreate -eq "yes") -or ($pathCreate -eq "YES"))
		{
		New-Item $path -type directory | out-null
		}
		elseif(($pathCreate -eq "N") -or ($pathCreate -eq "n") -or ($pathCreate -eq "no") -or ($pathCreate -eq "NO"))
		{
		Write-host " "
		Write-host "The path does not exist and you've chosen not to have it created. Create the directory and run the script again." -foregroundcolor Yellow
		do
			{
				Write-Host
				$continue = Read-Host "Please use the <Enter> key to exit..."
			}
			While ($continue -notmatch $null)
		exit
		}
	}	
}

#starts OS level VSS tracing
function enableVSSTracing
{
" "
Write-host "Starting VSS Tracing..." -foregroundcolor Green $nl
Write-host "-----------------------" 
" "
get-Date
" "
logman start vss -o $path\vss.etl -ets -p "{9138500e-3648-4edb-aa4c-859e9f7b7c38}" 0xfff 255
}
#stop VSS tracings collection
function disableVSSTracing
{
" "
Write-host "Stopping VSS Tracing..." -foregroundcolor Green $nl
Write-host "-----------------------"
" "
get-Date
" "
logman stop vss -ets
" "
}

#Here is where we wait for the end user to perform the backup using the backup software and then come back to the script to press "Enter", thereby stopping data collection
function start-3rdpartybackup
{
Write-host "Data Collection" -foregroundcolor green $nl
Write-host "---------------"
" "
get-Date
write-host " "
Write-Host "Data collection is now enabled.  Please start your backup using the third party software so the script can record the diagnostic data." -foregroundcolor Yellow
Write-host "When the Backup is COMPLETE use the <Enter> key to terminate data collection" -foregroundcolor Yellow -nonewline;Read-host " "
}

function get-applogs
{
" "	

write-host "Getting events in the application and system logs from the start time, ($startInfo)" -foregroundcolor Green $nl
write-host "-----------------------------------------------------------------------------------"  
" "
get-Date
" "
"Getting application log events..."
Get-WinEvent -LogName application -Oldest -ea silentlycontinue | where {$_.timecreated -ge ($startInfo.ToShortTimeString()) } | Select TimeCreated,ID,LevelDisplayName,ProviderName,Message |export-csv  $path\events-App.csv
"Getting system log events..."
Get-WinEvent -LogName system -Oldest -ea silentlycontinue | where {$_.timecreated -ge ($startInfo.ToShortTimeString()) } | Select TimeCreated,ID,LevelDisplayName,ProviderName,Message | export-csv  $path\events-Sys.csv
"Getting events complete"
}


 

#Based on the mail menu selection , we will execute the differnt functions. We will perform get-path irrespective of the selection because we have to write the logs
	
	get-Path
			
	if ($Selection -eq 1)
		{
		$getitall = $true
		startTranslog
		getLocalServerName
		exchVersion
		listVSSWritersBefore
		getDatabases
		getDBtoBackup
		copystatus
		createDiskShadowFile
		enableDiagLogging
		enableVSSTracing
		create-ExTRATracingConfig
		enable-ExTRATracing
		runDiskShadow
		disable-ExTRATracing
		disableDiagLogging
		disableVSSTracing
		listVSSWritersAfter
		removeExposedDrives
		get-applogs
		stopTransLog
		
		}
		
	elseif($Selection -eq 2)
		{
		$loggingonly = $true
		startTranslog
		getLocalServerName
		exchVersion
		listVSSWritersBefore
		getDatabases
		getDBtoBackup
		copystatus
		enableDiagLogging
		enableVSSTracing
		create-ExTRATracingConfig
		enable-ExTRATracing
		start-3rdpartybackup
		disable-ExTRATracing
		disableDiagLogging
		disableVSSTracing
		listVSSWritersAfter
		get-applogs
		stopTransLog
		}
		
	elseif($Selection -eq 3)
{
		$nl
		Write-Host "Custom Options:" 
	    Write-host "==============="
		$nl
		write-host "1.Enable Diagnostic Logging"
		write-host "2.Enable ExTRATracing"
		Write-host "3.Enable VSS Tracing"
		Write-host "4.Perform a Disk shadow backup"
		Write-host "5.Logging during 3rd Party Backup Software"
		$nl
		Write-host "It is mandatory to select option 4 or 5 along with other option(s)"-foregroundcolor Yellow
		Write-host "NOTE: Options 4 and 5 should never be selected together. Example 1,2,4 or 1,3,5 or 3,5 etc" -foregroundcolor Yellow
		$nl
		
		
		do 
		{
		[array]$a = (Read-host "Choose Options to execute(Separate with commas)").split(",") | %{$_.trim()}
		$b=$null
		if($a -notmatch "^([1-5]|[1][0])$") 
			{
			$b=$true
			$nl
			Write-host "Error! Please choose options between 1 and 5!" -ForegroundColor Red
			Write-host "Please make selection again"
			$nl
			}	
		
			elseif (($a -contains 4) -and ($a -contains 5))
			{
			$nl
			$b=$true
			Write-host "NOTE: Options 4 and 5 should never be selected together. Example 1,2,4 or 1,3,5 or 3,5 etc" -foregroundcolor Yellow
			Write-host "Please make selection again"
			$nl
			}
			
			elseif (($a -notcontains 4)-and($a -notcontains 5))
			{
			$nl
			$b=$true
			Write-host "It is mandatory to select option 4 or 5 along with other option(s)"-foregroundcolor Yellow
			Write-host "NOTE: Options 4 and 5 should never be selected together. Example 1,2,4 or 1,3,5 or 3,5 etc" -foregroundcolor Yellow
			Write-host "Please make selection again"
			$nl
			}
			
			else
			{
			$b = $false
			}
		}
		while ($b -ne $false)
			
			
		$nl
	
	startTransLog
	getLocalServerName
	exchVersion
	listVSSWritersBefore
	getDatabases
	getDBtoBackup
	copystatus
	switch ($a)
		{
			1{
			#write-host "Enable Diag logging"
			$enableDiagLog = $true 
			enableDiagLogging
			}
			
			2{
			#write-host "Enable EXTRA"
			$enableExTRATracing = $true
			create-ExTRATracingConfig
			enable-ExTRATracing 
			 }
			
			3{
			 #Write-host "Enable VSS Tracing"
			 $enableVSSTracing = $true
			 enableVSSTracing
			 }

			 4{
			 $enableDiskshadowBackup = $true
			 $exposeSnapshot = $true	
			 createDiskShadowFile
			 runDiskShadow
			  }

			 5{
			 start-3rdpartybackup
			  }
		}
		
	#Based on the custom selection, we will call appropriate functions	to disble logging etc.	
	
			if ($enableExTRATracing -eq $true)
			{
			disable-ExTRATracing
			}
			if ($enableDiagLog -eq $true)
			{
			disableDiagLogging
			}
			if ($enableVSSTracing -eq $true)
			{
			disableVSSTracing
			}
			if ($exposeSnapshot -eq $true)
			{
			removeExposedDrives
			}
	
	listVSSWritersAfter
	get-applogs
	stopTransLog
		}
		
	#End of script	