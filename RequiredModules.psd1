@{
    PSDependOptions              = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository      = 'PSGallery'
            AllowPreRelease = $true
        }
    }

    'powershell-yaml'            = '0.4.7'
    yayaml                       = 'latest'
    InvokeBuild                  = '5.11.3'
    PSScriptAnalyzer             = '1.23.0'
    Pester                       = '5.6.1'
    Plaster                      = '1.1.4'
    ModuleBuilder                = '3.1.0'
    ChangelogManagement          = '3.0.1'
    Sampler                      = '0.118.2'
    'Sampler.AzureDevOpsTasks'   = '0.1.2'
    'Sampler.DscPipeline'        = '0.2.0'
    MarkdownLinkCheck            = '0.2.0'
    'DscResource.AnalyzerRules'  = '0.2.0'
    DscBuildHelpers              = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    Datum                        = '0.40.1'
    ProtectedData                = '5.0.0'
    'Datum.ProtectedData'        = '0.0.1'
    'Datum.InvokeCommand'        = '0.3.0'
    Configuration                = '1.6.0'
    Metadata                     = '1.5.7'
    xDscResourceDesigner         = '1.13.0.0'
    'DscResource.Test'           = '0.16.3'
    'DscResource.DocGenerator'   = '0.12.5'
    PSDesiredStateConfiguration  = '2.0.7'

    # Composites
    'DscConfig.AADConnect'       = 'latest'
    'DscConfig.Demo'             = 'latest'

    #DSC Resources
    xPSDesiredStateConfiguration = '9.1.0'
    JeaDsc                       = @{
        Version    = '4.0.0-preview0005'
        Parameters = @{
            AllowPrerelease = $true
        }
    }
    xDscDiagnostics              = '2.8.0'
    AADConnectDsc                = @{
        Version    = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

}
