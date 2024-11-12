Describe "New-KraneNuspecFile" {
    Context "New-KraneNuspecFile with valid parameters" {
        BeforeAll {
            # Arrange
            $ProjectType = 'Module'
            $ProjectName = 'TestProject'
            $ProjectPath = $TestDrive

            # Act
            $NewProject = New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
            New-KraneNuspecFile -KraneModule $NewProject
            $NuspecFile = Join-Path -Path $NewProject.Outputs.FullName -ChildPath "Module\$($NewProject.ModuleName).nuspec"
            $NugetPackage = Join-Path -Path $NewProject.Outputs.FullName -ChildPath "Nuget\$($NewProject.ModuleName).$($NewProject.ProjectVersion).nuspec"
        }

        It "Nuspec file should be created" {
            $NuspecFile.Exists | Should -BeTrue
        }
        It "Nuspec package should be ceated" {
            $NugetPackage.Exists | Should -BeTrue
        }
    }
}