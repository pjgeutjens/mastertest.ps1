<#
.SYNOPSIS
    This script performs a global install-uninstall test on a package
    It will detect the presence of the application at appropriate moments
    During the process
.DESCRIPTION
    The script starts by performing a detection in case of "dirty" environment
    The script then installs the application and checks its presence
    The script then removes the application and verifies absense
.EXAMPLE
    master.test.ps1
#>

<# Script Exit Codes

    -1      =>  pre-test cleanup error
    1       =>  install error
    10      =>  post-install detection error
    11      =>  uninstall error
    110     =>  post-uninstall detection error
    999     =>  general error

    0       =>  SUCCESS

#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Try {

    if (Detect) {
        # seems we detected the application before starting our test
        # bit weird, so show a warning, but attempt to clean up
        Write-Warning "application detected before test start, uninstalling"
        Try {
            Uninstall
        }
        Catch {
            Write-Error "pre-test cleanup error"
            Exit -1
        }
        
    }
    
    # start by installing the application
    Try {
        Install
    }
    Catch {
        Write-Error "install error"
        Exit 1
    }
    
    # and make sure it's detected
    if (-not (Detect)) {
        Write-Error "application not detected after install"
        Exit 10
    }
    
    # then uninstall
    Try {
        Uninstall
    }
    Catch {
        Write-Error "uninstall error"
        Exit 11
    }
    
    # and make sure it's gone
    if (Detect) {
        Write-Error "application detected after uninstall"
        Exit 110
    }
}
Catch {
    Write-Error "Fatal script error"
    Exit 999
}




function Detect {
    $detected = $false

    # File Detection
    $filex86 = Test-Path 'C:\Program Files\Foo\bar.exe'
    $filex64 = Test-Path 'C:\Program Files (x86)\foo\bar.exe'

    $detected = $filex86 -or $filex64

    # File Version Detection
    $filevx86 = (get-item "C:\Program Files\Foo\bar.exe").VersionInfo.FileVersion
    $filevx64 = (get-item "C:\Program Files (x86)\Foo\bar.exe").VersionInfo.FileVersion
    $minversion = New-Object System.Version("1.0.0")

    $detected = ($filevx86 -ge $minversion) -or ($filevx64 -ge $minversion)

    # Registry Detection
    $regx86 = Test-Path "HKLM:\SOFTWARE\Microsoft\Foo"
    $regx64 = Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Foo"

    $detected = $regx86 -or $regx64

    # MSI ProductCode Detection
    $productcode = "{c3bd695f-d69a-4f40-bc86-565b8ca314c1}"
    $msi = @(get-wmiobject -Class win32_product | Where-Object {$_.IdentifyingNumber -eq $productcode}).Count

    $detected = [boolean]$msi

    return $detected
}

function Install {
    $exe = "$here\Deploy-Application.exe"
    $arguments = "install"

    Start-Process -FilePath $exe -ArgumentList $arguments -Wait -WindowStyle Hidden

}

function Uninstall {
    $exe = "$here\Deploy-Application.exe"
    $arguments = "uninstall"

    Start-Process -FilePath $exe -ArgumentList $arguments -Wait -WindowStyle Hidden

}