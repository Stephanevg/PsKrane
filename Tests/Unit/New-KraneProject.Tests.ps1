# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent -ChildPath "$($psroot.Parent.Name)/$($psroot.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Name -ScriptBlock {
    Describe "New-KraneProject" {
        Context "Non-Functional requirements" {
            BeforeAll {
            $command = Get-Command -Name New-KraneProject
            }
            It "Has a parameter called 'Type'" {
                $command.Parameters.ContainsKey('Type') | Should -Be $True
            }
            It "Parameter 'Type' should be of type ProjectType" {
                $command.Parameters.Type.ParameterType.Name | Should -Be 'ProjectType'
            }
            It "Has a parameter called 'Name'" {
                $command.Parameters.ContainsKey('Name') | Should -Be $True
            }
            It "Parameter 'Name' should be of type String" {
                $command.Parameters.Name.ParameterType.Name | Should -Be 'String'
            }
            It "Has a parameter called 'Path'" {
                $command.Parameters.ContainsKey('Path') | Should -Be $True
            }
            It "Parameter 'Path' should be of type DirectoryInfo" {
                $command.Parameters.Path.ParameterType.Name | Should -Be 'DirectoryInfo'
            }
        }
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
            It "KraneProject tags should be correct" {
                $NewProject.Tags | Should -Be $null
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
            It "KraneProject templates should not be empty" {
                $NewProject.Templates.Templates | Should -Not -BeNullOrEmpty
            }
        }
    
        Context "new project of type script with valid parameters" {
            #Not implemented yet
        }
    }
}
