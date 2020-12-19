function Start-SleepProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [int]$Seconds,
        [string]$Activity='Sleeping',
        [string]$Status='Sleeping...'
    )

    # Because Write-Progress fouls up some automation environments, we're not
    # going to use it unless the user has explicitly requested it with an
    # environment variable.

    $now = Get-DateTimeOffsetNow
    $nextStatus = $now.AddSeconds(60)
    $end = $now.AddSeconds($Seconds)

    while ($end -gt $now) {
        $secLeft = [Math]::Round(($end-$now).TotalSeconds)

        if (-not [String]::IsNullOrEmpty($env:POSHACME_SHOW_PROGRESS)) {
            $percent = ($Seconds - $secLeft) / $Seconds * 100
            Write-Progress $Activity $Status -SecondsRemaining $secLeft -PercentComplete $percent
        }

        if ($now -gt $nextStatus) {
            Write-Verbose "$secLeft seconds remaining to sleep"
            $nextStatus = $now.AddSeconds(60)
        }

        Start-Sleep -Milliseconds 1000
        $now = Get-DateTimeOffsetNow
    }

    if (-not [String]::IsNullOrEmpty($env:POSHACME_SHOW_PROGRESS)) {
        Write-Progress $Activity $Status -SecondsRemaining 0 -Completed
    }
}
