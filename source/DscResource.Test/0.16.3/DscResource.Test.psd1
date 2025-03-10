@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'DscResource.Test.psm1'

    # Version number of this module.
    ModuleVersion     = '0.16.3'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID              = '036f67a1-21a3-43b6-95a0-73d5549e854e'

    # Author of this module
    Author            = 'DSC Community'

    # Company or vendor of this module
    CompanyName       = 'DSC Community'

    # Copyright statement for this module
    Copyright         = '(c) dsccommunity. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Testing DSC Resources against HQRM guidelines'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Clear-DscLcmConfiguration','Get-DscResourceTestContainer','Get-InvalidOperationRecord','Get-InvalidResultRecord','Get-ObjectNotFoundRecord','Initialize-TestEnvironment','Invoke-DscResourceTest','New-DscSelfSignedCertificate','Restore-TestEnvironment','Task.Fail_Build_If_HQRM_Tests_Failed','Task.Invoke_HQRM_Tests_Stop_On_Fail','Task.Invoke_HQRM_Tests','Wait-ForIdleLcm')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @('Task.Fail_Build_If_HQRM_Tests_Failed','Task.Invoke_HQRM_Tests_Stop_On_Fail','Task.Invoke_HQRM_Tests','Task.Invoke_HQRM_Tests','Task.Fail_Build_If_HQRM_Tests_Failed','Task.Invoke_HQRM_Tests_Stop_On_Fail')

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags                       = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri                 = 'https://github.com/dsccommunity/DscResource.Test/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri                 = 'https://github.com/dsccommunity/DscResource.Test'

            ExternalModuleDependencies = @('DscResource.AnalyzerRules', 'Pester', 'xDSCResourceDesigner', 'PSPKI')

            # A URL to an icon representing this module.
            IconUri                    = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            Prerelease                 = ''

            # ReleaseNotes of this module
            ReleaseNotes               = '## [0.16.3] - 2024-08-29

### Added

- `Get-SystemExceptionRecord`
  - Added private command fixes ([Issue [#126](https://github.com/dsccommunity/DscResource.Test/issues/126)]).
- Public command `Get-ObjectNotFoundRecord`
  - Use private function `Get-SystemExceptionRecord`.

### Changed

- `Get-InvalidOperationRecord`
  - Use private function `Get-SystemExceptionRecord`.
- `Get-InvalidResultRecord`
  - Removed alias `Get-ObjectNotFoundRecord` and added as it''s own public command.
- `PSSAResource.common.v4.Tests`
  - Fixed rule suppression by using correct variable.

### Fixed

- `azure-pipelines`
  - Pin gitversion to V5.

'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
