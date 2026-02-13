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

function Get-VastActiveInstancesText {
    $lines = vastai show instances 2>$null
    if (-not $lines) { return @() }

    $rows = $lines | Where-Object { $_ -match '^\d+\s+\d+\s+' }

    foreach ($line in $rows) {
        # ID と Status
        if ($line -notmatch '^(?<id>\d+)\s+\d+\s+(?<status>\w+)\s+') { continue }

        $id = $Matches.id
        $status = $Matches.status

        # SSHホストとポート（ssh?.vast.ai PORT）
        if ($line -notmatch '(?<sshHost>ssh\d+\.vast\.ai)\s+(?<sshPort>\d{2,6})') { continue }

        $sshHost = $Matches.sshHost
        $sshPort = $Matches.sshPort

        if ($status -match 'running|loading|starting|boot') {
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

function vai-ssh {
    param(
        [string]$InstanceId,
        [string]$KeyPath = "$env:USERPROFILE\.ssh\vastai_key"
    )

    # ID省略なら running/loading を一覧から選ぶ（ここは今まで通り）
    if (-not $InstanceId) {
        $active = Get-VastActiveInstancesText
        if (-not $active -or $active.Count -eq 0) { Write-Host "No active instances found."; return }

        if ($active.Count -eq 1) {
            $InstanceId = $active[0].Id
        } else {
            Write-Host "Multiple active instances found:"
            for ($i=0; $i -lt $active.Count; $i++) { Write-Host "[$i] $($active[$i].Line)" }
            $choice = Read-Host "Pick number"
            if ($choice -match '^\d+$' -and [int]$choice -lt $active.Count) { $InstanceId = $active[[int]$choice].Id }
            else { Write-Host "Invalid choice."; return }
        }
    }

    # 接続情報は必ず ssh-url から取る（ここが安定）
    $u = (vastai ssh-url $InstanceId).Trim()

    if ($u -match '^ssh://(?<user>[^@]+)@(?<host>[^:]+):(?<port>\d+)$') {
        $cmd = "ssh $($Matches.user)@$($Matches.host) -p $($Matches.port) -i `"$KeyPath`""
        Write-Host ">> $cmd"
        Invoke-Expression $cmd
        return
    }

    throw "Unexpected ssh-url format: $u"
}

function vai-sync-rclone {
    param(
        [string]$InstanceId,
        [string]$KeyPath = "$env:USERPROFILE\.ssh\vastai_key"
    )

    if (-not $InstanceId) {
        $active = Get-VastActiveInstancesText
        if (-not $active -or $active.Count -eq 0) { Write-Host "No active instances found."; return }

        if ($active.Count -eq 1) {
            $InstanceId = $active[0].Id
        } else {
            Write-Host "Multiple active instances found:"
            for ($i=0; $i -lt $active.Count; $i++) { Write-Host "[$i] $($active[$i].Line)" }
            $choice = Read-Host "Pick number"
            if ($choice -match '^\d+$' -and [int]$choice -lt $active.Count) { $InstanceId = $active[[int]$choice].Id }
            else { Write-Host "Invalid choice."; return }
        }
    }

    $u = (vastai ssh-url $InstanceId).Trim()

    if ($u -match '^ssh://(?<user>[^@]+)@(?<host>[^:]+):(?<port>\d+)$') {
        $src = "$env:APPDATA\rclone\rclone.conf"
        $cmd = "scp -P $($Matches.port) -i `"$KeyPath`" `"$src`" $($Matches.user)@$($Matches.host):/dev/shm/rclone.conf"
        Write-Host ">> $cmd"
        Invoke-Expression $cmd
        return
    }

    throw "Unexpected ssh-url format: $u"
}

function vai-config {
    param(
        [string]$InstanceId,
        [string]$KeyPath  = "$env:USERPROFILE\.ssh\vastai_key",
        [string]$OutPath  = "$env:USERPROFILE\.ssh\config.vast",
        [string]$HostPrefix = "vast"
    )

    # --- ID省略なら running/loading を一覧から選ぶ（あなたのアルゴリズムそのまま） ---
    if (-not $InstanceId) {
        $active = Get-VastActiveInstancesText
        if (-not $active -or $active.Count -eq 0) { Write-Host "No active instances found."; return }

        if ($active.Count -eq 1) {
            $InstanceId = $active[0].Id
        } else {
            Write-Host "Multiple active instances found:"
            for ($i=0; $i -lt $active.Count; $i++) { Write-Host "[$i] $($active[$i].Line)" }
            $choice = Read-Host "Pick number"
            if ($choice -match '^\d+$' -and [int]$choice -lt $active.Count) { $InstanceId = $active[[int]$choice].Id }
            else { Write-Host "Invalid choice."; return }
        }
    }

    # --- ssh-url から接続情報を取る（安定） ---
    $u = (vastai ssh-url $InstanceId).Trim()
    if ($u -notmatch '^ssh://(?<user>[^@]+)@(?<host>[^:]+):(?<port>\d+)$') {
        throw "Unexpected ssh-url format: $u"
    }

    $user = $Matches.user
    $sshHost = $Matches.host
    $port = $Matches.port

    $alias = $HostPrefix

    # --- 出力ファイル準備 ---
    $sshDir = Split-Path -Parent $OutPath
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }

    # --- ファイル全体を上書き（常に1エントリのみ） ---
    $block = @"
Host $alias
  HostName $sshHost
  User $user
  Port $port
  IdentityFile $KeyPath
  IdentitiesOnly yes
  PreferredAuthentications publickey
  StrictHostKeyChecking accept-new
  ServerAliveInterval 60
  ServerAliveCountMax 3
"@

    Set-Content -Path $OutPath -Value $block -NoNewline

    Write-Host "Try: ssh $alias"
    Write-Host "VSCode: Remote-SSH -> $alias"
}

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

    if (-not $InstanceId) {
        $active = Get-VastActiveInstancesText
        if (-not $active -or $active.Count -eq 0) { Write-Host "No active instances found."; return }

        if ($active.Count -eq 1) {
            $InstanceId = $active[0].Id
        } else {
            Write-Host "Multiple active instances found:"
            for ($i=0; $i -lt $active.Count; $i++) { Write-Host "[$i] $($active[$i].Line)" }
            $choice = Read-Host "Pick number"
            if ($choice -match '^\d+$' -and [int]$choice -lt $active.Count) { $InstanceId = $active[[int]$choice].Id }
            else { Write-Host "Invalid choice."; return }
        }
    }

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

    $u = (vastai ssh-url $InstanceId).Trim()

    if ($u -match '^ssh://(?<user>[^@]+)@(?<host>[^:]+):(?<port>\d+)$') {
        $remotePathForScp = $remotePath
        if ($remotePath -match '\s') {
            $escaped = $remotePath -replace "'", "'\\''"
            $remotePathForScp = "'$escaped'"
        }

        $remote = "$($Matches.user)@$($Matches.host):$remotePathForScp"
        $scpArgs = @("-P", $Matches.port, "-i", $KeyPath)
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
        return
    }

    throw "Unexpected ssh-url format: $u"
}

function vai-destroy {
    param(
        [string]$InstanceId
    )

    if (-not $InstanceId) {
        $active = Get-VastActiveInstancesText
        if (-not $active -or $active.Count -eq 0) { Write-Host "No active instances found."; return }

        if ($active.Count -eq 1) {
            $InstanceId = $active[0].Id
        } else {
            Write-Host "Multiple active instances found:"
            for ($i=0; $i -lt $active.Count; $i++) { Write-Host "[$i] $($active[$i].Line)" }
            $choice = Read-Host "Pick number"
            if ($choice -match '^\d+$' -and [int]$choice -lt $active.Count) { $InstanceId = $active[[int]$choice].Id }
            else { Write-Host "Invalid choice."; return }
        }
    }

    Write-Host "Destroying instance $InstanceId ..."
    vastai destroy instance $InstanceId

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Instance $InstanceId destroyed."
    } else {
        Write-Host "Failed to destroy instance $InstanceId (exit code $LASTEXITCODE)" -ForegroundColor Red
    }
}

# PSReadLine の入力色を上書き（カラースキームは変えない）
Import-Module PSReadLine -ErrorAction SilentlyContinue

Set-PSReadLineOption -Colors @{
  Default   = 'Black'       # ← これが本命（白背景でも見える）
  Command   = 'DarkBlue'
  Parameter = 'DarkCyan'
  String    = 'DarkGreen'
  Operator  = 'DarkMagenta'
  Number    = 'DarkYellow'
}

