#Region '.\Private\Assert-DscModuleResourceIsValid.ps1' -1

function Assert-DscModuleResourceIsValid
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo]
        $DscResources
    )

    begin
    {
        Write-Verbose 'Testing for valid resources.'
        $failedDscResources = @()
    }

    process
    {
        foreach ($DscResource in $DscResources)
        {
            $failedDscResources += Get-FailedDscResource -DscResource $DscResource
        }
    }

    end
    {
        if ($failedDscResources.Count -gt 0)
        {
            Write-Verbose 'Found failed resources.'
            foreach ($resource in $failedDscResources)
            {
                Write-Warning "`t`tFailed Resource - $($resource.Name) ($($resource.Version))"
            }

            throw 'One or more resources is invalid.'
        }
    }
}
#EndRegion '.\Private\Assert-DscModuleResourceIsValid.ps1' 38
#Region '.\Private\Get-CimType.ps1' -1

function Get-CimType
{
    <#
    .SYNOPSIS
        Retrieves the CIM type for a specified DSC resource property.

    .DESCRIPTION
        The Get-CimType function retrieves the CIM (Common Information Model) type for a specified property of a DSC (Desired State Configuration) resource.
        If the property is not a CIM type, it returns null and writes a verbose message.

    .PARAMETER DscResourceName
        The name of the DSC resource.

    .PARAMETER PropertyName
        The name of the property for which to retrieve the CIM type.

    .EXAMPLE
        $cimType = Get-CimType -DscResourceName 'MyDscResource' -PropertyName 'MyProperty'
        This example retrieves the CIM type for the 'MyProperty' property of the 'MyDscResource' DSC resource.

    .OUTPUTS
        System.Object
            The CIM type of the specified property, or null if the property is not a CIM type.

    .NOTES
        This function relies on a global variable named $allDscResourcePropertiesTable to retrieve the CIM type.
        Ensure that this variable is properly initialized and populated before calling this function.
    #>

    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DscResourceName,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyName
    )

    $cimType = $allDscResourcePropertiesTable."$ResourceName-$PropertyName"

    if ($null -eq $cimType)
    {
        Write-Verbose "The CIM Type for DSC resource '$DscResourceName' with the name '$PropertyName'. It is not a CIM type."
        return
    }

    return $cimType
}
#EndRegion '.\Private\Get-CimType.ps1' 52
#Region '.\Private\Get-DscCimInstanceReference.ps1' -1

function Get-DscCimInstanceReference
{
    <#
    .SYNOPSIS
        Retrieves a scriptblock for a CIM instance reference of a DSC resource property.

    .DESCRIPTION
        The Get-DscCimInstanceReference function retrieves a scriptblock for a CIM (Common Information Model) instance reference of a specified property of a Desired State Configuration (DSC) resource.
        It uses the metadata information initialized by the Initialize-DscResourceMetaInfo function to find the type constraint of the property and generates the corresponding scriptblock.

    .PARAMETER ResourceName
        The name of the DSC resource.

    .PARAMETER ParameterName
        The name of the parameter for which to retrieve the CIM instance reference.

    .PARAMETER Data
        The data to be used for the CIM instance reference.

    .EXAMPLE
        $data = @{
            Property1 = 'Value1'
            Property2 = 'Value2'
        }
        $scriptblock = Get-DscCimInstanceReference -ResourceName 'MyResource' -ParameterName 'MyParameter' -Data $data
        $scriptblock.Invoke($data)
        This example retrieves a scriptblock for the 'MyParameter' parameter of the 'MyResource' DSC resource and invokes it with the specified data.

    .NOTES
        This function relies on the metadata information initialized by the Initialize-DscResourceMetaInfo function.
        Ensure that Initialize-DscResourceMetaInfo is called before using this function.

    .LINK
        Initialize-DscResourceMetaInfo
        Get-DscSplattedResource
    #>

    [CmdletBinding()]
    [OutputType([ScriptBlock])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'For debugging purposes')]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [string]
        $ParameterName,

        [Parameter()]
        [object]
        $Data
    )

    if ($Script:allDscResourcePropertiesTable)
    {
        if ($allDscResourcePropertiesTable.ContainsKey("$($ResourceName)-$($ParameterName)"))
        {
            $property = $allDscResourcePropertiesTable."$($ResourceName)-$($ParameterName)"
            $typeConstraint = $property.TypeConstraint -replace '\[\]', ''
            Get-DscSplattedResource -ResourceName $typeConstraint -Properties $Data -NoInvoke
        }
    }
    else
    {
        Write-Host "No DSC Resource Properties metadata was found, cannot translate CimInstance parameters. Call 'Initialize-DscResourceMetaInfo' first is this is needed."
    }
}
#EndRegion '.\Private\Get-DscCimInstanceReference.ps1' 69
#Region '.\Private\Get-DscResourceProperty.ps1' -1

