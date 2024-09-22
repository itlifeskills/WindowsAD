$department = "Art and Design"
$name = $department.Split(" ")
$groupName= "grp"
foreach($word in $name){
    
    if($word -ne "and"){
   
        $groupName = $groupName + "-" + ($word).ToLower()
   }
}



$departments = (Import-Csv -Path "C:\Scripts\Data\Departments.csv").Department

$path = "OU=Groups,OU=ITLifeSkills,DC=hq,DC=itlifeskills,DC=local"

foreach ($department in $departments){

    $name = $department.Split(" ")
    $groupName= "grp"
    foreach($word in $name){
    
        if($word -ne "and"){
   
            $groupName = $groupName + "-" + ($word).ToLower()
       }
    }

    New-ADGroup -Name $groupName -SamAccountName $groupName -GroupCategory Security -GroupScope Global -DisplayName $groupName -Path $path  -Description $department
}



$projects = (Import-Csv -Path "C:\Scripts\Data\Projects.csv").Project

$path = "OU=Groups,OU=ITLifeSkills,DC=hq,DC=itlifeskills,DC=local"

foreach ($project in $projects){

    $name = $project.Split(" ")
    $groupName= "grp"
    foreach($word in $name){
    
        if($word -ne "and"){
   
            $groupName = $groupName + "-" + ($word).ToLower()
       }
    }

    New-ADGroup -Name $groupName -SamAccountName $groupName -GroupCategory Security -GroupScope Global -DisplayName $groupName -Path $path  -Description $project
}



