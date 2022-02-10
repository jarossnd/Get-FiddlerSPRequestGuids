	<#
	.SYNOPSIS

	Outputs the SPRequestGuids from the server response headers to the screen

	.DESCRIPTION

	Outputs the SPRequestGuids from the server response headers to the screen

	.PARAMETER traceFile

	The full path to the Fiddler Trace

	.EXAMPLE

	.\Get-FiddlerSPRequestGuids.ps1 -traceFile .\myTrace.saz

	#>

	[CmdletBinding()]param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$traceFile
		)

$global:Correlations =@()

	function Process-FiddlerTrace($traceFile) {



		Write-Host "`n"; Write-Host "Extracting and processing the Fiddler Trace..." -ForegroundColor Green
		$tempFileName = [System.IO.Path]::GetTempFileName() + '.zip'
		$tempPath = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName().replace(".","")
		New-Item -Path $tempPath -ItemType Directory
		Copy-Item -Path $traceFile -Destination $tempFileName
		Expand-Archive -Path $tempFileName -Force -DestinationPath $tempPath
		
		# Find Correlation ID's in the extracted ZIP file
		
		$fiddlerFile = Get-ChildItem -Path $tempPath -Filter *_s.txt -Recurse
		$findGUID = "SPRequestGuid: "

		Write-Host "`n"
		
		foreach ($fiddlerLine in $fiddlerFile) {

			$foundGUID = Select-String -Pattern $findGUID -Path $fiddlerLine
			
			if($foundGUID -ne $null) {
				
	        $correlationID = $foundGUID.Line.ToString().Replace($findGUID,"")
	 
	        $date = Select-String -pattern "Date: " -Path $fiddlerLine | select -First 1
					
	        $date = [System.DateTime]$date.Line.ToString().replace("Date: ","")
			
			$UTCtime = $date.ToUniversalTime()

			$traceTimeUTC = $UTCtime.ToString("yyyy-MM-dd HH:mm:ss")

			# Get URL so that we can display output on sceen

			$requestfilename = $fiddlerLine.FullName.replace("_s.txt","_c.txt")

			$urlRaw = Select-String -Pattern "https://" -Path $requestfilename | select -First 1
			
			$urlRawString = $urlRaw.ToString().Split(" ")
			
			$fullUrl = $urlRawString[1]; $splitUrl = $fullUrl.Split("/"); $url = $splitUrl[2];


					
			Write-Host "Found CID " -ForegroundColor White -NoNewline; Write-Host $correlationID -ForegroundColor Red -NoNewline; Write-Host " on " -ForegroundColor Gray -NoNewline; Write-Host "$traceTimeUTC(UTC)" -ForegroundColor White -NoNewline; Write-Host " at" -ForegroundColor Gray -NoNewline; Write-Host " $url";
    
			$obj = New-Object PSObject
    		Add-Member -InputObject $obj -MemberType NoteProperty -Name Correlation -Value $correlationID
    		Add-Member -InputObject $obj -MemberType NoteProperty -Name UTCTime -Value $traceTimeUTC
			$global:Correlations+= $obj
			
			}

		}
}


Process-FiddlerTrace $TraceFile