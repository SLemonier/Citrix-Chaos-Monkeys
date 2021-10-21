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

#Stop and disable one service
function StopAndDisableOneService {
    Write-Host "Chaos Monkey will stop and disable one Citrix service on the Delivery Controller"
    Invoke-Command -ComputerName $ServerName -ScriptBlock {  
        $ServicesList = Get-Service -name "Citrix*"
        $ServiceToTest = Get-Random -InputObject $ServicesList
        Write-Host  "Stopping " $ServiceToTest.DisplayName -NoNewline
        Stop-Service -Name $ServiceToTest.Name -Force -WarningAction Ignore
        $count = 0
        while ((Get-Service -Name $ServiceToTest.Name).Status -ne "Stopped") {
            Write-host "." -NoNewline
            Start-Sleep -Seconds 5
            if($count -eq 20){
                Write-Host "Stopping service is taking a long time, please check $ServerName's state." -ForegroundColor Yellow
            }
            $count++
        }
        Write-Host " Done" -ForegroundColor Green
        Write-Host  "Disabling " $ServiceToTest.Name "..." -NoNewline
        Set-Service -Name $ServiceToTest.Name -StartupType Disabled 
        $count = 0
        while ((Get-Service -Name $ServiceToTest.Name).StartType -ne "Disabled") {
            Write-host "." -NoNewline
            Start-Sleep -Seconds 5
            if($count -eq 20){
                Write-Host "Disabling service is taking a long time, please check $ServerName's state." -ForegroundColor Yellow
            }
            $count++
        }
        Write-Host " Done" -ForegroundColor Green
    }
    Write-Host $ServiceToTest.Name " service was stopped and disabled successfully. It's now time to check alerts are properly raised and teams are responding accordingly." -ForegroundColor Yellow
    Write-Host "You should see:"
    Write-host "- an alert regarding " $ServiceToTest.Name " status"
    Read-Host "Press any key to continue once remediation is completed"
}

#Stop and disable all services
function StopAndDisableAllService {
    Write-Host "Chaos Monkey will stop and disable every Citrix service on the Delivery Controller"
    Invoke-Command -ComputerName $ServerName -ScriptBlock {  
        $ServicesList = Get-Service -name "Citrix*"
        $foreach($ServiceToTest in $ServicesList){
            Write-Host  "Stopping " $ServiceToTest.DisplayName -NoNewline
            Stop-Service -Name $ServiceToTest.Name -Force -WarningAction Ignore
            $count = 0
            while ((Get-Service -Name $ServiceToTest.Name).Status -ne "Stopped") {
                Write-host "." -NoNewline
                Start-Sleep -Seconds 5
                if($count -eq 20){
                    Write-Host "Stopping service is taking a long time, please check $ServerName's state." -ForegroundColor Yellow
                }
                $count++
            }
            Write-Host " Done" -ForegroundColor Green
            Write-Host  "Disabling " $ServiceToTest.Name "..." -NoNewline
            Set-Service -Name $ServiceToTest.Name -StartupType Disabled 
            $count = 0
            while ((Get-Service -Name $ServiceToTest.Name).StartType -ne "Disabled") {
                Write-host "." -NoNewline
                Start-Sleep -Seconds 5
                if($count -eq 20){
                    Write-Host "Disabling service is taking a long time, please check $ServerName's state." -ForegroundColor Yellow
                }
                $count++
            }
            Write-Host " Done" -ForegroundColor Green
        }
        Write-Host $ServiceToTest.Name " service was stopped and disabled successfully. It's now time to check alerts are properly raised and teams are responding accordingly." -ForegroundColor Yellow
        Write-Host "You should see:"
        Write-host "- an alert regarding " $ServiceToTest.Name " status"
        Read-Host "Press any key to continue once remediation is completed"
    }
}

#TODO CPU Pikes
#TODO Memory Pikes
#TODO disk space

#Pick the name of the current Delivery Controller
$ServerName = $env:COMPUTERNAME

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
        "Stop And Disable One Service",
        "Stop And Disable All Service",
        "Remove .lic files"
    )
    #Picking one of them
    $Test = Get-Random -InputObject $AllAvailableTests
    switch ($Test) {
        "Shutdown Server" { ShutDownServer }
        "Stop And Disable One Service" { StopAndDisableOneService }
        "Stop And Disable All Service" { StopAndDisableAllService }
        "Remove .lic files" { RemoveLicFiles } 
    }
} else {
    if($All){
        #Running all available test
        ShutDownServer
        StopAndDisableOneService
        StopAndDisableAllService
        RemoveLicFiles
    } 
}