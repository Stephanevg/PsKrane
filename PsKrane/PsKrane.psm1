Class ModuleBuild {
    [String]$ModuleName
    [System.IO.FileInfo]$ModuleFile
    [System.IO.FileInfo]$ModuleDataFile
    [System.IO.DirectoryInfo]$Root
    [System.IO.DirectoryInfo]$Build
    [System.IO.DirectoryInfo]$Sources
    [System.IO.DirectoryInfo]$Tests
    [System.IO.DirectoryInfo]$Outputs
    [System.IO.DirectoryInfo]$DestinationFolder
    [String[]] $Tags = @( 'PSEdition_Core', 'PSEdition_Desktop' )
    [String]$Description
    [String]$ProjectUri

    #Add option Overwrite

    ModuleBuild([System.IO.DirectoryInfo]$Root, [String]$ModuleName) {
        $this.Root = $Root
        $this.Build = "$Root\Build"
        $this.Sources = "$Root\Sources"
        $this.Tests = "$Root\Tests"
        $this.Outputs = "$Root\Outputs"
        $this.ModuleName = $ModuleName
        if (($this.Build.Exists -eq $false) -or ($this.Sources.Exists -eq $false) -or ($this.Tests.Exists -eq $false)) {
            Throw "No Build, Sources or Tests folder found in $($This.Root)"
        }

        $this.FetchModuleInfo()
    }

    hidden FetchModuleInfo() {

        if (($null -eq $this.ModuleName)) {
            Throw "Module Name not provided."
        }
        
        $this.SetModuleName($this.ModuleName)     
        
        
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
    [ModuleBuild]$Module
    [System.IO.DirectoryInfo]$Bin
    [System.IO.FileInfo]$BinaryModuleFile
    [System.IO.FileInfo]$ModuleDataFile

    Obfuscator() {}

    SetModuleBuild([ModuleBuild]$Module) {
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

Function New-KraModuleBuild {
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

    #Creating the ModuleBuild (simple PSM1 + PSD1)
    $VerbosePreference = 'Continue'
    $ModuleBuild = [ModuleBuild]::New($Root, $ModuleName)
    Return $ModuleBuild
}

Class NuSpecFile {
    [ModuleBuild]$ModuleBuild
    [String]$Version
    [System.IO.DirectoryInfo]$ExportFolderPath
    [System.IO.FileInfo]$NuSpecFilePath
    hidden [String]$RawContent

    NuspecFile([ModuleBuild]$ModuleBuild) {
        $this.SetModuleBuild($ModuleBuild)
        $this.ExportFolderPath = Join-Path -Path $this.ModuleBuild.Outputs -ChildPath "Nuget"
    }

    SetModuleBuild([ModuleBuild]$ModuleBuild) {
        $this.ModuleBuild = $ModuleBuild
    }

    hidden [Void]Generate() {
        $psd1Data = Import-PowerShellDataFile -Path $this.ModuleBuild.ModuleDataFile
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

        
        $Id = $this.ModuleBuild.ModuleName #0
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

        $Modulefolder = Join-Path -Path $this.ModuleBuild.Outputs.FullName -ChildPath "Module"
        $this.NuSpecFilePath = Join-Path -Path $Modulefolder -ChildPath ($this.ModuleBuild.ModuleName + ".nuspec")
        $this.RawContent | Out-File -FilePath $this.NuspecFilePath -Encoding utf8 -Force
        Return $this.NuspecFilePath

    }

    CreateNugetFile() {
        & nuget pack $this.NuSpecFilePath.FullName -OutputDirectory $this.ExportFolderPath -Version "1.0.0"
    }
}

Function New-KraNuspecFile {
    Param(
        [Parameter(Mandatory = $True)]
        [ModuleBuild]$ModuleBuild
    )

    $NuSpec = [NuSpecFile]::New($ModuleBuild)
    $NuSpec.CreateNuSpecFile()
    $NuSpec.CreateNugetFile()
}

