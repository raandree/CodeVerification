#Region './Private/Task.Create_AzureDevOps_Release.ps1' 0
<#
    .SYNOPSIS
        This is the alias to the meta build task Task.Create_AzureDevOps_Release's
        script file.

    .DESCRIPTION
        This makes available the alias 'Task.Create_AzureDevOps_Release' that
        is exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Create_AzureDevOps_Release' -Value "$PSScriptRoot/tasks/Create_AzureDevOps_Release.build.ps1"
#EndRegion './Private/Task.Create_AzureDevOps_Release.ps1' 17
#Region './Private/Task.Create_PR_From_SourceBranch.ps1' 0
<#
    .SYNOPSIS
        This is the alias to the build task Create_PR_From_SourceBranch's
        script file.

    .DESCRIPTION
        This makes available the alias 'Task.Create_PR_From_SourceBranch' that
        is exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Create_PR_From_SourceBranch' -Value "$PSScriptRoot/tasks/Create_PR_From_SourceBranch.build.ps1"
#EndRegion './Private/Task.Create_PR_From_SourceBranch.ps1' 17
#Region './Public/Invoke-AzureDevOpsTasksGit.ps1' 0
<#
    .SYNOPSIS
        Executes git with the provided arguments.

    .DESCRIPTION
        This command executes git with the provided arguments and throws an error
        if the call failed.

    .PARAMETER Argument
        Specifies the arguments to call git with. It is passes as an array of strings,
        e.g. @('tag', 'v2.0.0').

    .EXAMPLE
        Invoke-AzureDevOpsTasksGit -Argument @('config', 'user.name', 'MyName')

        Calls git to set user name in the git config.

    .NOTES
        Git does not throw an error that can be caught by the pipeline. For example
        this git command error but does not throw 'hello' as one would expect.
        ```
        PS> try { git describe --contains } catch { throw 'hello' }
        fatal: cannot describe '144e0422398e89cc8451ebba738c0a410b628302'
        ```
        So we have to determine if git worked or not by checking the last exit code
        and then throw an error to stop the pipeline.
#>
function Invoke-AzureDevOpsTasksGit
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Argument
    )

    # The catch is triggered only if 'git' can't be found.
    try
    {
        & git $Argument
    }
    catch
    {
        throw $_
    }

    <#
        This will trigger an error if git returned an error code from the above
        execution. Git will also have outputted an error message to the console
        so we just need to throw a generic error.
    #>
    if ($LASTEXITCODE)
    {
        throw "git returned exit code $LASTEXITCODE indicated failure."
    }
}
#EndRegion './Public/Invoke-AzureDevOpsTasksGit.ps1' 57