function Get-DscResourceProperty
{
    <#
    .SYNOPSIS
        Retrieves the properties of a specified DSC resource.

    .DESCRIPTION
        The Get-DscResourceProperty function retrieves the properties of a specified DSC (Desired State Configuration) resource.
        It imports the module containing the DSC resource and loads the CIM (Common Information Model) keywords and class resources.
        The function returns a collection of properties for the specified DSC resource.

    .PARAMETER ModuleInfo
        The PSModuleInfo object representing the module containing the DSC resource.
        This parameter is mandatory if ModuleName is not specified.

    .PARAMETER ModuleName
        The name of the module containing the DSC resource.
        This parameter is mandatory if ModuleInfo is not specified.

    .PARAMETER ResourceName
        The name of the DSC resource for which to retrieve the properties.

    .EXAMPLE
        $properties = Get-DscResourceProperty -ModuleName 'MyDscModule' -ResourceName 'MyDscResource'

        This example retrieves the properties of the 'MyDscResource' DSC resource from the 'MyDscModule' module.

    .EXAMPLE
        $module = Get-Module -Name 'MyDscModule' -ListAvailable
        $properties = Get-DscResourceProperty -ModuleInfo $module -ResourceName 'MyDscResource'

        This example retrieves the properties of the 'MyDscResource' DSC resource from the 'MyDscModule' module using the PSModuleInfo object.

    .OUTPUTS
        System.Collections.Generic.Dictionary[string, object]
            A collection of properties for the specified DSC resource.

    .NOTES
        This function relies on the Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache class to load CIM keywords and class resources.
        Ensure that the module containing the DSC resource is available and can be imported.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ModuleInfo')]
        [System.Management.Automation.PSModuleInfo]
        $ModuleInfo,

        [Parameter(Mandatory = $true, ParameterSetName = 'ModuleName')]
        [string]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceName
    )

    if ($ModuleName)
    {
        if (Get-Module -Name $ModuleName)
        {
            $ModuleInfo = Get-Module -Name $ModuleName
        }
        else
        {
            $ModuleInfo = Import-Module -Name $ModuleName -PassThru -Force | Where-Object Name -eq $ModuleName
        }
    }
    else
    {
        if (Get-Module -Name $ModuleInfo.Name)
        {
            $ModuleInfo = Get-Module -Name $ModuleInfo.Name
        }
        else
        {
            $ModuleInfo = Import-Module -Name $ModuleInfo.Name -PassThru -Force | Where-Object Name -eq $ModuleInfo.Name
        }
    }

    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ClearCache()
    $functionsToDefine = New-Object -TypeName 'System.Collections.Generic.Dictionary[string,ScriptBlock]'([System.StringComparer]::OrdinalIgnoreCase)
    [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::LoadDefaultCimKeywords($functionsToDefine)

    $schemaFilePath = $null
    $keywordErrors = New-Object -TypeName 'System.Collections.ObjectModel.Collection[System.Exception]'

    $foundCimSchema = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportCimKeywordsFromModule($ModuleInfo, $ResourceName, [ref] $SchemaFilePath, $functionsToDefine, $keywordErrors)
    if ($foundCimSchema)
    {
        [void][Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportScriptKeywordsFromModule($ModuleInfo, $ResourceName, [ref] $SchemaFilePath, $functionsToDefine)
    }
    else
    {
        [System.Collections.Generic.List[string]]$resourceNameAsList = $ResourceName
        [void][Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClassResourcesFromModule($ModuleInfo, $resourceNameAsList, $functionsToDefine)
    }

    $resourceProperties = ([System.Management.Automation.Language.DynamicKeyword]::GetKeyword($ResourceName)).Properties

    foreach ($key in $resourceProperties.Keys)
    {
        $resourceProperty = $resourceProperties.$key

        $dscClassParameterInfo = & $ModuleInfo {

            param (
                [Parameter(Mandatory = $true)]
                [string]$TypeName
            )

            $result = @{
                ElementType = $null
                Type        = $null
                IsArray     = $false
            }

            $result.Type = $TypeName -as [type]

            if ($null -eq $result.Type)
            {
                Write-Verbose "The type '$TypeName' could not be resolved."
            }

            if ($result.Type -and $result.Type.IsArray)
            {
                $result.ElementType = $result.Type.GetElementType().FullName
                $result.IsArray = $true
            }

            return $result

        } $resourceProperty.TypeConstraint

        $isArrayType = if ($null -ne $dscClassParameterInfo.Type)
        {
            $dscClassParameterInfo.IsArray
        }
        else
        {
            $resourceProperty.TypeConstraint -match '.+\[\]'
        }

        [PSCustomObject]@{
            Name           = $resourceProperty.Name
            ModuleName     = $ModuleInfo.Name
            ResourceName   = $ResourceName
            TypeConstraint = $resourceProperty.TypeConstraint
            Attributes     = $resourceProperty.Attributes
            Values         = $resourceProperty.Values
            ValueMap       = $resourceProperty.ValueMap
            Mandatory      = $resourceProperty.Mandatory
            IsKey          = $resourceProperty.IsKey
            Range          = $resourceProperty.Range
            IsArray        = $isArrayType
            ElementType    = $dscClassParameterInfo.ElementType
            Type           = $dscClassParameterInfo.Type
        }
    }
}
#EndRegion '.\Private\Get-DscResourceProperty.ps1' 162
#Region '.\Private\Get-DynamicTypeObject.ps1' -1

function Get-DynamicTypeObject
{
    <#
    .SYNOPSIS
        Retrieves the dynamic type of a given object.

    .DESCRIPTION
        The Get-DynamicTypeObject function returns the dynamic type of a given object.
        It checks for various properties (ElementType, PropertyType, Type) to determine the type of the object.

    .PARAMETER Object
        The object for which to retrieve the dynamic type.

    .EXAMPLE
        $type = Get-DynamicTypeObject -Object $myObject
        This example retrieves the dynamic type of the object stored in the $myObject variable.

    .OUTPUTS
        System.Type
            The dynamic type of the specified object.

    .NOTES
        This function is useful for dynamically determining the type of an object, especially in scenarios where the type may not be known at design time.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $Object
    )

    if ($Object.ElementType)
    {
        return $Object.Type.GetElementType()
    }
    elseif ($Object.PropertyType)
    {
        return $Object.PropertyType
    }
    elseif ($Object.Type)
    {
        return $Object.Type
    }
    else
    {
        return $Object
    }
}
#EndRegion '.\Private\Get-DynamicTypeObject.ps1' 50
#Region '.\Private\Get-PropertiesData.ps1' -1

function Get-PropertiesData
{
    <#
    .SYNOPSIS
        Retrieves the value of a specified property path from a global properties variable.

    .DESCRIPTION
        The Get-PropertiesData function retrieves the value of a specified property path from a global properties variable.
        It constructs the path dynamically and uses it to get and return the value.
        This function is useful for accessing nested properties in a dynamic and flexible manner.

    .PARAMETER Path
        An array of strings representing the property path to retrieve the value from.

    .EXAMPLE
        $value = Get-PropertiesData -Path 'Property1', 'SubProperty'

        This example retrieves the value of 'SubProperty' under 'Property1' from the global properties variable.

    .EXAMPLE
        $value = Get-PropertiesData -Path 'Settings', 'Database', 'ConnectionString'

        This example retrieves the value of 'ConnectionString' under 'Settings -> Database' from the global properties variable.

    .OUTPUTS
        System.Object
            The value of the specified property path, or null if the path does not exist.

    .NOTES
        This function relies on a global variable named $Properties to retrieve the data.
        Ensure that the $Properties variable is properly initialized and populated before calling this function.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]
        $Path
    )

    $paths = foreach ($p in $Path)
    {
        "['$p']"
    }

    $pathValue = try
    {
        [ScriptBlock]::Create("`$Properties$($paths -join '')").Invoke()
    }
    catch
    {
        $null
    }

    return $pathValue
}
#EndRegion '.\Private\Get-PropertiesData.ps1' 57
#Region '.\Private\Get-RequiredModulesFromMOF.ps1' -1

#author Iain Brighton, from here: https://gist.github.com/iainbrighton/9d3dd03630225ee44126769c5d9c50a9
# Not sure that takes all possibilities into account:
# i.e. when using Import-DscResource -Name ResourceName #even if it's bad practice
# Also need to return PSModuleInfo, instead of @{ModuleName='<version>'}
# Then probably worth promoting to public
function Get-RequiredModulesFromMOF
{
    <#
    .SYNOPSIS
        Scans a Desired State Configuration .mof file and returns the declared/
        required modules.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Path
    )

    process
    {
        $modules = @{}
        $moduleName = $null
        $moduleVersion = $null

        Get-Content -Path $Path -Encoding Unicode | ForEach-Object {

            $line = $_
            if ($line -match '^\s?Instance of')
            {
                ## We have a new instance so write the existing one
                if (($null -ne $moduleName) -and ($null -ne $moduleVersion))
                {
                    $modules[$moduleName] = $moduleVersion
                    $moduleName = $null
                    $moduleVersion = $null
                    Write-Verbose "Module Instance found: '$moduleName $moduleVersion'."
                }
            }
            elseif ($line -match '(?<=^\s?ModuleName\s?=\s?")\S+(?=";)')
            {
                ## Ignore the default PSDesiredStateConfiguration module
                if ($Matches[0] -notmatch 'PSDesiredStateConfiguration')
                {
                    $moduleName = $Matches[0]
                    Write-Verbose "Found Module Name '$modulename'."
                }
                else
                {
                    Write-Verbose 'Excluding PSDesiredStateConfiguration module'
                }
            }
            elseif ($line -match '(?<=^\s?ModuleVersion\s?=\s?")\S+(?=";)')
            {
                $moduleVersion = $Matches[0] -as [System.Version]
                Write-Verbose "Module version = '$moduleVersion'."
            }
        }

        $modules
    }
}
#EndRegion '.\Private\Get-RequiredModulesFromMOF.ps1' 64
#Region '.\Private\Get-StandardCimType.ps1' -1

