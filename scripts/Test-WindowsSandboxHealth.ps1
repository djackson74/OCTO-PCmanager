# Host-side Windows Sandbox connectivity prerequisite check.
# OCTO-PCmanager - run before relying on in-Sandbox downloads or installer tests.
param(
    [switch]$Quiet
)

$ErrorActionPreference = 'SilentlyContinue'
$failures = @()
$warnings = @()

function Write-Probe {
    param([string]$Text, [ConsoleColor]$Color = 'DarkGray')
    if (-not $Quiet) { Write-Host $Text -ForegroundColor $Color }
}

function Add-Fail { param([string]$Label) $script:failures += $Label; Write-Host "  FAIL  $Label" -ForegroundColor Red }
function Add-Warn { param([string]$Label) $script:warnings += $Label; Write-Host "  WARN  $Label" -ForegroundColor Yellow }
function Add-Ok   { param([string]$Label) Write-Probe "  OK  $Label" }

if (-not $Quiet) { Write-Host '=== Windows Sandbox health probe (host) ===' -ForegroundColor Cyan }

# Host egress
try {
    $t = Test-NetConnection -ComputerName '1.1.1.1' -Port 443 -WarningAction SilentlyContinue
    if ($t.TcpTestSucceeded) { Add-Ok 'host TCP 443 (1.1.1.1)' } else { Add-Fail 'host TCP 443 (1.1.1.1)' }
} catch { Add-Fail 'host TCP 443 (1.1.1.1)' }

try {
    $t2 = Test-NetConnection -ComputerName 'github.com' -Port 443 -WarningAction SilentlyContinue
    if ($t2.TcpTestSucceeded) { Add-Ok 'host TCP 443 (github.com)' } else { Add-Fail 'host TCP 443 (github.com)' }
} catch { Add-Fail 'host TCP 443 (github.com)' }

# Default Switch (Sandbox NAT)
$ds = Get-NetIPAddress -InterfaceAlias 'vEthernet (Default Switch)' -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($ds) {
    Add-Ok "Default Switch present ($($ds.IPAddress))"
} else {
    Add-Warn 'Default Switch not found (Sandbox not used yet or Hyper-V networking off)'
}

# Recent network fault events
$since = (Get-Date).AddHours(-24)
$bad = Get-WinEvent -FilterHashtable @{ LogName = 'System'; StartTime = $since } -MaxEvents 300 |
    Where-Object {
        $_.Id -eq 4266 -or $_.Id -eq 4003 -or $_.Id -eq 7023 -or
        $_.Message -match 'IP address conflict|limited connectivity|ephemeral port'
    }
if ($bad) {
    foreach ($e in ($bad | Select-Object -First 5)) {
        Add-Warn "recent $($e.ProviderName) Id=$($e.Id) @ $($e.TimeCreated)"
    }
} else {
    Add-Ok 'no recent IP conflict / UDP exhaustion / WLAN limited events (24h)'
}

# Default.wsb recipe - mapped folder?
$recipe = Join-Path $env:LOCALAPPDATA 'Packages\MicrosoftWindows.WindowsSandbox_cw5n1h2txyewy\LocalState\Recipes\Default.wsb'
if (Test-Path $recipe) {
    $raw = Get-Content $recipe -Raw
    if ($raw -match '<MappedFolder>' -and $raw -notmatch '<MappedFolders\s*/>') {
        Add-Ok 'Default.wsb has mapped folders'
    } else {
        Add-Warn 'Default.wsb has no mapped folders - in-Sandbox download required for file bootstrap'
    }
    if ($raw -match '<LogonCommand>\s*<Command>[^<]+</Command>' -and $raw -notmatch '<LogonCommand\s*/>') {
        Add-Ok 'Default.wsb has LogonCommand'
    } else {
        Add-Warn 'Default.wsb has no LogonCommand'
    }
} else {
    Add-Warn 'Default.wsb recipe not found'
}

if ($failures.Count -gt 0) {
    if (-not $Quiet) {
        Write-Host ('  FAIL  ' + $failures.Count + ' blockers - fix host network before Sandbox installer test') -ForegroundColor Red
    }
    exit 1
}

if (-not $Quiet) {
    if ($warnings.Count -gt 0) {
        Write-Host ('  OK  Sandbox prerequisites acceptable - ' + $warnings.Count + ' warnings') -ForegroundColor Cyan
    } else {
        Write-Host '  OK  Sandbox prerequisites acceptable' -ForegroundColor Cyan
    }
}
exit 0