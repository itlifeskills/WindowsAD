#Get all domain controllers in the AD forest
$sourceDCs = ((Get-ADForest).Domains | %{ Get-ADDomainController -Filter * -Server $_ }).HostName

#For each domain controller, find all domain controllers where it replicate to
foreach($sourceDC in $sourceDCs){
    $destinationDCs = (Get-ADReplicationConnection -Filter * | Select ReplicateFromDirectoryServer, ReplicateToDirectoryServer | 
                           where{$_.ReplicateFromDirectoryServer.Contains($sourceDC.Split(".")[0])}).ReplicateToDirectoryServer
    
    #Put all destination domain controllers into a string to show their names only
    $destinationDC = $null
    foreach($dc in $destinationDCs){
        $destinationDC += ($dc.Split(",")[0]).Split("=")[1] + "; "           
    }
    Write-Host "Replicating from $sourceDC to $destinationDC"

}
