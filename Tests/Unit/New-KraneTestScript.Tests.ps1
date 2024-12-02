# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "New-KraneTestScript" {
        Context "New-KraneTestScript with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive
                $TestScriptName = 'TestScript'
                                
                New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath 
                $NewProject = Get-KraneProject -Root "$($ProjectPath)\$($ProjectName)"
                New-KraneTestScript -KraneModule $NewProject -TestName $TestScriptName
            }
            It "Test should be created" {
                (Join-Path $NewProject.Tests.FullName -ChildPath "$($TestScriptName).Tests.ps1") | Should -Exist
            }
        }
    }
}