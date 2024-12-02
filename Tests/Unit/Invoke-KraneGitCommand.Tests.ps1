# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "Invoke-KraneGitCommand" {
        BeforeAll {
            # Arrange
            $ProjectType = 'Module'
            $ProjectName = 'TestProject'
            $ProjectPath = $TestDrive
            $ProjectVersion = '0.0.1'

            # Act
            New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath 
            $NewProject = Get-KraneProject -Root "$($ProjectPath)\$($ProjectName)"
            Set-Location -Path "$($ProjectPath)\$($ProjectName)"
            Invoke-Command -ScriptBlock { git init }
            Invoke-Command -ScriptBlock { git add . }
            Invoke-Command -ScriptBlock { git commit -m "Initial commit" }
        }
        Context "Invoke-KraneGitCommand with valid parameters" {
            It "GitAction tag Should not throw" {
                { Invoke-KraneGitCommand -KraneProject $NewProject -GitAction tag } | Should -Not -Throw
            }
        }
    }
}