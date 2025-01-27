#Region '.\Prefix.ps1' -1

$script:dscResourceCommonModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules/DscResource.Common'
Import-Module -Name $script:dscResourceCommonModulePath
#EndRegion '.\Prefix.ps1' 3
#Region '.\Enum\AttributeMappingFlowType.ps1' -1

enum AttributeMappingFlowType
{
    Direct
    Constant
    Expression
}
#EndRegion '.\Enum\AttributeMappingFlowType.ps1' 7
#Region '.\Enum\AttributeValueMergeType.ps1' -1

enum AttributeValueMergeType
{
    Update
    Replace
    MergeCaseInsensitive
    Merge
}
#EndRegion '.\Enum\AttributeValueMergeType.ps1' 8
#Region '.\Enum\ComparisonOperator.ps1' -1

enum ComparisonOperator {
    EQUAL
    NOTEQUAL
    LESSTHAN
    LESSTHAN_OR_EQUAL
    CONTAINS
    NOTCONTAINS
    STARTSWITH
    NOTSTARTSWITH
    ENDSWITH
    NOTENDSWITH
    GREATERTHAN
    GREATERTHAN_OR_EQUAL
    ISNULL
    ISNOTNULL
    ISIN
    ISNOTIN
    ISBITSET
    ISBITNOTSET
    ISMEMBEROF
    ISNOTMEMBEROF
}
#EndRegion '.\Enum\ComparisonOperator.ps1' 23
#Region '.\Enum\Ensure.ps1' -1

enum Ensure {
    Absent
    Present
    Unknown
}
#EndRegion '.\Enum\Ensure.ps1' 6
#Region '.\Classes\AADConnectDirectoryExtensionAttribute.ps1' -1

[DscResource()]
class AADConnectDirectoryExtensionAttribute
{
    [DscProperty(Key = $true)]
    [string]$Name

    [DscProperty(Key = $true)]
    [string]$AssignedObjectClass

    [DscProperty(Mandatory = $true)]
    [string]$Type

    [DscProperty(Mandatory = $true)]
    [bool]$IsEnabled

    [DscProperty()]
    [Ensure]
    $Ensure

    AADConnectDirectoryExtensionAttribute()
    {
        $this.Ensure = 'Present'
    }

    [bool]Test()
    {
        $currentState = Convert-ObjectToHashtable -Object $this.Get()
        $desiredState = Convert-ObjectToHashtable -Object $this

        if ($currentState.Ensure -ne $desiredState.Ensure)
        {
            return $false
        }
        if ($desiredState.Ensure -eq [Ensure]::Absent)
        {
            return $true
        }

        $compare = Test-DscParameterState -CurrentValues $currentState -DesiredValues $desiredState -TurnOffTypeChecking -SortArrayValues

        return $compare
    }

    [AADConnectDirectoryExtensionAttribute]Get()
    {
        $currentState = [AADConnectDirectoryExtensionAttribute]::new()

        $attribute = Get-AADConnectDirectoryExtensionAttribute -Name $this.Name -ErrorAction SilentlyContinue |
            Where-Object { $_.AssignedObjectClass -eq $this.AssignedObjectClass -and $_.Type -eq $this.Type }

        $currentState.Ensure = [Ensure][int][bool]$attribute
        $CurrentState.Name = $this.Name
        $currentState.AssignedObjectClass = $this.AssignedObjectClass
        $currentState.Type = $attribute.Type
        $currentState.IsEnabled = $attribute.IsEnabled

        return $currentState
    }

    [void]Set()
    {
        $param = Convert-ObjectToHashtable $this

        if ($this.Ensure -eq 'Present')
        {
            $cmdet = Get-Command -Name Add-AADConnectDirectoryExtensionAttribute
            $param = Sync-Parameter -Command $cmdet -Parameters $param
            Add-AADConnectDirectoryExtensionAttribute @param -Force
        }
        else
        {
            $cmdet = Get-Command -Name Remove-AADConnectDirectoryExtensionAttribute
            $param = Sync-Parameter -Command $cmdet -Parameters $param
            Remove-AADConnectDirectoryExtensionAttribute @param
        }

    }
}
#EndRegion '.\Classes\AADConnectDirectoryExtensionAttribute.ps1' 79
#Region '.\Classes\AADSyncRule.ps1' -1

