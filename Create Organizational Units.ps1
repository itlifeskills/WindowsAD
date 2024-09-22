$departments = (Import-Csv -Path "C:\Scripts\Data\Departments.csv").Department

foreach ($department in $departments){

    New-ADOrganizationalUnit -Name $department -Path "OU=Users,OU=ITLifeSkills,DC=hq,DC=itlifeskills,DC=local"
}

