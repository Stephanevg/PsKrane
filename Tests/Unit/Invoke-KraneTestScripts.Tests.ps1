# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "Invoke-KraneTestScripts" {
        Context "Invoke-KraneTestScripts with valid parameters" {
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
            it "Invoke-KraneTestScripts with latest version should not throw" {
                { Invoke-KraneTestScripts -KraneProject $NewProject } | Should -Not -Throw
            }
        }

        
    }
}