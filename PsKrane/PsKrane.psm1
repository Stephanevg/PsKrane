Enum ProjectType {
    Module
    Script
}

Enum ItemFileType{
    Class
    PublicFunction
    PrivateFunction
}

Class KraneFile {
    #CraneFile is a class that represents the .Krane.json file that is used to store the configuration of the Krane project.
    [System.IO.FileInfo]$Path
    [System.Collections.Hashtable]$Data = @{}
    [Bool]$IsPresent

    KraneFile([String]$Path) {

        #Handeling case when Path doesn't exists yet (For creation scenarios)
        $Root = ""
        if ((Test-Path -Path $Path) -eq $False) {
            if ($Path.EndsWith(".krane.json")) {
                [System.Io.DirectoryInfo]$Root = ([System.Io.FileInfo]$Path).Directory

            }
            else {
                [System.Io.DirectoryInfo]$Root = $Path
            }
        }
        else {
            #Path exists. We need to determine if it is a file or a folder.
            $Item = Get-Item -Path $Path

            if ($Item.PSIsContainer) {
                $Root = $Item
            }
            else {
                $Root = $Item.Directory
            }
        }
        


        $this.Path = Join-Path -Path $Root.FullName -ChildPath ".krane.json"
        $this.IsPresent = $this.Path.Exists
        if (!$this.Path.Exists) {
            #Krane file doesn't exists. No point in importing data from a file that doesn't exists.
            $this.Data = @{}
            return
        }
        $Raw = Get-Content -Path $This.Path.FullName -Raw | ConvertFrom-Json

        #Convert the JSON to a hashtable as it is easier to manipulate.

        foreach ($key in $Raw.PsObject.Properties) {
            $this.Data.$($key.Name) = $key.Value
        }
    }

    [String]Get([String]$Key) {
        return $this.Data.$Key
    }

    [Void]Set([String]$Key, [String]$Value) {
        $this.Data.$Key = $Value
    }

    [Void]Save() {
        if (!($this.Path.Exists)) {

            $Null = [System.Io.Directory]::CreateDirectory($this.Path.Directory.FullName) | Out-Null
        }
        $this.Data | ConvertTo-Json | Out-File -FilePath $this.Path.FullName -Encoding utf8 -Force
        $this.Path.Refresh()
        $this.IsPresent = $this.File.Exists
    }

    [void]Fetch() {
        $Raw = Get-Content -Path $This.Path.FullName -Raw | ConvertFrom-Json

        #Convert the JSON to a hashtable as it is easier to manipulate.

        foreach ($key in $Raw.PsObject.Properties) {
            $this.Data.$($key.Name) = $key.Value
        }
        $this.Path.Refresh()
        $this.IsPresent = $this.Path.Exists
    }

    [String]ToString() {
        return "ProjectName:{0} ProjectType:{1}" -f $this.Get("Name"), $this.Get("ProjectType")
    }

    static [KraneFile] Create([System.IO.DirectoryInfo]$Path, [String]$Name, [ProjectType]$Type) {
        $KraneFile = [KraneFile]::New($Path)
        if ($KraneFile.Path.Exists) {
            Throw ".Krane File $($KraneFile.Path.FullName) already exists"
        }

        $KraneFile.Set("Name", $Name)
        $KraneFile.Set("ProjectType", $Type)
        $KraneFile.Set("ProjectVersion", "0.0.1")
        $KraneFile.Save()

        Return $KraneFile
    }

}

Class KraneProject {
    [System.IO.DirectoryInfo]$Root
    [KraneFile]$KraneFile
    [ProjectType]$ProjectType
    [String]$ProjectVersion
    [System.IO.DirectoryInfo]$TemplatesPath
    [System.Collections.ArrayList]$Templates = [System.Collections.ArrayList]::New()


    KraneProject() {}

    KraneProject([System.IO.DirectoryInfo]$Root) {

        $this.KraneFile = [KraneFile]::New($Root)
        $this.ProjectVersion = $this.KraneFile.Get("ProjectVersion")

    }

    AddItem([String]$Name, [String]$Type) {
        throw "Must be overwritten!"
        #Add an item to the project. The item can be a script, a module, a test, etc.
    }

    hidden [void] LoadTemplates() {
        #Load the templates from the templates folder
        $AllModuleTemplates = Get-ChildItem -Path "$($PSScriptRoot)\Templates" -Filter "*.KraneTemplate.ps1"
        foreach ($TemplateFile in $AllModuleTemplates) {
            $Template = [KraneTemplate]::New($TemplateFile)
            $Template.SetLocation([LocationType]::Module)
            $this.Templates.Add($Template)
        }
        $AllCustomerTemplates = $null

        if($env:IsWindows) {
            $AllCustomerTemplates = Get-ChildItem -Path "$($env:ProgramData)\PsKrane\Templates" -Filter "*.KraneTemplate.ps1"
        }elseif($env:IsLinux){
            $AllCustomerTemplates = Get-ChildItem -Path " /opt/PsKrane/Templates" -Filter "*.KraneTemplate.ps1"
        }elseif($env:IsMacOS){
            $AllCustomerTemplates = Get-ChildItem -Path "/Applications/PsKrane/Templates" -Filter "*.KraneTemplate.ps1"
        }

        foreach ($TemplateFile in $AllCustomerTemplates) {
            $Template = [KraneTemplate]::New($TemplateFile)
            $Template.SetLocation([LocationType]::Customer)
            $this.Templates.Add($Template)
        }

        $ProjectRootFolder = Split-Path -Path $PSCommandPath -Parent
        [System.Io.DirectoryInfo] $TemplatesProjectFolder = Join-Path -Path $ProjectRootFolder -ChildPath "Krane/Templates"
        if($TemplatesProjectFolder.Exists) {
            $AllProjectTemplates = Get-ChildItem -Path $TemplatesProjectFolder.FullName -Filter "*.KraneTemplate.ps1"
            foreach ($TemplateFile in $AllProjectTemplates) {
                $Template = [KraneTemplate]::New($TemplateFile)
                $Template.SetLocation([LocationType]::Project)
                $this.Templates.Add($Template)
            }
        }
    }
}

