### PowerShell Profile Refactor
### Version 1.03 - Refactored

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                       https://github.com/ChrisTitusTech/powershell-profile.git.                         ############
############                                                                                                         ############
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
############                                                                                                         ############
############                      IF YOU WANT TO MAKE CHANGES, USE THE Edit-Profile FUNCTION                         ############
############                              AND SAVE YOUR CHANGES IN THE FILE CREATED.                                 ############
############                                                                                                         ############
#################################################################################################################################

# Color variables
$fetchColor = "Cyan"
$updateColor = "DarkYellow"
$installColor = "DarkYellow"
$finishedColor = "Magenta"
$successColor = "Green"

$profilePath = Split-Path -Path $PROFILE
# Initial GitHub.com connectivity check with 1 second timeout
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
# Internet connection could be lost, so we need to check it every time we need to connect to GitHub, we need a function for that
function Test-GitHubConnection {
    return Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
}

function Get-LatestCommitHash {
    param (
        [string]$user = "korneltlaczala",
        [string]$repo = "powershell-profile",
        [string]$branch = "dev"
    )

    $url = "https://github.com/$user/$repo/commits/$branch"
    $headers = @{
        "User-Agent" = "PowerShell"
        "Cache-Control" = "no-cache"
        "Pragma" = "no-cache"
    }
    $html = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing
    $commits = $html.links | Where-Object {$_.href -like "*/$user/$repo/commit/*"}
    $topCommit = $commits[0]
    $commitHash = $topCommit.href | Split-Path -Leaf
    return $commitHash
}

# Import Modules and External Profiles
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    try {
        Write-Host "Installing Terminal Icons module..." -ForegroundColor $installColor
        Install-Module -Name Terminal-Icons -Scope CurrentUser -Repository PSGallery -Force
        Write-Host "Terminal Icons module ready." -ForegroundColor $successColor
    }
    catch {
        Write-Error "Failed to install Terminal Icons module. Error: $_"
    }
}
Import-Module -Name Terminal-Icons
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# Check for Profile Updates
function Update-Profile {

    if (-not $global:canConnectToGitHub) {
        Write-Host "Skipping profile update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Checking for profile updates..." -ForegroundColor $fetchColor

        $profileAuthor = "korneltlaczala"
        $profileRepo = "powershell-profile"
        $profileBranch = "dev"

        Write-Host "Debugging 1"
        $commitHash = Get-LatestCommitHash -user $profileAuthor -repo $profileRepo -branch $profileBranch
        Write-Host "Debugging 2"
        $url = "https://raw.githubusercontent.com/$profileAuthor/$profileRepo/$commitHash/Microsoft.PowerShell_profile.ps1"

        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod -Uri $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
        $newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"

        if ($newhash.Hash -ne $oldhash.Hash) {
            Write-host "Updating profile..." -ForegroundColor $updateColor
            Copy-Item -Path "$env:temp/Microsoft.PowerShell_profile.ps1" -Destination $PROFILE -Force
            Write-Host "Profile has been updated." -ForegroundColor $finishedColor
            Write-Host "Please restart your shell to reflect changes" -ForegroundColor $finishedColor
        }
        else {
            Write-Host "Your profile is up to date." -ForegroundColor $successColor
        }
        # Get-Date | Set-Content -Path "$profilePath\lastupdate.log" -Force
    } catch {
        Write-Error "Unable to check for profile updates"
        return
    } finally {
        Remove-Item "$env:temp/Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue
    }
}

function Update-PowerShell {
    if (-not $global:canConnectToGitHub) {
        Write-Host "Skipping PowerShell update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor $fetchColor
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }

        if ($updateNeeded) {
            Write-Host "Updating PowerShell..." -ForegroundColor $updateColor
            winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
            Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor $finishedColor
        } else {
            Write-Host "Your PowerShell is up to date." -ForegroundColor $successColor
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}

# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

# Editor Configuration
$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
Set-Alias -Name vim -Value "$EDITOR.exe"

function Edit-Profile {
    vim $PROFILE.CurrentUserAllHosts
    Write-Host "Profile has been updated. Please restart your shell to reflect the changes"
}

function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

# Open WinUtil
function winutil {
	iwr -useb https://christitus.com/win | iex
}

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = "& '$args'"
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

# This function still does not work properly, as it does not reload the profile correctly.
function Reload-Profile {
    param (
        [switch]$noclear
    )

    if (! $noclear) {Clear-Host}
    . $profile
}

function reload {
    $currentPath = Get-Location
    if ($isAdmin) {
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command cd $currentPath"
    } else {
        Start-Process wt -ArgumentList "pwsh.exe -NoExit -Command cd $currentPath"
    }
    Start-Sleep -Seconds 1
    exit
}

function unzip () {

    param (
        [string]$file,
        [string]$OutFolder
    )

    $OutFolder = Join-Path $pwd.Path $OutFolder

    Write-Host("Extracting: ") -NoNewline
    Write-Host($file) -ForegroundColor "Magenta"
    Write-Host("to: ") -NoNewline
    Write-Host($OutFolder) -ForegroundColor "DarkYellow"
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $OutFolder
    Write-Host("Extraction complete.") -ForegroundColor $successColor
}
function hb {
    if ($args.Length -eq 0) {
        Write-Error "No file path specified."
        return
    }
    
    $FilePath = $args[0]
    
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
    } else {
        Write-Error "File path does not exist."
        return
    }
    
    $uri = "http://bin.christitus.com/documents"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $Content -ErrorAction Stop
        $hasteKey = $response.key
        $url = "http://bin.christitus.com/$hasteKey"
        Write-Output $url
    } catch {
        Write-Error "Failed to upload the document. Error: $_"
    }
}
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