function Get-StandardCimType
{
    <#
    .SYNOPSIS
        Retrieves the standard CIM types and their corresponding .NET types.

    .DESCRIPTION
        The Get-StandardCimType function retrieves a hashtable of standard Common Information Model (CIM) types and their corresponding .NET types.
        This function is useful for mapping CIM types to .NET types when working with DSC resources.

    .EXAMPLE
        $cimTypes = Get-StandardCimType
        This example retrieves the standard CIM types and their corresponding .NET types.

    .OUTPUTS
        System.Collections.Hashtable
            A hashtable containing the standard CIM types as keys and their corresponding .NET types as values.

    .NOTES
        This function is used internally by other functions such as Get-CimType and Write-CimProperty to map CIM types to .NET types.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param ()

    $types = @{
        Boolean               = 'System.Boolean'
        UInt8                 = 'System.Byte'
        SInt8                 = 'System.SByte'
        UInt16                = 'System.UInt16'
        SInt16                = 'System.Int16'
        UInt32                = 'System.UInt32'
        SInt32                = 'System.Int32'
        UInt64                = 'System.UInt64'
        SInt64                = 'System.Int64'
        Real32                = 'System.Single'
        Real64                = 'System.Double'
        Char16                = 'System.Char'
        DateTime              = 'System.DateTime'
        String                = 'System.String'
        Reference             = 'Microsoft.Management.Infrastructure.CimInstance'
        Instance              = 'Microsoft.Management.Infrastructure.CimInstance'
        BooleanArray          = 'System.Boolean[]'
        UInt8Array            = 'System.Byte[]'
        SInt8Array            = 'System.SByte[]'
        UInt16Array           = 'System.UInt16[]'
        SInt16Array           = 'System.Int16[]'
        UInt32Array           = 'System.UInt32[]'
        SInt32Array           = 'System.Int32[]'
        UInt64Array           = 'System.UInt64[]'
        SInt64Array           = 'System.Int64[]'
        Real32Array           = 'System.Single[]'
        Real64Array           = 'System.Double[]'
        Char16Array           = 'System.Char[]'
        DateTimeArray         = 'System.DateTime[]'
        StringArray           = 'System.String[]'

        MSFT_Credential       = 'System.Management.Automation.PSCredential'
        'MSFT_KeyValuePair[]' = 'System.Collections.Hashtable'
        MSFT_KeyValuePair     = 'System.Collections.Hashtable'
    }

    $types.GetEnumerator() | ForEach-Object {
        $type = $_.Value -as [type]

        if ($null -eq $type)
        {
            Write-Error -Message "Failed to load CIM Types. The type '$($_.Value)' could not be resolved."
        }

        [PSCustomObject]@{
            CimType    = $_.Key
            DotNetType = $_.Value
        }
    }
}
#EndRegion '.\Private\Get-StandardCimType.ps1' 78
#Region '.\Private\Resolve-ModuleMetadataFile.ps1' -1


function Resolve-ModuleMetadataFile
{
    [CmdletBinding(DefaultParameterSetName = 'ByDirectoryInfo')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path,

        [Parameter(ParameterSetName = 'ByDirectoryInfo', Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.DirectoryInfo]
        $InputObject
    )

    process
    {
        $metadataFileFound = $true
        $metadataFilePath = ''
        Write-Verbose "Using Parameter set - $($PSCmdlet.ParameterSetName)."
        switch ($PSCmdlet.ParameterSetName)
        {
            'ByPath'
            {
                Write-Verbose "Testing Path - $path."
                if (Test-Path -Path $Path)
                {
                    Write-Verbose "`tFound $path."
                    $item = (Get-Item -Path $Path)
                    if ($item.PSIsContainer)
                    {
                        Write-Verbose "`t`tIt is a folder."
                        $moduleName = Split-Path $Path -Leaf
                        $metadataFilePath = Join-Path -Path $Path -ChildPath "$moduleName.psd1"
                        $metadataFileFound = Test-Path -Path $metadataFilePath
                    }
                    else
                    {
                        if ($item.Extension -like '.psd1')
                        {
                            Write-Verbose "`t`tIt is a module metadata file."
                            $metadataFilePath = $item.FullName
                            $metadataFileFound = $true
                        }
                        else
                        {
                            $modulePath = Split-Path -Path $Path
                            Write-Verbose "`t`tSearching for module metadata folder in '$ModulePath'."
                            $moduleName = Split-Path $modulePath -Leaf
                            Write-Verbose "`t`tModule name is '$moduleName'."
                            $metadataFilePath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
                            Write-Verbose "`t`tChecking for '$metadataFilePath'."
                            $metadataFileFound = Test-Path -Path $metadataFilePath
                        }
                    }
                }
                else
                {
                    $metadataFileFound = $false
                }
            }
            'ByDirectoryInfo'
            {
                $moduleName = $InputObject.Name
                $metadataFilePath = Join-Path -Path $InputObject.FullName -ChildPath "$moduleName.psd1"
                $metadataFileFound = Test-Path -Path $metadataFilePath
            }
        }

        if ($metadataFileFound -and (-not [string]::IsNullOrEmpty($metadataFilePath)))
        {
            Write-Verbose "Found a module metadata file at '$metadataFilePath'."
            Convert-Path -Path $metadataFilePath
        }
        else
        {
            Write-Error "Failed to find a module metadata file at '$metadataFilePath'."
        }
    }
}
#EndRegion '.\Private\Resolve-ModuleMetadataFile.ps1' 80
#Region '.\Private\Write-CimProperty.ps1' -1

function Write-CimProperty
{
    <#
    .SYNOPSIS
        Writes the CIM property definition to a StringBuilder object.

    .DESCRIPTION
        The Write-CimProperty function appends the definition of a CIM (Common Information Model) property to a StringBuilder object.
        It handles both single properties and arrays, and recursively writes nested properties if necessary.
        This function is useful for dynamically constructing DSC (Desired State Configuration) resource blocks.

    .PARAMETER StringBuilder
        The StringBuilder object to which the CIM property definition will be appended.

    .PARAMETER CimProperty
        The CIM property object containing the property definition.

    .PARAMETER Path
        An array of strings representing the property path.

    .PARAMETER ResourceName
        The name of the DSC resource.

    .EXAMPLE
        $stringBuilder = [System.Text.StringBuilder]::new()
        Write-CimProperty -StringBuilder $stringBuilder -CimProperty $cimProperty -Path 'Property1' -ResourceName 'MyResource'

        This example appends the definition of the 'Property1' CIM property of the 'MyResource' DSC resource to the StringBuilder object.

    .OUTPUTS
        None. The function modifies the StringBuilder object in place.

    .NOTES
        This function relies on the Get-PropertiesData and Write-CimPropertyValue functions to retrieve property values and write nested properties.
        Ensure that these functions are available in the same scope.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        [Parameter(Mandatory = $true)]
        [object]
        $CimProperty,

        [Parameter(Mandatory = $true)]
        [string[]]
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceName
    )

    $null = $StringBuilder.Append("$($CimProperty.Name) = ")
    if ($CimProperty.IsArray -or $CimProperty.PropertyType.IsArray -or $CimProperty.CimType -eq 'InstanceArray')
    {
        $null = $StringBuilder.Append("@(`n")

        $pathValue = Get-PropertiesData -Path $Path

        $i = 0
        foreach ($element in $pathValue)
        {
            $p = $Path + $i
            Write-CimPropertyValue -StringBuilder $StringBuilder -CimProperty $CimProperty -Path $p -ResourceName $ResourceName
            $i++
        }

        $null = $StringBuilder.Append(")`n")
    }
    else
    {
        Write-CimPropertyValue -StringBuilder $StringBuilder -CimProperty $CimProperty -Path $Path -ResourceName $ResourceName
    }
}
#EndRegion '.\Private\Write-CimProperty.ps1' 79
#Region '.\Private\Write-CimPropertyValue.ps1' -1