Class KraneModule : KraneProject {
    [String]$ModuleName
    hidden [System.IO.FileInfo]$ModuleFile
    hidden [System.IO.FileInfo]$ModuleDataFile
    hidden [System.IO.DirectoryInfo]$Build
    hidden [System.IO.DirectoryInfo]$Sources
    hidden [System.IO.DirectoryInfo]$Tests
    hidden [System.IO.DirectoryInfo]$Outputs
    [String[]] $Tags = @( 'PSEdition_Core', 'PSEdition_Desktop' )
    [String]$Description
    [String]$ProjectUri
    [Bool]$IsGitInitialized
    [psModule]$PsModule
    [TestHelper]$TestData
    Hidden [System.Collections.Hashtable]$ModuleData = @{}

    #Add option Overwrite

    KraneModule([System.IO.DirectoryInfo]$Root) {
        #When the module Name is Not passed, we assume that a .Krane.json file is already present at the root.
        $this.KraneFile = [KraneFile]::New($Root)
        $this.ProjectType = [ProjectType]::Module
        $this.Root = $Root
        $this.Build = "$($Root.FullName)\Build"
        $this.Sources = "$($Root.FullName)\Sources"
        $this.Tests = "$($Root.FullName)\Tests"
        $this.Outputs = "$($Root.FullName)\Outputs"
        $This.LoadTemplates()
        #get the module name from the krane file
        

        $mName = $this.KraneFile.Get("Name")
        $this.SetModuleName($mName)
        $this.ProjectType = $this.KraneFile.Get("ProjectType")
        $this.FetchModuleInfo()
        $this.FetchGitInitStatus()
        
    }

    KraneModule([System.IO.DirectoryInfo]$Root, [String]$ModuleName) {
        #When the module Name is passed, we assume that the module is being created, and that there is not a .Krane.json file present. yet.
        #$this.KraneFile = [KraneFile]::New($Root)
        $Root = Join-Path -Path $Root -ChildPath $ModuleName
        $This.KraneFile = [KraneFile]::Create($Root, $ModuleName, [ProjectType]::Module)
        $this.ProjectType = [ProjectType]::Module
        $this.Root = $Root
        $this.Build = "$Root\Build"
        $this.Sources = "$Root\Sources"
        $this.Tests = "$Root\Tests"
        $this.Outputs = "$Root\Outputs"
        $this.ModuleName = $ModuleName
        $this.ProjectVersion = $this.GetProjectVersion()
        <#
        
        if (($this.Build.Exists -eq $false) -or ($this.Sources.Exists -eq $false) -or ($this.Tests.Exists -eq $false)) {
            Throw "No Build, Sources or Tests folder found in $($This.Root)"
        }
        #>

        $this.FetchModuleInfo()
        $this.FetchGitInitStatus()
    }

    hidden [void] FetchModuleInfo() {

        if (($null -eq $this.ModuleName)) {
            Throw "Module Name not provided."
        }
        
        $this.SetModuleName($this.ModuleName)

        if ($this.ModuleDataFile.Exists) {
            $this.ModuleData = Import-PowerShellDataFile -Path $this.ModuleDataFile.FullName
            $this.Description = $this.ModuleData.Description
            $this.ProjectUri = $this.ModuleData.PrivateData.PsData.ProjectUri
            $this.Tags = $this.ModuleData.PrivateData.PsData.Tags
        }
        
        $this.PsModule = [PsModule]::New($this.ModuleFile.FullName)
        
    }

    [void] BuildModule() {
        
        Write-Verbose "[KraneModule][BuildModule] Start"
        Write-Verbose "[KraneModule][BuildModule][PSM1] Starting PSM1 Operations $($this.ModuleName)"
        if ($this.ModuleFile.Exists) {
            Write-Verbose "[KraneModule][BuildModule][PSM1]  Module file already exists. Deleting."
            $this.ModuleFile.Delete()
            $this.ModuleFile.Refresh()
        }

        Write-Verbose "[KraneModule][BuildModule][PSM1]  (Re)creating file $($this.ModuleFile.FullName)"
        $Null = New-Item -Path $this.ModuleFile.FullName -ItemType "file" -Force
        

        $MainPSM1Contents = @()
        Write-Verbose "[KraneModule][BuildModule][PSM1]  Searching for classes and functions"


        [System.IO.FileInfo]$PreContentPath = Join-Path -Path $this.Sources.FullName -ChildPath "PreContent.ps1"
        If ($PrecontentPath.Exists) {
    
            Write-Verbose "[KraneModule][BuildModule][PSM1] Precontent.ps1 file found. Adding to module file."
            $MainPSM1Contents += $PreContentPath

        }
        else {
            Write-Verbose "[KraneModule][BuildModule][PSM1] No Precontent detected."

        }


        [System.IO.DirectoryInfo]$ClassFolderPath = Join-Path -Path $this.Sources.FullName -ChildPath "Classes"
        If ($ClassFolderPath.Exists) {
            
            $PublicClasses = Get-ChildItem -Path $ClassFolderPath.FullName -Filter *.ps1 | sort-object Name
            if ($PublicClasses) {
                write-Verbose "[KraneModule][BuildModule][PSM1] Classes Found. Importing..."
                $MainPSM1Contents += $PublicClasses
            }

        }

        [System.IO.DirectoryInfo]$PrivateFunctionsFolderPath = Join-Path -Path $this.Sources.FullName -ChildPath "Functions/Private"
        If ($PrivateFunctionsFolderPath.Exists) {
            $Privatefunctions = Get-ChildItem -Path $PrivateFunctionsFolderPath.FullName -Filter *.ps1 | sort-object Name

            if ($Privatefunctions) {
                write-Verbose "[KraneModule][BuildModule][PSM1] Private functions Found. Importing..."
                $MainPSM1Contents += $Privatefunctions
            }

        }

        $Publicfunctions = $null
        [System.IO.DirectoryInfo]$PublicFunctionsFolderPath = Join-Path -Path $this.Sources.FullName -ChildPath "Functions/Public"
        If ($PublicFunctionsFolderPath.Exists) {
            $Publicfunctions = Get-ChildItem -Path $PublicFunctionsFolderPath.FullName -Filter *.ps1 | sort-object Name
            
            if ($Publicfunctions) {
                write-Verbose "[KraneModule][BuildModule][PSM1] Public  functions Found. Importing..."
                $MainPSM1Contents += $Publicfunctions
            }

        }

        [System.IO.FileInfo]$PostContentPath = Join-Path -Path $this.Sources.FullName -ChildPath "postContent.ps1"
        If ($PostContentPath.Exists) {
            write-Verbose "[KraneModule][BuildModule][PSM1] Postcontent Found. Importing..."

            $MainPSM1Contents += $PostContentPath
        }
        

        #Creating PSM1
        
        write-Verbose "[KraneModule][BuildModule][PSM1] Building PSM1 content"
        Foreach ($file in $MainPSM1Contents) {
            write-Verbose "[KraneModule][BuildModule][PSM1]   Adding -> $($File.FullName)"
            Get-Content $File.FullName | out-File -FilePath $this.ModuleFile.FullName -Encoding utf8 -Append
    
        }

        Write-verbose "[KraneModule][BuildModule][PSD1] Starding PSD1 actions. Adding functions to export"

        if (!$this.ModuleDataFile.Exists) {
            Write-verbose "[KraneModule][BuildModule][PSD1] Module Manifest not found. Creating one."
            New-ModuleManifest -Path $this.ModuleDataFile.FullName
        }

        $ManifestParams = @{}
        $ManifestParams.Path = $this.ModuleDataFile.FullName
        $ManifestParams.FunctionsToExport = $Publicfunctions.BaseName
        $ManifestParams.Tags = $This.Tags
        $ManifestParams.RootModule = $this.ModuleFile.Name
        $ManifestParams.Description = $this.Description
        $ManifestParams.ProjectUri = $this.ProjectUri
        $ManifestParams.ModuleVersion = $this.ProjectVersion

        Write-verbose "[KraneModule][BuildModule][PSD1] Writing Manifest settings:"

        foreach ($ManifestSetting in $ManifestParams.GetEnumerator()) {
            Write-Verbose "[KraneModule][BuildModule][PSD1][Setting] $($ManifestSetting.Key) -> $($ManifestSetting.Value)"
        }

        try {
            Update-ModuleManifest @ManifestParams
        }
        Catch {
            Write-Error "[KraneModule][BuildModule][PSD1] Error updating module manifest. $_"
        }

        Write-Verbose "[KraneModule][BuildModule] End"

    }
    
    [void] SetModuleName([String]$ModuleName) {
        $this.ModuleName = $ModuleName
        $this.ModuleFile = Join-Path -Path $this.Outputs.FullName -ChildPath "Module\$($ModuleName).psm1"
        $this.ModuleDataFile = Join-Path -Path $this.Outputs.FullName -ChildPath "Module\$($ModuleName).psd1"
    }

    [void] CreateBaseStructure() {
        if ($this.Outputs.Exists -eq $false) {
            $Null = New-Item -Path $this.Outputs.FullName -ItemType "directory"
        }

        if ($this.Build.Exists -eq $false) {
            $Null = New-Item -Path $this.Build.FullName -ItemType "directory"
        }

        if ($this.Sources.Exists -eq $false) {
            $Null = New-Item -Path $this.Sources.FullName -ItemType "directory"
        }

        [System.IO.DirectoryInfo] $PrivateFunctions = Join-Path -Path $this.Sources.FullName -ChildPath "Functions/Private"
        if ($PrivateFunctions.Exists -eq $false) {
            $Null = New-Item -Path $PrivateFunctions.FullName -ItemType "directory"
        }
        
        [System.IO.DirectoryInfo] $PublicFunctions = Join-Path -Path $this.Sources.FullName -ChildPath "Functions/Public"
        if ($PublicFunctions.Exists -eq $false) {
            $Null = New-Item -Path $PublicFunctions.FullName -ItemType "directory"
        }

        if ($this.Tests.Exists -eq $false) {
            $Null = New-Item -Path $this.Tests.FullName -ItemType "directory"
        }


    }

    [void]ReverseBuild() {
        #ReverseBuild will take the module file and extract the content to the sources folder.
    

        $this.PsModule.ReverseBuild($this.Sources.FullName)

    }

    [string]GetProjectVersion() {
        return $this.KraneFile.Get("ProjectVersion")
    }

    Fetch() {
        if ($this.Build.Exists) {

            $e = Import-PowerShellDataFile -Path $this.Build.FullName
            $this.ProjectVersion = $this.setProjectVersion($e.ModuleVersion)
        }
    }

    hidden [void]SetProjectVersion($Version) {

        $this.KraneFile.Set("ProjectVersion", $Version)
        $this.KraneFile.Save()
    }

    [Void] FetchGitInitStatus() {
        [System.IO.DirectoryInfo]$GitFolderpath = join-Path -Path $this.Root.FullName -ChildPath ".git\"
        $this.IsGitInitialized = $GitFolderpath.Exists
    }

    [void] AddItem([String]$Name, [ItemFileType]$Type) {
        #Add an item to the project. The item can be a script, a module, a test, etc.
        switch ($Type) {
            "Class" {
                $this.AddClass($Name)
            }
            "PublicFunction" {
                $this.AddPublicFunction($Name)
            }
            "PrivateFunction" {
                $this.AddPrivateFunction($Name)
            }
            "Test" {
                $this.AddTest($Name)
            }
            default {
                Throw "Type $Type not supported"
            }
        }
    }

    hidden AddClass([String]$Name,[String]$Content) {
        [System.IO.FileInfo] $ClassPath = Join-Path -Path $this.Sources.FullName -ChildPath "Classes\$Name.ps1"
        if ($ClassPath.Exists) {
            Throw "Class $Name already exists"
        }
        $Null = New-Item -Path $ClassPath.FullName -ItemType "file" -Value $Content
    }

    hidden AddPublicFunction([String]$Name,[String]$Content) {
        [System.IO.FileInfo] $FunctionPath = Join-Path -Path $this.Sources.FullName -ChildPath "Functions\Public\$Name.ps1"
        if ($FunctionPath.Exists) {
            Throw "Function $Name already exists at $($FunctionPath.FullName)"
        }
        $Null = New-Item -Path $FunctionPath.FullName -ItemType "file" -Value $Content
    }

    hidden AddPrivateFunction([String]$Name,[String]$Content) {
        [System.IO.FileInfo]$FunctionPath = Join-Path -Path $this.Sources.FullName -ChildPath "Functions\Private\$Name.ps1"
        if ($FunctionPath.Exists) {
            Throw "Function $Name already exists"
        }
        $Null = New-Item -Path $FunctionPath.FullName -ItemType "file" -Value $Content
    }

    [KraneTemplate] GetTemplate([String]$Type) {
        #Get the module from the project
        
        $Template = $this.Templates | Where-Object { $_.Type -eq $Type }
        
        if ($null -eq $Template) {
            Throw "Template '$Type' not found"
        }
        Return $Template

    }

    [KraneTemplate] GetTemplate([String]$Type, [String]$Location) {
        #Get the module from the project
        
        $Template = $this.Templates | Where-Object { $_.Type -eq $Type -and $_.Location -eq $Location }
        
        if($null -eq $Template) {
            Throw "Template '$Type' of location type '$Location' not found"
        }
        Return $Template

    }
}