[DscResource()]
class AADSyncRule
{
    [DscProperty(Key = $true)]
    [string]$Name

    [DscProperty()]
    [string]$Description

    [DscProperty()]
    [bool]$Disabled

    [DscProperty(NotConfigurable)]
    [string]$Identifier

    [DscProperty(NotConfigurable)]
    [string]$Version

    [DscProperty()]
    [ScopeConditionGroup[]]$ScopeFilter

    [DscProperty()]
    [JoinConditionGroup[]]$JoinFilter

    [DscProperty()]
    [AttributeFlowMapping[]]$AttributeFlowMappings

    [DscProperty(Key = $true)]
    [string]$ConnectorName

    [DscProperty(NotConfigurable)]
    [string]$Connector

    [DscProperty()]
    [int]$Precedence

    [DscProperty()]
    [string]$PrecedenceAfter

    [DscProperty()]
    [string]$PrecedenceBefore

    [DscProperty(Mandatory = $true)]
    [string]$TargetObjectType

    [DscProperty(Mandatory = $true)]
    [string]$SourceObjectType

    [DscProperty(Mandatory = $true)]
    [string]$Direction

    [DscProperty(Mandatory = $true)]
    [string]$LinkType

    [DscProperty()]
    [bool]$EnablePasswordSync

    [DscProperty()]
    [string]$ImmutableTag

    [DscProperty()]
    [bool]$IsStandardRule

    [DscProperty(NotConfigurable)]
    [bool]$IsLegacyCustomRule

    [DscProperty()]
    [Ensure]$Ensure

    AADSyncRule()
    {
        $this.Ensure = 'Present'
    }

    [bool]Test()
    {
        $currentState = Convert-ObjectToHashtable -Object $this.Get()
        $desiredState = Convert-ObjectToHashtable -Object $this

        #Remove all whitespace from expressions in AttributeFlowMappings, otherwise they will not match due to encoding differences
        foreach ($afm in $currentState.AttributeFlowMappings)
        {
            if (-not [string]::IsNullOrEmpty($afm.Expression))
            {
                $afm.Expression = $afm.Expression -replace '\s', ''
            }
        }

        foreach ($afm in $desiredState.AttributeFlowMappings)
        {
            if (-not [string]::IsNullOrEmpty($afm.Expression))
            {
                $afm.Expression = $afm.Expression -replace '\s', ''
            }
        }

        if ($currentState.Ensure -ne $desiredState.Ensure)
        {
            return $false
        }
        if ($desiredState.Ensure -eq [Ensure]::Absent)
        {
            return $true
        }

        $param = @{
            CurrentValues       = $currentState
            DesiredValues       = $desiredState
            TurnOffTypeChecking = $true
            SortArrayValues     = $true
        }

        $param.ExcludeProperties = if ($this.IsStandardRule)
        {
            $this.GetType().GetProperties().Name | Where-Object { $_ -in 'Connector', 'Version', 'Identifier' }
        }
        else
        {
            'Connector', 'Version', 'Identifier'
        }

        $compare = Test-DscParameterState @param -ReverseCheck

        return $compare
    }