### Quality of Life Aliases

#no-clear Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }
function dtop { Set-Location -Path $HOME\Desktop }
function down { Set-Location -Path $HOME\Downloads }

# Quick Access to Editing the Profile
# epp - Edit PowerShell Profile
# upp - Update PowerShell Profile
# rpp - Reload PowerShell Profile
function epp { vim $PROFILE }
function upp { Update-Profile }
function rpp { reload-profile}

function uprel {
    Update-Profile
    reload
}

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# Git Shortcuts
function gs { git status }

function ga { git add . }

function gitcom { git commit -m "$args" }

function gd { git diff }

# ---------------------------------------------
# CONFLICTING ALIASES - needs fix
# ---------------------------------------------
# function gc { param($m) git commit -m "$m" }
# function gp { git push }
# ---------------------------------------------

function g { z Github }

function gcl { git clone "$args" }

function gcom {
    git add .
    git commit -m "$args"
}
function lazyg {
    git add .
    git commit -m "$args"
    git push
}

function gitlog { git log --oneline }

# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

# Enhanced PowerShell Experience
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    String = 'DarkCyan'
}

# Get theme from profile.ps1 or use a default theme
function Get-Theme {
    if (Test-Path -Path $PROFILE.CurrentUserAllHosts -PathType leaf) {
        $existingTheme = Select-String -Raw -Path $PROFILE.CurrentUserAllHosts -Pattern "oh-my-posh init pwsh --config"
        if ($null -ne $existingTheme) {
            Invoke-Expression $existingTheme
            return
        }
    } else {
        oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression
    }
}

## Final Line to set prompt
Get-Theme
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
} else {
    Write-Host "zoxide command not found. Attempting to install via winget..."
    try {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully. Initializing..."
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# Help Function
function Show-Help {
    @"
PowerShell Profile Help
=======================

Update-Profile - Checks for profile updates from a remote repository and updates if necessary.

Update-PowerShell - Checks for the latest PowerShell release and updates if a new version is available.

Edit-Profile - Opens the current user's profile for editing using the configured editor.

touch <file> - Creates a new empty file.

ff <name> - Finds files recursively with the specified name.

Get-PubIP - Retrieves the public IP address of the machine.

winutil - Runs the WinUtil script from Chris Titus Tech.

uptime - Displays the system uptime.

reload-profile - Reloads the current user's PowerShell profile.

unzip <file> - Extracts a zip file to the current directory.

hb <file> - Uploads the specified file's content to a hastebin-like service and returns the URL.

grep <regex> [dir] - Searches for a regex pattern in files within the specified directory or from the pipeline input.

df - Displays information about volumes.

sed <file> <find> <replace> - Replaces text in a file.

which <name> - Shows the path of the command.

export <name> <value> - Sets an environment variable.

pkill <name> - Kills processes by name.

pgrep <name> - Lists processes by name.

head <path> [n] - Displays the first n lines of a file (default 10).

tail <path> [n] - Displays the last n lines of a file (default 10).

nf <name> - Creates a new file with the specified name.

mkcd <dir> - Creates and changes to a new directory.

docs - Changes the current directory to the user's Documents folder.

dtop - Changes the current directory to the user's Desktop folder.

ep - Opens the profile for editing.

k9 <name> - Kills a process by name.

la - Lists all files in the current directory with detailed formatting.

ll - Lists all files, including hidden, in the current directory with detailed formatting.

gs - Shortcut for 'git status'.

ga - Shortcut for 'git add .'.

gc <message> - Shortcut for 'git commit -m'.

gp - Shortcut for 'git push'.

g - Changes to the GitHub directory.

gcom <message> - Adds all changes and commits with the specified message.

lazyg <message> - Adds all changes, commits with the specified message, and pushes to the remote repository.

sysinfo - Displays detailed system information.

flushdns - Clears the DNS cache.

cpy <text> - Copies the specified text to the clipboard.

pst - Retrieves text from the clipboard.

Use 'Show-Help' to display this help message.
"@
}


if (Test-Path "$profilePath\lastupdate.log") {
    $lastUpdate = Get-Content -Path "$profilePath\lastupdate.log"
    $lastUpdateDate = [datetime]::ParseExact($lastUpdate, 'dd/MM/yyyy HH:mm:ss', $null)
    $timeSinceLastUpdate = (Get-Date) - $lastUpdateDate
    if ($timeSinceLastUpdate.TotalHours -lt 24) {
        Write-Host "Skipping profile update check. Last update was $timeSinceLastUpdate ago." -ForegroundColor Yellow
        $update_skipped = $true
    }
}
if (-not $update_skipped) {
    Update-Profile
    Update-PowerShell
}
Write-Host "----------------------------------------"
Write-Host "Use 'Show-Help' to display help"
Write-Host "----------------------------------------"
