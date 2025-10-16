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

enum ComparisonOperator
{
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
#EndRegion '.\Enum\ComparisonOperator.ps1' 24
#Region '.\Enum\Ensure.ps1' -1

enum Ensure
{
    Absent
    Present
    Unknown
}
#EndRegion '.\Enum\Ensure.ps1' 7
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
    [Ensure]$Ensure

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
        $currentState.Name = $this.Name
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
#EndRegion '.\Classes\AADConnectDirectoryExtensionAttribute.ps1' 78
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
        $currentState = $this.Get() | ConvertTo-Yaml | ConvertFrom-Yaml
        $desiredState = $this | ConvertTo-Yaml | ConvertFrom-Yaml

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

        $param = @{
            CurrentValues       = $currentState
            DesiredValues       = $desiredState
            TurnOffTypeChecking = $true
            SortArrayValues     = $true
        }

        $param.ExcludeProperties = if ($this.IsStandardRule)
        {
            # Exclude all properties that are not relevant for standard rules
            ($this | Get-Member -MemberType Property).Name | Where-Object { $_ -notin 'Name', 'Disabled' }
        }
        else
        {
            # Cannot be compared as they are generated by the system
            'Connector', 'Version', 'Identifier'
        }

        $compare = if ($currentState.Ensure -eq $desiredState.Ensure)
        {
            if ($desiredState.Ensure -eq 'Present')
            {
                Write-Verbose "The sync rule '$($this.Name)' exists and should exist, comparing rule with 'Test-DscParameterState'."
                Test-DscParameterState @param -ReverseCheck

                if ($this.IsStandardRule)
                {
                    $param.ExcludeProperties = 'Connector', 'Version', 'Identifier', 'Precedence'
                    $param.Verbose = $false # Suppress verbose output for the actual comparison for standard rules
                    Write-Verbose '-----------------------------------------------------------------------------------------------------'
                    Write-Verbose '--------------------------- Comparing all properties for standard rule ------------------------------'
                    Write-Verbose '----------------------- The result will not effect the overall test result --------------------------'
                    Write-Verbose '-----------------------------------------------------------------------------------------------------'
                    $result = Test-DscParameterState @param -ReverseCheck
                    Write-Verbose '-----------------------------------------------------------------------------------------------------'
                    Write-Verbose "---- Test-DscParameterState returned '$result', but a negative value is not returned to the LCM -----"
                    Write-Verbose '-----------------------------------------------------------------------------------------------------'
                }
            }
            else
            {
                Write-Verbose "The sync rule '$($this.Name)' is absent and should be absent."
                $true
            }
        }
        else
        {
            if ($desiredState.Ensure -eq 'Present')
            {
                Write-Verbose "The sync rule '$($this.Name)' for connector '$($this.ConnectorName)' is absent, but should be present."
            }
            else
            {
                Write-Verbose "The sync rule '$($this.Name)' for connector '$($this.ConnectorName)' is present, but should be absent."
            }
            $false
        }

        # Write event log entries based on compliance state
        try
        {
            if ($compare)
            {
                # Sync rule is in desired state - write Information event
                Write-AADConnectEventLog -EventType 'Information' -EventId 1000 -Message 'AADSyncRule is in desired state and compliant with configuration' -SyncRuleName $this.Name -ConnectorName $this.ConnectorName -Direction $this.Direction -TargetObjectType $this.TargetObjectType -SourceObjectType $this.SourceObjectType -Precedence $this.Precedence -Disabled $this.Disabled -IsStandardRule $this.IsStandardRule
            }
            else
            {
                # Sync rule is not in desired state - write Warning event with specific event IDs
                if ($currentState.Ensure -ne $desiredState.Ensure)
                {
                    if ($desiredState.Ensure -eq 'Present')
                    {
                        # Sync rule is absent but should be present
                        Write-AADConnectEventLog -EventType 'Warning' -EventId 1001 -Message 'AADSyncRule is absent but should be present - configuration drift detected' -SyncRuleName $this.Name -ConnectorName $this.ConnectorName -Direction $this.Direction -TargetObjectType $this.TargetObjectType -SourceObjectType $this.SourceObjectType -Precedence $this.Precedence -Disabled $this.Disabled -IsStandardRule $this.IsStandardRule
                    }
                    else
                    {
                        # Sync rule is present but should be absent
                        Write-AADConnectEventLog -EventType 'Warning' -EventId 1002 -Message 'AADSyncRule is present but should be absent - configuration drift detected' -SyncRuleName $this.Name -ConnectorName $this.ConnectorName -Direction $this.Direction -TargetObjectType $this.TargetObjectType -SourceObjectType $this.SourceObjectType -Precedence $this.Precedence -Disabled $this.Disabled -IsStandardRule $this.IsStandardRule
                    }
                }
                else
                {
                    # Properties don't match for existing sync rule
                    Write-AADConnectEventLog -EventType 'Warning' -EventId 1003 -Message 'AADSyncRule configuration drift detected - current state does not match desired state' -SyncRuleName $this.Name -ConnectorName $this.ConnectorName -Direction $this.Direction -TargetObjectType $this.TargetObjectType -SourceObjectType $this.SourceObjectType -Precedence $this.Precedence -Disabled $this.Disabled -IsStandardRule $this.IsStandardRule
                }
            }
        }
        catch
        {
            # Event logging should not break the main DSC operation
            Write-Verbose "Failed to write event log entry: $($_.Exception.Message)"
        }        return $compare
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
        $connectorObject = Get-ADSyncConnector -Name $this.ConnectorName -ErrorAction SilentlyContinue
        if ($null -eq $connectorObject)
        {
            Write-Error "The connector '$($this.ConnectorName)' does not exist."
            return
        }