    [AADSyncRule]Get()
    {
        $syncRule = Get-ADSyncRule -Name $this.Name -ConnectorName $this.ConnectorName

        $currentState = [AADSyncRule]::new()
        $currentState.Name = $this.Name

        if ($syncRule.Count -gt 1)
        {
            Write-Error "There is more than one sync rule with the name '$($this.Name)'."
            $currentState.Ensure = 'Unknown'
            return $currentState
        }

        $currentState.Ensure = [Ensure][int][bool]$syncRule

        $currentState.ConnectorName = (Get-ADSyncConnector | Where-Object Identifier -EQ $syncRule.Connector).Name
        $currentState.Connector = $syncRule.Connector

        $currentState.Description = $syncRule.Description
        $currentState.Disabled = $syncRule.Disabled
        $currentState.Direction = $syncRule.Direction
        $currentState.EnablePasswordSync = $syncRule.EnablePasswordSync
        $currentState.Identifier = $syncRule.Identifier
        $currentState.LinkType = $syncRule.LinkType
        $currentState.Precedence = $syncRule.Precedence

        $currentState.ScopeFilter = @()
        foreach ($scg in $syncRule.ScopeFilter)
        {
            $scg2 = [ScopeConditionGroup]::new()
            foreach ($sc in $scg.ScopeConditionList)
            {
                $sc2 = [ScopeCondition]::new($sc.Attribute, $sc.ComparisonValue, $sc.ComparisonOperator)
                $scg2.ScopeConditionList += $sc2
            }

            $currentState.ScopeFilter += $scg2
        }

        $currentState.JoinFilter = @()
        foreach ($jcg in $syncRule.JoinFilter)
        {
            $jcg2 = [JoinConditionGroup]::new()
            foreach ($jc in $jcg.JoinConditionList)
            {
                $jc2 = [JoinCondition]::new($jc.CSAttribute, $jc.MVAttribute, $jc.CaseSensitive)
                $jcg2.JoinConditionList += $jc2
            }

            $currentState.JoinFilter += $jcg2
        }

        $currentState.AttributeFlowMappings = @()
        foreach ($af in $syncRule.AttributeFlowMappings)
        {
            $af2 = [AttributeFlowMapping]::new()
            $af2.Source = $af.Source[0]
            $af2.Destination = $af.Destination
            $af2.ExecuteOnce = $af.ExecuteOnce
            $af2.FlowType = $af.FlowType
            $af2.ValueMergeType = $af.ValueMergeType
            if ($null -eq $af.Expression)
            {
                $af2.Expression = ''
            }
            else
            {
                $af2.Expression = $af.Expression
            }

            $currentState.AttributeFlowMappings += $af2
        }

        $currentState.SourceObjectType = $syncRule.SourceObjectType
        $currentState.TargetObjectType = $syncRule.TargetObjectType
        $currentState.Version = $syncRule.Version
        $currentState.IsStandardRule = $syncRule.IsStandardRule
        $currentState.IsLegacyCustomRule = $syncRule.IsLegacyCustomRule

        return $currentState
    }

    [void]Set()
    {
        $this.Connector = (Get-ADSyncConnector | Where-Object Name -EQ $this.ConnectorName).Identifier

        $existingRule = Get-ADSyncRule -Name $this.Name -ConnectorName $this.ConnectorName
        $this.Identifier = if ($existingRule)
        {
            $existingRule.Identifier
        }
        else
        {
            New-Guid2 -InputString $this.Name
        }

        $allParameters = Convert-ObjectToHashtable -Object $this

        if ($this.Ensure -eq 'Present')
        {
            if ($this.IsStandardRule)
            {
                if ($null -eq $existingRule)
                {
                    Write-Error "A syncrule defined as 'IsStandardRule' does not exist. It cannot be enabled or disabled."
                    return
                }

                Write-Warning "The only property changed on a standard rule is 'Disabled'. All other configuration drifts will not be corrected."
                $existingRule.Disabled = $this.Disabled
                $existingRule | Add-ADSyncRule
            }
            else
            {
                if ($existingRule.IsStandardRule)
                {
                    Write-Error 'It is not allowed to modify a standard rule. It can only be enabled or disabled.'
                    return
                }

                $cmdet = Get-Command -Name New-ADSyncRule
                $param = Sync-Parameter -Command $cmdet -Parameters $allParameters
                $rule = New-ADSyncRule @param

                if ($this.ScopeFilter)
                {
                    foreach ($scg in $this.ScopeFilter)
                    {
                        $scopeConditions = foreach ($sc in $scg.ScopeConditionList)
                        {
                            [Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition]::new($sc.Attribute, $sc.ComparisonValue, $sc.ComparisonOperator)
                        }

                        $rule | Add-ADSyncScopeConditionGroup -ScopeConditions $scopeConditions
                    }
                }

                if ($this.JoinFilter)
                {
                    foreach ($jcg in $this.JoinFilter)
                    {
                        $joinConditions = foreach ($jc in $jcg.JoinConditionList)
                        {
                            [Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition]::new($jc.CSAttribute, $jc.MVAttribute, $jc.CaseSensitive)
                        }

                        $rule | Add-ADSyncJoinConditionGroup -JoinConditions $joinConditions
                    }

                }

                if ($this.AttributeFlowMappings)
                {
                    foreach ($af in $this.AttributeFlowMappings)
                    {
                        $afHashTable = Convert-ObjectToHashtable -Object $af
                        $param = Sync-Parameter -Command (Get-Command -Name Add-ADSyncAttributeFlowMapping) -Parameters $afHashTable
                        $param.SynchronizationRule = $rule

                        if ([string]::IsNullOrEmpty($param.Expression))
                        {
                            $param.Remove('Expression')
                        }

                        if ([string]::IsNullOrEmpty($param.Source))
                        {
                            $param.Remove('Source')
                        }

                        Add-ADSyncAttributeFlowMapping @param
                    }

                }

                $rule | Add-ADSyncRule
            }
        }
        else
        {
            if ($existingRule)
            {
                Remove-ADSyncRule -Identifier $this.Identifier
            }
        }
    }
}
#EndRegion '.\Classes\AADSyncRule.ps1' 314
#Region '.\Classes\AttributeFlowMapping.ps1' -1