function Write-CimPropertyValue
{
    <#
    .SYNOPSIS
        Writes the value of a CIM property to a StringBuilder object.

    .DESCRIPTION
        The Write-CimPropertyValue function appends the value of a CIM (Common Information Model) property to a StringBuilder object.
        It handles both single properties and arrays, and recursively writes nested properties if necessary.
        This function is useful for dynamically constructing DSC (Desired State Configuration) resource blocks.

    .PARAMETER StringBuilder
        The StringBuilder object to which the CIM property value will be appended.

    .PARAMETER CimProperty
        The CIM property object containing the property value.

    .PARAMETER Path
        An array of strings representing the property path.

    .PARAMETER ResourceName
        The name of the DSC resource.

    .EXAMPLE
        $stringBuilder = [System.Text.StringBuilder]::new()
        Write-CimPropertyValue -StringBuilder $stringBuilder -CimProperty $cimProperty -Path 'Property1' -ResourceName 'MyResource'

        This example appends the value of the 'Property1' CIM property of the 'MyResource' DSC resource to the StringBuilder object.

    .NOTES
        This function relies on the Get-PropertiesData and Get-DynamicTypeObject functions to retrieve property values and determine the type of the CIM property.
        Ensure that these functions are available in the same scope.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Text.StringBuilder]
        $StringBuilder,

        [Parameter(Mandatory = $true)]
        [object]
        $CimProperty,

        [Parameter(Mandatory = $true)]
        [string[]]
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $ResourceName
    )

    $type = Get-DynamicTypeObject -Object $CimProperty
    if ($type.IsArray)
    {
        if ($type -is [System.Management.Automation.PSCustomObject])
        {
            $typeName = $type.TypeConstraint -replace '\[\]', ''
            $typeProperties = ($allDscSchemaClasses.Where({ $_.CimClassName -eq $typeName -and $_.ResourceName -eq $ResourceName })).CimClassProperties
        }
        else
        {
            $typeName = $type.Name -replace '\[\]', ''
            $typeProperties = $type.GetElementType().GetProperties().Where({ $_.CustomAttributes.AttributeType.Name -eq 'DscPropertyAttribute' })
        }
    }
    else
    {
        if ($type -is [System.Management.Automation.PSCustomObject])
        {
            $typeName = $type.TypeConstraint
            $typeProperties = ($allDscSchemaClasses.Where({ $_.CimClassName -eq $typeName -and $_.ResourceName -eq $ResourceName })).CimClassProperties
        }
        elseif ($type -is [type])
        {
            $typeName = $type.Name
            $typeProperties = $type.GetProperties().Where({ $_.CustomAttributes.AttributeType.Name -eq 'DscPropertyAttribute' })
        }
        elseif ($type.GetType().FullName -eq 'Microsoft.Management.Infrastructure.Internal.Data.CimClassPropertyOfClass')
        {
            $typeName = $type.ReferenceClassName
            $typeProperties = ($allDscSchemaClasses.Where({ $_.CimClassName -eq $typeName -and $_.ResourceName -eq $ResourceName })).CimClassProperties
        }
    }

    $null = $StringBuilder.AppendLine($typeName)
    $null = $StringBuilder.AppendLine('{')

    foreach ($property in $typeProperties)
    {
        $isCimProperty = if ($property.GetType().Name -eq 'CimClassPropertyOfClass')
        {
            if ($property.CimType -in 'Instance', 'InstanceArray')
            {
                $true
            }
            else
            {
                $property.CimType -notin $script:standardCimTypes.CimType
            }
        }
        else
        {
            $property.PropertyType.FullName -notin $script:standardCimTypes.DotNetType -and $property.PropertyType.BaseType -ne [System.Enum]
        }

        $pathValue = Get-PropertiesData -Path ($Path + $property.Name)

        if ($null -ne $pathValue)
        {
            if ($isCimProperty)
            {
                Write-CimProperty -StringBuilder $StringBuilder -CimProperty $property -Path ($Path + $property.Name) -ResourceName $ResourceName
            }
            else
            {
                $paths = foreach ($p in $Path)
                {
                    "['$p']"
                }
                $null = $StringBuilder.AppendLine("$($property.Name) = `$Parameters$($paths -join '')['$($property.Name)']")
            }
        }
    }

    $null = $StringBuilder.AppendLine('}')
}
#EndRegion '.\Private\Write-CimPropertyValue.ps1' 129
#Region '.\Public\Clear-CachedDscResource.ps1' -1

function Clear-CachedDscResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '', Justification = 'Not possible via CIM')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param ()

    if ($pscmdlet.ShouldProcess($env:computername))
    {
        Write-Verbose 'Stopping any existing WMI processes to clear cached resources.'

        ### find the process that is hosting the DSC engine
        $dscProcessID = Get-WmiObject msft_providers |
            Where-Object { $_.provider -like 'dsccore' } |
                Select-Object -ExpandProperty HostProcessIdentifier

        ### Stop the process
        if ($dscProcessID -and $PSCmdlet.ShouldProcess('DSC Process'))
        {
            Get-Process -Id $dscProcessID | Stop-Process
        }
        else
        {
            Write-Verbose 'Skipping killing the DSC Process'
        }

        Write-Verbose 'Clearing out any tmp WMI classes from tested resources.'
        Get-DscResourceWmiClass -Class tmp* | Remove-DscResourceWmiClass
    }
}
#EndRegion '.\Public\Clear-CachedDscResource.ps1' 30
#Region '.\Public\Compress-DscResourceModule.ps1' -1

