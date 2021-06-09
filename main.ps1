<#
 .Synopsis
  Chaos Monkey script for Citrix environment
 .Description
 ###TODO
 .Parameter Prod
 Use Chaos Monkey in production environement
 This parameter is optionnal
 Script will pick only one component in the environment to fail and will stop executing once the failure is identified and remediated
 -All, -TestLicenseServer will be ignored if specified
.Parameter All
Test all the components
This parameter is optionnal
.Parameter TestLicenseServer
Test Citrix license server
This parameter is optionnal
.Parameter DeliveryController
 Specifiy the Delivery Controller to use for the provision
 This parameter is optionnal, by default it will use the local machine as the delivery controller
 .Parameter Log
 Specifiy the output file for the logs.
 This parameter is optionnal, by default, it will create a file in the current directory
 .Example
 # Configure local machine to autolog the user leogetz with the password P@ssw0rd
 SetAutologon.ps1 -Account leogetz -Password P@ssw0rd
 .Example
 # Configure local machine to autolog the user leogetz with the password P@ssw0rd and store the scripts in C:\Tmp
 SetAutologon.ps1 -Account leogetz -Password P@ssw0rd -Path C:\Tmp
 .Example
 # Configure local machine to autolog the user leogetz with the password P@ssw0rd and store the scripts in C:\Tmp
  and log the output in C:\Temp
 SetAutologon.ps1 -Account leogetz -Password P@ssw0rd -Path C:\Tmp -Log "C:\temp\test.log"
#>

[CmdletBinding()]
Param(
    # Declaring input variables for the script
    [Parameter(Mandatory=$false)] [switch]$Prod,
    [Parameter(Mandatory=$false)] [switch]$all,
    [Parameter(Mandatory=$false)] [switch]$TestLicenseServer,
    [Parameter(Mandatory=$false)] [string]$DeliveryController,
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

#Check if the DeliveryController parameter is set or if it has to use the local machine
if($DeliveryController){
    #Check if the parameter is a FQDN or not
    Write-Host "Trying to contact the Delivery Controller $DeliveryController... " -NoNewline
    if($DeliveryController -contains "."){
        $DDC = Get-BrokerController -DNSName "$DeliveryController"
    } else {
        $DDC = Get-BrokerController -DNSName "$DeliveryController.$env:USERDNSDOMAIN"
    }
} else {
    Write-Host "Trying to contact the Delivery Controller $env:COMPUTERNAME... " -NoNewline
    $DDC = Get-BrokerController -DNSName "$env:COMPUTERNAME.$env:USERDNSDOMAIN"
}
if(($DDC)){
    Write-Host "OK" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    Write-Host "Cannot contact the Delivery Controller. Please, check the role is installed on the target computer and your account is allowed to communicate with it." -ForegroundColor Red
    Stop-Transcript 
    break
}

##################################################################################################################################

if($Prod){ 
    Write-Host "Chaos Monkey launched with -Prod parameter. -All and parameter such as -Test**** will be ignored." -ForegroundColor Yellow
    Write-Host "Chaos Monkey will pick one component randomly to break." -ForegroundColor Yellow
    $AllAvailableTests = @(
        "License-server"
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
        Write-Host "Chaos Monkey has finished its job!" -ForegroundColor Green
    } else {
        if($TestLicenseServer){
            Write-Host "Chaos Monkey launched with -TestLicenseServer parameter." -ForegroundColor Yellow
            Write-host "Starting License Server Chaos Monkey..."
            . ./License-server/component.ps1 
            Write-Host "Chaos Monkey has finished its job!" -ForegroundColor Green
        } else {
            Write-Host "Chaos Monkey launched without parameter, Simians are sleeping. Your environment is safe..."
        }
    }
}

Stop-Transcript