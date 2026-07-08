# Windows Sandbox — connectivity and installer testing

Recorded: 2026-07-08 (host: GAMER, Windows 11 + WSL2 + Hyper-V).

## Symptom

Windows Sandbox opens (or starts briefly) but **cannot connect to the internet**, cannot download an installer/bootstrap script, or drops offline within a few minutes.

## What the device logs showed

| Signal | Log / source | Meaning |
|--------|----------------|---------|
| UDP port exhaustion | System — **Tcpip Event 4266** | All global UDP ephemeral ports in use; DNS/HTTPS from Sandbox NAT can fail. |
| Wi-Fi degraded | System — **WLAN-AutoConfig Event 4003** | Limited connectivity; auto-recovery in progress. |
| LAN IP conflict | System — **Service Control Manager 7023** (repeated) | Another device may share the host IP (`192.168.0.x`); destabilizes NAT. |
| VM did start | **Hyper-V-VmSwitch** on **Default Switch** | Sandbox VM attached; failure is usually **host egress/NAT**, not Hyper-V boot. |
| Empty recipe | `%LOCALAPPDATA%\Packages\MicrosoftWindows.WindowsSandbox_*\LocalState\Recipes\Default.wsb` | No `MappedFolders`, no `LogonCommand` — installer must download inside Sandbox. |
| Fresh install | Windows Update — `MicrosoftWindows.WindowsSandbox` | First session after install is higher risk; reboot after feature install. |

Host internet can be fine **after** the incident while still having failed **during** the Sandbox session.

## Diagnostic order

1. **Host first** (Sandbox uses Default Switch NAT through the host):
   ```powershell
   Test-NetConnection 1.1.1.1 -Port 443
   Test-NetConnection github.com -Port 443
   Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' }
   ```
2. **Recent network errors** (last 24h):
   ```powershell
   Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=(Get-Date).AddHours(-24) } -MaxEvents 200 |
     Where-Object { $_.Id -in 4266,4003,7023 -or $_.Message -match 'IP address conflict|limited connectivity|ephemeral port' } |
     Select-Object TimeCreated, Id, ProviderName, Message
   ```
3. **Hyper-V Default Switch** (Sandbox NIC):
   ```powershell
   Get-NetIPAddress -InterfaceAlias 'vEthernet (Default Switch)' -AddressFamily IPv4
   Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-VmSwitch-Operational' -MaxEvents 20
   ```
4. **Inside Sandbox** (if window is up):
   ```powershell
   Test-NetConnection 1.1.1.1 -Port 443
   Resolve-DnsName github.com
   ```

Run bundled probe: `scripts\Test-WindowsSandboxHealth.ps1`

## Fixes (safest first)

1. **Reboot host** — clears UDP ephemeral port exhaustion and stuck NAT state.
2. **Resolve LAN IP conflict** — ensure only one device uses the host's Wi-Fi/Ethernet address; check router DHCP reservations.
3. **Stabilize Wi-Fi** — disconnect/reconnect; confirm no "limited connectivity" icon before relaunching Sandbox.
4. **Do not rely on in-Sandbox download** for OCTO installer testing — map the repo:
   - Use a `.wsb` with `MappedFolders` pointing at `octo-dev` and a `LogonCommand` for `Install-OctoLauncher.ps1 -SkipBoot`.
   - Networking can stay enabled for package managers, but mapped folder removes the failure mode.
5. **After enabling Windows Sandbox feature** — one full reboot before first production test.
6. **Coexistence** — WSL2, VirtualBox host-only, and Default Switch together are normal; if 4266/4003 recur, reduce parallel VM/switch churn and reboot.

## What not to assume

- Empty Default Switch warnings (VmSwitch Event 285) alone are usually noise.
- Sandbox Operational logs may require elevation to read; System + Hyper-V-VmSwitch logs are often enough.
- Microsoft PC Manager AppModel warnings in Application log are unrelated to Sandbox NAT.

## OCTO cross-link

Launcher installer smoke tests in an isolated VM should prefer **mapped-folder bootstrap** over raw `Default.wsb` with empty `LogonCommand`. OCTO-PCmanager owns host-network diagnosis; octo-launcher owns the `.wsb` recipe when present.