Class ModuleObfuscator {
    [String]$ModuleName
    [KraneModule]$Module
    [System.IO.DirectoryInfo]$Bin
    [System.IO.FileInfo]$BinaryModuleFile
    [System.IO.FileInfo]$ModuleDataFile

    Obfuscator() {}

    SetKraneModule([KraneModule]$Module) {
        $Module.ModuleDataFile.Refresh()
        if (!$Module.ModuleDataFile.Exists) {
            Write-Verbose "[BUILD][OBFUSCATE] Module data file Not found. Building module"
            $this.Module.BuildModule()
        }
        $this.Module = $Module
        $this.Bin = $Module.Outputs.FullName + "\Bin"
        $this.BinaryModuleFile = Join-Path -Path $this.Bin.FullName -ChildPath ($this.Module.ModuleFile.BaseName + ".dll")
        $this.ModuleDataFile = $this.Bin.FullName + "\" + $this.Module.ModuleName + ".psd1"
        
    }

    Obfuscate() {

        Write-Verbose "[BUILD][OBFUSCATE] Obfuscating module"
        Write-Verbose "[BUILD][OBFUSCATE] Starting psd1 operations"

        if (!$this.ModuleDataFile.Exists) {
            $this.Module.ModuleDataFile.CopyTo($this.ModuleDataFile.FullName)
            $this.ModuleDataFile.Refresh()
        }
        #Does seem to work. 
        #Update-ModuleManifest -Path $this.ModuleDataFile.FullName -RootModule $this.BinaryModuleFile.Name
        $MdfContent = Get-Content -Path $this.ModuleDataFile.FullName
        $MdfContent.Replace($this.Module.ModuleFile.Name, $this.BinaryModuleFile.Name) | Set-Content -Path $this.ModuleDataFile.FullName

        


        #We obfuscate
        #Create the DLL in the Artifacts folder
    }
}

