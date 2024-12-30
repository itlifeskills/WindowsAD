#In ITLifeSkills, CurrentUsers.csv contains all current users in ITLifeSkills.
#Therefore, updating users in AD will require us to update their information in CurrentUsers.csv file 
$CurrentUsersFile = "C:\Scripts\Data\CurrentUsers.csv"
$CurrentUsers = Import-Csv -Path $CurrentUsersFile

#Import logon scripts for all departments from the CSV file.
$logonScripts = Import-Csv -Path "C:\Scripts\Data\LogonScript.csv"

#Import users who are requested to update their information from UpdateUsers.csv file.
$users = Import-Csv -Path "C:\Scripts\Data\UpdateUsers.csv" | where {$_.SamAccountName -eq "axs"}


#$UpdateUsers is to store all users with updated information which allow to filter and to export CurrentUsers.csv file.  
$UpdateUsers = @()

#The OU from which we start searching for the users
$baseOU = "OU=Users,OU=ITLifeSkills,DC=hq,DC=itlifeskills,DC=local"                     

function Update-Property( $propertyName, $currentValue, $newValue ){

    #If the propertyName is Manager, then update its value from Name to Distinguished Name.
    #This allow us to compare with the Distinguished Name of the manager of the user stored in AD
    if($propertyName -eq "Manager"){
         $managerName = $newValue   
         $newValue = (Get-ADUser -Filter 'Name -eq  $managerName').DistinguishedName
    }            

    #Determine if the new value is not null and different from current value of the user stored in AD 
    if(($newValue) -and ($newValue -ne $currentValue)){
        
        #If Yes, add the property with the new value into the $userProperties hash table
        $userProperties.Add($propertyName, $newValue)
        
        #Also, update the property of the current user in the CurrentUsers.csv with the new value
        if($propertyName -eq "Manager"){
            $currentUser.$propertyName = $managerName
        }
        else{
            $currentUser.$propertyName = $newValue
        }

        #If the Department of the user is changed
        if($propertyName -eq "Department"){            
            #Get the LogOnScript for the NEW department to update to the user 
            $script = ($logonScripts | where {$_.Department -eq $newValue}).LogonScript
            #Add the ScriptPath property with the $script variable to the $userProperties hash table
            $userProperties.Add("ScriptPath",$script)
            
            #Find the Distinguished name of the NEW department OU            
            $OU = (Get-ADOrganizationalUnit -SearchBase $baseOU -Filter 'Name -eq $newValue').DistinguishedName
            
            #Move the user to the new department OU
            Move-ADObject -Identity $updateUser.DistinguishedName -TargetPath $OU   
        }

    }
}


#Read each user that is to be updated from the UpdateUsers.csv file.

foreach($user in $users){             
  
    #Get the SamAccountName of the first user and store it in the $samAccount variable.
    $samAccount = $user.SamAccountName

    #Construct the hash table of $userproperties initially including only SamAccountName
    $userProperties = @{
       Identity = $samAccount
                
    }
    
    #Read the user with same $samAccount from the CurrentUsers.csv to be updated with the new properties
    $currentUser = $CurrentUsers | where {$_.SamAccountName -eq $samAccount}        

    #Read the user with same $samAccount from Active Directory to determine which properties to be updated
    $updateUser = Get-ADUser -Identity $samAccount -Properties *

    #For the current user read from the UpdateUsers.csv file, get only the Name and Value properties
    #filter to only the properties that are not Empty and not equal to the “MiddleName”.
    $updateProperties = $user.PSObject.Properties | Select Name, Value | where {($_.value -ne "")-and ($_.Name -ne "MiddleName")} 

    #Loop through each property of the current user read from UpdateUsers.csv
    foreach($property in $updateProperties){       
        #Build up the property Name and its Value 
        $propertyName = $property.Name
        $propertyValue = $property.Value

        #Get the current value of the property with the same Name from the user stored in Active Directory    
        $currentValue = $updateUser.$propertyName

        #Update the property using the Update-Property custom function
        Update-Property $propertyName $currentValue $propertyValue
    }
       
  #After the foreach loop completed, we will have the @userProperties hash table with the properties being updated  
  Set-ADUser @userProperties 

  #The properties of the $currentUser includes with updated information
  #We store $currentUser into the $UpdateUsers
  $UpdateUsers += $currentUser  


}    

#At this point the $UpdateUsers contains all users with updated information 

#First we remove the CurrentUsers.csv which contain all current users.
Remove-Item -Path $CurrentUsersFile

#Then build a list of samAccountNames of all users that got updated
$updatedSamAccount = $UpdateUsers.SamAccountName 

#Exclude users that got updated from the $CurrentUsers
$CurrentUsers | where {$_.SamAccountName -notin $updatedSamAccount} | 

#Export them to CurrentUsers.csv file
#The CurrentUsers.csv now only contains users that are not updated
Export-Csv -Path $CurrentUsersFile -NoTypeInformation

#Finally, append the users that got updated to the CurrentUsers.csv
$UpdateUsers | Export-Csv $CurrentUsersFile -Append 


#>   