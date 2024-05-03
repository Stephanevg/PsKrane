Enum ProjectType {
    Module
    Script
}

Class KraneFile {
    #CraneFile is a class that represents the .Krane.json file that is used to store the configuration of the Krane project.
    [System.IO.FileInfo]$Path
    [System.Collections.Hashtable]$Data = @{}
    [Bool]$IsPresent

    KraneFile([String]$Path) {

        #Handeling case when Path doesn't exists yet (For creation scenarios)
        $Root = ""
        if((Test-Path -Path $Path) -eq $False){
            if($Path.EndsWith(".krane.json")){
                [System.Io.DirectoryInfo]$Root = ([System.Io.FileInfo]$Path).Directory

            }
            else {
                [System.Io.DirectoryInfo]$Root = $Path
            }
        }else{
            #Path exists. We need to determine if it is a file or a folder.
            $Item = Get-Item -Path $Path

            if($Item.PSIsContainer){
                $Root = $Item
            }else{
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
        if (!($this.Path.Exists)){

            $Null = [System.Io.Directory]::CreateDirectory($this.Path.Directory.FullName) | Out-Null
        }
        $this.Data | ConvertTo-Json | Out-File -Path $this.Path.FullName -Encoding utf8 -Force
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
        $KraneFile.Save()

        Return $KraneFile
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
        #When the module Name is Not passed, we assume that a .Krane.json file is already present.
        $this.KraneFile = [KraneFile]::New($Root)
        $this.ProjectType = [ProjectType]::Module
        $this.Root = $Root
        $this.Build = "$($Root.FullName)\Build"
        $this.Sources = "$($Root.FullName)\Sources"
        $this.Tests = "$($Root.FullName)\Tests"
        $this.Outputs = "$($Root.FullName)\Outputs"

        #get the module name from the krane file
        

        $mName = $this.KraneFile.Get("Name")
        $this.SetModuleName($mName)
        $this.ProjectType = $this.KraneFile.Get("ProjectType")
        $this.FetchModuleInfo()
        
    }

    KraneModule([System.IO.DirectoryInfo]$Root, [String]$ModuleName) {
        #When the module Name is passed, we assume that the module is being created, and that there is not a .Krane.json file present. yet.
        #$this.KraneFile = [KraneFile]::New($Root)
        $This.KraneFile = [KraneFile]::Create($Root, $ModuleName, [ProjectType]::Module)
        $this.ProjectType = [ProjectType]::Module
        $this.Root = $Root
        $this.Build = "$Root\Build"
        $this.Sources = "$Root\Sources"
        $this.Tests = "$Root\Tests"
        $this.Outputs = "$Root\Outputs"
        $this.ModuleName = $ModuleName
        <#
        
        if (($this.Build.Exists -eq $false) -or ($this.Sources.Exists -eq $false) -or ($this.Tests.Exists -eq $false)) {
            Throw "No Build, Sources or Tests folder found in $($This.Root)"
        }
        #>

        $this.FetchModuleInfo()
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
       
        
    }

    [void] BuildModule() {
        
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
    
    [void] SetModuleName([String]$ModuleName) {
        $this.ModuleName = $ModuleName
        $this.ModuleFile = Join-Path -Path $this.Outputs.FullName -ChildPath "Module\$($ModuleName).psm1"
        $this.ModuleDataFile = Join-Path -Path $this.Outputs.FullName -ChildPath "Module\$($ModuleName).psd1"
    }

    [void] CreateBaseStructure(){
        if($this.Outputs.Exists -eq $false){
            $Null = New-Item -Path $this.Outputs.FullName -ItemType "directory"
        }

        if($this.Build.Exists -eq $false){
            $Null = New-Item -Path $this.Build.FullName -ItemType "directory"
        }

        if($this.Sources.Exists -eq $false){
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

        if($this.Tests.Exists -eq $false){
            $Null = New-Item -Path $this.Tests.FullName -ItemType "directory"
        }


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

#Private functions

#Original source https://github.com/PoshCode/Metadata/blob/main/Source/Public/ConvertTo-Metadata.ps1
function ConvertTo-Metadata {
    #.Synopsis
    #  Serializes objects to PowerShell Data language (PSD1)
    #.Description
    #  Converts objects to a texual representation that is valid in PSD1,
    #  using the built-in registered converters (see Add-MetadataConverter).
    #
    #  NOTE: Any Converters that are passed in are temporarily added as though passed Add-MetadataConverter
    #.Example
    #  $Name = @{ First = "Joel"; Last = "Bennett" }
    #  @{ Name = $Name; Id = 1; } | ConvertTo-Metadata
    #
    #  @{
    #    Id = 1
    #    Name = @{
    #      Last = 'Bennett'
    #      First = 'Joel'
    #    }
    #  }
    #
    #  Convert input objects into a formatted string suitable for storing in a psd1 file.
    #.Example
    #  Get-ChildItem -File | Select-Object FullName, *Utc, Length | ConvertTo-Metadata
    #
    #  Convert complex custom types to dynamic PSObjects using Select-Object.
    #
    #  ConvertTo-Metadata understands PSObjects automatically, so this allows us to proceed
    #  without a custom serializer for File objects, but the serialized data
    #  will not be a FileInfo or a DirectoryInfo, just a custom PSObject
    #.Example
    #  ConvertTo-Metadata ([DateTimeOffset]::Now) -Converters @{
    #     [DateTimeOffset] = { "DateTimeOffset {0} {1}" -f $_.Ticks, $_.Offset }
    #  }
    #
    #  Shows how to temporarily add a MetadataConverter to convert a specific type while serializing the current DateTimeOffset.
    #  Note that this serialization would require a "DateTimeOffset" function to exist in order to deserialize properly.
    #
    #  See also the third example on ConvertFrom-Metadata and Add-MetadataConverter.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification = "Too late to call it Metadatum, LOL")]
    [Alias('ToMetadata')]
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The object to convert to metadata
        [Parameter(ValueFromPipeline = $True)]
        $InputObject,

        # Serialize objects as hashtables
        [switch]$AsHashtable,

        # Additional converters
        [Hashtable]$Converters = @{}
    )
    begin {
        if ($t -is [string] -and [string]::IsNullOrWhiteSpace($t)) {
            # DO NOT USE += BECAUSE POWERSHELL WILL OPTIMIZE THIS AWAY
            $t = $t + "  "
        }
        else {
            $t = "  "
        }
        $Script:OriginalMetadataSerializers = $Script:MetadataSerializers.Clone()
        $Script:OriginalMetadataDeserializers = $Script:MetadataDeserializers.Clone()
        Add-MetadataConverter $Converters
    }
    end {
        $Script:MetadataSerializers = $Script:OriginalMetadataSerializers.Clone()
        $Script:MetadataDeserializers = $Script:OriginalMetadataDeserializers.Clone()
    }
    process {
        if ($Null -eq $InputObject) {
            '""'
            return
        }

        if ($InputObject -is [IPsMetadataSerializable] -or
            ($InputObject.ToPsMetadata -is [System.Management.Automation.PSMethod] -and
            $InputObject.FromPsMetadata -is [System.Management.Automation.PSMethod])) {
            try {
                $result = "(ConvertFrom-Metadata @'`n{1}`n'@ -As {0})" -f $InputObject.GetType().FullName, $InputObject.ToPsMetadata()
                if ($result -is [string]) {
                    $result
                    return
                }
            }
            catch {
                <# The way we handle this is to #>
                Write-Warning "InputObject of type $($InputObject.GetType().FullName) looks IMetadataSerializable, but threw an exception."
            }
        }

        if ($InputObject -is [Int16] -or
            $InputObject -is [Int32] -or
            $InputObject -is [Int64] -or
            $InputObject -is [Double] -or
            $InputObject -is [Decimal] -or
            $InputObject -is [Byte] ) {
            "$InputObject"
        }
        elseif ($InputObject -is [String]) {
            "'{0}'" -f $InputObject.ToString().Replace("'", "''")
        }
        elseif ($InputObject -is [Collections.IDictionary]) {
            "@{{`n{0}`n$($t -replace "  $")}}" -f ($(
                    ForEach ($key in @($InputObject.Keys)) {
                        if ("$key" -match '^([A-Za-z_]\w*|-?\d+\.?\d*)$') {
                            "$t$key = " + (ConvertTo-Metadata $InputObject[$key] -AsHashtable:$AsHashtable)
                        }
                        else {
                            "$t'$key' = " + (ConvertTo-Metadata $InputObject[$key] -AsHashtable:$AsHashtable)
                        }
                    }) -split "`n" -join "`n")
        }
        elseif ($InputObject -is [System.Collections.IEnumerable]) {
            "@($($(ForEach($item in @($InputObject)) { $item | ConvertTo-Metadata -AsHashtable:$AsHashtable}) -join ","))"
        }
        elseif ($InputObject -is [System.Management.Automation.ScriptBlock]) {
            # Escape single-quotes by doubling them:
            "(ScriptBlock '{0}')" -f ("$InputObject" -replace "'", "''")
        }
        elseif ($InputObject.GetType().FullName -eq 'System.Management.Automation.PSCustomObject') {
            # NOTE: we can't put [ordered] here because we need support for PS v2, but it's ok, because we put it in at parse-time
            $(if ($AsHashtable) {
                    "@{{`n$t{0}`n}}"
                }
                else {
                    "(PSObject @{{`n$t{0}`n}} -TypeName '$($InputObject.PSTypeNames -join "','")')"
                }) -f ($(
                    ForEach ($key in $InputObject | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name) {
                        if ("$key" -match '^([A-Za-z_]\w*|-?\d+\.?\d*)$') {
                            "$key = " + (ConvertTo-Metadata $InputObject.($key) -AsHashtable:$AsHashtable)
                        }
                        else {
                            "'$($key -replace "'","''")' = " + (ConvertTo-Metadata $InputObject.($key) -AsHashtable:$AsHashtable)
                        }
                    }
                ) -split "`n" -join "`n")
        }
        elseif ($MetadataSerializers.ContainsKey($InputObject.GetType())) {
            $Str = ForEach-Object $MetadataSerializers.($InputObject.GetType()) -InputObject $InputObject

            [bool]$IsCommand = & {
                $ErrorActionPreference = "Stop"
                $Tokens = $Null; $ParseErrors = $Null
                $AST = [System.Management.Automation.Language.Parser]::ParseInput( $Str, [ref]$Tokens, [ref]$ParseErrors)
                $Null -ne $Ast.Find( { $args[0] -is [System.Management.Automation.Language.CommandAst] }, $false)
            }

            if ($IsCommand) { "($Str)" } else { $Str }
        }
        else {
            Write-Warning "$($InputObject.GetType().FullName) is not serializable. Serializing as string"
            "'{0}'" -f $InputObject.ToString().Replace("'", "`'`'")
        }
    }
}

#Original source https://github.com/PoshCode/Metadata/blob/main/Source/Public/Export-Metadata.ps1
function Export-PowerShellDataFile {
    <#
        .Synopsis
            Creates a metadata file from a simple object
        .Description
            Serves as a wrapper for ConvertTo-Metadata to explicitly support exporting to files

            Note that exportable data is limited by the rules of data sections (see about_Data_Sections) and the available MetadataSerializers (see Add-MetadataConverter)

            The only things inherently importable in PowerShell metadata files are Strings, Booleans, and Numbers ... and Arrays or Hashtables where the values (and keys) are all strings, booleans, or numbers.

            Note: this function and the matching Import-Metadata are extensible, and have included support for PSCustomObject, Guid, Version, etc.
        .Example
            $Configuration | Export-Metadata .\Configuration.psd1

            Export a configuration object (or hashtable) to the default Configuration.psd1 file for a module
            the metadata module uses Configuration.psd1 as it's default config file.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification = "Too late to call it Metadatum, LOL")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "")] # Because PSSCriptAnalyzer team refuses to listen to reason. See bugs:  #194 #283 #521 #608
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Specifies the path to the PSD1 output file.
        [Parameter(Mandatory = $true, Position = 0)]
        $Path,

        # comments to place on the top of the file (to explain settings or whatever for people who might edit it by hand)
        [string[]]$CommentHeader,

        # Specifies the objects to export as metadata structures.
        # Enter a variable that contains the objects or type a command or expression that gets the objects.
        # You can also pipe objects to Export-Metadata.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,

        # Serialize objects as hashtables
        [switch]$AsHashtable,

        [Hashtable]$Converters = @{},

        # If set, output the nuspec file
        [Switch]$Passthru
    )
    begin {
        $data = @()
    }
    process {
        $data += @($InputObject)
    }
    end {
        # Avoid arrays when they're not needed:
        if ($data.Count -eq 1) {
            $data = $data[0]
        }
        Set-Content -Encoding UTF8 -Path $Path -Value ((@($CommentHeader) + @(ConvertTo-Metadata -InputObject $data -Converters $Converters -AsHashtable:$AsHashtable)) -Join "`n")
        if ($Passthru) {
            Get-Item $Path
        }
    }
}

# Public functions

Function New-KraneModuleBuild {
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

Function New-KraneProject {
    <#
    .SYNOPSIS
        Creates a new Krane project
    .DESCRIPTION
        Will create a base .krane.json project file. The project can be either a module or a script.
        Use -Force to create the base structure of the project.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
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
        ├───Outputs
        ├───Sources
        │   └───Functions
        │       ├───Private
        │       └───Public
        └───Tests

    #>
    
    
    [cmdletBinding()]
    [OutputType([KraneProject])]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Type of project to create. Can be either 'Module' or 'Script'")]
        [ProjectType]$Type,

        [Parameter(Mandatory = $True, HelpMessage = "Name of the project")]
        [String]$Name,

        [Parameter(Mandatory = $True, HelpMessage = "Root folder of the project")]
        [System.IO.DirectoryInfo]$Path,

        [Switch]$Force
    )

    switch($Type) {
        "Module" {

            $KraneProject = [KraneModule]::New($Path, $Name)
        }
        default {
            Throw "Project type $Type not supported"
        }
    }

    if($Force){
        $KraneProject.CreateBaseStructure()
    }

    Return $KraneProject

    
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

    [System.IO.FileInfo]$KraneFile = Join-Path -Path $Root.FullName -ChildPath ".krane.json"
    If (!($KraneFile.Exists)){
        Throw "No .Krane file found in $($Root.FullName). Verify the path, or create a new project using New-KraneProject"
    }
    write-Verbose "[Get-KraneProject] Fetching Krane project from path: $Root"
    Return [KraneFactory]::GetProject($KraneFile)
    
}