Class KraneFactory {
    static [KraneProject]GetProject([System.IO.FileInfo]$KraneFile) {
        $KraneDocument = [KraneFile]::New($KraneFile)
        $ProjectType = $KraneDocument.Get("ProjectType")
        $Root = $KraneFile.Directory

        switch ($ProjectType) {
            "Module" {
                write-verbose "[KraneFactory][GetProject] Returning root project of type Module $($Root.FullName)"
                $KM = [KraneModule]::New($Root)
                $KM.ProjectVersion = $KraneDocument.Get("ProjectVersion")
                return $KM
            }
            default {
                Throw "Project type $ProjectType not supported"
            }
        }
        
        Throw "Project type $ProjectType not supported" #For some strange reason, having the throw in the switch statement does no suffice for the compiler...
    }
}

Class NuSpecFile {
    [KraneModule]$KraneModule
    [String]$Version
    [System.IO.DirectoryInfo]$ExportFolderPath
    [System.IO.FileInfo]$NuSpecFilePath
    hidden [String]$RawContent

    NuspecFile([KraneModule]$KraneModule) {
        $this.SetKraneModule($KraneModule)
        $this.ExportFolderPath = Join-Path -Path $this.KraneModule.Outputs -ChildPath "Nuget"
    }

    SetKraneModule([KraneModule]$KraneModule) {
        $this.KraneModule = $KraneModule
    }

    hidden [Void]Generate() {
        $psd1Data = Import-PowerShellDataFile -Path $this.KraneModule.ModuleDataFile.FullName
        $NuSpecString = @"
<?xml version="1.0" encoding="utf-8"?>
<package>
    <metadata>
    <id>{0}</id>
    <version>{1}</version>
    <authors>{2}</authors>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <license type="expression">MIT</license>
    <!-- <icon>icon.png</icon> -->
    <projectUrl>{3}</projectUrl>
    <description>{4}</description>
    <releaseNotes>{5}</releaseNotes>
    <copyright>Copyright All rights reserved</copyright>
    <tags>{6}</tags>
    <dependencies>
    </dependencies>
    </metadata>
</package>
"@

        
        $Id = $this.KraneModule.ModuleName #0
        $this.Version = $psd1Data.ModuleVersion #1
        $Authors = $psd1Data.Author #2
        $ProjectUri = $psd1Data.PrivateData.PsData.ProjectUri #3
        $Description = $psd1Data.Description #4
        $ReleaseNotes = $psd1Data.releaseNotes #4
        $Tags = $psd1Data.PrivateData.PsData.tags -join "," #5
        $Final = $NuSpecString -f $Id, $this.Version, $Authors, $ProjectUri, $Description, $ReleaseNotes, $Tags
        $this.RawContent = $Final
    }

    [System.IO.FileInfo] CreateNuSpecFile() {
        $this.Generate()

        $Modulefolder = Join-Path -Path $this.KraneModule.Outputs.FullName -ChildPath "Module"
        $this.NuSpecFilePath = Join-Path -Path $Modulefolder -ChildPath ($this.KraneModule.ModuleName + ".nuspec")
        $this.RawContent | Out-File -FilePath $this.NuspecFilePath -Encoding utf8 -Force
        Return $this.NuspecFilePath

    }

    CreateNugetFile() {
        if (!($this.ExportFolderPath.Exists)) {
            $this.ExportFolderPath.Create()
        }
        & nuget pack $this.NuSpecFilePath.FullName -OutputDirectory $this.ExportFolderPath
    }
}