class AttributeFlowMapping
{
    AttributeFlowMapping()
    {
    }

    [DscProperty(Key)]
    [string]$Destination

    [DscProperty()]
    [bool]$ExecuteOnce

    [DscProperty(Key)]
    [string]$Expression

    [DscProperty(Key)]
    [AttributeMappingFlowType]$FlowType

    [DscProperty(NotConfigurable)]
    [string]$MappingSourceAsString

    [DscProperty(Key)]
    [string]$Source

    [DscProperty()]
    [AttributeValueMergeType]$ValueMergeType
}
#EndRegion '.\Classes\AttributeFlowMapping.ps1' 28
#Region '.\Classes\JoinCondition.ps1' -1

class JoinCondition
{
    [DscProperty()]
    [string]$CSAttribute

    [DscProperty()]
    [string]$MVAttribute

    [DscProperty()]
    [bool]$CaseSensitive

    JoinCondition()
    {
    }

    JoinCondition([string]$CSAttribute, [string]$MVAttribute, [bool]$CaseSensitive)
    {
        $this.CSAttribute = $CSAttribute
        $this.MVAttribute = $MVAttribute
        $this.CaseSensitive = $CaseSensitive
    }
}
#EndRegion '.\Classes\JoinCondition.ps1' 23
#Region '.\Classes\JoinConditionGroup.ps1' -1


class JoinConditionGroup
{
    [DscProperty()]
    [JoinCondition[]]$JoinConditionList

    ScopeConditionGroup()
    {
    }
}
#EndRegion '.\Classes\JoinConditionGroup.ps1' 11
#Region '.\Classes\ScopeCondition.ps1' -1

class ScopeCondition
{
    [DscProperty()]
    [string]$Attribute

    [DscProperty()]
    [string]$ComparisonValue

    [DscProperty()]
    [ComparisonOperator]$ComparisonOperator

    ScopeCondition()
    {
    }

    ScopeCondition([hashtable]$Definition)
    {
        $this.Attribute = $Definition['Attribute']
        $this.ComparisonValue = $Definition['ComparisonValue']
        $this.ComparisonOperator = $Definition['ComparisonOperator']
    }

    ScopeCondition([string]$Attribute, [string]$ComparisonValue, [string]$ComparisonOperator)
    {
        $this.Attribute = $Attribute
        $this.ComparisonValue = $ComparisonValue
        $this.ComparisonOperator = $ComparisonOperator
    }
}
#EndRegion '.\Classes\ScopeCondition.ps1' 30
#Region '.\Classes\ScopeConditionGroup.ps1' -1


class ScopeConditionGroup
{
    [DscProperty()]
    [ScopeCondition[]]$ScopeConditionList

    ScopeConditionGroup()
    {
    }
}
#EndRegion '.\Classes\ScopeConditionGroup.ps1' 11
#Region '.\Private\New-Guid2.ps1' -1