        $this.Connector = $connectorObject.Identifier
        Write-Verbose "Got connector '$($this.ConnectorName)' for rule '$($this.Name)' with identifier '$($this.Connector)'."

        $existingRule = Get-ADSyncRule -Name $this.Name -ConnectorName $this.ConnectorName
        $isNewRule = $null -eq $existingRule

        if ($existingRule)
        {
            Write-Verbose "Got existing rule '$($existingRule.Name)' with identifier '$($existingRule.Identifier)' for connector '$($this.ConnectorName)'."
            $this.Identifier = $existingRule.Identifier
        }
        else
        {
            $this.Identifier = New-Guid2 -InputString "$($this.Name)$($this.ConnectorName)"
            Write-Verbose "No existing rule found with the name '$($this.Name)'. Using identifier '$($this.Identifier)'."
        }

        $desiredState = Convert-ObjectToHashtable -Object $this

        if ($this.Ensure -eq 'Present')
        {
            Write-Verbose "The sync rule '$($this.Name)' should be present for connector '$($this.ConnectorName)'. Proceeding with creation or update."
            if ($this.IsStandardRule)
            {
                if ($null -eq $existingRule)
                {
                    Write-Error "A Sync Rule defined as 'IsStandardRule' does not exist. It cannot be enabled or disabled."
                    return
                }

                Write-Warning "The only property that will be changed on a standard rule is 'Disabled'. All other configuration drifts will not be corrected."
                $oldDisabledState = $existingRule.Disabled
                $existingRule.Disabled = $this.Disabled
                Write-Verbose "Setting the 'Disabled' property of the rule '$($this.Name)' to '$($this.Disabled)' and calling 'Add-ADSyncRule'."
                $existingRule | Add-ADSyncRule

                # Log standard rule disabled state change
                try
                {
                    $operationDetails = "Changed Disabled state from $oldDisabledState to $($this.Disabled)"
                    Write-Verbose '🔔 Attempting to log standard rule disabled state change event...'
                    Write-AADConnectEventLog -EventType 'Information' -EventId 2002 -Message 'Standard sync rule disabled state changed successfully' -SyncRuleName $this.Name -ConnectorName $this.ConnectorName -Direction $this.Direction -TargetObjectType $this.TargetObjectType -SourceObjectType $this.SourceObjectType -Precedence $this.Precedence -Disabled $this.Disabled -IsStandardRule $this.IsStandardRule -Operation $operationDetails -RuleIdentifier $this.Identifier
                }
                catch
                {
                    Write-Verbose "❌ Failed to write event log entry for standard rule change: $($_.Exception.Message)"
                }
            }
            else
            {
                if ($existingRule.IsStandardRule)
                {
                    Write-Error 'It is not allowed to modify a standard rule. It can only be enabled or disabled.'
                    return
                }

                $cmdet = Get-Command -Name New-ADSyncRule
                $param = Sync-Parameter -Command $cmdet -Parameters $desiredState
                $rule = New-ADSyncRule @param

                if ($this.ScopeFilter)
                {
                    $i = 0
                    foreach ($scg in $this.ScopeFilter)
                    {
                        Write-Verbose "Processing ScopeConditionList $i"
                        $scopeConditions = foreach ($sc in $scg.ScopeConditionList)
                        {
                            Write-Verbose "Processing ScopeFilter: Attribute = '$($sc.Attribute)', ComparisonValue = '$($sc.ComparisonValue)', ComparisonOperator = '$($sc.ComparisonOperator)'"
                            [Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition]::new($sc.Attribute, $sc.ComparisonValue, $sc.ComparisonOperator)
                        }
                        Write-Verbose "ScopeConditionList count is $($scopeConditions.Count)"
                        $rule | Add-ADSyncScopeConditionGroup -ScopeConditions $scopeConditions
                        $i++
                    }
                }

                if ($this.JoinFilter)
                {
                    $i = 0
                    foreach ($jcg in $this.JoinFilter)
                    {
                        Write-Verbose "Processing JoinConditionList $i"
                        $joinConditions = foreach ($jc in $jcg.JoinConditionList)
                        {
                            Write-Verbose "Processing JoinFilter: CSAttribute = '$($jc.CSAttribute)', MVAttribute = '$($jc.MVAttribute)', CaseSensitive = '$($jc.CaseSensitive)'"
                            [Microsoft.IdentityManagement.PowerShell.ObjectModel.JoinCondition]::new($jc.CSAttribute, $jc.MVAttribute, $jc.CaseSensitive)
                        }

                        Write-Verbose "JoinConditionList count is $($joinConditions.Count)"
                        $rule | Add-ADSyncJoinConditionGroup -JoinConditions $joinConditions
                    }

                }

                if ($this.AttributeFlowMappings)
                {
                    $i = 0
                    foreach ($af in $this.AttributeFlowMappings)
                    {
                        Write-Verbose "Processing AttributeFlowMapping $i, Source = '$($af.Source)', Destination = '$($af.Destination)', Expression = '$($af.Expression)'"
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

                Write-Verbose "Calling 'Add-ADSyncRule' to create or update the rule '$($this.Name)'."
                $rule | Add-ADSyncRule

                # Log rule creation or update
                $eventId = if ($isNewRule)
                {
                    2000
                }
                else
                {
                    2001
                }
                $message = if ($isNewRule)
                {
                    'Sync rule created successfully'
                }
                else
                {
                    'Sync rule updated successfully'
                }
                $operation = if ($isNewRule)
                {
                    'Create'
                }
                else
                {
                    'Update'
                }

                try
                {
                    $scopeFilterCount = if ($this.ScopeFilter)
                    {
                        $this.ScopeFilter.Count
                    }
                    else
                    {
                        0
                    }
                    $joinFilterCount = if ($this.JoinFilter)
                    {
                        $this.JoinFilter.Count
                    }
                    else
                    {
                        0
                    }
                    $attributeFlowMappingCount = if ($this.AttributeFlowMappings)
                    {
                        $this.AttributeFlowMappings.Count
                    }
                    else
                    {
                        0
                    }

                    Write-Verbose "🔔 Attempting to log sync rule $operation event (EventId: $eventId)..."
                    Write-AADConnectEventLog -EventType 'Information' -EventId $eventId -Message $message -SyncRuleName $this.Name -ConnectorName $this.ConnectorName -Direction $this.Direction -TargetObjectType $this.TargetObjectType -SourceObjectType $this.SourceObjectType -Precedence $this.Precedence -Disabled $this.Disabled -IsStandardRule $this.IsStandardRule -Operation $operation -RuleIdentifier $this.Identifier -ScopeFilterCount $scopeFilterCount -JoinFilterCount $joinFilterCount -AttributeFlowMappingCount $attributeFlowMappingCount
                }
                catch
                {
                    Write-Verbose "❌ Failed to write event log entry for sync rule $operation operation: $($_.Exception.Message)"
                }
            }
        }
        else
        {
            if ($existingRule)
            {
                # Log rule removal
                try
                {
                    Write-Verbose '🔔 Attempting to log sync rule removal event...'
                    Write-AADConnectEventLog -EventType 'Information' -EventId 2003 -Message 'Sync rule removed successfully' -SyncRuleName $this.Name -ConnectorName $this.ConnectorName -Direction $existingRule.Direction -TargetObjectType $existingRule.TargetObjectType -SourceObjectType $existingRule.SourceObjectType -Precedence $existingRule.Precedence -Disabled $existingRule.Disabled -IsStandardRule $existingRule.IsStandardRule -Operation 'Remove' -RuleIdentifier $this.Identifier
                }
                catch
                {
                    Write-Verbose "❌ Failed to write event log entry for sync rule removal: $($_.Exception.Message)"
                }

                Remove-ADSyncRule -Identifier $this.Identifier
            }
        }
    }
}
#EndRegion '.\Classes\AADSyncRule.ps1' 490
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

function New-Guid2
{
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
#EndRegion '.\Private\New-Guid2.ps1' 15
#Region '.\Public\Add-AADConnectDirectoryExtensionAttribute.ps1' -1

<#
.SYNOPSIS
    Adds a directory extension attribute to Azure AD Connect configuration.

.DESCRIPTION
    The Add-AADConnectDirectoryExtensionAttribute function adds a new directory extension attribute
    to the Azure AD Connect global settings. Directory extension attributes allow you to extend
    the schema of Azure AD objects with custom attributes that can be synchronized from on-premises
    Active Directory.

    This function supports two parameter sets: specifying individual properties or providing a
    complete attribute string. It includes validation and conflict resolution capabilities.

    This function requires Windows PowerShell 5.1 and does not work with PowerShell 7.

.PARAMETER Name
    Specifies the name of the directory extension attribute to add. The name should be unique
    within the object class and follow Azure AD naming conventions.

.PARAMETER Type
    Specifies the data type of the directory extension attribute. Common types include:
    - String: Text data
    - Integer: Numeric data
    - Boolean: True/False values
    - DateTime: Date and time values

.PARAMETER AssignedObjectClass
    Specifies the object class to which this attribute will be assigned. Common values include:
    - user: For user objects
    - group: For group objects
    - contact: For contact objects
    - device: For device objects

.PARAMETER IsEnabled
    Specifies whether the directory extension attribute is enabled for synchronization.
    Set to $true to enable or $false to disable.

.PARAMETER FullAttributeString
    Specifies a complete attribute definition string in the format:
    "attributeName.objectClass.dataType.enabledStatus"
    For example: "employeeNumber.user.String.True"

.PARAMETER Force
    Forces the addition of the attribute even if a conflicting attribute with the same name
    but different type exists. When specified, the existing conflicting attribute is removed.

.EXAMPLE
    Add-AADConnectDirectoryExtensionAttribute -Name "employeeNumber" -Type "String" -AssignedObjectClass "user" -IsEnabled $true

    Adds an employee number attribute for user objects as a string type.

.EXAMPLE
    Add-AADConnectDirectoryExtensionAttribute -FullAttributeString "departmentCode.user.String.True"

    Adds a department code attribute using the full attribute string format.

.EXAMPLE
    Add-AADConnectDirectoryExtensionAttribute -Name "badgeNumber" -Type "Integer" -AssignedObjectClass "user" -IsEnabled $true -Force

    Adds a badge number attribute, replacing any existing conflicting attribute with the same name.

.EXAMPLE
    Get-Content "attributes.txt" | ForEach-Object { Add-AADConnectDirectoryExtensionAttribute -FullAttributeString $_ }

    Adds multiple attributes from a text file, with each line containing a full attribute string.

.INPUTS
    String. You can pipe attribute strings to this function when using the FullAttributeString parameter.

.OUTPUTS
    None. This function does not return objects but modifies Azure AD Connect global settings.

.NOTES
    - This function requires Windows PowerShell 5.1 and does not work with PowerShell 7
    - Requires Azure AD Connect to be installed and the ADSync module to be available
    - Changes take effect immediately but may require synchronization cycle restart
    - Use Get-AADConnectDirectoryExtensionAttribute to verify the attribute was added successfully
    - Directory extension attributes are permanent once synchronized to Azure AD

.LINK
    https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-sync-feature-directory-extensions

.COMPONENT
    AADConnectDsc

.FUNCTIONALITY
    Azure AD Connect Directory Extension Attribute Management
#>
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
#EndRegion '.\Public\Add-AADConnectDirectoryExtensionAttribute.ps1' 167
#Region '.\Public\Convert-ObjectToHashtable.ps1' -1

<#
.SYNOPSIS
    Converts a PowerShell object to a hashtable.

.DESCRIPTION
    The Convert-ObjectToHashtable function converts any PowerShell object to a hashtable by
    extracting all properties and their values. This utility function is commonly used in
    DSC configurations and Azure AD Connect management scenarios where hashtable representations
    of objects are needed for parameter passing or configuration storage.

    The function filters out properties with null values to create a clean hashtable with only
    meaningful data. This is particularly useful when working with Azure AD Connect objects
    that may have many optional properties.

    This function works with both Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER Object
    Specifies the PowerShell object to convert to a hashtable. The object can be of any type
    that has properties accessible through the PSObject.Properties collection.

.EXAMPLE
    $syncRule = Get-ADSyncRule -Name "In from AD - User Common"
    $hashtable = Convert-ObjectToHashtable -Object $syncRule

    Converts an Azure AD Connect synchronization rule object to a hashtable.

.EXAMPLE
    Get-ADSyncRule | Select-Object -First 1 | Convert-ObjectToHashtable

    Retrieves a synchronization rule and converts it to a hashtable using pipeline input.

.EXAMPLE
    $user = [PSCustomObject]@{
        Name = "John Doe"
        Email = "john.doe@contoso.com"
        Department = $null
        Enabled = $true
    }
    $hashtable = Convert-ObjectToHashtable -Object $user
    # Results in: @{ Name = "John Doe"; Email = "john.doe@contoso.com"; Enabled = $true }

    Converts a custom object to a hashtable, excluding null properties.

.EXAMPLE
    $config = @{
        SyncRules = Get-ADSyncRule | ForEach-Object { Convert-ObjectToHashtable $_ }
    }

    Creates a configuration hashtable containing all synchronization rules as hashtables.

.INPUTS
    Object. You can pipe any PowerShell object to Convert-ObjectToHashtable.

.OUTPUTS
    Hashtable. Returns a hashtable containing all non-null properties and their values.

.NOTES
    - This function works with both Windows PowerShell 5.1 and PowerShell 7
    - Properties with null values are excluded from the resulting hashtable
    - Complex nested objects are included as-is (not recursively converted)
    - The function is optimized for performance and memory efficiency
    - Useful for DSC configurations and Azure AD Connect object manipulation

.LINK
    https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-hashtable

.COMPONENT
    AADConnectDsc

.FUNCTIONALITY
    PowerShell Object Utilities
#>
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
#EndRegion '.\Public\Convert-ObjectToHashtable.ps1' 93
#Region '.\Public\Get-AADConnectDirectoryExtensionAttribute.ps1' -1

<#
.SYNOPSIS
    Retrieves directory extension attributes from Azure AD Connect configuration.

.DESCRIPTION
    The Get-AADConnectDirectoryExtensionAttribute function retrieves directory extension attributes
    that are currently configured in Azure AD Connect global settings. These attributes represent
    schema extensions that allow synchronization of custom attributes from on-premises Active Directory
    to Azure AD.

    The function can retrieve all directory extension attributes or filter by a specific attribute name.
    Each returned object contains the attribute name, data type, assigned object class, and enabled status.

    This function requires Windows PowerShell 5.1 and does not work with PowerShell 7.

.PARAMETER Name
    Specifies the name of a specific directory extension attribute to retrieve. If not specified,
    all directory extension attributes are returned. Supports wildcard patterns.

.EXAMPLE
    Get-AADConnectDirectoryExtensionAttribute

    Retrieves all directory extension attributes currently configured in Azure AD Connect.

.EXAMPLE
    Get-AADConnectDirectoryExtensionAttribute -Name "employeeNumber"

    Retrieves the directory extension attribute named "employeeNumber" if it exists.

.EXAMPLE
    Get-AADConnectDirectoryExtensionAttribute -Name "employee*"

    Retrieves all directory extension attributes with names starting with "employee".

.EXAMPLE
    $attributes = Get-AADConnectDirectoryExtensionAttribute
    $attributes | Where-Object Type -eq "String"

    Retrieves all directory extension attributes and filters for those with String data type.

.INPUTS
    None. You cannot pipe objects to Get-AADConnectDirectoryExtensionAttribute.

.OUTPUTS
    PSCustomObject. Returns objects with the following properties:
    - Name: The attribute name
    - Type: The data type (String, Integer, Boolean, DateTime, etc.)
    - AssignedObjectClass: The object class (user, group, contact, device, etc.)
    - IsEnabled: Whether the attribute is enabled for synchronization

.NOTES
    - This function requires Windows PowerShell 5.1 and does not work with PowerShell 7
    - Requires Azure AD Connect to be installed and the ADSync module to be available
    - Returns an empty result if no directory extension attributes are configured
    - The returned objects can be used as input for other directory extension attribute functions

.LINK
    https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-sync-feature-directory-extensions

.COMPONENT
    AADConnectDsc

.FUNCTIONALITY
    Azure AD Connect Directory Extension Attribute Management
#>
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
#EndRegion '.\Public\Get-AADConnectDirectoryExtensionAttribute.ps1' 104
#Region '.\Public\Get-ADSyncRule.ps1' -1

<#
.SYNOPSIS
    Retrieves Azure AD Connect synchronization rules with enhanced filtering capabilities.

.DESCRIPTION
    The Get-ADSyncRule function provides a wrapper around the native ADSync\Get-ADSyncRule cmdlet,
    adding enhanced filtering capabilities by name and connector. This function supports multiple
    parameter sets for flexible rule retrieval and is designed to work with Windows PowerShell 5.1.

    This function is part of the AADConnectDsc module and requires an active Azure AD Connect
    installation with the ADSync PowerShell module available.

.PARAMETER Name
    Specifies the name of the synchronization rule to retrieve. When used alone, it searches
    across all connectors. When used with ConnectorName, it searches within the specified connector.

.PARAMETER Identifier
    Specifies the unique identifier (GUID) of the synchronization rule to retrieve.
    When specified, all other parameters are ignored.

.PARAMETER ConnectorName
    Specifies the name of the connector to filter synchronization rules.
    Can be used alone to get all rules for a connector, or with Name for specific rule lookup.

.EXAMPLE
    Get-ADSyncRule

    Retrieves all synchronization rules from Azure AD Connect.

.EXAMPLE
    Get-ADSyncRule -Name "In from AD - User Common"

    Retrieves the synchronization rule with the specified name from any connector.

.EXAMPLE
    Get-ADSyncRule -Identifier "12345678-1234-1234-1234-123456789012"

    Retrieves the synchronization rule with the specified GUID identifier.

.EXAMPLE
    Get-ADSyncRule -ConnectorName "contoso.com"

    Retrieves all synchronization rules associated with the specified connector.

.EXAMPLE
    Get-ADSyncRule -Name "In from AD - User Common" -ConnectorName "contoso.com"

    Retrieves the synchronization rule with the specified name from the specified connector.

.INPUTS
    None. You cannot pipe objects to Get-ADSyncRule.

.OUTPUTS
    Microsoft.IdentityManagement.PowerShell.ObjectModel.SynchronizationRule
    Returns synchronization rule objects that match the specified criteria.

.NOTES
    - This function requires Windows PowerShell 5.1 and does not work with PowerShell 7
    - Requires Azure AD Connect to be installed and the ADSync module to be available
    - The function provides enhanced error handling and parameter validation
    - Multiple parameter sets allow for flexible rule retrieval scenarios

.LINK
    https://docs.microsoft.com/en-us/azure/active-directory/hybrid/reference-connect-sync-functions-reference

.COMPONENT
    AADConnectDsc

.FUNCTIONALITY
    Azure AD Connect Synchronization Rule Management
#>
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
#EndRegion '.\Public\Get-ADSyncRule.ps1' 128
#Region '.\Public\Remove-AADConnectDirectoryExtensionAttribute.ps1' -1

<#
.SYNOPSIS
    Removes a directory extension attribute from Azure AD Connect configuration.

.DESCRIPTION
    The Remove-AADConnectDirectoryExtensionAttribute function removes a directory extension attribute
    from the Azure AD Connect global settings. This function allows you to clean up unused or
    incorrectly configured directory extension attributes from the synchronization configuration.

    The function supports two parameter sets: specifying individual properties or providing a
    complete attribute string. It includes validation to ensure the attribute exists before removal.

    WARNING: Removing a directory extension attribute that is actively used in synchronization
    rules may cause synchronization errors. Ensure the attribute is not referenced before removal.

    This function requires Windows PowerShell 5.1 and does not work with PowerShell 7.

.PARAMETER Name
    Specifies the name of the directory extension attribute to remove. Must match exactly with
    an existing attribute name.

.PARAMETER Type
    Specifies the data type of the directory extension attribute to remove. Must match exactly
    with the existing attribute's type (String, Integer, Boolean, DateTime, etc.).

.PARAMETER AssignedObjectClass
    Specifies the object class of the directory extension attribute to remove. Must match exactly
    with the existing attribute's object class (user, group, contact, device, etc.).

.PARAMETER FullAttributeString
    Specifies a complete attribute definition string in the format:
    "attributeName.objectClass.dataType.enabledStatus"
    For example: "employeeNumber.user.String.True"

.EXAMPLE
    Remove-AADConnectDirectoryExtensionAttribute -Name "employeeNumber" -Type "String" -AssignedObjectClass "user"

    Removes the employee number directory extension attribute for user objects.

.EXAMPLE
    Remove-AADConnectDirectoryExtensionAttribute -FullAttributeString "departmentCode.user.String.True"

    Removes the department code directory extension attribute using the full attribute string format.

.EXAMPLE
    Get-AADConnectDirectoryExtensionAttribute -Name "obsolete*" | Remove-AADConnectDirectoryExtensionAttribute

    Removes all directory extension attributes with names starting with "obsolete".

.EXAMPLE
    $attribute = Get-AADConnectDirectoryExtensionAttribute -Name "tempAttribute"
    if ($attribute) {
        Remove-AADConnectDirectoryExtensionAttribute -Name $attribute.Name -Type $attribute.Type -AssignedObjectClass $attribute.AssignedObjectClass
    }

    Safely removes a directory extension attribute after verifying it exists.

.INPUTS
    PSCustomObject. You can pipe directory extension attribute objects from Get-AADConnectDirectoryExtensionAttribute.

.OUTPUTS
    None. This function does not return objects but modifies Azure AD Connect global settings.

.NOTES
    - This function requires Windows PowerShell 5.1 and does not work with PowerShell 7
    - Requires Azure AD Connect to be installed and the ADSync module to be available
    - Changes take effect immediately but may require synchronization cycle restart
    - Verify that the attribute is not used in synchronization rules before removal
    - Use Get-AADConnectDirectoryExtensionAttribute to verify the attribute was removed successfully
    - Removed attributes cannot be recovered; back up configuration before making changes

.LINK
    https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-sync-feature-directory-extensions

.COMPONENT
    AADConnectDsc

.FUNCTIONALITY
    Azure AD Connect Directory Extension Attribute Management
#>
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
                Write-Error "The attribute string did not have the correct format. Make sure it is like 'attributeName.group.String.True'"
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
#EndRegion '.\Public\Remove-AADConnectDirectoryExtensionAttribute.ps1' 139
#Region '.\Public\Write-AADConnectEventLog.ps1' -1

function Write-AADConnectEventLog
{
    <#
    .SYNOPSIS
        Writes event log entries for AADConnectDsc module operations.

    .DESCRIPTION
        This function writes event log entries to a dedicated AADConnectDsc event log.
        It automatically creates the event log and source if they don't exist.
        The function is designed to track DSC resource compliance state changes
        and provide audit trails for Azure AD Connect synchronization rule management.

    .PARAMETER EventType
        The type of event to log. Valid values are 'Information', 'Warning', 'Error'.

    .PARAMETER EventId
        The event ID for the log entry. This should be unique for different types of events.
        Predefined Event IDs:
        - 1000: Information - Sync rule is in desired state and compliant
        - 1001: Warning - Sync rule is absent but should be present
        - 1002: Warning - Sync rule is present but should be absent
        - 1003: Warning - Sync rule configuration drift detected
        - 2000: Information - Sync rule created successfully
        - 2001: Information - Sync rule updated successfully
        - 2002: Information - Standard sync rule disabled state changed
        - 2003: Information - Sync rule removed successfully

    .PARAMETER Message
        The message to write to the event log.

    .PARAMETER SyncRuleName
        The name of the sync rule associated with this event.

    .PARAMETER ConnectorName
        The name of the connector associated with this event.

    .PARAMETER Direction
        The direction of the sync rule (Inbound/Outbound).

    .PARAMETER TargetObjectType
        The target object type of the sync rule.

    .PARAMETER SourceObjectType
        The source object type of the sync rule.

    .PARAMETER Precedence
        The precedence value of the sync rule.

    .PARAMETER Disabled
        Whether the sync rule is disabled.

    .PARAMETER IsStandardRule
        Whether this is a Microsoft standard rule.

    .EXAMPLE
        Write-AADConnectEventLog -EventType 'Warning' -EventId 1001 -Message "Sync rule is absent but should be present" -SyncRuleName 'MyRule' -ConnectorName 'MyConnector' -Direction 'Inbound' -TargetObjectType 'person'

    .EXAMPLE
        Write-AADConnectEventLog -EventType 'Warning' -EventId 1002 -Message "Sync rule is present but should be absent" -SyncRuleName 'MyRule' -ConnectorName 'MyConnector' -Direction 'Outbound' -Disabled $false

    .EXAMPLE
        Write-AADConnectEventLog -EventType 'Information' -EventId 1000 -Message "Sync rule is in desired state" -SyncRuleName 'MyRule' -ConnectorName 'MyConnector' -Precedence 100 -IsStandardRule $false
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]
        $EventType,

        [Parameter(Mandatory = $true)]
        [int]
        $EventId,

        [Parameter(Mandatory = $true)]
        [string]
        $Message,

        [Parameter()]
        [string]
        $SyncRuleName,

        [Parameter()]
        [string]
        $ConnectorName,

        [Parameter()]
        [string]
        $Direction,

        [Parameter()]
        [string]
        $TargetObjectType,

        [Parameter()]
        [string]
        $SourceObjectType,

        [Parameter()]
        [int]
        $Precedence,

        [Parameter()]
        [bool]
        $Disabled,

        [Parameter()]
        [bool]
        $IsStandardRule,

        [Parameter()]
        [string]
        $Operation,

        [Parameter()]
        [int]
        $ScopeFilterCount,

        [Parameter()]
        [int]
        $JoinFilterCount,

        [Parameter()]
        [int]
        $AttributeFlowMappingCount,

        [Parameter()]
        [string]
        $RuleIdentifier
    )