Class PsScriptFile {
    [System.Io.FileInfo]$Path
}

Class BuildScript : PsScriptFile {
    #Creates the build script that will be used to build the module and create the nuspec file
    BuildScript([KraneModule]$KraneModule) {
        
        $this.Path = Join-Path -Path $KraneModule.Build.FullName -ChildPath "Build.Krane.ps1"
    }

    BuildScript([System.Io.DirectoryInfo]$Path) {
        $this.Path = Join-Path -Path $Path.FullName -ChildPath "Build.Krane.ps1"
    }

    [void] CreateBuildScript() {
        $Content = @'
       
# This script is used to invoke PsKrane and to build the module and create the nuspec file

install-Module PsKrane -Repository PSGallery -Force
import-Module PsKrane -Force

$psr = $PSScriptRoot
$Root = split-Path -Path $psr -Parent

$KraneModule = Get-KraneProject -Root $Root
$KraneModule.Description = "This module is a test module"
$KraneModule.ProjectUri = "http://link.com"
$KraneModule.BuildModule()

New-KraneNugetFile -KraneModule $KraneModule -Force
'@

        $Content | Out-File -FilePath $this.Path.FullName -Encoding utf8 -Force
    }
}

Class TestScript : PsScriptFile {
    #Creates the test script that will be used to test the module
    TestScript([KraneModule]$KraneModule, [String]$TestName) {
        if (!($TestName.Contains(".Tests.ps1"))) {
            $TestName = $TestName + ".Tests.ps1"
        }
        $this.Path = Join-Path -Path $KraneModule.Tests.FullName -ChildPath $TestName
        
    }

    [void] CreateTestScript() {
        if (Test-Path $this.Path.FullName) {
            Write-Verbose "[Krane][TestScript][CreateTestScript]Test script $($this.Path.FullName) already exists"
            return
        }
        
        #Create the test script
        $Content = @'
# Generated with love using PsKrane

Import-Module PsKrane
[System.IO.DirectoryInfo]$psroot = $PSScriptRoot

$KraneProject = Get-KraneProject -Root $PsRoot.Parent

Import-Module $($KraneProject.ModuleDataFile.FullName) -Force

InModuleScope -ModuleName $KraneProject.ModuleName -ScriptBlock {
    Describe "Should return Plop" {
        it "Should return Plop" {
            $result = Write-Plop
            $result | Should -Be "Plop"
        }
    }
}
'@
        Write-Verbose "[Krane][TestScript][CreateTestScript]Creating Test script at -> $($this.Path.FullName)"
        $Content | Out-File -FilePath $this.Path.FullName -Encoding utf8 -Force
    }
}

Class GitHelper {
    [System.io.FileInfo]$Git
    GitHelper() {
        $GitCommand = Get-Command -Name "git"
        if ($null -eq $GitCommand) {
            Throw "Git not found. Please install git and make sure it is in the PATH"
        }
        Write-Verbose "[GitHelper] git command found at $($GitCommand.Source)"
        $this.Git = $GitCommand.Source
    }

    GitTag([string]$Tag) {

        try {
            Write-Verbose "[GitHelper][GitTag] tagging with value -> $tag"
            #& $this.Git.FullName tag -a $tag -m $tag
            $strOutput = & $this.Git.FullName tag -a $tag -m $tag 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to write tag: $strOutput"
            }
        }
        catch {
            throw "Error creating tag $tag. $_"
        }
    }

    GitTag([string]$TagAnnotation, [String]$TagMessage) {

        try {
            Write-Verbose "[GitHelper][GitTag] tagging with anonotation -> $TagAnnotation and message $TagMessage"
            $strOutput = & $this.Git.FullName tag -a $TagAnnotation -m $TagMessage 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to write tag: $strOutput"
            }
        }
        catch {
            throw "Error creating tag with annotation : $TagAnnotation and message: $TagMessage. error -> $_"
        }
    }

    GitCommit([string]$Message) {
        try {
            
            Write-Verbose "[GitHelper][GitCommit] commit with message -> $Message"
            $strOutput = & $this.Git.FullName commit -m $Message 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to commit: $strOutput"
            }
        }
        catch {
            throw "Error creating commit. $_"
        }
    }

    GitAdd([string]$Path) {
        try {
            & $this.Git.FullName add $Path
        }
        catch {
            throw "Error adding $Path to git. $_"
        }
    }

    GitPushTags() {
        $strOutput = ""
        try {
            #& $this.Git.FullName push --tags
            Write-Verbose "[GitHelper][GitPushTags] pushing tags"
            $strOutput = & $this.Git.FullName push --tags -q 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "LastExitcode: $LASTEXITCODE . Failed to push tags. Received output: $strOutput"
            }
        }
        catch {
            
            throw "Error pushing tags to git. output: $($strOutput). Error content: $_"
        }
    }

    GitPushWithTags() {
        try {
            Write-Verbose "[GitHelper][GitPushWithTags] pushing with tags"
            $strOutput = & $this.Git.FullName push --follow-tags 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to push with tags: $strOutput"
            }
        }
        catch {
            throw "Error pushing with tags to git. $_"
        }
    
    }
}


