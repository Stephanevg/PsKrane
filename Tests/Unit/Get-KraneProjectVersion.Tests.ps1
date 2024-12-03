
# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "Get-KraneProjectVersion" {
        Context "Get-KraneProjectVersion with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive
                $ProjectVersion = '0.0.1'

            
                # Act
                $NewProject = New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
                $Version = Get-KraneProjectVersion -KraneProject $NewProject
            }

            It "Version should not be null " {
                $Version | Should -Not -BeNullOrEmpty
            }
            It "Version should be correct" {
                $Version | Should -Be $ProjectVersion
            }
        }
    }
}