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
            @{ Name = 'MyClass.ps1'; Type = 'Class'; Location = 'System' }
            @{ Name = 'MyPrivateFunction.ps1'; Type = 'PublicFunction'; Location = 'System' }
            @{ Name = 'MyPublicFunction.ps1'; Type = 'PrivateFunction'; Location = 'System' }
            @{ Name = 'MyClass.ps1'; Type = 'Class'; Location = 'Module' }
            @{ Name = 'MyPrivateFunction.ps1'; Type = 'PublicFunction'; Location = 'Module' }
            @{ Name = 'MyPublicFunction.ps1'; Type = 'PrivateFunction'; Location = 'Module' }
            @{ Name = 'MyClass.ps1'; Type = 'Class'; Location = 'Project' }
            @{ Name = 'MyPrivateFunction.ps1'; Type = 'PublicFunction'; Location = 'Project' }
            @{ Name = 'MyPublicFunction.ps1'; Type = 'PrivateFunction'; Location = 'Project' }
        ) {
            Param($Name, $Type, $Location)
            { New-KraneItem -KraneProject $NewProject -Name $Name -Type $Type -Location $Location } | Should -Not -Throw
        }
    }
}