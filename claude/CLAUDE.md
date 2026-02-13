# CLAUDE.md

## 対話ルール
- 特に指定がなければ日本語で対話すること

## シェル環境
- PowerShell を使う場合は `powershell` ではなく `pwsh`(PowerShell 7）を使うこと
- Bash ツールから `pwsh -Command` を呼ぶ際、コマンド文字列はシングルクォートで囲むこと。ダブルクォートだと bash が `$PROFILE` や `$env:USERPROFILE` などを先にシェル変数として展開し空文字になる
  - OK: `pwsh -Command 'Write-Host $PROFILE'`
  - NG: `pwsh -Command "Write-Host $PROFILE"`
