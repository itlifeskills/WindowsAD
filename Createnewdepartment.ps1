$departments = (Import-Csv -Path "C:\Scripts\Data\Departments.csv").Department

foreach ($department in $departments){

    New-Item -Path "D:\Departments" -Name $department -ItemType "directory"
}