Class PsModule {
    [String]$ModuleName
    [System.IO.FileInfo]$ModuleFile
    [System.IO.FileInfo]$ModuleDataFile
    [bool] $IsPresent
    [System.Collections.ArrayList]$Classes = [System.Collections.ArrayList]::New()
    [System.Collections.ArrayList] $functions = [System.Collections.ArrayList]::New()
    Hidden [System.Collections.Hashtable]$ModuleData = @{}


    PsModule([System.IO.FileInfo]$Path) {
        if ($Path.Extension -ne '.psm1') {
            throw "Invalid file type $($Path.Extension) for module file $($Path.FullName)"
        }
        $this.ModuleFile = $Path

        $PsdFileName = $Path.FullName.Replace('.psm1', '.psd1')
        $this.ModuleDataFile = $PsdFileName
        if ($this.ModuleDataFile.Exists) {
            Write-Verbose "[PsModule] PSD1 file detected -> $($this.ModuleDataFile.FullName)"
            $this.ModuleData = Import-PowerShellDataFile -Path $this.ModuleDataFile.FullName

        }
        else {
            Write-Verbose "[PsModule] No PSD1 file found for $($this.ModuleDataFile.FullName)"
        }

        if ($Path.Exists) {
            Write-Verbose "[PsModule] PSM1 file detected -> $($Path.FullName)"
            $this.IsPresent = $true
            $this.GetAstClasses($Path)
            $this.GetASTFunctions($Path)

            if ($this.ModuleData.functionstoexport) {
                Write-Verbose "[PsModule] Setting identifying functions scope"
                foreach ($func in $this.functions) {
                    if ($func.Name -in $this.ModuleData.FunctionsToExport) {
                        $func.IsPrivate = $False
                        Write-Verbose "[PsModule] $($func.Name) -> IsPublic"
                    }
                    else {
                        $func.IsPrivate = $True
                        Write-Verbose "[PsModule] $($func.Name) -> IsPrivate"
                    }
                }
                
            }
        }
        else {
            $this.IsPresent = $false
        }
        
    }

    GetAstClasses([System.IO.FileInfo]$p) {

        Write-Verbose "[PsModule][GetAstClasses] Fetching classes from $($p.FullName)"
        If ( $P.Exists) {
            $Raw = [System.Management.Automation.Language.Parser]::ParseFile($p.FullName, [ref]$null, [ref]$Null)
            $ASTClasses = $Raw.FindAll( { $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true)

            foreach ($ASTClass in $ASTClasses) {

                $null = $this.Classes.Add($ASTClass)
            }
        }
        
            
        
    }

    GetASTFunctions([System.IO.FileInfo]$Path) {

        Write-Verbose "[PsModule][GetAstFunctions] Fetching functions from $($Path.FullName)"
        $RawFunctions = $null
        $ParsedFile = [System.Management.Automation.Language.Parser]::ParseFile($Path.FullName, [ref]$null, [ref]$Null)
        $RawAstDocument = $ParsedFile.FindAll({ $args[0] -is [System.Management.Automation.Language.Ast] }, $true)

        If ( $RawASTDocument.Count -gt 0 ) {

            ## source: https://stackoverflow.com/questions/45929043/get-all-functions-in-a-powershell-script/45929412
            $RawFunctions = $RawASTDocument.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $($args[0].parent) -isnot [System.Management.Automation.Language.FunctionMemberAst] })
        }
        foreach ($RawFunction in $RawFunctions) {
            $Func = [PsFunction]::New($RawFunction, $false)
            $null = $This.Functions.Add($Func)
        }
        
    }

    [Object[]]GetClasses() {
        return $this.Classes
    }

    [Object[]]GetFunctions() {
        return $this.Functions
    }


    ReverseBuild([System.IO.DirectoryInfo]$ExportFolderPath) {
        #This method will take the module file and extract the content to the sources folder and put the functions in the right folder.
        #It is recommended to export to a folder called 'Sources' as other internal Krane functions rely on this folder structure.

        [System.IO.DirectoryInfo]$PrivatePath = Join-Path -Path $ExportFolderPath.FullName -ChildPath "Functions\Private"
        [System.IO.DirectoryInfo]$PublicPath = Join-Path -Path $ExportFolderPath.FullName -ChildPath "Functions\Public"
        [System.IO.DirectoryInfo]$ClassesFolder = Join-Path -Path $ExportFolderPath.FullName -ChildPath "Classes"

        if ($PrivatePath.Exists -eq $false) {
            $null = New-Item -Path $PrivatePath.FullName -ItemType "directory" -Force
        }
        if ($PublicPath.Exists -eq $false) {
            $null = New-Item -Path $PublicPath.FullName -ItemType "directory" -Force
        }
        if ($ClassesFolder.Exists -eq $false) {
            $null = New-Item -Path $ClassesFolder.FullName -ItemType "directory" -Force
        }

        foreach ($funct in $this.functions) {
            $FileName = $funct.Name + ".ps1"
            if ($funct.IsPrivate) {
                $FullExportPath = Join-Path -Path $PrivatePath.FullName -ChildPath $FileName
                $funct.RawAst.Extent.Text | Out-File -FilePath $FullExportPath -Encoding utf8 -Force
            }
            else {
                $FullExportPath = Join-Path -Path $PublicPath.FullName -ChildPath $FileName
                $funct.RawAst.Extent.Text | Out-File -FilePath $FullExportPath -Encoding utf8 -Force
            }
        }

        foreach ($class in $this.Classes) {
            $FileName = $class.Name + ".ps1"
            $FullExportPath = Join-Path -Path $ClassesFolder.FullName -ChildPath $FileName
            $Class.Extent.Text | Out-File -FilePath $FullExportPath -Encoding utf8 -Force
        }
    }


}

Class PsFunction {
    $IsPrivate
    $Name
    $HasCommentBasedHelp
    $CommentBasedHelp
    [System.Io.FileInfo]$Path
    hidden $RawAst

    PsFunction([System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst, [bool]$IsPrivate) {
        Write-Verbose "[PsFunction] Creating function: $($FunctionAst.Name) IsPrivate: $IsPrivate"
        $this.RawAst = $FunctionAst
        $this.Name = $FunctionAst.Name
        $this.IsPrivate = $IsPrivate
        $this.HasCommentBasedHelp = $FunctionAst.GetHelpContent().Length -gt 0
        $this.CommentBasedHelp = $FunctionAst.GetHelpContent()
    }
}

Class TestHelper {}

Class PesterTestHelper : TestHelper {
    [object]$TestData
    [String[]]$Path
    [String]$Version = "Latest"

    PesterTestHelper() {}

    [void] InvokeTests([String[]]$Path) {
        #Accepts eithern a string or an array of strings that should be the path to the test script(s) or the folder containing test scripts.
        if ([string]::IsNullOrEmpty($Path)) {
            throw "No path provided for tests"
        }

        if ($this.Version -eq 'Latest') {
            Import-Module -Name Pester -Force
        }
        else {
            Import-Module -Name Pester -RequiredVersion $this.Version -Force -Global   
        }


        $this.Path = $Path
        $this.TestData = Invoke-Pester -Path $Path -PassThru -Show None
    }

    [void] SetVersion([String]$Version) {
        $this.Version = $Version
    }

    [String] ToString() {
        return "Result: {0} PassedCount: {1} FailedCount: {2}" -f $this.TestData.Result, $this.TestData.PassedCount, $this.TestData.FailedCount
    
    }

    [object] GetFailedTests() {
        return $this.TestData.Failed
    }

    [object] GetPassedTests() {
        return $this.TestData.Passed
    }
}

# Public functions

Function Get-KraneProjectVersion {
    <#
    .SYNOPSIS
        Retrieves the version of the Krane project
    .DESCRIPTION
        Retrieves the version of the Krane project
    .NOTES
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [KraneProject]$KraneProject
    )

    Return $KraneProject.KraneFile.Get("ProjectVersion")
}

