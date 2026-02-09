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

function ssh-vast {
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

function sync-vast-rclone {
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
