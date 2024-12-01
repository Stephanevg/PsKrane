# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent -ChildPath "$($psroot.Parent.Name)/$($psroot.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Name -ScriptBlock {
    Describe "New-KraneProject" {
        Context "new project of type module with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive
                
                # Act
                $NewProject = New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
            }

            It "KraneProject should not be null " {
                $NewProject | Should -Not -BeNullOrEmpty
            }
            It "KraneProject module name should correct" {
                $NewProject.ModuleName | Should -Be $ProjectName
            }
            It "KraneProject root path should be correct" {
                $NewProject.Root | Should -Be "$($ProjectPath)\$($ProjectName)"
            }
            It "KraneProject type should be correct" {
                $NewProject.ProjectType | Should -Be $ProjectType
            }
            It "KraneProject file should exist" {
                (Test-Path $NewProject.KraneFile.Path) | Should -Be $True
            }
            It "KraneProject file path should be correct" {
                $NewProject.KraneFile.Path.FullName | Should -Be "$($ProjectPath)\$($ProjectName)\.krane.json"
            }
    
            It "KraneProject description should be correct" {
                $NewProject.Description | Should -Be $null
            }
    
            It "KraneProject project uri should be correct" {
                $NewProject.ProjectUri | Should -Be $null
            }
            It "KraneProject templates should not be empty" {
                $NewProject.Templates.Templates | Should -Not -BeNullOrEmpty
            }
        }
    
        Context "new project of type script with valid parameters" {
            #Not implemented yet
        }
    }
}
