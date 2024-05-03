Enum ProjectType {
    Module
    Script
}

Class KraneFile {
    #CraneFile is a class that represents the .krane.psd1 file that is used to store the configuration of the Krane project.
    [System.IO.FileInfo]$Path
    [System.Collections.Hashtable]$Data
    [Bool]$IsPresent

    KraneFile([System.IO.DirectoryInfo]$Root) {
        $this.Path = Join-Path -Path $Root.FullName -ChildPath ".krane.psd1"
        $this.IsPresent = $this.File.Exists
        if(!$this.Path.Exists) {
            $this.Data = @{}
            return
        }
        $this.Data = Import-PowerShellDataFile -Path $This.Path.FullName
    }

    KraneFile([System.IO.FileInfo]$File) {
        $this.Path = $File
        $this.IsPresent = $this.Path.Exists
        if(!$this.Path.Exists) {
            $this.Data = @{}
            return
        }
        $this.Data = Import-PowerShellDataFile -Path $File.FullName
    }

    [String]Get([String]$Key) {
        return $this.Data.$Key
    }

    [Void]Set([String]$Key, [String]$Value) {
        $this.Data.$Key = $Value
    }

    [Void]Save() {
        Export-PowerShellDataFile -InputObject $this.Data -Path $this.File.FullName
        $this.File.Refresh()
        $this.IsPresent = $this.File.Exists
    }

    [void]Fetch() {
        $this.Data = Import-PowerShellDataFile -Path $this.File.FullName
        $this.File.Refresh()
        $this.IsPresent = $this.File.Exists
    }

    [String]ToString() {
        return "ProjectName:{0} ProjectType:{1}" -f $this.Get("Name"), $this.Get("ProjectType")
    }

}

Class KraneProject {
    [KraneFile]$KraneFile
    [ProjectType]$ProjectType
    [System.IO.DirectoryInfo]$Root

    KraneProject() {}

    KraneProject([System.IO.DirectoryInfo]$Root) {

        $this.KraneFile = [KraneFile]::New($Root)
        
    }
}

