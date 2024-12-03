# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "New-KraneNugetFile" {
        Context "New-KraneNugetFile with valid parameters" {
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

            It "New-KraneNugetFile without -Force should not throw" {
                { New-KraneNugetFile -KraneModule $NewProject } | Should -Not -Throw
            }
            It "New-KraneNugetFile -Force should not throw" {
                { New-KraneNugetFile -KraneModule $NewProject -Force } | Should -Not -Throw
            }
        }
    }
}