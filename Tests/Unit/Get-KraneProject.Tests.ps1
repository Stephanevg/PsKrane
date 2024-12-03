# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "Get-KraneProject" {
        Context "Get-KraneProject with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive
                $ProjectVersion = '0.0.1'

            
                # Act
                New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
                $NewProject = Get-KraneProject -Root "$($ProjectPath)\$($ProjectName)"
            }
            It "Project object should exist" {
                $NewProject | Should -Not -BeNullOrEmpty
            }
            It "Project object should have a module name" {
                $NewProject.ModuleName | Should -Be $ProjectName
            }
            It "Project object should have a root folder" {
                $NewProject.Root | Should -Not -BeNullOrEmpty
            }
            It "Project root folder should be correct" {
                $NewProject.Root.FullName | Should -Be "$($ProjectPath)\$($ProjectName)"
            }
            It "Project root folder should exist" {
            (Test-Path $NewProject.Root) | Should -Be $True
            }
            It "Project object should have a krane file" {
                $NewProject.KraneFile | Should -Not -BeNullOrEmpty
            }
            it "Project krane file should be correct" {
                $NewProject.KraneFile.Path.FullName | Should -Be "$($ProjectPath)\$($ProjectName)\.krane.json"
            } 
            It "Project krane file should exist" {
            (Test-Path $NewProject.KraneFile.Path) | Should -Be $True
            }
            It "Project object should have a project type" {
                $NewProject.ProjectType | Should -Be $ProjectType
            }
            It "Project object should have a project version" {
                $NewProject.ProjectVersion | Should -Be $ProjectVersion
            }
        }
    }
}