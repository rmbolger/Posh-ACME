function Start-SleepProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [int]$Seconds,
        [string]$Activity='Sleeping',
        [string]$Status='Sleeping...'
    )

    $end = (Get-DateTimeOffsetNow).AddSeconds($Seconds)

    while ($end -gt (Get-DateTimeOffsetNow)) {
        $secLeft = ($end - (Get-DateTimeOffsetNow)).TotalSeconds
        $percent = ($Seconds - $secLeft) / $Seconds * 100
        Write-Progress $Activity $Status -SecondsRemaining $secLeft -PercentComplete $percent
        Start-Sleep -Milliseconds 500
    }
    Write-Progress $Activity $Status -SecondsRemaining 0 -Completed
}