function Compress-DscResourceModule
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DscBuildOutputModules,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [PSModuleInfo[]]
        $Modules
    )

    begin
    {
        if (-not (Test-Path -Path $DscBuildOutputModules))
        {
            mkdir -Path $DscBuildOutputModules -Force
        }
    }

    process
    {
        foreach ($module in $Modules)
        {
            if ($PSCmdlet.ShouldProcess("Compress $Module $($Module.Version) from $(Split-Path -Parent $Module.Path) to $DscBuildOutputModules"))
            {
                Write-Verbose "Publishing Module $(Split-Path -Parent $Module.Path) to $DscBuildOutputModules"
                $destinationPath = Join-Path -Path $DscBuildOutputModules -ChildPath "$($module.Name)_$($module.Version).zip"
                Compress-Archive -Path "$($module.ModuleBase)\*" -DestinationPath $destinationPath

                (Get-FileHash -Path $destinationPath).Hash | Set-Content -Path "$destinationPath.checksum" -NoNewline
            }
        }
    }
}
#EndRegion '.\Public\Compress-DscResourceModule.ps1' 39
#Region '.\Public\Find-ModuleToPublish.ps1' -1

function Find-ModuleToPublish
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $DscBuildSourceResources,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.ModuleSpecification[]]
        $ExcludedModules = $null,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $DscBuildOutputModules
    )

    $modulesAvailable = Get-ModuleFromFolder -ModuleFolder $DscBuildSourceResources -ExcludedModules $ExcludedModules

    foreach ($module in $modulesAvailable)
    {
        $publishTargetZip = [System.IO.Path]::Combine(
            $DscBuildOutputModules,
            "$($module.Name)_$($module.version).zip"
        )
        $publishTargetZipCheckSum = [System.IO.Path]::Combine(
            $DscBuildOutputModules,
            "$($module.Name)_$($module.version).zip.checksum"
        )

        $zipExists = Test-Path -Path $publishTargetZip
        $checksumExists = Test-Path -Path $publishTargetZipCheckSum

        if (-not ($zipExists -and $checksumExists))
        {
            Write-Debug "ZipExists = $zipExists; CheckSum exists = $checksumExists"
            Write-Verbose -Message "Adding $($Module.Name)_$($Module.Version) to the Modules To Publish"
            Write-Output -InputObject $Module
        }
        else
        {
            Write-Verbose -Message "$($Module.Name) does not need to be published"
        }
    }
}
#EndRegion '.\Public\Find-ModuleToPublish.ps1' 48
#Region '.\Public\Get-DscFailedResource.ps1' -1

function Get-DscFailedResource
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.PowerShell.DesiredStateConfiguration.DscResourceInfo[]]
        $DscResource
    )

    process
    {
        foreach ($resource in $DscResource)
        {
            if ($resource.Path)
            {
                $resourceNameOrPath = Split-Path $resource.Path -Parent
            }
            else
            {
                $resourceNameOrPath = $resource.Name
            }

            if (-not (Test-xDscResource -Name $resourceNameOrPath))
            {
                Write-Warning "`tResources $($_.name) is invalid."
                $resource
            }
            else
            {
                Write-Verbose ('DSC Resource Name {0} {1} is Valid' -f $resource.Name, $resource.Version)
            }
        }
    }
}
#EndRegion '.\Public\Get-DscFailedResource.ps1' 35
#Region '.\Public\Get-DscResourceFromModuleInFolder.ps1' -1

function Get-DscResourceFromModuleInFolder
{
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleFolder,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSModuleInfo[]]
        $Modules
    )

    begin
    {
        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath = $ModuleFolder

        Write-Verbose "Retrieving all resources for '$ModuleFolder'."
        $dscResources = Get-DscResource

        $env:PSModulePath = $oldPSModulePath

        $result = @()
    }

    process
    {
        Write-Verbose "Filtering the $($dscResources.Count) resources."
        Write-Debug ($dscResources | Format-Table -AutoSize | Out-String)

        foreach ($dscResource in $dscResources)
        {
            if ($null -eq $dscResource.Module)
            {
                Write-Debug "Excluding resource '$($dscResource.Name) - $($dscResource.Version)', it is not part of a module."
                continue
            }

            foreach ($module in $Modules)
            {
                if (-not (Compare-Object -ReferenceObject $dscResource.Module -DifferenceObject $Module -Property ModuleType, Version, Name))
                {
                    Write-Debug "Resource $($dscResource.Name) matches one of the supplied Modules."
                    Write-Debug "`tIncluding $($dscResource.Name) $($dscResource.Version)"
                    $result += $dscResource
                }
            }
        }
    }

    end
    {
        $result
    }
}
#EndRegion '.\Public\Get-DscResourceFromModuleInFolder.ps1' 60
#Region '.\Public\Get-DscResourceWmiClass.ps1' -1

function Get-DscResourceWmiClass
{
    <#
        .Synopsis
            Retrieves WMI classes from the DSC namespace.
        .Description
            Retrieves WMI classes from the DSC namespace.
        .Example
            Get-DscResourceWmiClass -Class tmp*
        .Example
            Get-DscResourceWmiClass -Class 'MSFT_UserResource'
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '', Justification = 'Not possible via CIM')]
    param (
        #The WMI Class name search for. Supports wildcards.
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]
        $Class
    )

    begin
    {
        $dscNamespace = 'root/Microsoft/Windows/DesiredStateConfiguration'
    }

    process
    {
        Get-WmiObject -Namespace $dscNamespace -List @PSBoundParameters
    }
}
#EndRegion '.\Public\Get-DscResourceWmiClass.ps1' 33
#Region '.\Public\Get-DscSplattedResource.ps1' -1

function Get-DscSplattedResource
{
    <#
    .SYNOPSIS
        Generates a scriptblock for a DSC resource with splatted properties.

    .DESCRIPTION
        The Get-DscSplattedResource function generates a scriptblock for a Desired State Configuration (DSC) resource with splatted properties.
        It constructs the resource block dynamically based on the provided properties and optionally executes it.
        This function is useful for dynamically constructing and invoking DSC resource blocks.

    .PARAMETER ResourceName
        The name of the DSC resource.

    .PARAMETER ExecutionName
        The execution name of the DSC resource.

    .PARAMETER Properties
        A hashtable containing the properties to be splatted into the DSC resource block.

    .PARAMETER NoInvoke
        If specified, the function returns the scriptblock without invoking it.

    .EXAMPLE
        $properties = @{
            Property1 = 'Value1'
            Property2 = 'Value2'
        }
        $scriptblock = Get-DscSplattedResource -ResourceName 'MyResource' -Properties $properties -NoInvoke
        $scriptblock.Invoke($properties)
        This example generates a scriptblock for the 'MyResource' DSC resource with the specified properties and invokes it.

    .NOTES
        This function relies on the Get-CimType and Write-CimProperty functions to retrieve CIM types and write nested properties.
        Ensure that these functions are available in the same scope.

    .LINK
        Get-CimType
        Write-CimProperty
    #>

    [CmdletBinding()]
    [OutputType([scriptblock])]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ResourceName,

        [Parameter()]
        [String]
        $ExecutionName,

        [Parameter()]
        [hashtable]
        $Properties,

        [Parameter()]
        [switch]
        $NoInvoke
    )

    if (-not $script:allDscResourcePropertiesTable -and -not $script:allDscResourcePropertiesTableWarningShown)
    {
        Write-Warning -Message "The 'allDscResourcePropertiesTable' is not defined. This will be an expensive operation. Resources with MOF sub-types are only supported when calling 'Initialize-DscResourceMetaInfo' once before starting the compilation process."
        $script:allDscResourcePropertiesTableWarningShown = $true
    }

    # Remove Case Sensitivity of ordered Dictionary or Hashtables
    $Properties = @{} + $Properties

    $stringBuilder = [System.Text.StringBuilder]::new()
    $null = $stringBuilder.AppendLine("Param([hashtable]`$Parameters)")
    $null = $stringBuilder.AppendLine()

    if ($ExecutionName)
    {
        $null = $stringBuilder.AppendLine("$ResourceName '$ExecutionName' {")
    }
    else
    {
        $null = $stringBuilder.AppendLine("$ResourceName {")
    }

    foreach ($propertyName in $Properties.Keys)
    {
        $cimProperty = Get-CimType -DscResourceName $ResourceName -PropertyName $propertyName
        if ($cimProperty)
        {
            Write-CimProperty -StringBuilder $stringBuilder -CimProperty $cimProperty -Path $propertyName -ResourceName $ResourceName
        }
        else
        {
            $null = $stringBuilder.AppendLine("$propertyName = `$Parameters['$propertyName']")
        }
    }

    $null = $stringBuilder.AppendLine('}')
    Write-Debug -Message ('Generated Resource Block = {0}' -f $stringBuilder.ToString())

    if ($NoInvoke)
    {
        [scriptblock]::Create($stringBuilder.ToString())
    }
    else
    {
        if ($Properties)
        {
            [scriptblock]::Create($stringBuilder.ToString()).Invoke($Properties)
        }
        else
        {
            [scriptblock]::Create($stringBuilder.ToString()).Invoke()
        }
    }
}

