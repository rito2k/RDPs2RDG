<#
 .SYNOPSIS  
     This script loops through all valid RDP Files in a provided folder path, extracts machine and logon name for each of them and generates a Remote Desktop Connection Manager group file for your convenience.

 .DESCRIPTION  
     This script loops through all valid RDP Files in a provided folder path, extracts machine and logon name for each of them and generates a Remote Desktop Connection Manager group file for your convenience.
     Provide the default logon user name to connect to the remote machines with. If not provided, "Administrator" will be used.
     Provide the default logon domain name to connect to the remote machines with. If not provided, "MyDomain" will be used.
     Provide the path to the existing RDP files to generate the RDCMan file from. If not provided, the path where the script is located will be used.
     Provide the name for the group node containing the remote servers to connect to. If not provided, "MyWorkspace" will be used.     
               
 .PARAMETER DefaultLogonName
    (OPTIONAL)
    Defines the logon user name to connect to the remote machines with. If not provided, "Administrator" will be used.

 .PARAMETER DefaultLogonDomain
    (OPTIONAL)
    Defines the logon domain name to connect to the remote machines with. If not provided, "MyDomain" will be used.

 .PARAMETER RdpFilesPath
    (OPTIONAL)
    Defines the path to the existing RDP files to generate the RDCMan file from. If not provided, the path where the script is located will be used.

 .PARAMETER WorkspaceName
    (OPTIONAL)
    Defines the name for the group node containing the remote servers to connect to. Default is "MyWorkspace"

 .PARAMETER Users
    (OPTIONAL)
    Comma or semi-colon delimited list of usernames for login profiles. Leave the domain off the username, it derives it from the DefaultLogonDomain parameter

 .PARAMETER DefaultPassword
    (OPTIONAL)
    Default password used for all user accounts in test environments. This will store the password encrypted in the RDG file using the Windows ProtectedData API.

 .PARAMETER debugging
    (OPTIONAL)
    Switch to turn on extra debug logging 

 .EXAMPLE
    RDPs2RDG.ps1 -DefaultLogonName WsAdm -DefaultLogonDomain mydomain -RdpFilesPath C:\RDPs -WorkspaceName MyWorkspace -Users "jsmith,mroony,aguy" -DefaultPassword "testPassword"

 .NOTES
     File Name  : RDPs2RDG.ps1
     Author     : https://github.com/rito2k/RDPs2RDG
     Version    : 2.0
     Date       : Aug 18th, 2021

     You can download the latest Remote Desktop Connection Manager version at https://docs.microsoft.com/en-us/sysinternals/downloads/rdcman
#>

Param (
    [Parameter(Mandatory=$false)]
	[string]$DefaultLogonName = "Administrator",
    [Parameter(Mandatory=$false)]
	[string]$DefaultLogonDomain = "MyDomain",
    [Parameter(Mandatory=$false)]
    [string]$RdpFilesPath,
    [Parameter(Mandatory=$false)]
    [string]$WorkspaceName = "MyWorkspace",
    [Parameter(Mandatory=$false)]
    [string]$Users,
    [Parameter(Mandatory=$false)]
    [string]$DefaultPassword,
    [switch]$debugging
)

Add-Type -AssemblyName System.Security
    

function encryptPass($plaintext){
    $bytetext = [System.Text.Encoding]::Unicode.GetBytes($plaintext)

    #$scope = [System.Security.Cryptography.DataProtectionScope]::CurrentUser = 0
    $protectedPass = [System.Security.Cryptography.ProtectedData]::Protect($bytetext,$null,0)
    return [System.Convert]::ToBase64String($protectedPass)
}

$Time1=Get-Date

if ($RdpFilesPath -eq ""){
    $RdpFilesPath = $PSScriptRoot
}
else {
    If (!(Test-Path $RdpFilesPath -PathType Container)){
        Write-Host "Path '$RdpFilesPath' does not exist!" -ForegroundColor Red
        Exit
    }
    
}

try {
    if (!($RdpFiles = Get-ChildItem $RdpFilesPath -Filter "*.rdp")){
        Write-Host "No RDP files found in '$RdpFilesPath'!" -ForegroundColor Red
        Exit
    }
    $NewRDCFile = $RdpFilesPath + "\$WorkspaceName.rdg"

    If (Test-Path $NewRDCFile -PathType Leaf){
        $wshell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
        $answer = $wshell.Popup("The file '$NewRDCFile' already exists! Do you want overwrite it?",0,"Attention!",32+4)
        if ($answer -eq 6)
            {Remove-Item $NewRDCFile -Force}
        else
        {
            If ($debugging) {Write-Host "Exiting..." -ForegroundColor Gray}
            Exit
        }
    }
}
catch {   
}

