﻿# Copyright (C) 2014 Yusuf Ozturk
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

function script:Start-PoSHServer {
 
  <#
      .SYNOPSIS
     
      Powershell Web Server to serve HTML and Powershell web contents.
 
      .DESCRIPTION
     
      Listens a port to serve web content. Supports HTML and Powershell.
    
      .PARAMETER  WhatIf
     
      Display what would happen if you would run the function with given parameters.
    
      .PARAMETER  Confirm
     
      Prompts for confirmation for each operation. Allow user to specify Yes/No to all option to stop prompting.
    
      .EXAMPLE
     
      Start-PoSHServer -IP 127.0.0.1 -Port 8080
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net" -Port 8080
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -asJob
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -SSL -SSLPort 8443 -asJob
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -SSL -SSLIP "127.0.0.1" -SSLPort 8443 -asJob
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -DebugMode
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net,www.poshserver.net" -Port 8080
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net,www.poshserver.net" -Port 8080 -HomeDirectory "C:\inetpub\wwwroot"
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net,www.poshserver.net" -Port 8080 -HomeDirectory "C:\inetpub\wwwroot" -LogDirectory "C:\inetpub\wwwroot"
		
      .EXAMPLE
     
      Start-PoSHServer -Hostname "poshserver.net" -Port 8080 -CustomConfig "C:\inetpub\config.ps1" -CustomJob "C:\inetpub\job.ps1"

      .INPUTS
    
      None
 
      .OUTPUTS
 
      None
	
      .NOTES
    
      Author: Yusuf Ozturk
      Website: http://www.yusufozturk.info
      Email: yusuf.ozturk@outlook.com
      Date created: 09-Oct-2011
      Last modified: 07-Apr-2014
      Version: 3.7
 
      .LINK
    
      http://www.poshserver.net
		
  #>
 
  [CmdletBinding(SupportsShouldProcess = $true)]
  param (

    # Hostname
    [Alias('IP')]
    [string]$Hostname,
	
    # Port Number
    [string]$Port,
	
    # SSL IP Address
    [string]$SSLIP,
	
    # SSL Port Number
    [string]$SSLPort,
	
    # SSL Port Number
    [string]$SSLName,
	
    # Home Directory
    [string]$HomeDirectory,
	
    # Log Directory
    [string]$LogDirectory,

    # Custom Config Path    
    [string]$CustomConfig,

    # Custom Child Config Path
    [string]$CustomChildConfig,

    # Custom Job Path    
    [string]$CustomJob,
	
    # Custom Job Schedule
    [ValidateSet('1','5','10','20','30','60')] 
    [string]$CustomJobSchedule = '5',
	
    # Background Job ID
    [string]$JobID,

    # Background Job Username
    [string]$JobUsername,
	
    # Background Job User Password
    [string]$JobPassword,
	
    # Background Job Credentials
    [switch]$JobCredentials = $false,
	
    # Enable SSL
    [switch]$SSL = $false,

    # Debug Mode
    [switch]$DebugMode = $false,
	
    # Background Job
    [switch]$asJob = $false
  )
	
  # Enable Debug Mode
  if ($DebugMode)	{
    $DebugPreference = 'Continue'
  }	else {
    $ErrorActionPreference = 'silentlycontinue'
  }

  # Get PoSH Server Path
  $PoSHServerPath = "$env:ProgramW6432\PoSHServer"
	
  # Get PoSH Server Module Path
  $PoSHModulePath = "$env:ProgramW6432\PoSHServer\modules\PoSHServer"
	
  # Test PoSH Server Module Path
  $PoSHModulePathTest = Test-Path -Path $PoSHModulePath
	
  if (!$PoSHModulePathTest) {
    $ModulePaths = ($env:PSModulePath).Split(';')
		
    # Test Module Paths
    Foreach ($ModulePath in $ModulePaths)	{
      $ModulePath = "$ModulePath\PoSHServer"
      $ModulePath = $ModulePath.Replace('\\','\')
      $PoSHModulePathTest = Test-Path -Path $ModulePath
      if ($PoSHModulePathTest) {
        $PoSHModulePath = $ModulePath
        break
      }
    }
  }
	
  if (!$PoSHModulePathTest)
  {
    Write-Warning -Message 'Could not detect PoSH Server Module Path.'
    Write-Warning -Message 'Aborting..'
		
    $ResultCode = '-1'
    $ResultMessage = 'Could not detect PoSH Server Module Path.'
  }
  else
  {
    # Import Functions
    . $PoSHModulePath\modules\functions.ps1
  }
	
  # Background Job Control
  if ($asJob -and $ResultCode -ne '-1')
  {
    if ($JobCredentials)
    {
      Write-Host ' '
      Write-Host 'Please specify user credentials for PoSH Server background job.'
      Write-Host ' '
      $JobUsername = Read-Host -Prompt 'Username'
      $JobSecurePassword = Read-Host -Prompt 'Password' -AsSecureString			
      $JobSecureCredentials = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $JobUsername,$JobSecurePassword
      $JobPassword = $JobSecureCredentials.GetNetworkCredential().Password
    }
  }
	
  # Background Job ID
  if ($JobID -and $ResultCode -ne '-1')
  {
    $JobIDPath = "$PoSHServerPath\jobs\job-$JobID.txt"
    $TestJobID = Test-Path -Path $JobIDPath
    if ($JobIDPath)
    {
      $JobIDContent = Get-Content -Path $JobIDPath
      $Hostname = $JobIDContent.Split(';')[0]
      $Port = $JobIDContent.Split(';')[1]
      $SSLIP = $JobIDContent.Split(';')[2]
      $SSLPort = $JobIDContent.Split(';')[3]
      $SSLName = $JobIDContent.Split(';')[4]
      $HomeDirectory = $JobIDContent.Split(';')[5]
      $LogDirectory = $JobIDContent.Split(';')[6]
      $CustomConfig = $JobIDContent.Split(';')[7]
      $CustomChildConfig = $JobIDContent.Split(';')[8]
      $CustomJob = $JobIDContent.Split(';')[9]
    }
    else
    {
      Write-Warning -Message 'Job ID does not exist.'
      Write-Warning -Message 'Aborting..'

      $ResultCode = '-1'
      $ResultMessage = 'Job ID does not exist.'
    }
  }
	
  if ($ResultCode -ne '-1')
  {	
    # Get Home and Log Directories
    if (!$HomeDirectory) { $HomeDirectory = "$PoSHServerPath\webroot\http" }
    if (!$LogDirectory) { $LogDirectory = "$PoSHServerPath\webroot\logs" }

    # Admin Privileges Verification
    . $PoSHModulePath\modules\adminverification.ps1
		
    # Server IP Verification
    . $PoSHModulePath\modules\ipverification.ps1
		
    # PHP Encoding Module
    . $PoSHModulePath\modules\phpencoding.ps1
		
    # Break Script If Something's Wrong
    if ($ShouldProcess -eq $false)
    {
      $ResultCode = '-1'
      $ResultMessage = 'Please check module output.'
    }
  }
	
  if ($ResultCode -ne '-1')
  {	
    # Enable Background Job
    if ($asJob)
    {	
      if (!$Hostname)
      {
        $Hostname = '+'
        $TaskHostname = 'localhost'
      }
      else
      {
        $TaskHostname = $Hostname.Split(',')[0]
      }
			
      if (!$Port)
      {
        $Port = '8080'
        $TaskPort = '8080'
      }
      else
      {
        $TaskPort = $Port.Split(',')[0]
      }
			
      if ($SSL)
      {
        if (!$SSLIP) 
        {
          $SSLIP = '127.0.0.1'
					
          if (!$SSLPort)
          {
            $SSLPort = '8443'
          }
        }
      }
			
      $CheckTask = schtasks.exe | Where-Object {$_ -like "PoSHServer-$TaskHostname-$TaskPort*"}
      if ($CheckTask)
      {
        Write-Warning -Message 'This job already exists. You should run it from Scheduled Jobs.'
        Write-Warning -Message 'Aborting..'
				
        $ResultCode = '-1'
        $ResultMessage = 'This job already exists. You should run it from Scheduled Jobs.'
      }
      else
      {
        # Prepare Job Information
        $TaskID = Get-Random -Maximum 10000
        $TaskName = "PoSHServer-$TaskHostname-$TaskPort-$TaskID"
        $CreateJobIDPath = $PoSHServerPath + '\jobs\job-' + $TaskID + '.txt'
        $CreateJobIDValue = $Hostname + ';' + $Port + ';' + $SSLIP + ';' + $SSLPort + ';' + $SSLName + ';' + $HomeDirectory + ';' + $LogDirectory + ';' + $CustomConfig + ';' + $CustomChildConfig + ';' + $CustomJob
        $CreateJobID = Add-Content -Path $CreateJobIDPath -Value $CreateJobIDValue
				
        # Create Scheduled Jobs
        $CreateTask = schtasks /create /tn "$TaskName" /xml "$PoSHServerPath\jobs\template.xml" /ru SYSTEM
        $ChangeTaskProcess = $true
        while ($ChangeTaskProcess)
        {
          if ($SSL)
          {
            $ChangeTask = schtasks /change /tn "$TaskName" /tr "Powershell -Command &{Import-Module PoSHServer; Start-PoSHServer -SSL -JobID $TaskID}" /rl highest
          }
          else
          {
            $ChangeTask = schtasks /change /tn "$TaskName" /tr "Powershell -Command &{Import-Module PoSHServer; Start-PoSHServer -JobID $TaskID}" /rl highest
          }
					
          if ($ChangeTask)
          {
            $ChangeTaskProcess = $false
          }
        }
				
        if ($JobUsername -and $JobPassword)
        {
          $ChangeTaskProcess = $true
          while ($ChangeTaskProcess)
          {
            $ChangeTask = schtasks /tn "$TaskName" /Change /RU "$JobUsername" /RP "$JobPassword"
						
            if ($ChangeTask)
            {
              $ChangeTaskProcess = $false
            }
          }
        }
				
        # Start Background Job
        $RunTask = schtasks /run /tn "$TaskName"
				
        # PoSH Server Welcome Banner
        Get-PoSHWelcomeBanner -Hostname $Hostname -Port $Port -SSL $SSL -SSLIP $SSLIP -SSLPort $SSLPort -DebugMode $DebugMode
      }
    }
    else
    {
      # PoSH Server Scheduled Background Jobs
      $PoSHJobArgs = @($Hostname,$Port,$HomeDirectory,$LogDirectory,$PoSHModulePath,$asJob)
      $PoSHJob = Start-Job -scriptblock {
        param ([string]$Hostname, [string]$Port, [string]$HomeDirectory, [string]$LogDirectory, [string]$PoSHModulePath, [switch]$asJob)
			
        # Import Functions
        . $PoSHModulePath\modules\functions.ps1
				
        # PoSH Server Custom Configuration
        $PoSHCustomConfigPath = $HomeDirectory + '\config.ps1'
	
        # Test Config Path
        $TestPoSHCustomConfigPath = Test-Path -Path $PoSHCustomConfigPath
	
        if (!$TestPoSHCustomConfigPath)
        {			
          # Import Config
          . $PoSHModulePath\modules\config.ps1
        }
        else
        {
          # Import Config
          . $HomeDirectory\config.ps1
        }
				
        while ($true)
        {
          Start-Sleep -Seconds 60			
					
          # Get Job Time
          $JobTime = Get-Date -format HHmm
					
          if ($LogSchedule -eq 'Hourly')
          {
            # PoSH Server Log Hashing (at *:30 hourly)
            if ($JobTime -eq '*30')
            {
              New-PoSHLogHash -LogSchedule $LogSchedule -LogDirectory $LogDirectory
            }
          }
          else
          {
            # PoSH Server Log Hashing (at 02:30 daily)
            if ($JobTime -eq '0230')
            {
              New-PoSHLogHash -LogSchedule $LogSchedule -LogDirectory $LogDirectory
            }
          }
        }
      } -ArgumentList $PoSHJobArgs
			
      # PoSH Server Custom Background Jobs
      $PoSHCustomJobArgs = @($Hostname,$Port,$HomeDirectory,$LogDirectory,$PoSHModulePath,$CustomJob,$CustomJobSchedule,$asJob)
      $PoSHCustomJob = Start-Job -scriptblock {
        param (
          [string]$Hostname, 
          [string]$Port, 
          [string]$HomeDirectory, 
          [string]$LogDirectory, 
          [string]$PoSHModulePath, 
          [string]$CustomJob, 
          [string]$CustomJobSchedule, 
          [switch]$asJob
        )
			
        # Import Functions
        . $PoSHModulePath\modules\functions.ps1
				
        # PoSH Server Custom Configuration
        $PoSHCustomConfigPath = $HomeDirectory + '\config.ps1'
	
        # Test Config Path
        $TestPoSHCustomConfigPath = Test-Path -Path $PoSHCustomConfigPath
	
        if (!$TestPoSHCustomConfigPath)
        {			
          # Import Config
          . $PoSHModulePath\modules\config.ps1
        }
        else
        {
          # Import Config
          . $HomeDirectory\config.ps1
        }
				
        while ($true)
        {
          Start-Sleep -Seconds 60								
          # Get Job Time          $JobTime = Get-Date -format HHmm
					
          if ($CustomJobSchedule -eq '1')
          {
            # PoSH Server Custom Jobs (at every 1 minute)
            if ($CustomJob)
            {
              . $CustomJob
            }
          }					
          elseif ($CustomJobSchedule -eq '5')
          {
            # PoSH Server Custom Jobs (at every 5 minutes)            if ($JobTime -like '*5' -or $JobTime -like '*0')            {            if ($CustomJob)            {            . $CustomJob            }            }
          }
          elseif ($CustomJobSchedule -eq '10')
          {
            # PoSH Server Custom Jobs (at every 10 minutes)
            if ($JobTime -like '*00' -or $JobTime -like '*10' -or $JobTime -like '*20' -or $JobTime -like '*30' -or $JobTime -like '*40' -or $JobTime -like '*50')
            {
              if ($CustomJob)
              {
                . $CustomJob
              }
            }
          }
          elseif ($CustomJobSchedule -eq '20')
          {
            # PoSH Server Custom Jobs (at every 20 minutes)
            if ($JobTime -like '*00' -or $JobTime -like '*20' -or $JobTime -like '*40')
            {
              if ($CustomJob)
              {
                . $CustomJob
              }
            }
          }
          elseif ($CustomJobSchedule -eq '30')
          {
            # PoSH Server Custom Jobs (at every 30 minutes)
            if ($JobTime -like '*00' -or $JobTime -like '*30')
            {
              if ($CustomJob)
              {
                . $CustomJob
              }
            }
          }
          elseif ($CustomJobSchedule -eq '60')
          {
            # PoSH Server Custom Jobs (at every hour)
            if ($JobTime -like '*00')
            {
              if ($CustomJob)
              {
                . $CustomJob
              }
            }
          }					
          else
          {
            # PoSH Server Custom Jobs (at every 5 minutes)
            if ($JobTime -like '*5' -or $JobTime -like '*0')
            {
              if ($CustomJob)
              {
                . $CustomJob
              }
            }
          }
        }
      } -ArgumentList $PoSHCustomJobArgs			      # PoSH Server Custom Config      if ($CustomConfig)      {      . $CustomConfig      }
			
      # Create an HTTPListener
      try
      {
        $Listener = New-Object -TypeName Net.HttpListener
      }
      catch
      {
        Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
      }
			
      # Add Prefix Urls
      try
      {
        if (!$Hostname) 
        {
          $Hostname = '+'
					
          if (!$Port)
          {
            $Port = '8080'
          }
					
          $Prefix = 'http://' + $Hostname + ':' + $Port + '/'
          $Listener.Prefixes.Add($Prefix)
        }
        else
        {
          $Hostnames = @($Hostname.Split(','))
					
          if (!$Port)
          {
            $Port = '8080'
          }
							
          foreach ($Hostname in $Hostnames)
          {
            $Prefix = 'http://' + $Hostname + ':' + $Port + '/'
            $Listener.Prefixes.Add($Prefix)
          }
        }
				
        if ($SSL)
        {
          if (!$SSLIP) 
          {
            $SSLIP = '127.0.0.1'
						
            if (!$SSLPort)
            {
              $SSLPort = '8443'
            }
						
            $Prefix = 'https://' + $SSLIP + ':' + $SSLPort + '/'
            $Listener.Prefixes.Add($Prefix)
          }
          else
          {
            $SSLIPAddresses = @($SSLIP.Split(','))
						
            if (!$SSLPort)
            {
              $SSLPort = '8443'
            }
								
            foreach ($SSLIPAddress in $SSLIPAddresses)
            {
              $Prefix = 'https://' + $SSLIPAddress + ':' + $SSLPort + '/'
              $Listener.Prefixes.Add($Prefix)
            }
          }
        }		
      }
      catch
      {
        Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
      }
			
      # Start Listener
      try
      {
        $Listener.Start()
      }
      catch
      {
        Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
      }
			
      # Configure SSL
      try
      {
        if ($SSL)
        {
          if ($SSLName)
          {
            $PoSHCert = Get-ChildItem -Recurse -Path Cert: | Where-Object { $_.FriendlyName -eq $SSLName }
						
            if (!$PoSHCert)
            {
              $PoSHCert = Get-ChildItem -Recurse -Path Cert: | Where-Object { $_.FriendlyName -eq 'PoSHServer SSL Certificate' }
            }
          }
          else
          {
            $PoSHCert = Get-ChildItem -Recurse -Path Cert: | Where-Object { $_.FriendlyName -eq 'PoSHServer SSL Certificate' }
          }
					
          if (!$PoSHCert)
          {
            if ($DebugMode)
            {
              Add-Content -Value "Sorry, I couldn't find your SSL certificate." -Path "$LogDirectory\debug.txt"
              Add-Content -Value 'Creating Self-Signed SSL certificate..' -Path "$LogDirectory\debug.txt"
            }
            Request-PoSHCertificate
            $PoSHCert = Get-ChildItem -Recurse -Path Cert: | Where-Object { $_.FriendlyName -eq 'PoSHServer SSL Certificate' }
          }
					
          # Register SSL Certificate
          $CertThumbprint = $PoSHCert[0].Thumbprint
          Register-PoSHCertificate -SSLIP $SSLIP -SSLPort $SSLPort -Thumbprint $CertThumbprint -DebugMode $DebugMode
        }
      }
      catch
      {
        Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
      }
			
      # PoSH Server Welcome Banner
      try
      {
        Get-PoSHWelcomeBanner -Hostname $Hostname -Port $Port -SSL $SSL -SSLIP $SSLIP -SSLPort $SSLPort -DebugMode $DebugMode
      }
      catch
      {
        Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
      }
			
      # PoSH Server Async Process Script
      $ScriptBlock = `
      {
        Param($Listener, $Hostname, $Hostnames, $HomeDirectory, $LogDirectory, $PoSHModulePath, $CustomChildConfig, $DebugMode)
				
        # Import Functions
        . $PoSHModulePath\modules\functions.ps1
				
        # Enable Debug Mode
        if ($DebugMode)
        {
          $DebugPreference = 'Continue'
        }
        else
        {
          $ErrorActionPreference = 'silentlycontinue'
        }
				
        # PHP Encoding Module
        . $PoSHModulePath\modules\phpencoding.ps1
				
        # PoSH Server Custom Child Config
        if ($CustomChildConfig)
        {
          . $CustomChildConfig
        }
				
        # Create loop
        $ShouldProcess = $true
				
        # Get Server Requests
        while ($ShouldProcess)
        {		
          # PoSH Server Custom Configuration
          $PoSHCustomConfigPath = $HomeDirectory + '\config.ps1'
		
          # Test Config Path
          $TestPoSHCustomConfigPath = Test-Path -Path $PoSHCustomConfigPath
		
          if (!$TestPoSHCustomConfigPath)
          {			
            # Import Config
            . $PoSHModulePath\modules\config.ps1
          }
          else
          {
            # Import Config
            . $HomeDirectory\config.ps1
          }
					
          # Reset Authentication
          $Listener.AuthenticationSchemes = 'Anonymous'
					
          # Set Authentication
          if ($BasicAuthentication -eq 'On') { $Listener.AuthenticationSchemes = 'Basic' }
          if ($NTLMAuthentication -eq 'On') { $Listener.AuthenticationSchemes = 'NTLM' }
          if ($WindowsAuthentication -eq 'On') { $Listener.AuthenticationSchemes = 'IntegratedWindowsAuthentication' }

          # Open Connection
          $task = $Listener.GetContextAsync()
          while( -not $Context )
          {
            if( $task.Wait(500) )
            {
              $Context = $task.Result
            }
            Start-Sleep -Milliseconds 100
          }
					
          # Authentication Module
          . $PoSHModulePath\modules\authentication.ps1
								
          # Set Home Directory
          [IO.Directory]::SetCurrentDirectory("$HomeDirectory")
          $File = $Context.Request.Url.LocalPath
          $Response = $Context.Response
          $Response.Headers.Add('Accept-Encoding','gzip')
          $Response.Headers.Add('Server','PoSH Server')
          $Response.Headers.Add('X-Powered-By','Microsoft PowerShell')
					
          # Set Request Parameters
          $Request = $Context.Request
          $InputStream = $Request.InputStream
          $ContentEncoding = $Request.ContentEncoding
							
          # IP Restriction Module
          . $PoSHModulePath\modules\iprestriction.ps1
					
          # Get Query String
          $PoSHQuery = Get-PoSHQueryString -Request $Request
					
          # Get Post Stream
          $PoSHPost = Get-PoSHPostStream -InputStream $InputStream -ContentEncoding $ContentEncoding
					
          # Cookie Information
          $PoSHCookies = $Request.Cookies['PoSHSessionID']
          if (!$PoSHCookies)
          {
            $PoSHCookie = New-Object -TypeName Net.Cookie
            $PoSHCookie.Name = 'PoSHSessionID'
            $PoSHCookie.Value = New-PoSHTimeStamp
            $Response.AppendCookie($PoSHCookie)
          }
					
          # Get Default Document
          if ($File -notlike '*.*' -and $File -like '*/')
          {
            $FolderPath = [IO.Directory]::GetCurrentDirectory() + $File
            $RequstURL = [string]$Request.Url
            $SubfolderName = $File
            $File = $File + $DefaultDocument
          }
          elseif ($File -notlike '*.*' -and $File -notlike '*/')
          {
            $FolderPath = [IO.Directory]::GetCurrentDirectory() + $File + '/'
            $RequstURL = [string]$Request.Url + '/'
            $SubfolderName = $File + '/'
            $File = $File + '/' + $DefaultDocument 
          }
          else
          {
            $FolderPath = $Null
          }
					
          # PoSH API Support
          if ($File -like '*.psxml')
          {
            $File = $File.Replace('.psxml','.ps1')
						
            # Full File Path
            $File = [IO.Directory]::GetCurrentDirectory() + $File
						
            # Get Mime Type
            $MimeType = 'text/psxml'
          }
          else
          {
            # Full File Path
            $File = [IO.Directory]::GetCurrentDirectory() + $File
						
            # Get Mime Type
            $FileExtension = (Get-ChildItem -Path $File -ErrorAction SilentlyContinue).Extension
            $MimeType = Get-MimeType $FileExtension
          }
					
          # Content Filtering Module
          . $PoSHModulePath\modules\contentfiltering.ps1
					
          # Stream Content
          if ([IO.File]::Exists($File) -and $ContentSessionDrop -eq '0' -and $IPSessionDrop -eq '0')  
          { 
            if ($MimeType -eq 'text/ps1')
            {
              try
              {
                # Need to be able to override these
                $returnstring = "$(. $File)" # executes code here into a strings

                # TODO : return errors to browser

                if($Response.ContentType -eq $null)
                {
                  $Response.ContentType = 'text/html'
                }
                if($Response.StatusCode -eq $null)
                {
                  $Response.StatusCode = [Net.HttpStatusCode]::OK
                }
                $LogResponseStatus = $Response.StatusCode
                $ResponseStream = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                $ResponseStream.Write($returnstring)
                $ResponseStream.Flush()
              }
              catch
              {
                Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
              }
            }
            elseif ($MimeType -eq 'text/psxml')
            {
              try
              {
                $Response.ContentType = 'text/xml'
                $Response.StatusCode = [Net.HttpStatusCode]::OK
                $LogResponseStatus = $Response.StatusCode
                $ResponseStream = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                $ResponseStream.WriteLine("$(. $File)")
                $ResponseStream.Flush()
              }
              catch
              {
                Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
              }
            }
            elseif ($MimeType -eq 'text/php')
            {
              try
              {
                if ($PHPCgiPath)
                {
                  $TestPHPCgiPath = Test-Path -Path $PHPCgiPath
                }
                else
                {
                  $TestPHPCgiPath = $false
                }
								
                if ($TestPHPCgiPath)
                {
                  if ($File -like 'C:\Windows\*')
                  {
                    $Response.ContentType = 'text/html'
                    $Response.StatusCode = [Net.HttpStatusCode]::NotFound
                    $LogResponseStatus = $Response.StatusCode
                    $ResponseStream = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                    $ResponseStream.WriteLine("$(. $PoSHModulePath\modules\phpsecurityerror.ps1)")
                    $ResponseStream.Flush()                                        
                  }
                  else
                  {
                    $Response.ContentType = 'text/html'
                    $PHPContentOutput = Get-PoSHPHPContent -PHPCgiPath "$PHPCgiPath" -File "$File" -PoSHPHPGET $PoSHQuery.PoSHQueryString -PoSHPHPPOST $PoSHPost.PoSHPostStream
                    $PHPContentOutput = Set-PHPEncoding -PHPOutput $PHPContentOutput
                    $Response.StatusCode = [Net.HttpStatusCode]::OK
                    $LogResponseStatus = $Response.StatusCode
                    $ResponseStream = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                    $ResponseStream.WriteLine("$PHPContentOutput")
                    $ResponseStream.Flush()
                  }
                }
                else
                {
                  $Response.ContentType = 'text/html'
                  $Response.StatusCode = [Net.HttpStatusCode]::NotFound
                  $LogResponseStatus = $Response.StatusCode
                  $ResponseStream = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                  $ResponseStream.WriteLine("$(. $PoSHModulePath\modules\phpcgierror.ps1)")	
                  $ResponseStream.Flush()					
                }
              }
              catch
              {
                Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
              }
            }				
            else
            {
              try
              {
                $Response.ContentType = "$MimeType"
                $FileContent = [IO.File]::ReadAllBytes($File)
                $Response.ContentLength64 = $FileContent.Length
                $Response.StatusCode = [Net.HttpStatusCode]::OK
                $LogResponseStatus = $Response.StatusCode
                $Response.OutputStream.Write($FileContent, 0, $FileContent.Length)
                $ResponseStream.Flush()
              }
              catch
              {
                Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
              }
            }
          }
          else
          {
            # Content Filtering and IP Restriction Control
            if ($ContentSessionDrop -eq '0' -and $IPSessionDrop -eq '0')
            {
              if ($FolderPath)
              {
                $TestFolderPath = Test-Path -Path $FolderPath
              }
              else
              {
                $TestFolderPath = $false
              }
            }
            else
            {
              $TestFolderPath = $false
            }
						
            if ($DirectoryBrowsing -eq 'On' -and $TestFolderPath)
            {
              try
              {
                $Response.ContentType = 'text/html'
                $Response.StatusCode = [Net.HttpStatusCode]::OK
                $LogResponseStatus = $Response.StatusCode
                $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                if ($Hostname -eq '+') { $HeaderName = 'localhost' } else { $HeaderName = $Hostnames[0] }
                $DirectoryContent = (Get-DirectoryContent -Path "$FolderPath" -HeaderName $HeaderName -RequestURL $RequestURL -SubfolderName $SubfolderName)
                $Response.WriteLine("$DirectoryContent")
              }
              catch
              {
                Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
              }
            }
            else
            {
              try
              {
                $Response.ContentType = 'text/html'
                $Response.StatusCode = [Net.HttpStatusCode]::NotFound
                $LogResponseStatus = $Response.StatusCode
                $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                $Response.WriteLine("$(. $PoSHModulePath\modules\notfound.ps1)")
              }
              catch
              {
                Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
              }
            }
          }
					
          # Logging Module
          . $PoSHModulePath\modules\log.ps1
					
          # Close Connection
          try
          {
            $Response.Close()
          }
          catch
          {
            Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
          }
        }	
      }
			
      if ($DebugMode)
      {	
        # Invoke PoSH Server Multithread Process - Thread 1
        Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig -DebugMode | Out-Null
				
        # Invoke PoSH Server Multithread Process - Thread 2
        Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig -DebugMode | Out-Null
				
        # Invoke PoSH Server Multithread Process - Thread 3
        Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig -DebugMode | Out-Null
      }
      else
      {
        # Invoke PoSH Server Multithread Process - Thread 1
        Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig | Out-Null
				
        # Invoke PoSH Server Multithread Process - Thread 2
        Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig | Out-Null
				
        # Invoke PoSH Server Multithread Process - Thread 3
        Invoke-AsyncHTTPRequest -ScriptBlock $ScriptBlock -Listener $Listener -Hostname $Hostname -Hostnames $Hostnames -HomeDirectory $HomeDirectory -LogDirectory $LogDirectory -PoSHModulePath $PoSHModulePath -CustomChildConfig $CustomChildConfig | Out-Null
      }
			
      # Create loop
      $ShouldProcess = $true
			
      # Get Server Requests
      while ($ShouldProcess)
      {
        # PoSH Server Custom Configuration
        $PoSHCustomConfigPath = $HomeDirectory + '\config.ps1'
	
        # Test Config Path
        $TestPoSHCustomConfigPath = Test-Path -Path $PoSHCustomConfigPath
	
        if (!$TestPoSHCustomConfigPath)
        {			
          # Import Config
          . $PoSHModulePath\modules\config.ps1
        }
        else
        {
          # Import Config
          . $HomeDirectory\config.ps1
        }
				
        # Reset Authentication
        $Listener.AuthenticationSchemes = 'Anonymous'
				
        # Set Authentication
        if ($BasicAuthentication -eq 'On') { $Listener.AuthenticationSchemes = 'Basic' }
        if ($NTLMAuthentication -eq 'On') { $Listener.AuthenticationSchemes = 'NTLM' }
        if ($WindowsAuthentication -eq 'On') { $Listener.AuthenticationSchemes = 'IntegratedWindowsAuthentication' }

        # Open Connection
        $task = $Listener.GetContextAsync()
        while( -not $Context )
        {
          if( $task.Wait(500) )
          {
            $Context = $task.Result
          }
          Start-Sleep -Milliseconds 100
        }
				
        # Authentication Module
        . $PoSHModulePath\modules\authentication.ps1
							
        # Set Home Directory
        [IO.Directory]::SetCurrentDirectory("$HomeDirectory")
        $File = $Context.Request.Url.LocalPath
        $Response = $Context.Response
        $Response.Headers.Add('Accept-Encoding','gzip')
        $Response.Headers.Add('Server','PoSH Server')
        $Response.Headers.Add('X-Powered-By','Microsoft PowerShell')
				
        # Set Request Parameters
        $Request = $Context.Request
        $InputStream = $Request.InputStream
        $ContentEncoding = $Request.ContentEncoding
						
        # IP Restriction Module
        . $PoSHModulePath\modules\iprestriction.ps1
				
        # Get Query String
        $PoSHQuery = Get-PoSHQueryString -Request $Request
				
        # Get Post Stream
        $PoSHPost = Get-PoSHPostStream -InputStream $InputStream -ContentEncoding $ContentEncoding
				
        # Cookie Information
        $PoSHCookies = $Request.Cookies['PoSHSessionID']
        if (!$PoSHCookies)
        {
          $PoSHCookie = New-Object -TypeName Net.Cookie
          $PoSHCookie.Name = 'PoSHSessionID'
          $PoSHCookie.Value = New-PoSHTimeStamp
          $Response.AppendCookie($PoSHCookie)
        }
				
        # Get Default Document
        if ($File -notlike '*.*' -and $File -like '*/')
        {
          $FolderPath = [IO.Directory]::GetCurrentDirectory() + $File
          $RequstURL = [string]$Request.Url
          $SubfolderName = $File
          $File = $File + $DefaultDocument
        }
        elseif ($File -notlike '*.*' -and $File -notlike '*/')
        {
          $FolderPath = [IO.Directory]::GetCurrentDirectory() + $File + '/'
          $RequstURL = [string]$Request.Url + '/'
          $SubfolderName = $File + '/'
          $File = $File + '/' + $DefaultDocument 
        }
        else
        {
          $FolderPath = $Null
        }
				
        # PoSH API Support
        if ($File -like '*.psxml')
        {
          $File = $File.Replace('.psxml','.ps1')
					
          # Full File Path
          $File = [IO.Directory]::GetCurrentDirectory() + $File
					
          # Get Mime Type
          $MimeType = 'text/psxml'
        }
        else
        {
          # Full File Path
          $File = [IO.Directory]::GetCurrentDirectory() + $File
					
          # Get Mime Type
          $FileExtension = (Get-ChildItem -Path $File -ErrorAction SilentlyContinue).Extension
          $MimeType = Get-MimeType $FileExtension
        }
				
        # Content Filtering Module
        . $PoSHModulePath\modules\contentfiltering.ps1
				
        # Stream Content
        if ([IO.File]::Exists($File) -and $ContentSessionDrop -eq '0' -and $IPSessionDrop -eq '0')  
        { 
          if ($MimeType -eq 'text/ps1')
          {
            try
            {
              $Response.ContentType = 'text/html'
              $Response.StatusCode = [Net.HttpStatusCode]::OK
              $LogResponseStatus = $Response.StatusCode
              $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
              $Response.WriteLine("$(. $File)")
            }
            catch
            {
              Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
            }
          }
          elseif ($MimeType -eq 'text/psxml')
          {
            try
            {
              $Response.ContentType = 'text/xml'
              $Response.StatusCode = [Net.HttpStatusCode]::OK
              $LogResponseStatus = $Response.StatusCode
              $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
              $Response.WriteLine("$(. $File)")
            }
            catch
            {
              Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
            }
          }
          elseif ($MimeType -eq 'text/php')
          {
            try
            {
              if ($PHPCgiPath)
              {
                $TestPHPCgiPath = Test-Path -Path $PHPCgiPath
              }
              else
              {
                $TestPHPCgiPath = $false
              }
							
              if ($TestPHPCgiPath)
              {
                if ($File -like 'C:\Windows\*')
                {
                  $Response.ContentType = 'text/html'
                  $Response.StatusCode = [Net.HttpStatusCode]::NotFound
                  $LogResponseStatus = $Response.StatusCode
                  $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                  $Response.WriteLine("$(. $PoSHModulePath\modules\phpsecurityerror.ps1)")
                }
                else
                {
                  $Response.ContentType = 'text/html'
                  $PHPContentOutput = Get-PoSHPHPContent -PHPCgiPath "$PHPCgiPath" -File "$File" -PoSHPHPGET $PoSHQuery.PoSHQueryString -PoSHPHPPOST $PoSHPost.PoSHPostStream
                  $PHPContentOutput = Set-PHPEncoding -PHPOutput $PHPContentOutput
                  $Response.StatusCode = [Net.HttpStatusCode]::OK
                  $LogResponseStatus = $Response.StatusCode
                  $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                  $Response.WriteLine("$PHPContentOutput")
                }
              }
              else
              {
                $Response.ContentType = 'text/html'
                $Response.StatusCode = [Net.HttpStatusCode]::NotFound
                $LogResponseStatus = $Response.StatusCode
                $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
                $Response.WriteLine("$(. $PoSHModulePath\modules\phpcgierror.ps1)")						
              }
            }
            catch
            {
              Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
            }
          }				
          else
          {
            try
            {
              $Response.ContentType = "$MimeType"
              $FileContent = [IO.File]::ReadAllBytes($File)
              $Response.ContentLength64 = $FileContent.Length
              $Response.StatusCode = [Net.HttpStatusCode]::OK
              $LogResponseStatus = $Response.StatusCode
              $Response.OutputStream.Write($FileContent, 0, $FileContent.Length)
            }
            catch
            {
              Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
            }
          }
        }
        else
        {
          # Content Filtering and IP Restriction Control
          if ($ContentSessionDrop -eq '0' -and $IPSessionDrop -eq '0')
          {
            if ($FolderPath)
            {
              $TestFolderPath = Test-Path -Path $FolderPath
            }
            else
            {
              $TestFolderPath = $false
            }
          }
          else
          {
            $TestFolderPath = $false
          }
					
          if ($DirectoryBrowsing -eq 'On' -and $TestFolderPath)
          {
            try
            {
              $Response.ContentType = 'text/html'
              $Response.StatusCode = [Net.HttpStatusCode]::OK
              $LogResponseStatus = $Response.StatusCode
              $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
              if ($Hostname -eq '+') { $HeaderName = 'localhost' } else { $HeaderName = $Hostnames[0] }
              $DirectoryContent = (Get-DirectoryContent -Path "$FolderPath" -HeaderName $HeaderName -RequestURL $RequestURL -SubfolderName $SubfolderName)
              $Response.WriteLine("$DirectoryContent")
            }
            catch
            {
              Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
            }
          }
          else
          {
            try
            {
              $Response.ContentType = 'text/html'
              $Response.StatusCode = [Net.HttpStatusCode]::NotFound
              $LogResponseStatus = $Response.StatusCode
              $Response = New-Object -TypeName IO.StreamWriter -ArgumentList ($Response.OutputStream,[Text.Encoding]::UTF8)
              $Response.WriteLine("$(. $PoSHModulePath\modules\notfound.ps1)")
            }
            catch
            {
              Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
            }
          }
        }
				
        # Logging Module
        . $PoSHModulePath\modules\log.ps1
				
        # Close Connection
        try
        {
          $Response.Close()
        }
        catch
        {
          Add-Content -Value $_ -Path "$LogDirectory\debug.txt"
        }
      }
			
      # Stop Listener
      $Listener.Stop()
    }
  }
}