Set-Alias -Name x -Value Get-DscSplattedResource -Scope Global
#EndRegion '.\Public\Get-DscSplattedResource.ps1' 118
#Region '.\Public\Get-ModuleFromFolder.ps1' -1

function Get-ModuleFromFolder
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo[]])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo[]]
        $ModuleFolder,

        [Parameter()]
        [AllowNull()]
        [Microsoft.PowerShell.Commands.ModuleSpecification[]]
        $ExcludedModules
    )

    begin
    {
        $allModulesInFolder = @()
    }

    process
    {
        foreach ($folder in $ModuleFolder)
        {
            Write-Debug -Message "Replacing Module path with $folder"
            $oldPSModulePath = $env:PSModulePath
            $env:PSModulePath = $folder
            Write-Debug -Message 'Discovering modules from folder'
            $allModulesInFolder += Get-Module -Refresh -ListAvailable
            Write-Debug -Message 'Reverting PSModulePath'
            $env:PSModulePath = $oldPSModulePath
        }
    }

    end
    {

        $allModulesInFolder | Where-Object {
            $source = $_
            Write-Debug -Message "Checking if module '$source' is sxcluded."
            $isExcluded = foreach ($excludedModule in $ExcludedModules)
            {
                Write-Debug "`t Excluded module '$ExcludedModule'"
                if (($excludedModule.Name -and $excludedModule.Name -eq $source.Name) -and
                    (
                        (-not $excludedModule.Version -and
                        -not $excludedModule.Guid -and
                        -not $excludedModule.MaximumVersion -and
                        -not $excludedModule.RequiredVersion ) -or
                        ($excludedModule.Version -and $excludedModule.Version -eq $source.Version) -or
                        ($excludedModule.Guid -and $excludedModule.Guid -ne $source.Guid) -or
                        ($excludedModule.MaximumVersion -and $excludedModule.MaximumVersion -ge $source.Version) -or
                        ($excludedModule.RequiredVersion -and $excludedModule.RequiredVersion -eq $source.Version)
                    )
                )
                {
                    Write-Debug ('Skipping {0} {1} {2}' -f $source.Name, $source.Version, $source.Guid)
                    return $false
                }
            }
            if (-not $isExcluded)
            {
                return $true
            }
        }
    }

}
#EndRegion '.\Public\Get-ModuleFromFolder.ps1' 70
#Region '.\Public\Initialize-DscResourceMetaInfo.ps1' -1

function Initialize-DscResourceMetaInfo
{
    <#
    .SYNOPSIS
        Initializes the metadata information for DSC resources.

    .DESCRIPTION
        The Initialize-DscResourceMetaInfo function initializes the metadata information for Desired State Configuration (DSC) resources.
        It retrieves the properties and schema classes for DSC resources from the specified module path and stores them in a global variable.
        This function is useful for preparing DSC resource metadata for further processing or validation.

    .PARAMETER ModulePath
        The path to the module containing the DSC resources.

    .PARAMETER ReturnAllProperties
        If specified, all properties of the DSC resources will be returned, including standard CIM types.

    .PARAMETER Force
        If specified, the metadata information will be re-initialized even if it has already been initialized.

    .PARAMETER PassThru
        If specified, the function will return the metadata information as an output.

    .EXAMPLE
        Initialize-DscResourceMetaInfo -ModulePath 'C:\Modules\DscResources'
        This example initializes the metadata information for DSC resources located in the 'C:\Modules\DscResources' path.

    .EXAMPLE
        $metadata = Initialize-DscResourceMetaInfo -ModulePath 'C:\Modules\DscResources' -PassThru
        This example initializes the metadata information for DSC resources and returns it as an output.

    .NOTES
        This function relies on the Get-ModuleFromFolder, Get-DscResourceFromModuleInFolder, and Get-DscResourceProperty functions to retrieve module and resource information.
        Ensure that these functions are available in the same scope.

    .LINK
        Get-ModuleFromFolder
        Get-DscResourceFromModuleInFolder
        Get-DscResourceProperty
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]
        $ModulePath,

        [Parameter()]
        [switch]
        $ReturnAllProperties,

        [Parameter()]
        [switch]
        $Force,

        [Parameter()]
        [switch]
        $PassThru
    )

    if ($script:allDscResourcePropertiesTable.Count -ne 0 -and -not $Force)
    {
        if ($PassThru)
        {
            return $script:allDscResourcePropertiesTable
        }
        else
        {
            return
        }
    }

    if (-not (Test-Path -Path $ModulePath))
    {
        Write-Error -Message "The module path '$ModulePath' does not exist."
        return
    }

    $allModules = Get-ModuleFromFolder -ModuleFolder $ModulePath
    if ($null -eq $allModules -or $allModules.Count -eq 0)
    {
        Write-Error -Message "No modules found in the module path '$ModulePath'."
        return
    }

    $allModules = Get-ModuleFromFolder -ModuleFolder $ModulePath
    $allDscResources = Get-DscResourceFromModuleInFolder -ModuleFolder $ModulePath -Modules $allModules
    $modulesWithDscResources = $allDscResources | Select-Object -ExpandProperty ModuleName -Unique
    $modulesWithDscResources = $allModules | Where-Object Name -In $modulesWithDscResources

    $script:standardCimTypes = Get-StandardCimType

    $script:allDscResourcePropertiesTable = @{}
    $script:allDscSchemaClasses = @()

    $script:allDscResourceProperties = foreach ($dscResource in $allDscResources)
    {
        $moduleInfo = $modulesWithDscResources |
            Where-Object { $_.Name -EQ $dscResource.ModuleName -and $_.Version -eq $dscResource.Version }

        $dscModule = [System.Tuple]::Create($dscResource.Module.Name, [System.Version]$dscResource.Version)
        $exceptionCollection = [System.Collections.ObjectModel.Collection[System.Exception]]::new()
        $schemaMofFile = [System.IO.Path]::ChangeExtension($dscResource.Path, 'schema.mof')

        if (Test-Path -Path $schemaMofFile)
        {
            $dscSchemaClasses = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClasses($schemaMofFile, $dscModule, $exceptionCollection)
            foreach ($dscSchemaClass in $dscSchemaClasses)
            {
                $dscSchemaClass | Add-Member -Name ModuleName -MemberType NoteProperty -Value $dscResource.ModuleName
                $dscSchemaClass | Add-Member -Name ModuleVersion -MemberType NoteProperty -Value $dscResource.Version
                $dscSchemaClass | Add-Member -Name ResourceName -MemberType NoteProperty -Value $dscResource.Name
            }
            $script:allDscSchemaClasses += $dscSchemaClasses
        }

        $cimProperties = if ($ReturnAllProperties)
        {
            Get-DscResourceProperty -ModuleInfo $moduleInfo -ResourceName $dscResource.Name
        }
        else
        {
            Get-DscResourceProperty -ModuleInfo $moduleInfo -ResourceName $dscResource.Name |
                Where-Object TypeConstraint -NotIn $script:standardCimTypes.CimType
        }

        foreach ($cimProperty in $cimProperties)
        {
            [PSCustomObject]@{
                Name           = $cimProperty.Name
                TypeConstraint = $cimProperty.TypeConstraint
                IsKey          = $cimProperty.IsKey
                Mandatory      = $cimProperty.Mandatory
                Values         = $cimProperty.Values
                Range          = $cimProperty.Range
                ModuleName     = $dscResource.ModuleName
                ResourceName   = $dscResource.Name
            }
            $script:allDscResourcePropertiesTable."$($dscResource.Name)-$($cimProperty.Name)" = $cimProperty
        }

    }

    if ($PassThru)
    {
        $script:allDscResourcePropertiesTable
    }
}
#EndRegion '.\Public\Initialize-DscResourceMetaInfo.ps1' 148
#Region '.\Public\Publish-DscConfiguration.ps1' -1

