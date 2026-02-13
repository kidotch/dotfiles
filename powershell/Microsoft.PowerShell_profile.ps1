function vim { & "C:\Program Files\Neovim\bin\nvim.exe" @args }
function vi  { & "C:\Program Files\Neovim\bin\nvim.exe" @args }

oh-my-posh init pwsh --config ~\.config\ohmyposh\config.json | Invoke-Expression

Set-Alias ahk "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

function Enter-VS {
    Import-Module "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
    Enter-VsDevShell -VsInstallPath 'C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools' -SkipAutomaticLocation
}

$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --info=inline --border=rounded"

function Invoke-GhqFzf {
    $preview = 'pwsh -NoProfile -Command "Set-Location \"{}\"; Write-Host \"=== Branch ===\"  -ForegroundColor Yellow; git branch --show-current; Write-Host \"\"; Write-Host \"=== Status ===\"  -ForegroundColor Yellow; git status --short; if (-not (git status --short)) { Write-Host \"(clean)\" -ForegroundColor Green }; Write-Host \"\"; Write-Host \"=== Recent Commits ===\"  -ForegroundColor Yellow; git log --oneline -5"'
    $repo = ghq list -p | ForEach-Object {
        $parent = Split-Path $_ -Parent
        $leaf = Split-Path $_ -Leaf
        "$parent\`e[36m$leaf`e[0m"
    } | fzf --ansi --prompt "ghq> " --keep-right --preview $preview --preview-window "right:50%:wrap"
    if ($repo) {
        $repo = $repo -replace '\e\[[0-9;]*m', ''
        Set-Location $repo
        ls
    }
}

Set-Alias gr Invoke-GhqFzf

function cc {
    claude @args
}

function ccd {
    claude --dangerously-skip-permissions @args
}

function gsclip {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    $secret = Get-Secret -Name $Name -AsPlainText
    $secret | Set-Clipboard
    Write-Host "Copied secret '$Name' to clipboard"
}

function Get-VastInstancesText {
    param([string]$StatusPattern = 'running|loading|starting|boot')

    $lines = vastai show instances 2>$null
    if (-not $lines) { return @() }

    $rows = $lines | Where-Object { $_ -match '^\d+\s+\d+\s+' }

    foreach ($line in $rows) {
        if ($line -notmatch '^(?<id>\d+)\s+\d+\s+(?<status>\w+)\s+') { continue }

        $id = $Matches.id
        $status = $Matches.status

        if ($line -notmatch '(?<sshHost>ssh\d+\.vast\.ai)\s+(?<sshPort>\d{2,6})') { continue }

        $sshHost = $Matches.sshHost
        $sshPort = $Matches.sshPort

        if ($status -match $StatusPattern) {
            [pscustomobject]@{
                Id      = $id
                Status  = $status
                SshHost = $sshHost
                SshPort = $sshPort
                Line    = $line
            }
        }
    }
}

function _Select-VaiInstance {
    param([string]$InstanceId, [string]$StatusPattern = 'running|loading|starting|boot')
    if ($InstanceId) { return $InstanceId }

    $active = Get-VastInstancesText -StatusPattern $StatusPattern
    if (-not $active -or $active.Count -eq 0) { Write-Host "No matching instances found."; return $null }
    if ($active.Count -eq 1) { return $active[0].Id }

    Write-Host "Multiple active instances found:"
    for ($i=0; $i -lt $active.Count; $i++) { Write-Host "[$i] $($active[$i].Line)" }
    $choice = Read-Host "Pick number"
    if ($choice -match '^\d+$' -and [int]$choice -lt $active.Count) { return $active[[int]$choice].Id }
    Write-Host "Invalid choice."; return $null
}

function _Get-VaiSshInfo {
    param([string]$InstanceId)
    $u = (vastai ssh-url $InstanceId).Trim()
    if ($u -notmatch '^ssh://(?<user>[^@]+)@(?<host>[^:]+):(?<port>\d+)$') {
        throw "Unexpected ssh-url format: $u"
    }
    return @{ User = $Matches.user; Host = $Matches.host; Port = $Matches.port }
}

function vai-ssh {
    param(
        [string]$InstanceId,
        [string]$KeyPath = "$env:USERPROFILE\.ssh\vastai_key"
    )

    $InstanceId = _Select-VaiInstance $InstanceId
    if (-not $InstanceId) { return }

    $info = _Get-VaiSshInfo $InstanceId
    $cmd = "ssh $($info.User)@$($info.Host) -p $($info.Port) -i `"$KeyPath`" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    Write-Host ">> $cmd"
    Invoke-Expression $cmd
}

function vai-sync-rclone {
    param(
        [string]$InstanceId,
        [string]$KeyPath = "$env:USERPROFILE\.ssh\vastai_key"
    )

    $InstanceId = _Select-VaiInstance $InstanceId
    if (-not $InstanceId) { return }

    $info = _Get-VaiSshInfo $InstanceId
    $src = "$env:APPDATA\rclone\rclone.conf"
    $cmd = "scp -P $($info.Port) -i `"$KeyPath`" `"$src`" $($info.User)@$($info.Host):/dev/shm/rclone.conf"
    Write-Host ">> $cmd"
    Invoke-Expression $cmd
}

function vai-config {
    param(
        [string]$InstanceId,
        [string]$KeyPath  = "$env:USERPROFILE\.ssh\vastai_key",
        [string]$OutPath  = "$env:USERPROFILE\.ssh\config.vast",
        [string]$HostPrefix = "vast"
    )

    $InstanceId = _Select-VaiInstance $InstanceId
    if (-not $InstanceId) { return }

    $info = _Get-VaiSshInfo $InstanceId

    $sshDir = Split-Path -Parent $OutPath
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }

    $block = @"
