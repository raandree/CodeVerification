@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'Sampler.psm1'

    # Version number of this module.
    ModuleVersion     = '0.118.2'

    # Supported PSEditions
    # CompatiblePSEditions = @('Desktop','Core') # Removed to support PS 5.0

    # ID used to uniquely identify this module
    GUID              = 'b59b8442-9cf9-4c4b-bc40-035336ace573'

    # Author of this module
    Author            = 'Gael Colas'

    # Company or vendor of this module
    CompanyName       = 'SynEdgy Limited'

    # Copyright statement for this module
    Copyright         = '(c) Gael Colas. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Sample Module with Pipeline scripts and its Plaster template to create a module following some of the community accepted practices.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @(
        'Plaster'
    )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules     = @()

    # Functions to export from this module
    FunctionsToExport = @('Add-Sample','Convert-SamplerHashtableToString','Get-BuildVersion','Get-BuiltModuleVersion','Get-ClassBasedResourceName','Get-CodeCoverageThreshold','Get-MofSchemaName','Get-OperatingSystemShortName','Get-PesterOutputFileFileName','Get-Psm1SchemaName','Get-SamplerAbsolutePath','Get-SamplerBuiltModuleBase','Get-SamplerBuiltModuleManifest','Get-SamplerCodeCoverageOutputFile','Get-SamplerCodeCoverageOutputFileEncoding','Get-SamplerModuleInfo','Get-SamplerModuleRootPath','Get-SamplerProjectName','Get-SamplerSourcePath','Invoke-SamplerGit','Merge-JaCoCoReport','New-SampleModule','New-SamplerJaCoCoDocument','New-SamplerPipeline','Out-SamplerXml','Set-SamplerPSModulePath','Split-ModuleVersion','Update-JaCoCoStatistic')

    # Cmdlets to export from this module
    CmdletsToExport   = ''

    # Variables to export from this module
    VariablesToExport = ''

    # Aliases to export from this module
    AliasesToExport   = '*'

    # List of all modules packaged with this module
    ModuleList        = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Extension for Plaster Template discoverability with `Get-PlasterTemplate -IncludeInstalledModules`
            Extensions   = @(
                @{
                    Module         = 'Plaster'
                    minimumVersion = '1.1.3'
                    Details        = @{
                        TemplatePaths = @(
                            'Templates\Classes'
                            'Templates\ClassResource'
                            'Templates\Composite'
                            'Templates\Enum'
                            'Templates\MofResource'
                            'Templates\PrivateFunction'
                            'Templates\PublicCallPrivateFunctions'
                            'Templates\PublicFunction'
                            'Templates\Sampler'
                        )
                    }
                }
            )

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('Template', 'pipeline', 'plaster', 'DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource', 'Windows', 'MacOS', 'Linux')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/gaelcolas/Sampler/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/gaelcolas/Sampler'

            # A URL to an icon representing this module.
            IconUri      = 'https://raw.githubusercontent.com/gaelcolas/Sampler/main/Sampler/assets/sampler.png'

            # ReleaseNotes of this module
            ReleaseNotes = '## [0.118.2] - 2025-01-19

### Changed

- Pinned GitVersion to v5 in the pipeline since v6 is not yet supported, also
  updated templates to pin GitVersion v5. Workaround for issue [#477](https://github.com/gaelcolas/Sampler/issues/477).
- Fix issue template in repository and Plaster template ([issue #483](https://github.com/gaelcolas/Sampler/issues/483)).
- Task `publish_module_to_gallery`
  - Changed to use `Publish-PSResource` if available.
  - Remove unnecessary debug information.

'

            Prerelease   = ''
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
