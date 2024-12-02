# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "New-KraneItem" {
        BeforeAll {
            # Arrange
            $ProjectType = 'Module'
            $ProjectName = 'TestProject'
            $ProjectPath = $TestDrive
            $ProjectVersion = '0.0.1'

            # Act
            $NewProject = New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath 
            Set-Location -Path $NewProject.Root
        }
        Context "New-KraneItem with valid parameters" {
            It "Using New-KraneItem to create new item of type '<Type>' in '<Location>' Should not throw" -TestCases @(
                @{ Name = 'MyClass.ps1'; Type = 'Class'; Location = 'Module' }
                @{ Name = 'MyPrivateFunction.ps1'; Type = 'PublicFunction'; Location = 'Module' }
                @{ Name = 'MyPublicFunction.ps1'; Type = 'PrivateFunction'; Location = 'Module' }
            ) {
                Param($Name, $Type, $Location)
                { New-KraneItem -KraneProject $NewProject -Name $Name -Type $Type -Location $Location } | Should -Not -Throw
            }
        }
    }
}