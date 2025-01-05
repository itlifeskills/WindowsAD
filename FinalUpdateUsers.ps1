#Import logon scripts for all departments from the CSV file.
$logonScripts = Import-Csv -Path "D:\Scripts\Data\LogonScript.csv"

#The OU from which we start searching for the users
$baseOU = "OU=Users,OU=ITLifeSkills,DC=hq,DC=itlifeskills,DC=local"   

#The date users get updated
$updatedDate = (Get-Date).ToString("yyyy-MM-dd")

#Construct paths to CSV files
$basePath = "D:\Departments\Human Resources\UserManagement\"
$updateuserPath = $basePath + "UpdateUsers.csv"
$currentuserPath = $basePath + "Completed\CurrentUsers.csv"

#$UpdateUsers is to store all users with updated information .  
$UpdatedUserPath = $basePath + "Completed\UpdatedUsers.csv"

#In ITLifeSkills, CurrentUsers.csv contains all current users in ITLifeSkills.
#Therefore, updating users in AD will require us to update CurrentUsers.csv 
$CurrentUsers = Import-Csv -Path $currentuserPath
                

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

#Check to see if the UpdateUsers.csv file has been uploaded to the right location
$updatefile = Test-Path $updateuserPath

if($updatefile){

    #Import users who are requested to update their information 
    #from UpdateUsers.csv file.
    $users = Import-Csv -Path $updateuserPath 
    
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
        $updateProperties = $user.PSObject.Properties | Select Name, Value | 
        where {($_.value -ne "")-and ($_.Name -ne "MiddleName")} 

        #Loop through each property of the current user read from UpdateUsers.csv
        foreach($property in $updateProperties){       
            #Build up the property Name and its Value 
            $propertyName = $property.Name
            $propertyValue = $property.Value

            #Get the current value of the property with the same 
            #Name from the user stored in Active Directory    
            $currentValue = $updateUser.$propertyName

            #Update the property using the Update-Property custom function
            Update-Property $propertyName $currentValue $propertyValue
        }
       
      #After the foreach loop completed, 
      #we will have the @userProperties hash table with the properties being updated  
      Set-ADUser @userProperties
      #Add the updated date to each update user
      $user | Add-Member -MemberType NoteProperty -Name "UpdatedOn" -Value $updatedDate 

    }    
    #Append all the users in the UpdateUsers.csv file 
    #along with the updated date to the UpdatedUsers.csv file
    $users | Export-Csv -Path $UpdatedUserPath -NoTypeInformation -Append
    Remove-Item -Path $updateuserPath   

    #At this point the $CurrentUsers  contains all users with updated information 
    $CurrentUsers | Export-Csv -Path $currentuserPath -NoTypeInformation
}


 