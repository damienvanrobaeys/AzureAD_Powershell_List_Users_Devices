If (!(Get-Module -listavailable | where {$_.name -like "*AzureAD*"})) 
	{ 
		Install-Module AzureAD -ErrorAction SilentlyContinue 
	} 
Else 
	{ 
		Import-Module AzureAD -ErrorAction SilentlyContinue 
	} 
	
Try
	{
		$Ask_Creds = Connect-AzureAD
		write-host "Conexion OK to your tenant"
	}
Catch
	{
		write-host "Conexion KO to your tenant"	
	}

$Get_All_Users = Get-AzureADUser -All $true
$Users_report = @()
ForEach($User in $Get_All_Users)
	{
		$User_ObjectID = $User.ObjectID	
		$User_DisplayName = $User.DisplayName
		$User_Mail = $User.UserPrincipalName
		$User_Mobile = $User.Mobile
		$User_OU = $User.extensionproperty.onPremisesDistinguishedName
		$User_Account_Status = $User.AccountEnabled
		
		$Get_User_Devices = (Get-AzureADUserRegisteredDevice -ObjectId $User_ObjectID)
		$Count_User_Devices = $Get_User_Devices.count
				
		$User_Owner_Obj = New-Object PSObject
		$User_Owner_Obj | Add-Member NoteProperty -Name "User Name" -Value $User_DisplayName
		$User_Owner_Obj | Add-Member NoteProperty -Name "User Mail" -Value $User_Mail -force
		$User_Owner_Obj | Add-Member NoteProperty -Name "User OU" -Value $User_OU -force
		$User_Owner_Obj | Add-Member NoteProperty -Name "Account enabled ?" -Value $User_Account_Status		
		$User_Owner_Obj | Add-Member NoteProperty -Name "Devices count" -Value $Count_User_Devices -force
				
		If($Count_User_Devices -eq 0)
			{
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device name" -Value "No device" -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device last logon" -Value "No device" -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS type" -Value "No device" -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS version" -Value "No device" -force
			}
			
		If($Count_User_Devices -gt 1)
			{
				$Devices_LastLogon = @()
				$Devices_OSType = @()
				$Devices_OSVersion = @()
				$Devices_DisplayName = @()
				
				$Devices_LastLogon = ""
				$Devices_OSType = ""
				$Devices_OSVersion = ""
				$Devices_DisplayName = ""

				ForEach($Device in $Get_User_Devices)
					{
						$Device_LastLogon = $Device.ApproximateLastLogonTimeStamp
						$Device_OSType = $Device.DeviceOSType
						$Device_OSVersion = $Device.DeviceOSVersion
						$Device_DisplayName = $Device.DisplayName
						
						If ($owner -eq $Get_User_Devices[-1])
							{
								$Devices_LastLogon += "$Device_LastLogon" 
								$Devices_OSType += "$Device_OSType"
								$Devices_OSVersion += "$Device_OSVersion"
								$Devices_DisplayName += "$Device_DisplayName"
							}
						Else
							{
								$Devices_LastLogon += "$Device_LastLogon`n" 
								$Devices_OSType += "$Device_OSType`n"
								$Devices_OSVersion += "$Device_OSVersion`n"
								$Devices_DisplayName += "$Device_DisplayName`n"
							}
					}

				$User_Owner_Obj | Add-Member NoteProperty -Name "Device name" -Value $Devices_DisplayName -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device last logon" -Value $Devices_LastLogon -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS type" -Value $Devices_OSType -force	
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS version" -Value $Devices_OSVersion -force
			}
		Else		
			{
				$Device_LastLogon = $Get_User_Devices.ApproximateLastLogonTimeStamp
				$Device_OSType = $Get_User_Devices.DeviceOSType
				$Device_OSVersion = $Get_User_Devices.DeviceOSVersion
				$Device_DisplayName = $Get_User_Devices.DisplayName

				$User_Owner_Obj | Add-Member NoteProperty -Name "Device name" -Value $Device_DisplayName -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device last logon" -Value $Device_LastLogon -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS type" -Value $Device_OSType -force	
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS version" -Value $Device_OSVersion -force
				
			}
		$Users_report += $User_Owner_Obj
	}
	
$Users_report | out-gridview		
$Users_report| export-csv "CSV_Path\list_Users_Devices.csv" -notype -delimiter ";" 
