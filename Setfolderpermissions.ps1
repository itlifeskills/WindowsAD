
# Get a list of folder folders
$domainUsers = "HQ\Domain Users"
$folderPath = "D:\Projects\"
$folders = (Get-ChildItem -Path $folderPath).Name 


#Loop throug each folder in all the folders found in the D:\Departments folder
foreach ($folder in $folders){ 


   if($folder -ne "Accounting and Finance"){  #Only run the script to apply the permission on the Accounting and Finance folder

    
    $path = $folderPath + $folder #Set path for the current folder
    $name = $folder.Split(" ") #Split the folder name by the space to construct the group name
    $groupName= "HQ\grp" # Set the intial group name
    foreach($word in $name){ #Loop through each word in the folder name
        if($word -ne "and"){ #If the word is not "and"
           #Add the initial group name with a "-" and the current word in the folder name and convert it to lower case 
           $groupName = $groupName + "-" + ($word).ToLower() 
            
       }
    } #After the for loop we will have the group name. For example, HQ\grp-accounting-finance

    
    ###Disable inheritance and preserve inherited access rules
    $aclList  = Get-Acl -Path $path
    $isProtected = $true #Protect the item from being inherited
    $preserveInheritance = $true #Keep all the entries in the current ACL 
    $aclList.SetAccessRuleProtection($isProtected, $preserveInheritance)
    Set-Acl -Path $path -AclObject $aclList
    
    ## Remove Domain Users
    $aclList = Get-ACL -Path $path
    
    $aclList.Access | Where-Object { $_.IdentityReference.Value -eq $domainUsers } | 
                    ForEach-Object {$aclList.RemoveAccessRule($_)} | Out-Null
    Set-Acl -Path $path -AclObject $aclList
    
    # Prepare the list of the permission properties to assign to the folder
    $aclList = Get-ACL -Path $path
    $identity =  $groupName
    $fileSystemRights = "Modify"
    $InheritanceFlags = "ContainerInherit, ObjectInherit" #Apply to this folder, subfolders and files
    $type = "Allow"
        
    # Create a new access rule containing the permission properties to assign to the folder
    $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $InheritanceFlags, "None", $type 
    $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
    
    # Apply the new rule to the folder
    $aclList.AddAccessRule($fileSystemAccessRule)
    Set-Acl -Path $path -AclObject $aclList

    ##$aclList | Select *
  }
}