#========================================

Write-Host "Octopus.Action.Package.NuGetPackageId = $OctopusActionPackageNuGetPackageId"

if ( ($OctopusActionPackageUpdateIisWebsiteName -ne $null) -and ($OctopusActionPackageUpdateIisWebsiteName -ne "") )
	{
		$IISWebSiteName=$OctopusParameters['Octopus.Action.Package.UpdateIisWebsiteName'] 
		Write-Host "IISWebSiteName is $IISWebSiteName"; 
	}
else
	{
		Write-Host "OctopusActionName is $OctopusActionName "; 
		$IISWebSiteName=$OctopusActionName
	}

#--------------------------------------------------------------------------------------------------------------------------------
$WebSitePort = 80;
#--------------------------------------------------------------------------------------------------------------------------------
$AppPoolRuntimeVersion="v4.0";
#--------------------------------------------------------------------------------------------------------------------------------

$AppPoolName = "App_$OctopusActionName"
Write-Host "AppPoolName  is  $AppPoolName";

$array = $OctopusReleaseNumber.Split('-');
$array = $array.RemoveRange(1,1);
$branchName= $array -join "-"

Write-Host "Ive got this branch $branchName from this release number $OctopusReleaseNumber "

#Write-Host "OctopusWebSiteName variable is equal null!!!";

$IISWebSiteNameCurr = $IISWebSiteName + "/" + $branchName

Set-OctopusVariable -Name "Octopus.Action.Package.UpdateIisWebsiteName" -Value $IISWebSiteNameCurr

Write-Host "Octopus Variable  site name for IISWebSiteName is $IISWebSiteNameCurr"

###########################################################################
 Import-Module WebAdministration 

if ((Test-Path -path iis:) -ne $True)
{
	throw "Must have IIS snap-in enabled."
}


$IISWebSiteNameO = $IISWebSiteName -replace "/", "\"
$IISPath = "IIS:\Sites\$IISWebSiteNameO\$branchName"

if($IISWebSiteName -like '*/*')
{
	Write-Host "doing replace slash"
	$IISWebSiteName =$IISWebSiteName.Split('/')[0];
}
$IISWebSitePath = "IIS:\Sites\$IISWebSiteName"

if (Test-Path $IISPath)
{ 
	Write-Host "Web Site and path Exists. $IISPath" 
}
else 
{
		if (Test-Path $IISWebSitePath)
		{ 
			Write-Host "Web Site Exists. $IISWebSitePath" 
		}
		else 
		{
				Write-host "Creating Website Site $IISWebSiteName !"
			  
				if (Test-Path "IIS:\AppPools\$AppPoolName")
				{
					Write-Host "WebAppPool already exist"
				}
				else
				{
					$pool = New-WebAppPool -Name $AppPoolName
		
					$pool.recycling.periodicrestart.time = [TimeSpan]::FromMinutes(0)
					$pool.processModel.idleTimeout = [TimeSpan]::FromMinutes(0)
		

					Set-ItemProperty ("IIS:\AppPools\$AppPoolName") -Name managedRuntimeVersion $AppPoolRuntimeVersion
					Set-ItemProperty ("IIS:\AppPools\$AppPoolName") -Name managedRuntimeVersion v4.0
					Set-ItemProperty ("IIS:\AppPools\"+$AppPoolName) -Name recycling.periodicrestart.time $pool.recycling.periodicrestart.time
					Set-ItemProperty ("IIS:\AppPools\"+$AppPoolName) -Name processModel.idleTimeout $pool.processModel.idleTimeout
					Set-ItemProperty ("IIS:\AppPools\$AppPoolName") -Name processModel.identityType 2 
				}
						
		}

		$a=Get-Website;
		Write-host "get website is $a"
		$ExtraIISCommandString="";
		If($a -eq $Null)
		{
			$ExtraIISCommandString += ' -Id "1" ';
			$Id="1";
		}
	  
		If($WebSiteIPAddress -ne $Null)
		{
			$ExtraIISCommandString += ' -IPAddress $WebSiteIPAddress ';
			$IPAddress=$WebSiteIPAddress;
		}
		else
		{
			$ExtraIISCommandString += ' -IPAddress "*" ';
			$IPAddress="*";
		}
				
		Write-Host '$WebSiteDomain' = "$WebSiteDomain"
		If($WebSiteDomain -ne $Null)
		{
			$ExtraIISCommandString += ' -HostHeader "$WebSiteDomain" ';
			$HostHeader="$WebSiteDomain";
		}

				Write-Host "ExtraIISCommandString  is  $ExtraIISCommandString";
	
				# CREATE WEB SITE
				Write-Host "IISWebSiteName is $IISWebSiteName" 
				
				If($a -eq $Null)
				{
					Invoke-Expression 'New-Website -Name "$IISWebSiteName" -PhysicalPath "C:\inetpub\wwwroot\" -Port "$WebSitePort" -ApplicationPool "$AppPoolName" -Id "$Id"  -IPAddress "$IPAddress"  -HostHeader "$HostHeader" '
				}
				else
				{
					Invoke-Expression 'New-Website -Name "$IISWebSiteName" -PhysicalPath "C:\inetpub\wwwroot\" -Port "$WebSitePort" -ApplicationPool "$AppPoolName"   -IPAddress "$IPAddress"  -HostHeader "$HostHeader" '
				}


				if($WebSiteAuthWindows -ne $Null)
				{
					Set-WebConfigurationProperty -filter /system.webServer/security/authentication/windowsAuthentication -name enabled -value true -PSPath $IISWebSitePath
				}
		
	    New-Item "$IISPath" -physicalPath "C:\inetpub\wwwroot\" -type Application -ApplicationPool $AppPoolName -Verbose
	} 