Host $HostPrefix
  HostName $($info.Host)
  User $($info.User)
  Port $($info.Port)
  IdentityFile $KeyPath
  IdentitiesOnly yes
  PreferredAuthentications publickey
  StrictHostKeyChecking accept-new
  ServerAliveInterval 60
  ServerAliveCountMax 3
"@

    Set-Content -Path $OutPath -Value $block -NoNewline

    Write-Host "Try: ssh $HostPrefix"
    Write-Host "VSCode: Remote-SSH -> $HostPrefix"
}

$GHQ_KIDOTCH = "$env:USERPROFILE\ghq\github.com\kidotch"

$env:Path += ";C:\Users\ahcha\Reaper"

$env:RCLONE_CONFIG_PASS = "rccdms0835"

function vai-scp {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
        [string[]]$Paths,
        [string]$InstanceId,
        [string]$KeyPath = "$env:USERPROFILE\.ssh\vastai_key"
    )

    if (-not $Paths -or $Paths.Count -lt 2) {
        throw "Usage: scp-vast <source-path...> <remote-path> [-InstanceId <id>] [-KeyPath <path>]"
    }

    $sourceInputs = $Paths[0..($Paths.Count - 2)]
    $remotePath = $Paths[-1]

    $InstanceId = _Select-VaiInstance $InstanceId
    if (-not $InstanceId) { return }

    $resolvedSources = @()
    $recursive = $false

    foreach ($source in $sourceInputs) {
        $items = @(Get-Item -Path $source -ErrorAction SilentlyContinue)
        if (-not $items -or $items.Count -eq 0) {
            throw "Source path not found: $source"
        }

        foreach ($item in $items) {
            $resolvedSources += $item.FullName
            if ($item.PSIsContainer) { $recursive = $true }
        }
    }

    $resolvedSources = $resolvedSources | Select-Object -Unique

    $info = _Get-VaiSshInfo $InstanceId
    $remotePathForScp = $remotePath
    if ($remotePath -match '\s') {
        $escaped = $remotePath -replace "'", "'\\''"
        $remotePathForScp = "'$escaped'"
    }

    $remote = "$($info.User)@$($info.Host):$remotePathForScp"
    $scpArgs = @("-P", $info.Port, "-i", $KeyPath)
    if ($recursive) { $scpArgs += "-r" }
    $scpArgs += $resolvedSources
    $scpArgs += $remote

    $preview = "scp " + (($scpArgs | ForEach-Object {
        if ($_ -match '\s') { "`"$_`"" } else { "$_" }
    }) -join " ")

    Write-Host ">> $preview"
    & scp @scpArgs

    if ($LASTEXITCODE -ne 0) {
        throw "scp failed with exit code $LASTEXITCODE"
    }
}

function _Invoke-VaiInstanceAction {
    param(
        [string]$InstanceId,
        [string]$Action,
        [string]$PastTense,
        [string]$StatusPattern = 'running|loading|starting|boot'
    )

    $InstanceId = _Select-VaiInstance $InstanceId $StatusPattern
    if (-not $InstanceId) { return }

    Write-Host "$Action instance $InstanceId ..."
    vastai $Action instance $InstanceId

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Instance $InstanceId $PastTense."
    } else {
        Write-Host "Failed to $Action instance $InstanceId (exit code $LASTEXITCODE)" -ForegroundColor Red
    }
}

function vai-stop    { param([string]$InstanceId) _Invoke-VaiInstanceAction $InstanceId 'stop' 'stopped' }
function vai-start   { param([string]$InstanceId) _Invoke-VaiInstanceAction $InstanceId 'start' 'started' 'exited|stopped' }
function vai-destroy { param([string]$InstanceId) _Invoke-VaiInstanceAction $InstanceId 'destroy' 'destroyed' '.*' }

# PSReadLine の入力色をテーマに応じて切り替え
Import-Module PSReadLine -ErrorAction SilentlyContinue

$_wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

function _Set-PSReadLineLight {
    Set-PSReadLineOption -Colors @{
        Default   = 'Black'
        Command   = 'DarkBlue'
        Parameter = 'DarkCyan'
        String    = 'DarkGreen'
        Operator  = 'DarkMagenta'
        Number    = 'DarkYellow'
    }
}

function _Set-PSReadLineDark {
    Set-PSReadLineOption -Colors @{
        Default   = 'White'
        Command   = 'Cyan'
        Parameter = 'DarkCyan'
        String    = 'Green'
        Operator  = 'Magenta'
        Number    = 'Yellow'
    }
}

function Set-TerminalDark {
    $json = Get-Content $_wtSettingsPath -Raw | ConvertFrom-Json
    $json.profiles.defaults.colorScheme = 'Dimidium'
    $json.theme = 'dark'
    $json | ConvertTo-Json -Depth 10 | Set-Content $_wtSettingsPath
    _Set-PSReadLineDark
}

function Set-TerminalLight {
    $json = Get-Content $_wtSettingsPath -Raw | ConvertFrom-Json
    $json.profiles.defaults.colorScheme = 'One Half Light (modified)'
    $json.theme = 'light'
    $json | ConvertTo-Json -Depth 10 | Set-Content $_wtSettingsPath
    _Set-PSReadLineLight
}

# 起動時: 現在のスキームに合わせてPSReadLineの色を設定
if (Test-Path $_wtSettingsPath) {
    $json = Get-Content $_wtSettingsPath -Raw | ConvertFrom-Json
    if ($json.profiles.defaults.colorScheme -eq 'One Half Light (modified)') {
        _Set-PSReadLineLight
    } else {
        _Set-PSReadLineDark
    }
} else {
    _Set-PSReadLineDark
}

