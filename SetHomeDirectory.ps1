#path to the Users shared folder
$homepath = "\\hq\CorporateData\Users\"

#initial OU where the script starts searching for the users
$basepath = "OU=Users,OU=ITLifeSkills,DC=hq,DC=itlifeskills,DC=local"
$users = Get-ADUser -SearchBase $basepath -Filter *


foreach($user in $users){
    #Get the current user identity
    $identity = $user.SamAccountName
    #Get the current user name
    $name = $user.Name
    
    #construct the homedirectory path
    $homedirectory = $homepath + $name

    #Update the current user with the new path to the Home directory.
    Set-ADUser -Identity $identity -HomeDirectory $homedirectory
}

