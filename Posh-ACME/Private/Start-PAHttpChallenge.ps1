function Start-PAHttpChallenge {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('domain','fqdn')]
        [String]$MainDomain,
        [Parameter()]
        [Alias('TTL')]
        [int16]$TimeToLive = 30,
        [Parameter()]
        [int16]$Port = 80,
        [Parameter()]
        [switch]$NoMainDomainBinding
    )

    begin {
        # Make sure we have an account configured
        if (!(Get-PAAccount)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    process {
        # (re)init array for process loop
        [array]$openAuthorizations = @()
        # get all open authorizations if no MainDomain is given
        if (!$MainDomain) {
            # get pending PAOrder(s)
            [array]$openAuthorizations = Get-PAOrder | Get-PAAuthorizations | Where-Object { ($_.DNS01Status -eq 'pending') -and ( $_.HTTP01Status -eq 'pending') }

            # throw a terminating error - no authorizations, nothing to do
            if (!($openAuthorizations)) {
                throw 'No open PAOrder(s) found.'
            }
        }
        # if MainDomain is given set array
        else {
            # get pending PAOrder for given MainDomain
            [array]$openAuthorizations = Get-PAOrder -MainDomain $MainDomain | Get-PAAuthorizations | Where-Object { ($_.DNS01Status -eq 'pending') -and ( $_.HTTP01Status -eq 'pending') }

            # if array is empty, write non terminating error and continue with process loop
            if (!($openAuthorizations)) {
                Write-Error -Message ('no pending challenge found for "{0}"' -f $MainDomain)
                return
            }
        }

        # loop through array (needed for processing function call without given MainDomain)
        foreach ($openAuthorization in $openAuthorizations) {
            # create variable with all necessary information for http listener
            $httpPublish = $openAuthorization | Select-Object `
                'HTTP01Token'`
                , @{L = 'MainDomain'; E = {$_.fqdn}}`
                , 'HTTP01Url'`
                , @{L = 'Body'; E = { Get-KeyAuthorization $_.HTTP01Token (Get-PAAccount) } }

            # set path to token file
            [string]$uriPath = ('/.well-known/acme-challenge/{0}' -f $httpPublish.HTTP01Token)

            #region initialize and start WebServer
            try {
                # create http listener
                $httpListener = [System.Net.HttpListener]::new()

                # set binding of http listener based on NoMainDomainBinding switch - main purpose for testing, may help in some productive environments
                if ($NoMainDomainBinding) {
                    [string]$bindingMainDomain = '*'
                }
                else {
                    # set from $httpPublish.MainDomain to * - why ever i get errors since function rework and setting a prefix other than localhost/*
                    [string]$bindingMainDomain = '*'
                }

                # set binding, if port is 80 do not explicitly set port (more beautiful log/verbose/....)
                if ($Port -eq 80) {
                    $httpListener.Prefixes.Add(('http://{0}/' -f $bindingMainDomain))
                }
                else {
                    $httpListener.Prefixes.Add(('http://{0}:{1}/' -f $bindingMainDomain, $Port))
                }
                # start the listener
                $httpListener.Start()
            }
            catch {
                $errorMSG = $_
                Write-Error -Message ('WebServer start failed! ({0})' -f $errorMSG)
                return $httpPublish
            }
            # set listening URL - trim start to avoid double // in listener URI
            [string]$httpListenerUri = ('{0}{1}' -f $($httpListener.Prefixes), $uriPath.TrimStart('/'))
            # set start and end time based on TTL
            [dateTime]$startTime = Get-Date
            [dateTime]$endTime = $startTime.AddSeconds($TimeToLive)

            # time to interact with the listener
            Write-Verbose -Message ('httpListener "{0}" started with {1} seconds timeout' -f $httpListenerUri, $TimeToLive)

            try {
                # inform ACME server that challenge is ready  - suppress verbose output, it just fills the console
                Write-Verbose -Message ('{0}Send-ChallengeAck to {1}' -f $(Get-Date -Format '[HH:mm:ss]::'), $httpPublish.HTTP01Url)
                $null = Send-ChallengeAck $httpPublish.HTTP01Url -Verbose:$false

                # enter listening loop - as long as listener is listening this loops run
                while ($httpListener.IsListening) {

                    # get context async so we can do other logic while listener is running
                    $contextTask = $httpListener.GetContextAsync()

                    # other logic
                    while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {
                        # process timeout - if timeout is 0 server runs until challenge is valid
                        if (($TimeToLive -ne 0) -and ($endTime -lt (Get-Date))) {
                            Write-Verbose -Message ('{0}timeout reached, stopping WebServer' -f $(Get-Date -Format '[HH:mm:ss]::'))
                            $httpListener.Stop()
                            return
                        }
                        # check challenge state - suppress verbose output, it just fills the console
                        if ($(Get-PAOrder -MainDomain $httpPublish.MainDomain -Refresh -Verbose:$false | Select-Object -ExpandProperty 'status') -eq 'valid') {
                            Write-Verbose -Message ('{0}challenge succeeded, stopping WebServer' -f $(Get-Date -Format '[HH:mm:ss]::'))
                            $httpListener.Stop()
                            return
                        }
                    }

                    # get actual request context
                    $context = $contextTask.GetAwaiter().GetResult()

                    # short - if requested url matches answer
                    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq $uriPath) {
                        # verbose out response
                        Write-Verbose -Message ('{0}challenge sent to {1}' -f $(Get-Date -Format '[HH:mm:ss]::'), $context.Request.UserHostAddress )

                        #respond to the request
                        $context.Response.Headers.Add("Content-Type", "text/plain")
                        $context.Response.StatusCode = 200
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($httpPublish.Body) # convert string to bytes
                        $context.Response.ContentLength64 = $buffer.Length
                        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to browser
                        $context.Response.OutputStream.Close() # close the response
                    }
                    # response to invalid path (primarily for verbose output)
                    else {
                        # verbose out response
                        Write-Verbose -Message ('{0}invalid path request from {1} to {2}' -f $(Get-Date -Format '[HH:mm:ss]::'), $context.Request.UserHostAddress, $context.Request.Url )

                        #respond to the request
                        $context.Response.Headers.Add("Content-Type", "text/plain")
                        $context.Response.StatusCode = 404
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes('')
                        $context.Response.ContentLength64 = $buffer.Length
                        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to browser
                        $context.Response.OutputStream.Close() # close the response
                    }
                }
            }
            catch {
                $errorMSG = $_
                Write-Error -Message ('httpListener failed! ({0})' -f $errorMSG)
                return
            }
            finally {
                # initial integration to capture CTRL+C and stop listener - may also fetch unexpected behavior
                if ($httpListener.IsListening) {
                    Write-Verbose -Message ('script abortion or unexpected behavior, stopping httpListener')
                    $httpListener.Stop()
                }
            }
        }
    }
    end {
        # finished, New-PACertificate can be executed. Return PAAuthorizations if output may be used in a variable/pipe
        return {Get-PAOrder -Refresh | Get-PAAuthorizations}
    }





    <#
        .SYNOPSIS
        tba

        .DESCRIPTION
        tba

        .PARAMETER MainDomain
        The primary domain associated with an order.

        .PARAMETER TimeToLive
        tba

        .PARAMETER Port
        tba

        .PARAMETER NoMainDomainBinding
        tba

        .EXAMPLE
        A sample command that uses the function or script, optionally followed by sample output and a description. Repeat this keyword for each example.

        .LINK
        Project: https://github.com/rmbolger/Posh-ACME

        .LINK
        Get-PAAccount

        .LINK
        Get-PAOrder

        .LINK
        Get-PAAuthorizations
    #>
}