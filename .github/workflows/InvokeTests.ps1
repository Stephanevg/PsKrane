[System.Io.FileInfo]$PsRoot = $PSScriptRoot

#Grabbing main folder path
$ProjectRoot = ($PsRoot.Directory).Parent
$TestsFolder = Join-Path -Path $ProjectRoot.FullName -ChildPath "Tests"

write-host "Invoking tests in $TestsFolder"
invoke-pester $TestsFolder #-OutputFile $ProjectRoot\testresults.xml -OutputFormat NUnitXml -PassThru -Show Summary