function New-Guid2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $InputString
    )

    $md5 = [System.Security.Cryptography.MD5]::Create()

    $hash = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString))
    return [System.Guid]::new($hash).Guid
}
#EndRegion '.\Private\New-Guid2.ps1' 14
#Region '.\Public\Add-AADConnectDirectoryExtensionAttribute.ps1' -1

function Add-AADConnectDirectoryExtensionAttribute
{
    [CmdletBinding(DefaultParameterSetName = 'ByProperties')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByProperties')]
        [string]$Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByProperties')]
        [string]$Type,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByProperties')]
        [string]$AssignedObjectClass,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByProperties')]
        [bool]$IsEnabled,

        [Parameter(Mandatory = $true, ParameterSetName = 'SingleObject')]
        [string]$FullAttributeString,

        [Parameter()]
        [switch]$Force
    )

    process
    {
        $currentAttributes = Get-AADConnectDirectoryExtensionAttribute

        if ($FullAttributeString)
        {
            $attributeValues = $FullAttributeString -split '\.'
            if ($attributeValues.Count -ne 4)
            {
                Write-Error "The attribute string did not have the correct format. Make sure it is like 'attributeName.group.String.True'"
                return
            }
            $Name = $attributeValues[0]
            $AssignedObjectClass = $attributeValues[1]
            $Type = $attributeValues[2]
            $IsEnabled = $attributeValues[3]
        }

        if ($currentAttributes | Where-Object {
                $_.Name -eq $Name -and
                $_.AssignedObjectClass -eq $AssignedObjectClass -and
                $_.Type -eq $Type -and
                $_.IsEnabled -eq $IsEnabled
            })
        {
            Write-Error "The attribute '$Name' with the type '$Type' assigned to the class '$AssignedObjectClass' is already defined."
            return
        }

        if (($existingAttribute = $currentAttributes | Where-Object {
                    $_.Name -eq $Name -and
                    $_.Type -ne $Type
                }) -and -not $Force)
        {
            Write-Error "The attribute '$Name' is already defined with the type '$($existingAttribute.Type)'."
            return
        }
        else
        {
            $existingAttribute | Remove-AADConnectDirectoryExtensionAttribute
        }

        $settings = Get-ADSyncGlobalSettings
        $attributeParameter = $settings.Parameters | Where-Object Name -EQ Microsoft.OptionalFeature.DirectoryExtensionAttributes
        $currentAttributeList = $attributeParameter.Value -split ','

        $newAttributeString = "$Name.$AssignedObjectClass.$Type.$IsEnabled"
        $currentAttributeList += $newAttributeString

        $attributeParameter.Value = $currentAttributeList -join ','
        $settings.Parameters.AddOrReplace($attributeParameter)

        Set-ADSyncGlobalSettings -GlobalSettings $settings | Out-Null
    }
}
#EndRegion '.\Public\Add-AADConnectDirectoryExtensionAttribute.ps1' 79
#Region '.\Public\Convert-ObjectToHashtable.ps1' -1

function Convert-ObjectToHashtable
{
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Object
    )

    process
    {
        $hashtable = @{ }

        foreach ($property in $Object.PSObject.Properties.Where({ $null -ne $_.Value }))
        {
            $hashtable.Add($property.Name, $property.Value)
        }

        $hashtable
    }
}
#EndRegion '.\Public\Convert-ObjectToHashtable.ps1' 21
#Region '.\Public\Get-AADConnectDirectoryExtensionAttribute.ps1' -1

function Get-AADConnectDirectoryExtensionAttribute
{
    param (
        [Parameter()]
        [string]$Name
    )

    $settings = Get-ADSyncGlobalSettings
    $attributeParameter = $settings.Parameters | Where-Object Name -EQ Microsoft.OptionalFeature.DirectoryExtensionAttributes

    $attributes = $attributeParameter.Value -split ','

    if (-not $attributes)
    {
        return
    }

    if ($Name)
    {
        $attributes = $attributes | Where-Object { $_ -like "$Name.*" }
        if (-not $attributes)
        {
            Write-Error "The attribute '$Name' is not defined."
            return
        }
    }

    foreach ($attribute in $attributes)
    {
        $attribute = $attribute -split '\.'
        [pscustomobject]@{
            Name                = $attribute[0]
            Type                = $attribute[2]
            AssignedObjectClass = $attribute[1]
            IsEnabled           = $attribute[3]
        }
    }
}
#EndRegion '.\Public\Get-AADConnectDirectoryExtensionAttribute.ps1' 39
#Region '.\Public\Get-ADSyncRule.ps1' -1

