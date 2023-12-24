$elgpvdc03Sysvol = "\\ELGPVDC03\sysvol\hq.itlifeskills.local\Policies"
$aurpvdc01Sysvol = "\\AURPVDC01\sysvol\hq.itlifeskills.local\Policies"
$chipvdc11Sysvol = "\\CHIPVDC11\sysvol\hq.itlifeskills.local\Policies"


$sysVols = $elgpvdc03Sysvol, $aurpvdc01Sysvol, $chipvdc11Sysvol 

$sysVols | Get-ChildItem 

#New-GPO -Name "ITLifeSkills Computer Settings" -Server ELGPVDC03
