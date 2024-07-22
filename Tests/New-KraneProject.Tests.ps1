Describe "Testing Write-Host" {
    It "Should output 'plop'" {
        $output = Write-output "plop"
        $output | Should -Be "plop"
    }
}