Function New-KraneProject {
    <#
    .SYNOPSIS
        Creates a new Krane project
    .DESCRIPTION
        Will create a base .krane.json project file. The project can be either a module or a script.
        Use -Force to create the base structure of the project.
    .NOTES
        Author: Stéphane vg
    .LINK
        https://github.com/Stephanevg/PsKrane
    .EXAMPLE
        New-KraneProject -Type Module -Path C:\Users\Stephane\Code\KraneTest\wip -Name "wip" -verbose

        ModuleName     : wip
        ModuleFile     : C:\Users\Stephane\Code\KraneTest\wip\Outputs\Module\wip.psm1
        ModuleDataFile : C:\Users\Stephane\Code\KraneTest\wip\Outputs\Module\wip.psd1
        Build          : C:\Users\Stephane\Code\KraneTest\wip\Build
        Sources        : C:\Users\Stephane\Code\KraneTest\wip\Sources
        Tests          : C:\Users\Stephane\Code\KraneTest\wip\Tests
        Outputs        : C:\Users\Stephane\Code\KraneTest\wip\Outputs
        Tags           : {PSEdition_Core, PSEdition_Desktop}
        Description    : 
        ProjectUri     : 
        KraneFile      : ProjectName:wip ProjectType:Module
        ProjectType    : Module
        Root           : C:\Users\Stephane\Code\KraneTest\wip

    .EXAMPLE
        New-KraneProject -Type Module -Path C:\Users\Stephane\Code\KraneTest\plop -Name "Plop" -Force

        When using force, it will create the base structure of the project.

        C:\USERS\STEPHANE\CODE\KRANETEST\PLOP
        │   .krane.json
        ├───Build
        │   └───Build.Krane.ps1
        ├───Outputs
        ├───Sources
        │   └───Functions
        │       ├───Private
        │       └───Public
        └───Tests
    .PARAMETER Type
            Type of project to create. Can be either 'Module' or 'Script'
    .PARAMETER Name
            Name of the project
    .PARAMETER Path
            Root folder of the project
    .PARAMETER Force    
            Switch to create the base structure of the project
    #>
    
    [cmdletBinding()]
    [OutputType([KraneProject])]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Type of project to create. Can be either 'Module' or 'Script'")]
        [ProjectType]$Type,

        [Parameter(Mandatory = $True, HelpMessage = "Name of the project")]
        [String]$Name,

        [Parameter(Mandatory = $True, HelpMessage = "Root folder of the project")]
        [System.IO.DirectoryInfo]$Path
    )

    [System.IO.DirectoryInfo]$DestinationPath = Join-Path -Path $Path.FullName -ChildPath $Name

    if($DestinationPath.Exists){
        $KraneFile = Get-ChildItem -Path $DestinationPath.FullName -Filter ".krane.json"
        if($KraneFile){

            Write-warning "[New-KraneProject] Project already exists at '$($DestinationPath.FullName)'."
            return
        }
        #Kranefile doesn't exists. This means the folder is empty. We can create the project
    }

    switch ($Type) {
        "Module" {

            $KraneProject = [KraneModule]::New($Path, $Name)
        }
        default {
            Throw "Project type $Type not supported"
        }
    }

    $KraneProject.CreateBaseStructure()
    Add-KraneBuildScript -KraneModule $KraneProject
    
    Return $KraneProject
 
}

Function New-KraneNuspecFile {
    <#
    .SYNOPSIS
        Creates a new NuSpec file
    .DESCRIPTION
        Creates a new Nuspec File based on a PsKrane project.
    .LINK
        https://github.com/Stephanevg/PsKrane
    .EXAMPLE
        $KraneProject = Get-KraneProject -Root C:\Plop\
        New-KraneNuspecFile -KraneProject $KraneProject
        
        Generates a .nuspec file in .\Outputs\Module\ folder of the KraneProject
    #>
    
    
    Param(
        [Parameter(Mandatory = $True)]
        [KraneModule]$KraneModule
    )

    $NuSpec = [NuSpecFile]::New($KraneModule)
    $NuSpec.CreateNuSpecFile()
}

Function Get-KraneProject {
    [CmdletBinding()]
    [OutputType([KraneProject])]
    Param(
        [Parameter(Mandatory = $False, HelpMessage = "Root folder of the project. If not specified, it assumes it is located in a folder called 'Build' in the root of the project.")]
        [System.IO.DirectoryInfo]$Root
    )

    
    # Retrieve parent folder
    if (!$Root) {
        #Stole this part from PSHTML
        $EC = Get-Variable ExecutionContext -ValueOnly
        $Root = $ec.SessionState.Path.CurrentLocation.Path 
        write-Verbose "[Get-KraneProject] Root parameter was omitted. Using Current location: $Root"
 
    }
    ElseIf ($Root.Exists -eq $false) {
        Throw "Root $($Root.FullName) folder not found"
    }

    [System.IO.FileInfo]$KraneFile = Join-Path -Path $Root.FullName -ChildPath ".krane.json"
    If (!($KraneFile.Exists)) {
        Throw "No .Krane file found in $($Root.FullName). Verify the path, or create a new project using New-KraneProject"
    }
    write-Verbose "[Get-KraneProject] Fetching Krane project from path: $Root"
    Return [KraneFactory]::GetProject($KraneFile)
    
}

