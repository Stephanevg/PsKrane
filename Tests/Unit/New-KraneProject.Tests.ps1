# Generated with love using PsKrane

[System.IO.DirectoryInfo]$psroot = $PSScriptRoot
$ModuleName = $psroot.Parent.Parent.Name
[System.Io.DirectoryInfo] $ModuleRoot = $psroot.Parent.Parent #après tu reference $ModuleRoot.FullName
$ModuleFileName = "$ModuleName" + ".psd1"
[System.Io.Fileinfo] $ModuleFullPath = [System.IO.Path]::Combine($ModuleRoot.FullName , $ModuleName, $ModuleFileName) #Apres tu utilise $ModuleFullPath.FullName pour le path en full vers le psd1 pour les imports

Import-Module $ModuleFullPath.FullName -Force

InModuleScope -ModuleName $psroot.Parent.Parent.Name -ScriptBlock {
    Describe "New-KraneProject" {
        Context "Non-Functional requirements" {
            BeforeAll {
            $command = Get-Command -Name New-KraneProject
            }
            It "Has a parameter called 'Type'" {
                $command.Parameters.ContainsKey('Type') | Should -Be $True
            }
            It "Parameter 'Type' should be of type ProjectType" {
                $command.Parameters.Type.ParameterType.Name | Should -Be 'ProjectType'
            }
            It "Has a parameter called 'Name'" {
                $command.Parameters.ContainsKey('Name') | Should -Be $True
            }
            It "Parameter 'Name' should be of type String" {
                $command.Parameters.Name.ParameterType.Name | Should -Be 'String'
            }
            It "Has a parameter called 'Path'" {
                $command.Parameters.ContainsKey('Path') | Should -Be $True
            }
            It "Parameter 'Path' should be of type DirectoryInfo" {
                $command.Parameters.Path.ParameterType.Name | Should -Be 'DirectoryInfo'
            }
        }
        Context "new project of type module with valid parameters" {
            BeforeAll {
                # Arrange
                $ProjectType = 'Module'
                $ProjectName = 'TestProject'
                $ProjectPath = $TestDrive

                if ($IsWindows) {
                    $ExpectedRootPath = "$($ProjectPath)\$($ProjectName)"
                    $ExpectedKraneProjetFilePath = "$($ProjectPath)\$($ProjectName)\.krane.json"
                } else {
                    $ExpectedRootPath = "$($ProjectPath)/$($ProjectName)"
                    $ExpectedKraneProjetFilePath = "$($ProjectPath)/$($ProjectName)/.krane.json"
                }
                
                # Act
                $NewProject = New-KraneProject -Type $ProjectType -Name $ProjectName -Path $ProjectPath
            }

            It "KraneProject should not be null " {
                $NewProject | Should -Not -BeNullOrEmpty
            }
            It "KraneProject module name should correct" {
                $NewProject.ModuleName | Should -Be $ProjectName
            }
            It "KraneProject tags should be correct" {
                $NewProject.Tags | Should -Be @('PSEdition_Core', 'PSEdition_Desktop')
            }
            It "KraneProject root path should be correct" {
                $NewProject.Root | Should -Be $ExpectedRootPath
            }
            It "KraneProject type should be correct" {
                $NewProject.ProjectType | Should -Be $ProjectType
            }
            It "KraneProject file should exist" {
                (Test-Path $NewProject.KraneFile.Path) | Should -Be $True
            }
            It "KraneProject file path should be correct" {
                $NewProject.KraneFile.Path.FullName | Should -Be $ExpectedKraneProjetFilePath
            }
            It "KraneProject templates should not be empty" {
                $NewProject.Templates.Templates | Should -Not -BeNullOrEmpty
            }
        }
    
        Context "new project of type script with valid parameters" {
            #Not implemented yet
        }
    }
}
