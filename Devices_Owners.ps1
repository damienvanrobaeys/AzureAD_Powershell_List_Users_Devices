[CmdletBinding()]
Param(
		[Parameter(Mandatory=$false)]	
		[string]$Tattoo_XML_Path
	 )	


If (!(Get-Module -listavailable | where {$_.name -like "*AzureAD*"})) 
	{ 
		Install-Module AzureAD -ErrorAction SilentlyContinue 
	} 
Else 
	{ 
		Import-Module AzureAD -ErrorAction SilentlyContinue 			
	} 
	
$Ask_Creds = Connect-MSGraph

Try
	{
		$Ask_Creds = Connect-MSGraph
		write-host "Conexion OK to your tenant"
	}
Catch
	{
		write-host "Conexion KO to your tenant"	
	}
		

$Get_All_Devices = Get-AzureADDevice -All $true
$Devices_report = @()
ForEach($Device in $Get_All_Devices)
	{	
		$found = $false
	
		$Device_ObjectID = $Device.ObjectID
		$Device_LastLogon = $Device.ApproximateLastLogonTimeStamp
		$Device_DeviceId = $Device.DeviceId
		$Device_DeviceOSType = $Device.DeviceOSType
		$Device_DeviceOSVersion = $Device.DeviceOSVersion
		$Device_DisplayName = $Device.DisplayName
		$Device_DeviceTrustType = $Device.DeviceTrustType
		$Device_Account_Status = $Device.AccountEnabled
						
		$Get_Devices_Owners = Get-AzureADDeviceRegisteredOwner -ObjectId $Device_ObjectID
		$Count_Device_Owners = $Get_Devices_Owners.count
		
		$Device_Owner_Obj = New-Object PSObject
		$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Name" -Value $Device_DisplayName				
		$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Last logon" -Value $Device_LastLogon -force
		$Device_Owner_Obj | Add-Member NoteProperty -Name "Is account enabled ?" -Value $Device_Account_Status -force		
		$Device_Owner_Obj | Add-Member NoteProperty -Name "Device OS" -Value $Device_DeviceOSType -force		
		$Device_Owner_Obj | Add-Member NoteProperty -Name "Device OS version" -Value $Device_DeviceOSVersion -force	
		$Device_Owner_Obj | Add-Member NoteProperty -Name "Owner count" -Value $Count_Device_Owners -force			
		
		If($Count_Device_Owners -eq 0)
			{
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner name" -Value "No owner" -force		
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner mail" -Value "No owner" -force		
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner OU" -Value "No owner" -force						
			}
							
		ElseIf($Count_Device_Owners -gt 1)
			{
				$Owners_Name = @()
				$Owners_Mail = @()
				$Owners_OU = @()
				
				$Owners_Name = ""
				$Owners_Mail = ""
				$Owners_OU = ""

				ForEach($Owner in $Get_Devices_Owners)
					{		
						$Owner_DisplayName = $Owner.DisplayName
						$Owner_Mail = $Owner.UserPrincipalName
						$Owner_Mobile = $Owner.Mobile
						$Owner_OU = $Owner.extensionproperty.onPremisesDistinguishedName		

						If ($owner -eq $Get_Devices_Owners[-1])
							{
								$owners_Name += "$owner_displayName"
								$Owners_Mail += "$Owner_Mail" 
								$Owners_OU += "$Owner_OU" 									
							}
						Else
							{
								$owners_Name += "$owner_displayName`n" 			
								$Owners_Mail += "$Owner_Mail`n" 
								$Owners_OU += "$Owner_OU`n" 									
							}													
					}		
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner name" -Value $Owners_Name -force		
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner mail" -Value $Owners_Mail -force
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner OU" -Value $Owners_OU -force												
			}			
		Else
			{
				$Owner_DisplayName = $Get_Devices_Owners.DisplayName		
				$Owner_Mail = $Get_Devices_Owners.UserPrincipalName
				$Owner_Mobile = $Get_Devices_Owners.Mobile
				$Owner_OU = $Get_Devices_Owners.extensionproperty.onPremisesDistinguishedName		
				
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner name" -Value $Owner_DisplayName -force		
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner mail" -Value $Owner_Mail -force		
				$Device_Owner_Obj | Add-Member NoteProperty -Name "Device Owner OU" -Value $Owner_OU -force											
			}
		$Devices_report += $Device_Owner_Obj
	}
	
$Devices_report | out-gridview	
$Devices_report	| export-csv "CSV_Path\list_devices_owner.csv" -notype -delimiter ";" 
		
		
		
		