Function Add-KraneBuildScript {
    <#
    .SYNOPSIS
        Adds the build script to the project
    .DESCRIPTION
        Adds the build script to the project. The build script is used to invoke PsKrane and to build the module and create the nuspec file
    .NOTES
        Author: Stephane van Gulick
        version: 0.1
    .LINK
        http://github.com/stephanevg/PsKrane
    .EXAMPLE
        Add-BuildScript -Root C:\Users\Stephane\Code\KraneTest\wip
        
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, ParameterSetName = "Path")]
        [System.IO.DirectoryInfo]$Path,

        [Parameter(Mandatory = $False, ParameterSetName = "KraneModule")]
        [KraneModule]$KraneModule
    )

    Switch ($PSCmdlet.ParameterSetName) {
        "Path" {
            $BuildScript = [BuildScript]::New($Path)
            $BuildScript.CreateBuildScript()
        }
        "KraneModule" {
            $BuildScript = [BuildScript]::New($KraneModule.Build)
            $BuildScript.CreateBuildScript()
        }
    }

}

Function New-KraneTestScript {
    <#
    .SYNOPSIS
        Creates a new test script
    .DESCRIPTION
        Creates a new test script in the Tests folder of the project
    .NOTES
    
    .PARAMETER KraneModule
        The KraneModule object that represents the project
    .PARAMETER TestName
        The name of the test script
    .EXAMPLE    
        New-KraneTestScript -KraneModule $KraneModule -TestName "Plop"
        Creates a new test script called Plop.Tests.ps1 in the Tests folder of the project
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [KraneModule]$KraneModule,

        [Parameter(Mandatory = $True)]
        [String]$TestName
    )

    $TestScript = [TestScript]::New($KraneModule, $TestName)
    $TestScript.CreateTestScript()
}

Function Invoke-KraneBuild {
    [CmdletBinding()]
    Param(
        [KraneProject]$KraneProject
    )
    $BuildFile = Join-Path -Path $KraneProject.Build.FullName -ChildPath "Build.Krane.ps1"
    if (!(Test-Path -Path $BuildFile)) {
        Throw "BuildFile $($BuildFile) not found. Please make sure it is there, and try again"
    }

    & $BuildFile
}

Function New-KraneNugetFile {
    <#
    .SYNOPSIS
        Creates a new nuget package
    .DESCRIPTION
        Create a new nuget package based for a specific kraneproject (Nuspec must already have been generated)
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        https://github.com/Stephanevg/PsKrane
    .EXAMPLE
        $KraneProject = Get-KraneProject -Root C:\Plop\
        New-KraneNugetFile -KraneProject $KraneProject -Force
        
        Generates a .nupkg file in .\Outputs\Nuget\ folder of the KraneProject.
        -Force will create the nuspec file

    .PARAMETER KraneModule
        The KraneModule object that represents the project

    .PARAMETER Force
        Creates the nuspec file first
    #>
    
    
    Param(
        [Parameter(Mandatory = $True)]
        [KraneModule]$KraneModule,

        [Switch]$Force
    )

    $NuSpec = [NuSpecFile]::New($KraneModule)
    
    if ($Force) {
        $NuSpec.CreateNuSpecFile()
    }

    $NuSpec.CreateNugetFile()
}

Function Invoke-KraneGitCommand {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [KraneProject]$KraneProject,

        [Parameter(Mandatory = $true)]
        [ValidateSet("tag", "PushTags", "PushWithTags")]
        [String]$GitAction,

        [String]$Argument


    )

    $GitHelper = [GitHelper]::New()

    switch ($GitAction) {
        "tag" {
            if (!($Argument)) {
                $Argument = "v{0}" -f $KraneProject.ProjectVersion
            }
            Write-Verbose "[Invoke-KraneGitCommand] Invoking Git action $GitAction with argument $Argument"
            $GitHelper.GitTag($Argument)
        }
        "PushWithTags" {
            Write-Verbose "[Invoke-KraneGitCommand] Invoking Git action $GitAction"
            $GitHelper.GitPushWithTags()
        }
        "PushTags" {
            Write-Verbose "[Invoke-KraneGitCommand] Invoking Git action $GitAction"
            $GitHelper.GitPushTags()
        }
    }
    
}

Function Invoke-KraneTestScripts {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [KraneProject]$KraneProject,

        [Parameter(Mandatory = $False)]
        [String]$Version = "Latest"

    )

    $TestHelper = [PesterTestHelper]::New()
    $TestHelper.SetVersion($Version)
    $TestHelper.InvokeTests($KraneProject.Tests.FullName)
    $KraneProject.TestData = $TestHelper
    Return $TestHelper
}

Enum LocationType {
    Module
    Customer
    Project
}

Class KraneTemplate {
    [String]$Type
    hidden [String]$Content
    [System.Io.FileInfo]$Path
    [LocationType]$Location

    KraneTemplate([System.Io.FileInfo]$Path) {
        if($Path.Exists -eq $false){
            Throw "Template file $($Path.FullName) not found"
        }

        $This.Type = $Path.BaseName.Split(".")[0]
        $this.Path = $Path
        $this.Content = Get-Content -Path $Path.FullName -Raw
    }

    SetLocation([LocationType]$Location) {
        $this.Location = $Location
    }

    [String] ToString(){
        return "{0}->{1}" -f $this.Type, $this.Location
    }
}

Function New-KraneItem {
    <#
    .SYNOPSIS
        This function helps to create a new item in the project
    .DESCRIPTION
        Items in a krane project kan be  a private function, a public function or a class
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Test-MyTestFunction -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    
    param(
        [Parameter(Mandatory = $True)]
        [KraneProject]$KraneProject,

        [Parameter(Mandatory = $True)]
        [ItemFileType]$Type,

        [Parameter(Mandatory = $True)]
        [String]$Name,

        [Parameter(Mandatory = $False)]
        [LocationType]$Location = [LocationType]::Module
    )

    switch ($Type) {
        'PublicFunction' { $typ = "function" }
        'PrivateFunction' { $typ = "function" }
        Default {}
    }

    $Template = $KraneProject.GetTemplate($typ,$Location)

    if($null -eq $Template){
        throw "No Template not found for '$Name' in location '$location'"
    }

    switch($Type){
        "Class" {
            $KraneProject.addClass($Name, $Template.Content.Replace('###ClassName###', $Name))
        }
        "PublicFunction" {
            $KraneProject.addPublicFunction($Name, $Template.Content.Replace('###FunctionName###', $Name))
        }
        "PrivateFunction" {
            
            $KraneProject.addPrivateFunction($Name, $Template.Content.Replace('###FunctionName###', $Name))
        }
    }
    
}
