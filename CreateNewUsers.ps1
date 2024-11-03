#Import logon scripts for all departments from the CSV file.
$logonScripts = Import-Csv -Path "C:\Scripts\Data\LogonScript.csv"

#Import user Angel Stewart from CSV file.
$users = Import-Csv -Path "C:\Scripts\Data\NewUsers.csv" | where {$_.FirstName -eq "Angel" -and $_.LastName -eq "Stewart"}

$defphone = "713-485-5555"            #Default phone number
$homeFolder = "\\chipvfs01\Users\"    #Path to Users shared folder which is to store user home folders
$userAccounts = @()                   #UserAccounts object to store user account information    

foreach($user in $users){             #Loop through each user read from the NewUsers.csv file

    #Read users information from the CSV file
    $gname = $user.FirstName
    $mname = $user.MiddleName
    $sname = $user.LastName
    $fullname = $gname + " " + $sname
    $description = $user.Description
    $office = $user.Office
    $country = $user.Country
    $company = "ITLifeSkills"
    $title = $user.JobTitle
    $department = $user.Department

    #Get the LogOnScript for the department of the current user 
    $script = ($logonScripts | where {$_.Department -eq $department}).LogonScript

    #Use the phone number in the CSV file if found otherwise use the default phone number
    if($user.PhoneNumber){

        $phone = $user.PhoneNumber
    
    }
    else{
        $phone = $defphone
    }

    # Generate a random password using ascii-characters-from-33-126
    # For more information about the asciicharacters https://www.ibm.com/docs/en/sdse/6.4.0?topic=configuration-ascii-characters-from-33-126

    $password = -join([char[]](33..122) | Get-Random -Count 10)
    $securePassword = ConvertTo-SecureString ($password) -AsPlainText -Force

    #Construct the username samAccount from middle name, given name and surname.
    if($user.MiddleName){

        $samAccount = ($gname[0] + $mname[0] + $sname[0]).ToLower()
    
    }
    else{
        $samAccount = ($gname[0] + "x" + $sname[0]).ToLower()
    
    }

    # Verify if the username exists, if Yes add $i to the username
    $i = 1
    do{
        
        try{
        $exist = Get-ADUser -Identity $samAccount
        $samAccount = $samAccount + $i
        $i++
        }
        catch{

            break
    
        }
    }while($exist)
           
    $userprincipal = $samAccount + "@hq.itlifeskills.local"    
    
    #If found  the manager in the CSV file, get the distinguished name of the manager
    $manager = $user.Manager
    if($manager){
        $userManager = (Get-ADUser -Filter 'DisplayName -eq $manager').DistinguishedName
    }
    else{
        $userManager = $null
    }

    #Find the Distinguished name of the department OU 
    $baseOU = "OU=Users,OU=ITLifeSkills,DC=hq,DC=itlifeskills,DC=local"
    $OU = (Get-ADOrganizationalUnit -SearchBase $baseOU -Filter 'Name -eq $department').DistinguishedName

    #Path to the User Home Folder
    $userFolder = $homeFolder + $fullname

    #Form the object of user properties
    $userProperties = @{
        GivenName = $gname
        Surname = $sname
        DisplayName = $fullname
        Name = $fullname
        SamAccountName = $samAccount
        AccountPassword = $securePassword
        UserPrincipalName = $userprincipal
        Office = $office
        Company = $company
        Country = $country
        Department = $department
        Description = $description
        Title = $title
        OfficePhone = $phone
        HomeDirectory = $userFolder
        HomeDrive = "U:"
        ScriptPath = $script 
        Path = $OU
        Manager = $userManager
        ChangePasswordAtLogon = $true
        Enabled = $true
    }
    
    #Create the new user from the @userProperties object
    New-ADUser @userProperties
    
    #Chek if the folder exists. If not, create the user home folder
    $exist = Test-Path $userFolder

    if(!$exist){
    
        New-Item -Path $userFolder -ItemType "Directory"
    }
       
    #Get the current access list on the user home folder    
    $aclList  = Get-Acl -Path $userFolder
    
    #Create a rule parameters object for to grant FullControl access for the current user
    
    $parameters = @(
     "HQ\$samAccount"        #IdentityReference
     "FullControl"           #FileSystemRights
     ,@(                     #InheritanceFlags
        "ContainerInherit"   #Apply to the current folder
        "ObjectInherit"      #Apply to subfolders and files in the current folder
     )
     "None"                  #PropagationFlags
     "Allow"                 #AccessControlType
    )

    #Create the rule from the paramters
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $parameters

    #Add the rule into the current access list
    $aclList.AddAccessRule($rule)

    #Set the new rule on the user home folder    
    $aclList | Set-Acl $userFolder

    #Build the userdata object to export

    $userData = [PSCustomObject]@{
        Name = $fullname;    
        SamAccountName = $samAccount;
        AccountPassword = $password;
        Office = $office;
        Company = $company;
        Country = $country
        Department = $department;
        Description = $description;
        Title = $title;
        OfficePhone = $phone;
        Manager = $manager
    }

    $userAccounts += $userData

}


$userAccounts | Export-Csv -Path "C:\Scripts\Data\UserAccounts.csv" -NoTypeInformation
#Get-ADUser -Identity egh -Properties *