If ($debugging) {Write-Host "Building base file '$NewRDCFile' . . ." -ForegroundColor Gray}

#Create base RDCMan file
$xmlsb = '<?xml version="1.0" encoding="utf-8"?>
<RDCMan programVersion="2.8.2" schemaVersion="3">
  <file>
    <credentialsProfiles />
    <properties>
      <expanded>True</expanded>
      <name>$WorkspaceName</name>
    </properties>
    <remoteDesktop inherit="None">
      <sameSizeAsClientArea>True</sameSizeAsClientArea>
      <fullScreen>False</fullScreen>
      <colorDepth>24</colorDepth>
    </remoteDesktop>
    <group>
      <properties>
        <expanded>True</expanded>
        <name>$WorkspaceName</name>
      </properties>
      <logonCredentials inherit="None">
        <profileName scope="Local">Custom</profileName>
        <userName>$DefaultLogonName</userName>
        <password />
        <domain>$DefaultLogonDomain</domain>
      </logonCredentials>
    </group>
  </file>
  <connected />
  <favorites />
  <recentlyUsed />
</RDCMan>'

#Interpret & replace variable value
$xmlsb = $xmlsb.Replace('$WorkspaceName',$WorkspaceName)
$xmlsb = $xmlsb.Replace('$DefaultLogonName',$DefaultLogonName)
$xmlsb = $xmlsb.Replace('$DefaultLogonDomain',$DefaultLogonDomain)

#Transform string to XML structure
$xml = [xml]$xmlsb

#Save base RDC file
$xml.Save($NewRDCFile)

If ($debugging) {Write-Host "Adding remote machines to $NewRDCFile . . ." -ForegroundColor Gray}

#Read XML Object
[XML]$RDCConfig = Get-Content -Path $NewRDCFile

#Loop through RDP files and collect machine name as "connection strings"

$RdpFiles = Get-ChildItem $RdpFilesPath -Filter "*.rdp"
foreach ($RdpFile in $RdpFiles)
{
    try{
        #$RdpContent = Get-Content $RdpFile
        if ($FullAdressString = Select-String -Path $RdpFile.FullName -Pattern "full address:s:" -SimpleMatch){
            $MachineConnectionString = $FullAdressString.Line.Trim().Substring(15)
        }
        if ($UserNameString = Select-String -Path $RdpFile.FullName -Pattern "username:s:" -SimpleMatch){
            $UserName = $UserNameString.Line.Trim().Substring(11)
        }
        else {
            $UserName = $DefaultLogonName
        }
        $MachineName = $RdpFile.Name.Substring(0,$RdpFile.Name.LastIndexOf("."))
    }
    catch{
        $MachineConnectionString = ""
    }
    if (($null -eq $MachineConnectionString) -or ($MachineConnectionString -eq ""))
    {
        Write-Host "Warning: Could not find full address in '$RdpFile', please check it." -ForegroundColor Yellow
    }
    else {
        [XML]$Server ="        
        <server>
            <properties>
              <displayName>$MachineName</displayName>
              <name>$MachineConnectionString</name>
            </properties>
         </server>"
        $New = $RDCConfig.ImportNode($Server.Server, $true)
        try
            {$RDCConfig.RDCMan.file.group.AppendChild($New) | out-null}
        Finally
        {
            If ($debugging) {Write-Host "Added server '$MachineName' (Logon username: $UserName)" -ForegroundColor Cyan}
        }
    }
}#for-each RDP file

if($Users.Length -gt 0){
    $userArray =  $Users.Split($(",;".ToCharArray()))
    foreach($user in $userArray){
        $profileTemplate = @"
            <credentialsProfile inherit="None">
                    <profileName scope="Local">{0}\{1}</profileName>
                    <userName>{1}</userName>
                    <password>{2}</password>
                    <domain>{0}</domain>
            </credentialsProfile>
"@

            $encPass = encryptPass -plaintext $DefaultPassword

            [xml]$xmlTemplate = $profileTemplate -f $DefaultLogonDomain, $user, $encPass

            $New = $RDCConfig.ImportNode($xmlTemplate.credentialsProfile, $true)

            try
                {$RDCConfig.RDCMan.file.GetElementsByTagName('credentialsProfiles').AppendChild($New)| out-null}
            Finally
            {
                If ($debugging) {Write-Host "Added user credentials for: '$user'" -ForegroundColor Cyan}
            }
    }#for-each user
}#if Users specified

#Save final RDCMan file
$RDCConfig.Save($NewRDCFile)
Write-Host "$NewRDCFile has been successfully generated!" -ForegroundColor Green

$Time2=Get-Date
If ($debugging) {write-host "Elapsed time: "($Time2 - $Time1) -ForegroundColor Gray}