[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

BeforeDiscovery {
    Get-Module -Name $psroot.Parent.Parent.Name | Remove-Module -Force
    Import-Module  (Join-Path -Path $psroot.Parent.Parent -ChildPath "$($psroot.Parent.Parent.Name)/$($psroot.Parent.Parent.Name).psm1") -Force

    $allModuleFunctions = Get-Command -Module $psroot.Parent.Parent.Name -CommandType Function 

    # Build test cases.
    $testCases = @()

    foreach ($function in $allModuleFunctions) {
        $testCases += @{
            Name = $function.Name
        }
    }
}

Describe "Each function should have pester tests" -Tag 'TestQuality' {
    it 'Should have a unit test for <Name>' -ForEach $testCases {
        Get-ChildItem -Path 'tests\' -Recurse -Include "$Name.Tests.ps1" | Should -Not -BeNullOrEmpty
    }
}

Describe "Each function should have help content" -tag 'HelpQuality' {
    BeforeEach {
        $help = Get-Help -Name $Name -Full
    }
    It "Should have help content for <Name>" -ForEach $testCases {
        $help | Should -Not -BeNullOrEmpty
    }
    It 'Should have .SYNOPSIS for <Name>' -ForEach $testCases {
        $help.Synopsis | Should -Not -BeNullOrEmpty
    }
    It 'Should have .DESCRIPTION for <Name>' -ForEach $testCases {
        $help.Description | Should -Not -BeNullOrEmpty
    }
    It 'Should have at least one (1) example for <Name>' -ForEach $testCases {
        $help.Examples.Count | Should -BeGreaterThan 0
    }
} 