    try
    {
        $logName = 'AADConnectDsc'
        $sourceName = 'AADConnectDsc'

        # Always write verbose output for debugging, even if event logging fails
        Write-Verbose "Attempting to write event log entry: EventType=$EventType, EventId=$EventId, SyncRule=$SyncRuleName"

        # Check if the event log exists, if not create it
        if (-not [System.Diagnostics.EventLog]::Exists($logName))
        {
            Write-Verbose "Event log '$logName' does not exist. Creating it now."
            try
            {
                New-EventLog -LogName $logName -Source $sourceName
                Write-Verbose "Event log '$logName' created successfully."
            }
            catch
            {
                Write-Warning "Failed to create event log '$logName': $($_.Exception.Message). This requires Administrator privileges."
                Write-Verbose "Event logging will be skipped. To enable event logging, run 'New-EventLog -LogName '$logName' -Source '$sourceName'' as Administrator."
                return
            }
        }
        elseif (-not [System.Diagnostics.EventLog]::SourceExists($sourceName))
        {
            Write-Verbose "Event source '$sourceName' does not exist in log '$logName'. Creating it now."
            try
            {
                New-EventLog -LogName $logName -Source $sourceName
                Write-Verbose "Event source '$sourceName' created successfully."
            }
            catch
            {
                Write-Warning "Failed to create event source '$sourceName': $($_.Exception.Message). This requires Administrator privileges."
                Write-Verbose "Event logging will be skipped. To enable event logging, run 'New-EventLog -LogName '$logName' -Source '$sourceName'' as Administrator."
                return
            }
        }

        # Build the complete message with context in multi-line format
        $contextMessage = $Message

        if ($SyncRuleName -or $ConnectorName -or $Direction -or $TargetObjectType -or $SourceObjectType)
        {
            $contextMessage += "`n`nSync Rule Details:"

            if ($SyncRuleName)
            {
                $contextMessage += "`n  Rule Name: $SyncRuleName"
            }

            if ($ConnectorName)
            {
                $contextMessage += "`n  Connector: $ConnectorName"
            }

            if ($Direction)
            {
                $contextMessage += "`n  Direction: $Direction"
            }

            if ($TargetObjectType)
            {
                $contextMessage += "`n  Target Object Type: $TargetObjectType"
            }

            if ($SourceObjectType)
            {
                $contextMessage += "`n  Source Object Type: $SourceObjectType"
            }

            if ($PSBoundParameters.ContainsKey('Precedence'))
            {
                $contextMessage += "`n  Precedence: $Precedence"
            }

            if ($PSBoundParameters.ContainsKey('Disabled'))
            {
                $contextMessage += "`n  Disabled: $Disabled"
            }

            if ($PSBoundParameters.ContainsKey('IsStandardRule'))
            {
                $ruleType = if ($IsStandardRule)
                {
                    'Microsoft Standard Rule'
                }
                else
                {
                    'Custom Rule'
                }
                $contextMessage += "`n  Rule Type: $ruleType"
            }

            if ($Operation)
            {
                $contextMessage += "`n  Operation: $Operation"
            }

            if ($RuleIdentifier)
            {
                $contextMessage += "`n  Rule Identifier: $RuleIdentifier"
            }

            # Add configuration complexity details for create/update operations
            if ($PSBoundParameters.ContainsKey('ScopeFilterCount'))
            {
                $contextMessage += "`n  Scope Filter Groups: $ScopeFilterCount"
            }

            if ($PSBoundParameters.ContainsKey('JoinFilterCount'))
            {
                $contextMessage += "`n  Join Filter Groups: $JoinFilterCount"
            }

            if ($PSBoundParameters.ContainsKey('AttributeFlowMappingCount'))
            {
                $contextMessage += "`n  Attribute Flow Mappings: $AttributeFlowMappingCount"
            }
        }

        # Write the event log entry
        try
        {
            Write-EventLog -LogName $logName -Source $sourceName -EventId $EventId -EntryType $EventType -Message $contextMessage
            Write-Verbose "✅ Event log entry written successfully: EventType=$EventType, EventId=$EventId, SyncRule=$SyncRuleName, Connector=$ConnectorName"
        }
        catch
        {
            Write-Warning "❌ Failed to write event log entry: $($_.Exception.Message). This typically requires Administrator privileges."
            Write-Verbose "To enable event logging, run PowerShell as Administrator or pre-create the event log with: New-EventLog -LogName '$logName' -Source '$sourceName'"

            # For debugging purposes, always log the event details to verbose output
            Write-Verbose 'Event details that would have been logged:'
            Write-Verbose "  EventType: $EventType"
            Write-Verbose "  EventId: $EventId"
            Write-Verbose "  Message: $contextMessage"
        }
    }
    catch
    {
        Write-Warning "❌ Event logging failed: $($_.Exception.Message)"
        Write-Verbose 'Event logging attempted but failed. DSC operation will continue normally.'
        # Don't throw - event logging should not break the main DSC operation
    }
}
#EndRegion '.\Public\Write-AADConnectEventLog.ps1' 280
