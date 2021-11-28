<#
 .Synopsis
  Chaos Monkey script for Citrix environment
 .Description
 ####TODO
 .Parameter Prod
 Use Chaos Monkey in production environement
 This parameter is optionnal
 Script will pick only one component in the environment to fail and will stop executing once the failure is identified and remediated
 -All, -TestLicenseServer, -TestDeliveryControllerServer will be ignored if specified
.Parameter All
Test all the components
This parameter is optionnal
.Parameter TestLicenseServer
Test Citrix license server
This parameter is optionnal
.Parameter TestDeliveryControllerServer
Test Citrix DeliveryController server where the script is running from
This parameter is optionnal
 .Parameter Log
 Specifiy the output file for the logs.
 This parameter is optionnal, by default, it will create a file in the current directory
#>

[CmdletBinding()]
Param(
    # Declaring input variables for the script
    [Parameter(Mandatory=$false)] [switch]$Prod,
    [Parameter(Mandatory=$false)] [switch]$all,
    [Parameter(Mandatory=$false)] [switch]$TestLicenseServer,
    [Parameter(Mandatory=$false)] [switch]$TestDeliveryControllerServer,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] [string]$LogFile=".\CitrixChaosMonkey.log"
)
#Start logging
Start-Transcript -Path $LogFile

#Setting variables prior to their usage is not mandatory
Set-StrictMode -Version 2

##################################################################################################################################
############################################### Check Chaos Monkeys pre-requisites ###############################################
##################################################################################################################################

Write-Host "Checking pre-requisistes..."

#Check Snapin can be loaded
#Could be improved by only loading the necessary modules but it would not be compatible with version older than 1912
Write-Host "Loading Citrix Snapin... " -NoNewline
if(!(Add-PSSnapin Citrix* -ErrorAction SilentlyContinue -PassThru )){
    Write-Host "Failed" -ForegroundColor Red
    Write-Host "Citrix Snapin cannot be loaded. Please, check the component is installed on the computer." -ForegroundColor Red
    #Stop logging
    Stop-Transcript 
    break
}
Write-Host "OK" -ForegroundColor Green

##################################################################################################################################

if($Prod){ 
    Write-Host "Chaos Monkey launched with -Prod parameter. -All and parameter such as -Test**** will be ignored." -ForegroundColor Yellow
    Write-Host "Chaos Monkey will pick one component randomly to break." -ForegroundColor Yellow
    $AllAvailableTests = @(
        "License-server",
        "DeliveryController-server"
    )
    $Test = Get-Random -InputObject $AllAvailableTests
    Write-host "Chaos Monkey chose $test!"
    . ./$test/component.ps1
    Write-Host "Chaos Monkey has finished its job!" -ForegroundColor Green
} else {
    if($All){
        Write-Host "Chaos Monkey launched with -All parameter. All the components will be tested." -ForegroundColor Yellow
        Write-Host "Other parameter such as -Test**** will be ignored." -ForegroundColor Yellow
        Write-host "Starting License Server Chaos Monkey..."
        . ./License-server/component.ps1 
        Write-host "Starting Delivery Controller Server Chaos Monkey..."
        . ./DeliveryController-server/component.ps1 
        Write-Host "Chaos Monkey has finished its job!" -ForegroundColor Green
    } else {
        if($TestLicenseServer){
            Write-Host "Chaos Monkey launched with -TestLicenseServer parameter." -ForegroundColor Yellow
            Write-host "Starting License Server Chaos Monkey..."
            . ./License-server/component.ps1 
            Write-Host "Chaos Monkey has finished its job!" -ForegroundColor Green
        } else if($TestDeliveryController){
            Write-Host "Chaos Monkey launched with -TestDeliveryControllerServer parameter." -ForegroundColor Yellow
            Write-host "Starting Delivery Controller Server Chaos Monkey..."
            . ./Delivery Controller-server/component.ps1 
            Write-Host "Chaos Monkey has finished its job!" -ForegroundColor Green
        }
        else {
            Write-Host "Chaos Monkey launched without parameter, Simians are sleeping. Your environment is safe..."
        }
    }
}

Stop-Transcript
