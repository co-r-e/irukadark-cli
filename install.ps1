# Install the IrukaDark CLI on Windows (Windows 11 or later). No administrator rights are needed.
#   irm https://raw.githubusercontent.com/co-r-e/irukadark-cli/main/install.ps1 | iex
# Options (environment variables):
#   IRUKADARK_VERSION  A version to install, such as 0.1.0 (default: the latest)
#
# irukadark.exe goes to %LOCALAPPDATA%\Programs\irukadark-cli (apart from IrukaDark Desktop, so removing one never
# removes the other), and that folder is added to your user PATH. The PATH is read without expanding names such as
# %JAVA_HOME% and written back as REG_EXPAND_SZ (setx is not used: it cuts the PATH at 1,024 characters). Apps started
# from the Start menu (Claude Code, Codex, VS Code) are told about the change right away, and this PowerShell window can
# run irukadark at once.

& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  $Repository = 'co-r-e/irukadark-cli'

  function Fail([string]$Message) {
    throw "irukadark: $Message"
  }

  # Move a file, trying again for a few seconds: antivirus software can hold a file it has just scanned
  function Move-WithRetry([string]$From, [string]$To) {
    for ($attempt = 1; ; $attempt++) {
      try {
        Move-Item -LiteralPath $From -Destination $To
        return
      } catch {
        if ($attempt -ge 10) { throw }
        Start-Sleep -Milliseconds 500
      }
    }
  }

  # The processor of Windows itself (an x64 PowerShell on an Arm PC reports AMD64 in PROCESSOR_ARCHITECTURE)
  $native = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').PROCESSOR_ARCHITECTURE
  $arch = switch ($native) {
    'AMD64' { 'x64' }
    'ARM64' { 'arm64' }
    default { Fail "This processor ($native) is not supported." }
  }

  $name = "irukadark-win32-$arch.exe"
  if ($env:IRUKADARK_VERSION) {
    $base = "https://github.com/$Repository/releases/download/v$($env:IRUKADARK_VERSION.TrimStart('v'))"
  } else {
    $base = "https://github.com/$Repository/releases/latest/download"
  }
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

  $tmp = Join-Path ([IO.Path]::GetTempPath()) "irukadark-$([Guid]::NewGuid())"
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    Write-Host "Downloading $name..."
    try {
      Invoke-WebRequest -UseBasicParsing -Uri "$base/$name" -OutFile (Join-Path $tmp $name)
      Invoke-WebRequest -UseBasicParsing -Uri "$base/SHA256SUMS" -OutFile (Join-Path $tmp 'SHA256SUMS')
    } catch {
      Fail "Could not download $base/$name ($($_.Exception.Message))"
    }
    $expected = $null
    foreach ($line in Get-Content (Join-Path $tmp 'SHA256SUMS')) {
      if ($line.Trim() -match '^([0-9a-f]{64})\s+\*?(.+)$' -and $Matches[2] -eq $name) {
        $expected = $Matches[1]
        break
      }
    }
    $actual = (Get-FileHash -Algorithm SHA256 -Path (Join-Path $tmp $name)).Hash.ToLowerInvariant()
    if (-not $expected -or $expected -ne $actual) {
      Fail 'The download does not match its checksum. Nothing was installed.'
    }

    $installDir = Join-Path $env:LOCALAPPDATA 'Programs\irukadark-cli'
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
    $target = Join-Path $installDir 'irukadark.exe'
    # A running irukadark (such as irukadark mcp started by an agent) keeps irukadark.exe open, and Windows does not let
    # anyone replace an open .exe. Move it aside to a new name first, and put it back if the new one cannot be placed.
    $old = $null
    if (Test-Path -LiteralPath $target) {
      $old = "$target.old-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())"
      Move-WithRetry $target $old
    }
    try {
      Move-WithRetry (Join-Path $tmp $name) $target
    } catch {
      if ($old) { Move-WithRetry $old $target }
      Fail "Could not put irukadark.exe in $installDir ($($_.Exception.Message)). Nothing was changed."
    }
    # Earlier copies that are no longer running (irukadark also removes them when it starts)
    Get-ChildItem -Path $installDir -Filter 'irukadark.exe.old-*' -ErrorAction SilentlyContinue |
      Remove-Item -Force -ErrorAction SilentlyContinue

    # irukadark update replaces only a copy it knows was installed by this script
    $configDir = Join-Path $env:USERPROFILE '.irukadark'
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    $record = @{ method = 'script'; path = $target } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText((Join-Path $configDir 'install.json'), "$record`n")

    # The user PATH (HKCU\Environment), kept as REG_EXPAND_SZ without expanding the names in it
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    try {
      $current = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
      $entries = @($current -split ';' | Where-Object { $_ -ne '' })
      $onPath = $entries | Where-Object { $_.TrimEnd('\') -ieq $installDir.TrimEnd('\') }
      if (-not $onPath) {
        $key.SetValue('Path', (($entries + $installDir) -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
        Add-Type -Namespace IrukaDarkInstall -Name Environment -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
        $result = [UIntPtr]::Zero
        # HWND_BROADCAST = 0xffff, WM_SETTINGCHANGE = 0x1a, SMTO_ABORTIFHUNG = 0x2
        [void][IrukaDarkInstall.Environment]::SendMessageTimeout([IntPtr]0xffff, 0x1a, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
      }
    } finally {
      $key.Close()
    }
    # This PowerShell window
    if (-not (($env:Path -split ';') | Where-Object { $_.TrimEnd('\') -ieq $installDir.TrimEnd('\') })) {
      $env:Path = "$env:Path;$installDir"
    }

    # Windows PowerShell 5.1 turns a native command's redirected error output into an error, which would stop this script
    # after the install has finished (irukadark may print an update notice there)
    $version = $null
    $started = $false
    try {
      $version = & {
        $ErrorActionPreference = 'Continue'
        $env:IRUKADARK_NO_UPDATE_CHECK = '1'
        try { & $target version 2>$null } finally { Remove-Item Env:IRUKADARK_NO_UPDATE_CHECK -ErrorAction SilentlyContinue }
      }
      $started = $LASTEXITCODE -eq 0
    } catch { }
    if (-not $started -or -not $version) {
      Write-Warning "irukadark.exe was installed to $target, but it did not start. Run '$target version' to see why."
      $version = 'irukadark'
    }
    Write-Host "Installed $version to $target"
    Write-Host ''
    Write-Host 'Next:'
    Write-Host '  irukadark auth login       Sign in'
    Write-Host '  irukadark skills install   Let Claude Code and Codex use irukadark'
  } finally {
    Remove-Item -Recurse -Force -Path $tmp -ErrorAction SilentlyContinue
  }
}