function Publish-DscConfiguration
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DscBuildOutputConfigurations,

        [Parameter()]
        [string]
        $PullServerWebConfig = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer\web.config"
    )

    process
    {
        Write-Verbose "Publishing Configuration MOFs from '$DscBuildOutputConfigurations'."

        Get-ChildItem -Path (Join-Path -Path $DscBuildOutputConfigurations -ChildPath '*.mof') |
            ForEach-Object {
                if (-not (Test-Path -Path $PullServerWebConfig))
                {
                    Write-Warning "The Pull Server configg '$PullServerWebConfig' cannot be found."
                    Write-Warning "`t Skipping Publishing Configuration MOFs"
                }
                elseif ($PSCmdlet.ShouldProcess($_.BaseName))
                {
                    Write-Verbose -Message "Publishing $($_.Name)"
                    Publish-MofToPullServer -FullName $_.FullName -PullServerWebConfig $PullServerWebConfig
                }
            }
    }
}
#EndRegion '.\Public\Publish-DscConfiguration.ps1' 33
#Region '.\Public\Publish-DscResourceModule.ps1' -1


function Publish-DscResourceModule
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DscBuildOutputModules,

        [Parameter()]
        [System.IO.FileInfo]
        $PullServerWebConfig = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer\web.config"
    )

    begin
    {
        if (-not (Test-Path $PullServerWebConfig))
        {
            if ($PSBoundParameters['ErrorAction'] -eq 'SilentlyContinue')
            {
                Write-Warning -Message "Could not find the Web.config of the pull Server at '$PullServerWebConfig'."
            }
            else
            {
                throw "Could not find the Web.config of the pull Server at '$PullServerWebConfig'."
            }
            return
        }
        else
        {
            $webConfigXml = [xml](Get-Content -Raw -Path $PullServerWebConfig)
            $configXElement = $webConfigXml.SelectNodes("//appSettings/add[@key = 'ConfigurationPath']")
            $OutputFolderPath = $configXElement.Value
        }
    }

    process
    {
        if ($OutputFolderPath)
        {
            Write-Verbose 'Moving Processed Resource Modules from'
            Write-Verbose "`t$DscBuildOutputModules to"
            Write-Verbose "`t$OutputFolderPath"

            if ($PSCmdlet.ShouldProcess("copy '$DscBuildOutputModules' to '$OutputFolderPath'"))
            {
                Get-ChildItem -Path $DscBuildOutputModules -Include @('*.zip', '*.checksum') |
                    Copy-Item -Destination $OutputFolderPath -Force
            }
        }
    }
}
#EndRegion '.\Public\Publish-DscResourceModule.ps1' 53
#Region '.\Public\Push-DscConfiguration.ps1' -1

function Push-DscConfiguration
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session,

        [Parameter()]
        [Alias('MOF', 'Path')]
        [System.IO.FileInfo]
        $ConfigurationDocument,

        [Parameter()]
        [System.Management.Automation.PSModuleInfo[]]
        $WithModule,

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true, Position = 1)]
        [Alias('DscBuildOutputModules')]
        $StagingFolderPath = "$Env:TMP\DSC\BuildOutput\modules\",

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true, Position = 3)]
        $RemoteStagingPath = '$Env:TMP\DSC\modules\',

        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true, Position = 4)]
        [switch]
        $Force
    )

    process
    {
        if ($PSCmdlet.ShouldProcess($Session.ComputerName, "Applying MOF '$ConfigurationDocument'"))
        {
            if ($WithModule)
            {
                Push-DscModuleToNode -Module $WithModule -StagingFolderPath $StagingFolderPath -RemoteStagingPath $RemoteStagingPath -Session $Session
            }

            Write-Verbose 'Removing previously pushed configuration documents'
            $resolvedRemoteStagingPath = Invoke-Command -Session $Session -ScriptBlock {
                $resolvedStagingPath = $ExecutionContext.InvokeCommand.ExpandString($Using:RemoteStagingPath)
                $null = Get-Item "$resolvedStagingPath\*.mof" | Remove-Item -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $resolvedStagingPath))
                {
                    mkdir -Force $resolvedStagingPath -ErrorAction Stop
                }
                $resolvedStagingPath
            } -ErrorAction Stop

            $remoteConfigDocumentPath = [System.IO.Path]::Combine($ResolvedRemoteStagingPath, 'localhost.mof')

            Copy-Item -ToSession $Session -Path $ConfigurationDocument -Destination $remoteConfigDocumentPath -Force -ErrorAction Stop

            Write-Verbose "Attempting to apply '$remoteConfigDocumentPath' on '$($session.ComputerName)'"
            Invoke-Command -Session $Session -ScriptBlock {
                Start-DscConfiguration -Wait -Force -Path $Using:resolvedRemoteStagingPath -Verbose -ErrorAction Stop
            }
        }
    }
}
#EndRegion '.\Public\Push-DscConfiguration.ps1' 63
#Region '.\Public\Push-DscModuleToNode.ps1' -1

