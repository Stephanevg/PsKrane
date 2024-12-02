
# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "New-KraneNuspecFile" {
        Context "New-KraneNuspecFile with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive

                # Act
                $NewProject = New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
                Invoke-KraneBuild -KraneProject $NewProject
                New-KraneNuspecFile -KraneModule $NewProject
                $NuspecFile = Join-Path -Path $NewProject.Outputs.FullName -ChildPath "Module\$($NewProject.ModuleName).nuspec"
                $NugetPackage = Join-Path -Path $NewProject.Outputs.FullName -ChildPath "Nuget\$($NewProject.ModuleName).$($NewProject.ProjectVersion).nupkg"
            }

            It "Nuspec file should be created" {
            (test-path -Path $NuspecFile) | Should -Be $true
            }
            It "Nuspec package should be ceated" {
            (test-path -Path $NugetPackage) | Should -Be $true
            }
        }
    }
}