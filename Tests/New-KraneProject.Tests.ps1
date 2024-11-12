Describe "New-KraneProject" {
    Context "new project of type module with valid parameters" {
        BeforeAll {
            # Arrange
            $type = 'Module'
            $name = 'TestProject'
            $path = $TestDrive
       
            # Act
            $result = New-KraneProject -Type $type -Name $name -Path $path
        }

        It "KraneProject should not be null " {
            # Assert
            $result | Should -Not -BeNullOrEmpty
        }
        It "KraneProject module name should correct" {
            $result.ModuleName | Should -Be $name
        }
        It "KraneProject root path should be correct" {
            $result.Root | Should -Be "$($path)\$($name)"
        }
        It "KraneProject type should be correct" {
            $result.ProjectType | Should -Be $type
        }
        It "KraneProject file should exist" {
            (Test-Path $result.KraneFile.Path) | Should -Be $True
        }
    }
}