<#
    .SYNOPSIS
    Injects Modules via PS Session.

    .DESCRIPTION
    Injects the missing modules on a remote node via a PSSession.
    The module list is checked again the available modules from the remote computer,
    Any missing version is then zipped up and sent over the PS session,
    before being extracted in the root PSModulePath folder of the remote node.

    .PARAMETER Module
    A list of Modules required on the remote node. Those missing will be packaged based
    on their Path.

    .PARAMETER StagingFolderPath
    Staging folder where the modules are being zipped up locally before being sent accross.

    .PARAMETER Session
    Session to use to gather the missing modules and to copy the modules to.

    .PARAMETER RemoteStagingPath
    Path on the remote Node where the modules will be copied before extraction.

    .PARAMETER Force
    Force all modules to be re-zipped, re-sent, and re-extracted to the target node.

    .EXAMPLE
    Push-DscModuleToNode -Module (Get-ModuleFromFolder C:\src\SampleKitchen\modules) -Session $RemoteSession -StagingFolderPath "C:\BuildOutput"

#>
function Push-DscModuleToNode
{
    [CmdletBinding()]
    [OutputType([void])]
    param (
        # Param1 help description
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [Alias('ModuleInfo')]
        [System.Management.Automation.PSModuleInfo[]]
        $Module,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [Alias('DscBuildOutputModules')]
        $StagingFolderPath = "$Env:TMP\DSC\BuildOutput\modules\",

        [Parameter(Mandatory = $true, Position = 2, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [System.Management.Automation.Runspaces.PSSession]
        $Session,

        [Parameter(Position = 3, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        $RemoteStagingPath = '$Env:TMP\DSC\modules\',

        [Parameter(Position = 4, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [switch]
        $Force
    )

    process
    {
        # Find the modules already available remotely
        if (-not $Force)
        {
            $remoteModuleAvailable = Invoke-Command -Session $Session -ScriptBlock {
                Get-Module -ListAvailable
            }
        }

        $resolvedRemoteStagingPath = Invoke-Command -Session $Session -ScriptBlock {
            $ResolvedStagingPath = $ExecutionContext.InvokeCommand.ExpandString($using:RemoteStagingPath)
            if (-not (Test-Path $ResolvedStagingPath))
            {
                mkdir -Force $ResolvedStagingPath
            }
            $resolvedStagingPath
        }

        # Find the modules missing on remote node
        $missingModules = $Module.Where{
            $matchingModule = foreach ($remoteModule in $RemoteModuleAvailable)
            {
                if (
                    $remoteModule.Name -eq $_.Name -and
                    $remoteModule.Version -eq $_.Version -and
                    $remoteModule.Guid -eq $_.Guid
                )
                {
                    Write-Verbose "Module match: '$($remoteModule.Name)'."
                    $remoteModule
                }
            }
            if (-not $matchingModule)
            {
                Write-Verbose "Module not found: '$($_.Name)'."
                $_
            }
        }
        Write-Verbose "The Missing modules are '$($MissingModules.Name -join ', ')'."

        # Find the missing modules from the staging folder
        #  and publish it there
        Write-Verbose "Looking for missing zip modules in '$($StagingFolderPath)'."
        $missingModules.Where{ -not (Test-Path -Path "$StagingFolderPath\$($_.Name)_$($_.version).zip") } |
            Compress-DscResourceModule -DscBuildOutputModules $StagingFolderPath

        # Copy missing modules to remote node if not present already
        foreach ($module in $missingModules)
        {
            $fileName = "$($StagingFolderPath)/$($module.Name)_$($module.Version).zip"
            $testPathResult = Invoke-Command -Session $Session -ScriptBlock {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]
                    $FileName
                )
                Test-Path -Path $FileName
            } -ArgumentList $fileName

            if ($Force -or -not ($testPathResult))
            {
                Write-Verbose "Copying '$fileName*' to '$ResolvedRemoteStagingPath'."
                Invoke-Command -Session $Session -ScriptBlock {
                    param (
                        [Parameter(Mandatory = $true)]
                        [string]
                        $PathToZips
                    )
                    if (-not (Test-Path -Path $PathToZips))
                    {
                        mkdir -Path $PathToZips -Force
                    }
                } -ArgumentList $resolvedRemoteStagingPath

                $param = @{
                    ToSession   = $Session
                    Path        = "$($StagingFolderPath)/$($module.Name)_$($module.Version)*"
                    Destination = $ResolvedRemoteStagingPath
                    Force       = $true
                }
                Copy-Item @param | Out-Null
            }
            else
            {
                Write-Verbose 'The File is already present remotely.'
            }
        }

        # Extract missing modules on remote node to PSModulePath
        Write-Verbose "Expanding '$resolvedRemoteStagingPath/*.zip' to '$env:CommonProgramW6432\WindowsPowerShell\Modules\$($Module.Name)\$($module.version)'."
        Invoke-Command -Session $Session -ScriptBlock {
            param (
                [Parameter()]
                $MissingModules,
                [Parameter()]
                $PathToZips
            )
            foreach ($module in $MissingModules)
            {
                $fileName = "$($module.Name)_$($module.version).zip"
                Write-Verbose "Expanding '$PathToZips/$fileName' to '$Env:CommonProgramW6432\WindowsPowerShell\Modules\$($Module.Name)\$($module.version)'."
                Expand-Archive -Path "$PathToZips/$fileName" -DestinationPath "$Env:ProgramW6432\WindowsPowerShell\Modules\$($Module.Name)\$($module.version)" -Force
            }
        } -ArgumentList $missingModules, $resolvedRemoteStagingPath
    }
}
#EndRegion '.\Public\Push-DscModuleToNode.ps1' 165
#Region '.\Public\Remove-DscResourceWmiClass.ps1' -1

<#
    .Synopsis
        Removes a WMI class from the DSC namespace.
    .Description
        Removes a WMI class from the DSC namespace.
    .Example
        Get-DscResourceWmiClass -Class tmp* | Remove-DscResourceWmiClass
    .Example
        Remove-DscResourceWmiClass -Class 'tmpD460'
#>
function Remove-DscResourceWmiClass
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '', Justification = 'Not possible via CIM')]
    [CmdletBinding()]
    param (
        #The WMI Class name to remove.  Supports wildcards.
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string]
        $ResourceType
    )

    begin
    {
        $dscNamespace = 'root/Microsoft/Windows/DesiredStateConfiguration'
    }

    process
    {
        #Have to use WMI here because I can't find how to delete a WMI instance via the CIM cmdlets.
        (Get-WmiObject -Namespace $dscNamespace -List -Class $ResourceType).psbase.Delete()
    }
}
#EndRegion '.\Public\Remove-DscResourceWmiClass.ps1' 34
#Region '.\Public\Test-DscResourceFromModuleInFolderIsValid.ps1' -1

function Test-DscResourceFromModuleInFolderIsValid
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]
        $ModuleFolder,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [System.Management.Automation.PSModuleInfo[]]
        [AllowNull()]
        $Modules
    )

    process
    {
        foreach ($module in $Modules)
        {
            $Resources = Get-DscResourceFromModuleInFolder -ModuleFolder $ModuleFolder -Modules $module

            $Resources.Where{ $_.ImplementedAs -eq 'PowerShell' } | Assert-DscModuleResourceIsValid
        }
    }
}
#EndRegion '.\Public\Test-DscResourceFromModuleInFolderIsValid.ps1' 26
