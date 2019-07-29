function Start-PAHttpChallenge {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('domain', 'fqdn')]
        [String]$MainDomain,
        [Parameter()]
        [Alias('TTL')]
        [int16]$TimeToLive = 120,
        [Parameter()]
        [int16]$Port,
        [Parameter()]
        [ALias('NoFqdnBinding')]
        [switch]$NoPrefix
    )
    begin {
        # write information that verbose output of sub functions is surpassed.
        # did this because verbose output from api calls are unnecessarily filling the output
        Write-Verbose -Message ('INFO: Verbose messages for sub functions are suppressed.')
        # Make sure we have an account configured
        if (!(Get-PAAccount -Verbose:$false)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
        # account present, lets start
        # if TimeToLive is set to zero, write a warning
        if ($TimeToLive -eq 0) {
            Write-Warning -Message 'TimeToLive ist set to 0. If domain can''t be validated, listener will run infinitely until manually stopped'
        }
        # if fqdn binding is skipped, write warning that this may need admin rights
        if ($NoFqdnBinding) {
            Write-Warning -Message 'NoFqdnBinding is specified. THis may require Administrator rights.'
        }
        # set the prefix for verbose messages with time output
        [string]$logTimeFormat = '[HH:mm:ss]::'

        # set fqdn suffix for http listener
        if ($Port) {
            [string]$fqdnSuffix = (':{0}/' -f $Port)
        }
        else {
            [string]$fqdnSuffix = ('/' -f $Port)
        }

        # set TTL to at least 6 seconds to be sure at least one validation check can be executed
        if ($TimeToLive -ne 0 -and $TimeToLive -lt 6) {
            Write-Warning -Message ('Set TimeToLive from {0} to 6 seconds so validation check will be executed at least once' -f $TimeToLive)
            $TimeToLive = 6
        }
    }
    process {
        # (re)init prevRuntime
        [int16]$prevRunTime = 0
        # (re)init array for process loop
        [array]$openAuthorizations = @()
        # get all open authorizations if no MainDomain is given
        if (!$MainDomain) {
            # get pending PAOrder(s)
            [array]$openAuthorizations = Get-PAOrder -Verbose:$false |
                Get-PAAuthorizations -Verbose:$false |
                Where-Object { ($_.DNS01Status -eq 'pending') -and ( $_.HTTP01Status -eq 'pending')
            }
            # throw a terminating error - no authorizations, nothing to do
            if (!($openAuthorizations)) {
                throw 'No open PAOrder(s) found.'
            }
        }
        # if MainDomain is given set array
        else {
            # check if parameter is maindomain or san
            if (Get-PAOrder -MainDOmain $MainDomain) {
            }
            elseif ((Get-PAOrder).SANs -contains $MainDomain) {
                # parameter is SAN get MainDomain
                $trueMainDomain = Get-PAOrder -Verbose:$false |
                    Where-Object -FilterScript {$_.SANs -contains $MainDomain} |
                    Select-Object -ExpandProperty 'MainDomain'
                Write-Warning -Message ('{0} is a SAN, setting MainDomain to {1} and continue processing all pending requests for MainDomain' -f $MainDomain, $trueMainDomain)
                $MainDomain = $trueMainDomain
            }
            else {
                # nothing found, throw out, message is handled witch catch
                throw
            }

            # get pending PAOrder for given/fetched MainDomain.
            [array]$openAuthorizations = Get-PAOrder -MainDomain $MainDomain -Verbose:$false |
                Get-PAAuthorizations -Verbose:$false |
                Where-Object {
                ( $_.HTTP01Status -eq 'pending')
            }

            # if array is empty, write non terminating error and continue with process loop
            if (!($openAuthorizations)) {
                Write-Error -Message ('no pending challenge found for Domain "{0}"' -f $MainDomain)
                return
            }
        }
        Write-verbose -Message ('found {0} authorizations with HTTP01Status pending' -f $openAuthorizations.Count)
        # create array with all necessary information for http listener
        [array]$httpPublish = $openAuthorizations |
            Select-Object `
        @{L = 'fqdn'; E = {$_.fqdn}}`
            , 'HTTP01Url'`
            , 'HTTP01Token'`
            , @{L = 'subUrl'; E = { ('/.well-known/acme-challenge/{0}' -f $_.HTTP01Token) } }`
            , @{L = 'Body'; E = { Get-KeyAuthorization $_.HTTP01Token (Get-PAAccount) -Verbose:$false } }
        #region initialize and start WebServer
        try {
            # create http listener
            $httpListener = [System.Net.HttpListener]::new()

            # add listener Prefixes
            if ($NoPrefix) {
                $httpListener.Prefixes.Add(('http://*{0}' -f $fqdnSuffix))
            }
            else {
                foreach ($domain in $httpPublish) {
                    $httpListener.Prefixes.Add(('http://{0}{1}' -f $domain.fqdn, $fqdnSuffix))
                }
            }
            # start the listener
            $httpListener.Start()
        }
        catch {
            $errorMSG = $_
            Write-Error -Message ('WebServer start failed! ({0})' -f $errorMSG)
            continue listenerLoop
        }
        # set start and end time based on TTL
        [dateTime]$startTime = Get-Date
        [dateTime]$endTime = $startTime.AddSeconds($TimeToLive)

        # generate RegEx from fqdn(s) for matching in listener validation
        [regex]$regexFqdn = $httpPublish.fqdn -Join '|'

        # generate RegEx from subUrl(s) for matching in listener
        [regex]$regexSubUrl = $httpPublish.subUrl -Join '|'

        # time to interact with the listener
        Write-verbose -Message ('{0}httpListener started with {1} seconds timeout' -f $(Get-Date -Format $logTimeFormat), $TimeToLive)
        foreach ($preFix in $httpListener.Prefixes) {
            Write-Verbose -Message ('   {0}' -f $preFix)
        }

        try {
            # inform ACME server that challenge is ready  - suppress verbose output, it just fills the console
            Write-verbose -Message ('{0}Send-ChallengeAck to' -f $(Get-Date -Format $logTimeFormat), ($httpPublish.HTTP01Url -join ','))
            foreach ($HTTP01Url in $httpPublish.HTTP01Url) {
                Write-Verbose -Message ('   {0}' -f $HTTP01Url)
            }
            $null = $httpPublish.HTTP01Url | Send-ChallengeAck -Verbose:$false

            # enter listening loop - as long as listener is listening this loops run
            while ($httpListener.IsListening) {
                # get context async so we can do other logic while listener is running
                $contextTask = $httpListener.GetContextAsync()

                # other logic
                while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {
                    # get runtime in seconds
                    [int16]$runTime = $TimeToLive - (New-TimeSpan -Start (Get-Date) -End $endTime).TotalSeconds.ToString("00")

                    # process timeout - if timeout is 0 server runs until challenge is valid
                    if (($TimeToLive -ne 0) -and ($endTime -lt (Get-Date))) {
                        Write-verbose -Message ('{0}timeout reached, stopping httpListener' -f $(Get-Date -Format $logTimeFormat))
                        $httpListener.Stop()
                        return
                    }

                    # check challenge state every 5 seconds- suppress verbose output, it just fills the console
                    if ($prevRunTime -ne $runTime -and $runTime % 5 -eq 0) {
                        # write current Runtime to variable to avoid multi checks
                        $prevRunTime = $runTime
                        Write-verbose ('{0}checking HTTP01Status' -f $(Get-Date -Format $logTimeFormat))
                        [array]$validatedAuthorizations = Get-PAOrder -Refresh -MainDomain $MainDomain -Verbose:$false |
                            Get-PAAuthorizations -Verbose:$false |
                            Where-Object -FilterScript {
                            ($_.fqdn -match $regexFqdn) -and ($_.HTTP01Status -eq 'valid')
                        }

                        if ($validatedAuthorizations.Count -eq $httpPublish.Count) {
                            Write-verbose -Message ('{0}challenge succeeded, stopping httpListener' -f $(Get-Date -Format $logTimeFormat))
                            $httpListener.Stop()
                            return
                        }
                    }
                }
                # get actual request context
                $context = $contextTask.GetAwaiter().GetResult()
                # short - if requested url matches answer
                if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -match $regexSubUrl) {
                    $responseData = $httpPublish | Where-Object -FilterScript {$_.subUrl -eq $($context.Request.RawUrl)}

                    # verbose out response
                    Write-verbose -Message ('{0}sending challenge {1} to {2}' -f $(Get-Date -Format $logTimeFormat), $responseData.HTTP01Token, $context.Request.RemoteEndPoint )
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
                    Write-verbose -Message ('{0}invalid path request from {1} to {2}' -f $(Get-Date -Format $logTimeFormat), $context.Request.RemoteEndPoint, $context.Request.Url )
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
            Write-Error -Message ('httpListener failed! ({0})' -f $errorMSG)
        }
        finally {
            # initial integration to capture CTRL+C and stop listener - will also fetch unexpected behavior
            if ($httpListener.IsListening) {
                Write-verbose -Message ('script abortion or unexpected behavior, stopping httpListener')
                $httpListener.Stop()
            }
            # return PAAuthorizations for MainDomain if output may be used in a variable/pipe
            Write-Output -InputObject (
                Get-PAOrder -MainDomain $MainDomain -Refresh -Verbose:$false |
                    Get-PAAuthorizations -Verbose:$false
            )
        }
    }
    end {}

    <#
        .SYNOPSIS
        Starts a local HTTP Listener for pending HTTP01Status acme challenges.

        .DESCRIPTION
        Uses [System.Net.HttpListener] class to open a http listener for pending http challenges.
        If parameter MainDOmain is not specified, all open Orders are fetched with Get-PAOrder.
        Is a SAN is given in parameter MainDomain, the actual MainDomain will be fetched and
        http listener will process MainDOmain and all SAN(s).

        .PARAMETER MainDomain
        The primary domain associated with an order.

        .PARAMETER TimeToLive
        The TimeOut in Seconds for the Webserver. WHen Timout is reached http listener stops, regardless of HTTP01Status.

        .PARAMETER Port
        The Port on which http listener is listening.

        .PARAMETER NoPrefix
        If parameter is set, http listener will bind on http://*

        .EXAMPLE
        Start-PAHttpChallenge

        Start http listener for all orders with HTTP01Status pending

        .EXAMPLE
        Start-PAHttpChallenge -MainDomain 'test.example.com' -Port 8080 -TimeToLive 30

        Start http listener for domain 'test.example.com' on Port 8080 with a Timeout of 30 seconds.
        If 'test.example.com' is a SAN, Start-PAHttpChallenge will fetch the MainDomain and process
        the MainDomain and all SAN(s).

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