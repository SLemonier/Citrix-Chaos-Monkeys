#Creating a function for each test to ease the call

#Shutdown server
function ShutDownServer {
    Write-Host "Chaos Monkey will shut down the server"
    Write-Host "Shutting down server..." -NoNewline
    Stop-Computer -ComputerName $ServerName -Force | Out-Null
    $count = 0
    while ((Test-Connection -ComputerName $ServerName -quiet)) {
        Write-host "." -NoNewline
        Start-Sleep -Seconds 5
        if($count -eq 20){
            Write-Host "Shutdown is taking a long time, please check $ServerName's state." -ForegroundColor Yellow
        }
        $count++
    }
    Write-Host " Done" -ForegroundColor Green
    Write-Host "The server was shut down successfully. It's now time to check alerts are properly raised and teams are responding accordingly." -ForegroundColor Yellow
    Write-Host "You should see:"
    Write-host "- an alert regarding License Server unavailability (e.g ping)"
    Write-Host "- an alert regarding event ID 1151 and/or 1154 from source Citrix Broker Server on your delivery controller(s)"
    Read-Host "Press any key to continue once remediation is completed"
}

#Stop and disable service
function StopAndDisableService {
    Write-Host "Chaos Monkey will stop and disable Citrix License service"
    Invoke-Command -ComputerName $ServerName -ScriptBlock {  
        Write-Host  "Stopping Citrix Licensing service..." -NoNewline
        Stop-Service -Name "Citrix Licensing" -Force -WarningAction Ignore
        $count = 0
        while ((Get-Service -Name "Citrix Licensing").Status -ne "Stopped") {
            Write-host "." -NoNewline
            Start-Sleep -Seconds 5
            if($count -eq 20){
                Write-Host "Stopping service is taking a long time, please check $ServerName's state." -ForegroundColor Yellow
            }
            $count++
        }
        Write-Host " Done" -ForegroundColor Green
        Write-Host  "Disabling Citrix Lincensing service..." -NoNewline
        Set-Service -Name "Citrix Licensing" -StartupType Disabled 
        $count = 0
        while ((Get-Service -Name "Citrix Licensing").StartType -ne "Disabled") {
            Write-host "." -NoNewline
            Start-Sleep -Seconds 5
            if($count -eq 20){
                Write-Host "Disabling service is taking a long time, please check $ServerName's state." -ForegroundColor Yellow
            }
            $count++
        }
        Write-Host " Done" -ForegroundColor Green
    }
    Write-Host "Citrix Licensing service was stopped and disabled successfully. It's now time to check alerts are properly raised and teams are responding accordingly." -ForegroundColor Yellow
    Write-Host "You should see:"
    Write-host "- an alert regarding Citrix Licensing service status"
    Write-Host "- an alert regarding event ID 1151 and/or 1154 from source Citrix Broker Server on your delivery controller(s)"
    Read-Host "Press any key to continue once remediation is completed"
}

#Remove .lic files
function RemoveLicFiles {
    Write-Host "Chaos Monkey will remove .lic files"
    Invoke-Command -ComputerName $ServerName -ScriptBlock { 
        Write-Host "Saving Citrix Licensing files in C:\DoNotDelete..." -NoNewline
        if(!(Test-Path -Path "C:\DoNotDelete")){
            New-Item -ItemType Directory -Path "C:\DoNotDelete" -Force | Out-Null 
        }
        Try{
            Move-Item -Path "C:\Program Files (x86)\Citrix\Licensing\MyFiles\*.lic" -Destination "C:\DoNotDelete" | Out-Null
        } Catch {Stop-Transcript;break}
        Write-Host " Done" -ForegroundColor Green
        Write-Host  "Removing Citrix Licensing files..." -NoNewline
        try {
            Remove-Item -Path "C:\Program Files (x86)\Citrix\Licensing\MyFiles\*.lic" -Force | Out-Null
        } catch {Stop-Transcript;break}
        Write-Host " Done" -ForegroundColor Green
        Write-Host "Restarting Citrix Licensing Service..." -NoNewline
        Restart-Service -Name "Citrix Licensing" - Force -WarningAction Ignore
        Write-Host " Done" -ForegroundColor Green
    }
    Write-Host "Citrix Licensing files were removed successfully. It's now time to check alerts are properly raised and teams are responding accordingly." -ForegroundColor Yellow
    Write-Host "You should see:"
    Write-host "- an alert regarding event ID 20737 from source Citrix_Licensing on your Citrix License server"
    Write-Host "- an alert regarding event ID 1151 and/or 1154 from source Citrix Broker Server on your delivery controller(s)"
    Write-Host "Licensing files were saved in C:\DoNotDelete folder."
    Read-Host "Press any key to continue once remediation is completed (Licensing files will be restored by the script)"
    Invoke-Command -ComputerName $ServerName -ScriptBlock { 
        Write-Host "Restoring Citrix Licensing files..." -NoNewline
        Try{
            Move-Item -Path "C:\DoNotDelete\*.lic" -Destination "C:\Program Files (x86)\Citrix\Licensing\MyFiles\" | Out-Null
        } Catch {Stop-Transcript;break}
        Write-Host " Done" -ForegroundColor Green
        Write-Host  "Removing DoNotDelete folder..." -NoNewline
        try {
            Remove-Item -Path "C:\DoNotDelete\" -Recurse -Force | Out-Null
        } catch {Stop-Transcript;break}
        Write-Host " Done" -ForegroundColor Green
        Write-Host "Restarting Citrix Licensing Service..." -NoNewline
        Restart-Service -Name "Citrix Licensing" -WarningAction Ignore
        Write-Host " Done" -ForegroundColor Green
    }
    Read-Host "Environment is restored to its previous state. Press any key to continue"
}

#TODO Corrupt .lic files
#TODO CPU Pikes
#TODO Memory Pikes
#TODO disk space

#Pick the name from the Get-BrokerSite output
$ServerName = (Get-BrokerSite -AdminAddress $AdminAddress).LicenseServerName

#Valide Pre-requisites (e.g Remote PowerShell)
Write-Host "Trying to communicate with $ServerName... " -NoNewline
If((Test-WSMan -ComputerName $ServerName)){
    Write-host "OK"-ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    Write-Host "Check Remote Powershell is enabled on $ServerName" -ForegroundColor Red
    Stop-Transcript 
    break
}

#Starting the chaos!
if($Prod){ 
    #Listing available tests
    $AllAvailableTests = @(
        "Shutdown Server",
        "Stop And Disable Service",
        "Remove .lic files"
    )
    #Picking one of them
    $Test = Get-Random -InputObject $AllAvailableTests
    switch ($Test) {
        "Shutdown Server" { ShutDownServer }
        "Stop And Disable Service" { StopAndDisableService }
        "Remove .lic files" { RemoveLicFiles } 
    }
} else {
    if($All){
        #Running all available test
        ShutDownServer
        StopAndDisableService
        RemoveLicFiles
    } 
}