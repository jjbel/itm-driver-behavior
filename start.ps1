# https://learn.microsoft.com/en-us/powershell/module/nettcpip/get-netipaddress?view=windowsserver2025-ps
# for me it's the first wifi adapter: the IPv4 address has the alias Wi-Fi, not Wi-Fi 2 or Wi-Fi 3
$ip = ((Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi | Out-String) -split '\n')[1].Substring(20)

# HTTPS is needed for the app to work with camera
# when testing on the local network on a phone, or when reloading on desktop
# else weird behaviour happens
# https://www.npmjs.com/package/live-server-https
npx live-server --host=$ip --https=.\node_modules\live-server-https
