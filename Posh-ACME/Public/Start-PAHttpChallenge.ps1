function Start-PAHttpChallenge {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('domain', 'fqdn')]
        [string]$MainDomain,
        [Parameter()]
        [Alias('TTL')]
        [int]$TimeToLive = 120,
        [Parameter()]
        [ValidateRange(1,65535)]
        [int]$Port,
        [Parameter()]
        [string[]]$ListenerPrefixes
    )

    Begin {

        # write information that verbose output of sub functions is surpassed.
        # did this because verbose output from api calls are unnecessarily filling the output
        Write-Verbose 'Verbose messages for sub functions are suppressed.'
        # Make sure we have an account configured
        if (!(Get-PAAccount -Verbose:$false)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }

        # account present, lets start
        # if TimeToLive is set to zero, write a warning
        if ($TimeToLive -eq 0) {
            Write-Warning 'TimeToLive is set to 0. If domain can''t be validated, listener will run indefinitely or until manually stopped.'
        }

        # set the prefix for verbose messages with time output
        $logTimeFormat = '[HH:mm:ss]::'

        # set port suffix for http listener
        $portSuffix = '/'
        if ($Port) {
            $portSuffix = ':{0}/' -f $Port
        }

        # set TTL to at least 6 seconds to be sure at least one validation check can be executed
        if ($TimeToLive -ne 0 -and $TimeToLive -lt 6) {
            Write-Warning ('Set TimeToLive from {0} to 6 seconds so validation check will be executed at least once' -f $TimeToLive)
            $TimeToLive = 6
        }
    }

    Process {

        # init prevRuntime
        $prevRunTime = 0

        # get a reference to the order we're going to use
        if (-not $MainDomain) {
            # grab the current order and set $MainDomain
            $order = Get-PAOrder -Verbose:$false
            $MainDomain = $order.MainDomain
        }
        else {
            # try to get the order specified by $MainDomain
            if (-not ($order = Get-PAOrder -MainDomain $MainDomain)) {
                throw "No order found for domain $MainDomain"
            }
        }

        # get pending authorizations for the order
        $openAuthorizations = @($order | Get-PAAuthorizations -Verbose:$false |
            Where-Object { $_.status -eq 'pending' -and $_.HTTP01Status -eq 'pending' })

        # return if there's nothing to do
        if ($openAuthorizations.Count -eq 0) {
            Write-Warning "No pending authorizations found for Domain `"$MainDomain`""
            return
        }
        Write-Verbose ('Found {0} authorizations with HTTP01Status pending' -f $openAuthorizations.Count)

        # create array with all necessary information for http listener
        [array]$httpPublish = $openAuthorizations | Select-Object `
            @{L = 'fqdn'; E = {$_.fqdn}},
            'HTTP01Url',
            'HTTP01Token',
            @{L = 'subUrl'; E = { ('/.well-known/acme-challenge/{0}' -f $_.HTTP01Token) } },
            @{L = 'Body'; E = { Get-KeyAuthorization $_.HTTP01Token (Get-PAAccount) -Verbose:$false } }

        # initialize and start WebServer
        try {
            # create http listener
            $httpListener = [System.Net.HttpListener]::new()

            # add listener prefix(es)
            if (-not $ListenerPrefixes) {
                $prefix = 'http://*{0}' -f $portSuffix
                Write-Verbose "Adding listener prefix $prefix"
                $httpListener.Prefixes.Add($prefix)
            }
            else {
                foreach ($prefix in $ListenerPrefixes) {
                    Write-Verbose "Adding listener prefix $prefix"
                    $httpListener.Prefixes.Add($prefix)
                }
            }

            # start the listener
            $httpListener.Start()
        }
        catch { throw }

        # set start and end time based on TTL
        [dateTime]$startTime = Get-Date
        [dateTime]$endTime = $startTime.AddSeconds($TimeToLive)

        # generate RegEx from fqdn(s) for matching in listener validation
        [regex]$regexFqdn = $httpPublish.fqdn -Join '|'

        # generate RegEx from subUrl(s) for matching in listener
        [regex]$regexSubUrl = $httpPublish.subUrl -Join '|'

        # time to interact with the listener
        Write-Verbose ('{0}httpListener started with {1} seconds timeout' -f $(Get-Date -Format $logTimeFormat), $TimeToLive)
        foreach ($preFix in $httpListener.Prefixes) {
            Write-Verbose ('   {0}' -f $preFix)
        }

        try {
            # inform ACME server that challenge is ready  - suppress verbose output, it just fills the console
            Write-Verbose ('{0}Send-ChallengeAck to' -f $(Get-Date -Format $logTimeFormat), ($httpPublish.HTTP01Url -join ','))
            foreach ($HTTP01Url in $httpPublish.HTTP01Url) {
                Write-Verbose ('   {0}' -f $HTTP01Url)
            }
            $null = $httpPublish.HTTP01Url | Send-ChallengeAck -Verbose:$false

            # enter listening loop - as long as listener is listening this loops run
            while ($httpListener.IsListening) {
                # get context async so we can do other logic while listener is running
                $contextTask = $httpListener.GetContextAsync()

                # other logic
                while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {
                    # get runtime in seconds
                    $runTime = $TimeToLive - ([Math]::Round( ((Get-Date) - $endTime).TotalSeconds, 0))

                    # process timeout - if timeout is 0 server runs until challenge is valid
                    if (($TimeToLive -ne 0) -and ($endTime -lt (Get-Date))) {
                        Write-Verbose ('{0}timeout reached, stopping httpListener' -f $(Get-Date -Format $logTimeFormat))
                        $httpListener.Stop()
                        return
                    }

                    # check challenge state every 5 seconds- suppress verbose output, it just fills the console
                    if ($prevRunTime -ne $runTime -and $runTime % 5 -eq 0) {
                        # write current Runtime to variable to avoid multi checks
                        $prevRunTime = $runTime
                        Write-Verbose ('{0}checking HTTP01Status' -f $(Get-Date -Format $logTimeFormat))
                        [array]$validatedAuthorizations = Get-PAOrder -Refresh -MainDomain $MainDomain -Verbose:$false |
                            Get-PAAuthorizations -Verbose:$false |
                            Where-Object { ($_.fqdn -match $regexFqdn) -and ($_.HTTP01Status -eq 'valid') }

                        if ($validatedAuthorizations.Count -eq $httpPublish.Count) {
                            Write-Verbose ('{0}challenge succeeded, stopping httpListener' -f $(Get-Date -Format $logTimeFormat))
                            $httpListener.Stop()
                            return
                        }
                    }
                }

                # get actual request context
                $context = $contextTask.GetAwaiter().GetResult()

                # short - if requested url matches answer
                if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -match $regexSubUrl) {
                    $responseData = $httpPublish | Where-Object { $_.subUrl -eq $($context.Request.RawUrl) }

                    # verbose out response
                    Write-Verbose ('{0}sending challenge {1} to {2}' -f $(Get-Date -Format $logTimeFormat), $responseData.HTTP01Token, $context.Request.RemoteEndPoint )
                    #respond to the request
                    $context.Response.Headers.Add("Content-Type", "text/plain")
                    $context.Response.StatusCode = 200
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData.Body)
                    $context.Response.ContentLength64 = $buffer.Length
                    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $context.Response.OutputStream.Close()
                }
                # response to invalid path (primarily for verbose output)
                else {
                    # verbose out response
                    Write-Verbose ('{0}invalid path request from {1} to {2}' -f $(Get-Date -Format $logTimeFormat), $context.Request.RemoteEndPoint, $context.Request.Url )
                    #respond to the request
                    $context.Response.Headers.Add("Content-Type", "text/plain")
                    $context.Response.StatusCode = 404
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes('')
                    $context.Response.ContentLength64 = $buffer.Length
                    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $context.Response.OutputStream.Close()
                }
            }
        }
        catch {
            $errorMSG = $_
            Write-Error ('httpListener failed! ({0})' -f $errorMSG)
        }
        finally {

            # initial integration to capture CTRL+C and stop listener - will also fetch unexpected behavior
            if ($httpListener.IsListening) {
                Write-Verbose ('script abortion or unexpected behavior, stopping httpListener')
                $httpListener.Stop()
            }

            # dispose if necessary
            if ($null -ne $httpListener) {
                $httpListener.Dispose()
            }

            # return PAAuthorizations for MainDomain if output may be used in a variable/pipe
            Get-PAOrder -MainDomain $MainDomain -Refresh -Verbose:$false |
                Get-PAAuthorizations -Verbose:$false
        }
    }

    <#
    .SYNOPSIS
        Starts a local web server to answer pending http-01 ACME challenges.

    .DESCRIPTION
        Uses [System.Net.HttpListener] class to answer http-01 ACME challenges for the
        current or specified order. If MainDomain is not specified, the current Order is used.

    .PARAMETER MainDomain
        The primary domain associated with an order.

    .PARAMETER TimeToLive
        The timeout in seconds for the webserver. When reached, the http listener stops regardless of HTTP01Status.

    .PARAMETER Port
        The TCP port on which the http listener is listening. 80 by default.

    .PARAMETER ListenerPrefixes
        By default, the http listener will use a wildcard prefix that should match all incoming requests. For advanced usage, you can specify a list of prefixes to use instead. Make sure to include a trailing '/' on all of them. See https://docs.microsoft.com/en-us/dotnet/api/system.net.httplistener for details.

    .EXAMPLE
        Start-PAHttpChallenge

        Start http listener for pending challenges on the current order.

    .EXAMPLE
        Start-PAHttpChallenge -MainDomain 'test.example.com' -Port 8080 -TimeToLive 30

        Start http listener for domain 'test.example.com' on Port 8080 with a Timeout of 30 seconds.

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
