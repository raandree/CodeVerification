function Get-FreeDiskSpace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DriveLetter
    )

    if ($DriveLetter -and -not (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -eq $DriveLetter })) {
        Write-Error "Drive letter '$DriveLetter' does not exist."
        return
    }
    else{
        Write-Host "Drive letter '$DriveLetter' exists."
    }

    if ($DriveLetter) {
        Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -eq $DriveLetter } | Select-Object Name, 
            @{Name="FreeSpace(GB)";Expression={[math]::round($_.Free/1GB,2)}}, 
            @{Name="UsedSpace(GB)";Expression={[math]::round(($_.Used/1GB),2)}}, 
            @{Name="TotalSize(GB)";Expression={[math]::round($_.Used/1GB + $_.Free/1GB,2)}} | 
            Format-Table -AutoSize
    } else {
        Get-PSDrive -PSProvider FileSystem | Select-Object Name, 
            @{Name="FreeSpace(GB)";Expression={[math]::round($_.Free/1GB,2)}}, 
            @{Name="UsedSpace(GB)";Expression={[math]::round(($_.Used/1GB),2)}}, 
            @{Name="TotalSize(GB)";Expression={[math]::round($_.Used/1GB + $_.Free/1GB,2)}} | 
            Format-Table -AutoSize
    }
}

# Call the function to display the disk space information
Get-FreeDiskSpace