Class KraneModule : KraneProject {
    [String]$ModuleName
    [System.IO.FileInfo]$ModuleFile
    [System.IO.FileInfo]$ModuleDataFile
    [System.IO.DirectoryInfo]$Build
    [System.IO.DirectoryInfo]$Sources
    [System.IO.DirectoryInfo]$Tests
    [System.IO.DirectoryInfo]$Outputs
    [String[]] $Tags = @( 'PSEdition_Core', 'PSEdition_Desktop' )
    [String]$Description
    [String]$ProjectUri
    Hidden [System.Collections.Hashtable]$ModuleData = @{}

    #Add option Overwrite

    KraneModule([System.IO.DirectoryInfo]$Root){
        #When the module Name is Not passed, we assume that a .Krane.psd1 file is already present.
        $this.KraneFile = [KraneFile]::New($Root)
        $this.ProjectType = [ProjectType]::Module
        $this.Root = $Root
        $this.Build = "$Root\Build"
        $this.Sources = "$Root\Sources"
        $this.Tests = "$Root\Tests"
        $this.Outputs = "$Root\Outputs"

        #get the module name from the krane file
        $mName = $this.KraneFile.Get("Name")
        $this.SetModuleName($mName)
        $this.ProjectType = $this.KraneFile.Get("ProjectType")
        $this.FetchModuleInfo()
        
    }

    KraneModule([System.IO.DirectoryInfo]$Root, [String]$ModuleName) {
        #When the module Name is passed, we assume that the module is being created, and that there is not a .Krane.psd1 file present. yet.
        $this.KraneFile = [KraneFile]::New($Root)
        $this.ProjectType = [ProjectType]::Module
        $this.Root = $Root
        $this.Build = "$Root\Build"
        $this.Sources = "$Root\Sources"
        $this.Tests = "$Root\Tests"
        $this.Outputs = "$Root\Outputs"
        $this.ModuleName = $ModuleName
        if (($this.Build.Exists -eq $false) -or ($this.Sources.Exists -eq $false) -or ($this.Tests.Exists -eq $false)) {
            Throw "No Build, Sources or Tests folder found in $($This.Root)"
        }
        $this.KraneFile.Set("ModuleName", $ModuleName)
        $this.KraneFile.Set("ProjectType", "Module")
        $this.FetchModuleInfo()
    }

    hidden FetchModuleInfo() {

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
       
        
    }

    BuildModule() {
        
        if ($this.ModuleFile.Exists) {
            $this.ModuleFile.Delete()
            $this.ModuleFile.Refresh()
        }

        Write-Verbose "[BUILD][START]  Creating module file."
        $Null = New-Item -Path $this.ModuleFile.FullName -ItemType "file" -Force
        

        $MainPSM1Contents = @()

        [System.IO.DirectoryInfo]$ClassFolderPath = Join-Path -Path $this.Sources -ChildPath "Classes"
        If ($ClassFolderPath.Exists) {
            write-Verbose "[Classes] Folder Found"
            $PublicClasses = Get-ChildItem -Path $ClassFolderPath.FullName -Filter *.ps1 | sort-object Name
            $MainPSM1Contents += $PublicClasses

        }

        [System.IO.DirectoryInfo]$PrivateFunctionsFolderPath = Join-Path -Path $this.Sources -ChildPath "Functions/Private"
        If ($ClassFolderPath.Exists) {
            write-Verbose "[Functions] Private functions Found"
            $Privatefunctions = Get-ChildItem -Path $PrivateFunctionsFolderPath.FullName -Filter *.ps1 | sort-object Name
            $MainPSM1Contents += $Privatefunctions

        }

        $Publicfunctions = $null
        [System.IO.DirectoryInfo]$PublicFunctionsFolderPath = Join-Path -Path $this.Sources -ChildPath "Functions/Public"
        If ($ClassFolderPath.Exists) {
            write-Verbose "[Functions] Public functions Found"
            $Publicfunctions = Get-ChildItem -Path $PublicFunctionsFolderPath.FullName -Filter *.ps1 | sort-object Name
            $MainPSM1Contents += $Publicfunctions

        }

        [System.IO.FileInfo]$PreContentPath = Join-Path -Path $this.Sources.FullName -ChildPath "PreContent.ps1"
        If ($PrecontentPath.Exists) {
    
            write-Verbose "[BUILD][Pre] Pre content Found. Adding to module file"
            Get-Content -Path $PreContentPath.FullName | out-File -FilePath $this.ModuleFile.FullName -Encoding utf8 -Append

        }
        else {
            write-Verbose "[BUILD][Pre] No Pre content Found. Skipping."

        }

        #Creating PSM1
        Write-Verbose "[BUILD][START][MAIN PSM1] Building main PSM1"
        Foreach ($file in $MainPSM1Contents) {
            Get-Content $File.FullName | out-File -FilePath $this.ModuleFile.FullName -Encoding utf8 -Append
    
        }

        [System.IO.FileInfo]$PostContentPath = Join-Path -Path $this.Sources.FullName -ChildPath "postContent.ps1"

        If ($PostContentPath.Exists) {
            Write-verbose "[BUILD][START][POST] PostContent.ps1 file found. Adding to module file."

            $file = Get-item $PostContentPath
            Get-content $File.FullName | out-File -FilePath $this.ModuleFile.FullName -Encoding utf8 -Append
        }
        else {
            Write-Verbose "[BUILD][START][POST] No post content file found!"
        }

        
        Write-verbose "[BUILD][START][PSD1] Starding PSD1 actions. Adding functions to export"

        if (!$this.ModuleDataFile.Exists) {
            New-ModuleManifest -Path $this.ModuleDataFile.FullName
        }
        Update-ModuleManifest -Path $this.ModuleDataFile.FullName -FunctionsToExport $Publicfunctions.BaseName -Tags $This.Tags -RootModule $this.ModuleFile.Name -Description $this.Description -ProjectUri $this.ProjectUri

        

        Write-verbose "[BUILD][END]End of Build Process"

    }
    
    SetModuleName([String]$ModuleName) {
        $this.ModuleName = $ModuleName
        $this.ModuleFile = Join-Path -Path $this.Outputs.FullName -ChildPath "Module\$($ModuleName).psm1"
        $this.ModuleDataFile = Join-Path -Path $this.Outputs.FullName -ChildPath "Module\$($ModuleName).psd1"
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
                write-verbose "Creating root project of type Module $($Root.FullName)"
                return [KraneModule]::New($Root)
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
        $psd1Data = Import-PowerShellDataFile -Path $this.KraneModule.ModuleDataFile
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
    <tags>{5}</tags>
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
        $Final = $NuSpecString -f $Id, $this.Version, $Authors, $ProjectUri, $Description, $Tags
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
        & nuget pack $this.NuSpecFilePath.FullName -OutputDirectory $this.ExportFolderPath -Version "1.0.0"
    }
}
Function New-KraneKraneModule {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, HelpMessage = "Root folder of the project. If not specified, it assumes it is located in a folder called 'Build' in the root of the project.")]
        [System.IO.DirectoryInfo]$Root,
        [Parameter(Mandatory = $true, HelpMessage = "Name of the module to build.")]
        [String]$ModuleName
    )

    if (($Root.Exists -eq $false)) {
        Throw "Root $($Root.FullName) folder not found"
    }

    # Retrieve parent folder
    if (!$Root) {
        
        $Current = (Split-Path -Path $MyInvocation.MyCommand.Path)
        $Root = ((Get-Item $Current).Parent).FullName
    }
    Write-Verbose "[BUILD][START] Root project is : $($Root.FullName)"

    #Creating the KraneModule (simple PSM1 + PSD1)
    $VerbosePreference = 'Continue'
    $KraneModule = [KraneModule]::New($Root, $ModuleName)
    Return $KraneModule
}

Function New-KraneNuspecFile {
    Param(
        [Parameter(Mandatory = $True)]
        [KraneModule]$KraneModule
    )

    $NuSpec = [NuSpecFile]::New($KraneModule)
    $NuSpec.CreateNuSpecFile()
    $NuSpec.CreateNugetFile()
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
    ElseIf($Root.Exists -eq $false) {
        Throw "Root $($Root.FullName) folder not found"
    }

    [System.IO.FileInfo]$KraneFile = Join-Path -Path $Root.FullName -ChildPath ".krane.psd1"
    If (!($KraneFile.Exists)){
        Throw "No .Krane file found in $($Root.FullName). Verify the path, or create a new project using New-KraneProject"
    }
    write-Verbose "[Get-KraneProject] Fetching Krane project from path: $Root"
    Return [KraneFactory]::GetProject($KraneFile)
    
}

