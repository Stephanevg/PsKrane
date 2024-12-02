# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "Get-KraneTemplate" {
        Context "Get-KraneTemplate with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive

                # Act
                New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
                $NewProject = Get-KraneProject -Root "$($ProjectPath)\$($ProjectName)"
            }
            It "Templates should exist" {
            (Get-KraneTemplate -KraneProject $NewProject) | Should -Not -BeNullOrEmpty
            }
            It "There must be at least 3 templates" {
            (Get-KraneTemplate -KraneProject $NewProject).Count | Should -BeGreaterOrEqual 3
            }
            It "There must be at least 3 templates located in Module folder" {
            (Get-KraneTemplate -KraneProject $NewProject -Location Module).count | Should -BeGreaterOrEqual 3
            }
            It "There must be at least 1 template of type Class" {
            (Get-KraneTemplate -KraneProject $NewProject -Type Class).count | Should -BeGreaterOrEqual 1
            }
            It "There must be at least 1 template of type Function" {
            (Get-KraneTemplate -KraneProject $NewProject -Type Function).count | Should -BeGreaterOrEqual 1
            }
            It "There must be at least 1 template of type Script" {
            (Get-KraneTemplate -KraneProject $NewProject -Type Script).count | Should -BeGreaterOrEqual 1
            }
        }
    }
}