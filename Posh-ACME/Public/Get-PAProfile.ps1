function Get-PAProfile {
    [CmdletBinding()]
    [OutputType('PoshACME.PAProfile')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable','')]
    param(
        [string]$Profile
    )

    Begin {
        # make sure we have a server configured
        if (-not ($server = Get-PAServer)) {
            try { throw "No ACME server configured. Run Set-PAServer first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }
    }

    Process {

        # https://letsencrypt.org/2025/01/09/acme-profiles/
        # https://www.ietf.org/archive/id/draft-aaron-acme-profiles-00.html

        if (-not $server.meta.profiles) {
            return
        }

        # We want to return the data as a list instead of the monolithic object
        # the JSON converts to where each profile name is a property
        $profObj = $server.meta.profiles
        foreach ($profName in $profObj.PSObject.Properties.Name) {
            if (-not $Profile -or $Profile -eq $profName) {
                [pscustomobject]@{
                    PSTypeName = 'PoshACME.PAProfile'
                    Profile = $profName
                    ProfileDescription = $profObj.$profName
                }
            }
        }
    }
}
