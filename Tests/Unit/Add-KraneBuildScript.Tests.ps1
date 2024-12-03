# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "New-KraneBuild" {
        Context "New-KraneBuild with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive
                $ProjectVersion = '0.0.1'

                # Act
                $NewProject = New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
                Add-KraneBuildScript -KraneProject $NewProject
            }

            It "Add build script by path should not throw" {
                { Add-KraneBuildScript -Path "$($ProjectPath)\$($ProjectName)\Build" } | Should -Not -Throw
            }

            It "Add build script by KraneProject should not throw" {
                { Add-KraneBuildScript -KraneProject $NewProject } | Should -Not -Throw
            }
        }
    }
}