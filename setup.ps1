Write-Host "Test-prompt for developer" -ForegroundColor darkYellow
$informationColor = "Cyan"
$successColor = "Magenta"
$profileURL = "https://github.com/korneltlaczala/powershell-profile/raw/dev/Microsoft.PowerShell_profile.ps1"

# Ensure the script can run with elevated privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

# Check for internet connectivity before proceeding
if (-not (Test-InternetConnection)) {
    break
}

# OMP Install
try {
    Write-Host "Installing Oh My Posh..." -ForegroundColor $informationColor
    winget install -h -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
    write-host "Oh My Posh ready." -ForegroundColor $successColor
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

# Font Install
try {
    Write-Host "Installing fonts" -ForegroundColor $informationColor
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name

    if ($fontFamilies -notcontains "CaskaydiaCove NF") {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFileAsync((New-Object System.Uri("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip")), ".\CascadiaCode.zip")
        
        while ($webClient.IsBusy) {
            Start-Sleep -Seconds 2
        }

        Expand-Archive -Path ".\CascadiaCode.zip" -DestinationPath ".\CascadiaCode" -Force
        $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
        Get-ChildItem -Path ".\CascadiaCode" -Recurse -Filter "*.ttf" | ForEach-Object {
            If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {        
                $destination.CopyHere($_.FullName, 0x10)
            }
        }

        Remove-Item -Path ".\CascadiaCode" -Recurse -Force
        Remove-Item -Path ".\CascadiaCode.zip" -Force
    }
    Write-Host "Fonts ready." -ForegroundColor $successColor
}
catch {
    Write-Error "Failed to download or install the Cascadia Code font. Error: $_"
}

# Choco install
try {
    Write-Host "Installing Chocolatey..." -ForegroundColor $informationColor
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey ready." -ForegroundColor $successColor
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}

# Terminal Icons Install
try {
    Write-Host "Installing Terminal Icons module..." -ForegroundColor $informationColor
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force
    Write-Host "Terminal Icons module ready." -ForegroundColor $successColor
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}
# zoxide Install
try {
    Write-Host "Installing zoxide..." -ForegroundColor $informationColor
    winget install -e --id ajeetdsouza.zoxide
    Write-Host "zoxide ready." -ForegroundColor $successColor
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}
# zfz Install for zoxide completions
try {
    Write-Host "Installing fzf..." -ForegroundColor $informationColor
    winget install fzf
    Write-Host "fzf ready." -ForegroundColor $successColor
}
catch {
    Write-Error "Failed to install zfz. Error: $_"
}

# Profile creation or update
if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        # Detect Version of PowerShell & Create Profile directories if they do not exist.
        $profilePath = ""
        if ($PSVersionTable.PSEdition -eq "Core") { 
            $profilePath = "$env:userprofile\Documents\Powershell"
        }
        elseif ($PSVersionTable.PSEdition -eq "Desktop") {
            $profilePath = "$env:userprofile\Documents\WindowsPowerShell"
        }

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory"
        }

        Write-Host "Fetching profile..." -ForegroundColor $informationColor
        Invoke-RestMethod $profileURL -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created." -ForegroundColor $successColor
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        Write-Host "Fetching updated profile..." -ForegroundColor $informationColor
        Get-Item -Path $PROFILE | Move-Item -Destination "oldprofile.ps1" -Force
        Invoke-RestMethod $profileURL -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created and old profile removed." -ForegroundColor $successColor
        Write-Host "Please back up any persistent components of your old profile (oldprofile.ps1 in this directory) to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to backup and update the profile. Error: $_"
    }
}

# Final check and message to the user
if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($fontFamilies -contains "CaskaydiaCove NF")) {
    Write-Host "Setup completed successfully. Please restart your PowerShell session to apply changes." -ForegroundColor Green
} else {
    Write-Warning "Setup completed with errors. Please check the error messages above."
}

