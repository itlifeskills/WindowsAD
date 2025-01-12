#Path to the Projects folder in namespace root.
$path = "\\hq\CorporateData\Projects\"

#Path to the targets where actual data is stored
$targetpaths = "\\CHIPVFS01\Projects\", "\\CHIPVFS02\Projects\"

#Loop through each target path
foreach($targetpath in $targetpaths){
    
    #Get all the subfolders in the target path
    $folders= Get-ChildItem -Path $targetpath

    #Loop through each subfolder
    foreach($folder in $folders){
        
        #Construct the full path for the folder target
        $folderpath = $path + $folder

        #Construct the full path for the target
        $foldertargetpath = $targetpath + $folder
        
        #Create the folder with target
        New-DfsnFolder -Path $folderpath -TargetPath $foldertargetpath

    }

}
