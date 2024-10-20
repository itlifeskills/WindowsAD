$projects = (Import-Csv -Path "C:\Scripts\Data\Projects.csv").Project

foreach ($project in $projects){

    New-Item -Path "D:\Projects" -Name $project -ItemType "directory"
}

