Describe "Testing Write-Host" {
    It "Should output 'plop'" {
        $output = Write-Host "plop" -NoNewline
        $output | Should -Be "plop"
    }
}
