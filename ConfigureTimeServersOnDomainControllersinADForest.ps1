#1. Configure PDC Emulator of the root domain to use external time sources

ping 1.north-america.pool.ntp.org
ping 2.north-america.pool.ntp.org

$currentdomain = (Get-ADDomain).DNSRoot
$pcdEmulator = (Get-ADDomain).PDCEmulator
$hostname = $env:computername + "." + $currentdomain
$path="HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Parameters"
$externalNTPServers = "1.north-america.pool.ntp.org,0x8 2.north-america.pool.ntp.org,0x8" #0x08 - send request as Client mode

if(($hostname -eq $pcdEmulator)){
    Set-ItemProperty $path -Name "Type" -Value "NTP"
    Set-ItemProperty $path -Name "NtpServer" -Value $externalNTPServers
    Write-Host $hostname "has been configured to sync time with" $externalNTPServers

}
else{
    Set-ItemProperty $path -Name "Type" -Value "NT5DS"
    Write-Host $hostname "has been configured to sync time with a domain controller"
}

#Update change and query peers and current time sources
hostname
net stop w32time 
net start w32time
w32tm /resync /rediscover
w32tm /query /peers
w32tm /query /source


#2. Configure PDC Emulator of the child domain to use external time sources
ipconfig /flushdns
ping 1.north-america.pool.ntp.org
ping 2.north-america.pool.ntp.org


$currentdomain = (Get-ADDomain).ChildDomains[0]
$pcdEmulator = (Get-ADDomain -Identity $currentdomain).PDCEmulator
$hostname = $env:computername + "." + $currentdomain
$path="HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Parameters"
$externalNTPServers = "1.north-america.pool.ntp.org,0x8 2.north-america.pool.ntp.org,0x8" #0x08 - send request as Client mode

if(($hostname -eq $pcdEmulator)){
    Set-ItemProperty $path -Name "Type" -Value "NTP"
    Set-ItemProperty $path -Name "NtpServer" -Value $externalNTPServers
    Write-Host $hostname "has been configured to sync time with" $externalNTPServers

}
else{
    Set-ItemProperty $path -Name "Type" -Value "NT5DS"
    Write-Host $hostname "has been configured to sync time with a domain controller"
}

#Update change and query peers and current time sources
hostname
net stop w32time 
net start w32time
w32tm /resync /rediscover
w32tm /query /peers
w32tm /query /source


#3. Configure on all domain controllers in the child domain to use the PDC Emulator of the child domain as their time source.
hostname
$currentdomain = (Get-ADDomain).ChildDomains[0]
$pcdEmulator = (Get-ADDomain -Identity $currentdomain).PDCEmulator

w32tm /config /syncfromflags:manual /manualpeerlist:$pcdEmulator

net stop w32time 
net start w32time
w32tm /resync /rediscover

w32tm /query /source