function Get-ADSyncRule
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByNameAndConnector')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ByIdentifier')]
        [guid]
        $Identifier,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByNameAndConnector')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ByConnector')]
        [string]
        $ConnectorName
    )

    $connectors = Get-ADSyncConnector

    if ($PSCmdlet.ParameterSetName -eq 'ByIdentifier')
    {
        ADSync\Get-ADSyncRule -Identifier $Identifier
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        if ($Name)
        {
            ADSync\Get-ADSyncRule | Where-Object Name -EQ $Name
        }
        else
        {
            ADSync\Get-ADSyncRule
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ByConnector')
    {
        $connector = $connectors | Where-Object Name-eq $ConnectorName
        ADSync\Get-ADSyncRule | Where-Object Connector -EQ $connector.Identifier
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'ByNameAndConnector')
    {
        $connector = $connectors | Where-Object Name -EQ $ConnectorName
        if ($null -eq $connector)
        {
            Write-Error "The connector '$ConnectorName' does not exist"
            return
        }
        ADSync\Get-ADSyncRule | Where-Object { $_.Name -eq $Name -and $_.Connector -eq $connector.Identifier }
    }
    else
    {
        ADSync\Get-ADSyncRule
    }
}
#EndRegion '.\Public\Get-ADSyncRule.ps1' 57
#Region '.\Public\Remove-AADConnectDirectoryExtensionAttribute.ps1' -1

function Remove-AADConnectDirectoryExtensionAttribute
{
    [CmdletBinding(DefaultParameterSetName = 'ByProperties')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByProperties')]
        [string]$Name,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByProperties')]
        [string]$Type,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByProperties')]
        [string]$AssignedObjectClass,

        [Parameter(Mandatory = $true, ParameterSetName = 'SingleObject')]
        $FullAttributeString
    )

    process
    {
        $currentAttributes = Get-AADConnectDirectoryExtensionAttribute

        if ($FullAttributeString)
        {
            $attributeValues = $FullAttributeString -split '\.'
            if ($attributeValues.Count -ne 4)
            {
                Write-Error "The attribute string did not have the correct format. Make sure it is like 'attributeName.group.String.True'".
                return
            }
            $Name = $attributeValues[0]
            $AssignedObjectClass = $attributeValues[1]
            $Type = $attributeValues[2]
            $IsEnabled = $attributeValues[3]
        }

        if (-not ($existingAttribute = $currentAttributes | Where-Object {
                    $_.Name -eq $Name -and
                    $_.AssignedObjectClass -eq $AssignedObjectClass -and
                    $_.Type -eq $Type
                }))
        {
            Write-Error "The attribute '$Name' with the type '$Type' assigned to the class '$AssignedObjectClass' is not defined."
            return
        }

        $settings = Get-ADSyncGlobalSettings
        $attributeParameter = $settings.Parameters | Where-Object Name -EQ Microsoft.OptionalFeature.DirectoryExtensionAttributes
        $currentAttributeList = $attributeParameter.Value -split ','

        $attributeStringToRemove = "$($existingAttribute.Name).$($existingAttribute.AssignedObjectClass).$($existingAttribute.Type).$($existingAttribute.IsEnabled)"
        $currentAttributeList = $currentAttributeList -ne $attributeStringToRemove

        $attributeParameter.Value = $currentAttributeList -join ','
        $settings.Parameters.AddOrReplace($attributeParameter)

        Set-ADSyncGlobalSettings -GlobalSettings $settings | Out-Null
    }
}
#EndRegion '.\Public\Remove-AADConnectDirectoryExtensionAttribute.ps1' 59
