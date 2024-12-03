# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "Invoke-KraneBuild" {
        Context "Invoke-KraneBuild with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive
                $ProjectVersion = '0.0.1'

                # Act
                New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath 
                $NewProject = Get-KraneProject -Root "$($ProjectPath)\$($ProjectName)"
                Invoke-KraneBuild -KraneProject $NewProject
            }

            It "Output directory should exist" {
                Test-Path -Path "$($ProjectPath)\$($ProjectName)\Outputs" | Should -BeTrue
            }
            It "Module subdirectory should exist" {
                Test-Path -Path "$($ProjectPath)\$($ProjectName)\Outputs\Module" | Should -BeTrue
            }
            It "Nuget subdirectory should exist" {
                Test-Path -Path "$($ProjectPath)\$($ProjectName)\Outputs\Nuget" | Should -BeTrue
            }
            It "psd1 file should exist" {
                Test-Path -Path "$($ProjectPath)\$($ProjectName)\Outputs\Module\$($ProjectName).psd1" | Should -BeTrue
            }
            It "psm1 file should exist" {
                Test-Path -Path "$($ProjectPath)\$($ProjectName)\Outputs\Module\$($ProjectName).psm1" | Should -BeTrue
            }
            It "nuspec file should exist" {
                Test-Path -Path "$($ProjectPath)\$($ProjectName)\Outputs\Module\$($ProjectName).nuspec" | Should -BeTrue
            }
            It "nupkg file should exist" {
                Test-Path -Path "$($ProjectPath)\$($ProjectName)\Outputs\Nuget\$($ProjectName).$($ProjectVersion).nupkg" | Should -BeTrue
            }
        }
    }
}