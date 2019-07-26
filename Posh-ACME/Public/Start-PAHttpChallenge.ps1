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
        [switch]$NoPrefix
    )

    begin {
        # if TImeToLive is set to zero, write a warning
        if($TimeToLive -eq 0) {
            Write-Warning -Message 'TimeToLive ist set to 0. If domain can''t be validated, listener will run infinitely until manually stopped'
        }
        # set the prefix for verbose messages with time output
        [string]$logTimeFormat = '[HH:mm:ss]::'

        # write information that verbose output of sub functions is surpassed.
        # did this because verbose output from api calls are unnecessarily filling the output
        Write-Verbose -Message ('INFO: Verbose messages for sub functions are suppressed.')
        # Make sure we have an account configured
        if (!(Get-PAAccount -Verbose:$false)) {
            throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first."
        }
    }

    process {
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
        # loop through array of open authorizations
        :listenerLoop foreach ($openAuthorization in $openAuthorizations) {
            # create variable with all necessary information for http listener
            $httpPublish = $openAuthorization |
                Select-Object 'HTTP01Token'`
                , @{L = 'MainDomain'; E = {$_.fqdn}}`
                , 'HTTP01Url'`
                , @{L = 'Body'; E = { Get-KeyAuthorization $_.HTTP01Token (Get-PAAccount) -Verbose:$false } }

            # set web path to token file
            [string]$uriPath = ('/.well-known/acme-challenge/{0}' -f $httpPublish.HTTP01Token)

            #region initialize and start WebServer
            try {
                # create http listener
                $httpListener = [System.Net.HttpListener]::new()

                # set binding of http listener based on NoPrefix switch
                # main purpose for testing, may help in some productive environments
                if ($NoPrefix) {
                    [string]$bindingMainDomain = '*'
                }
                else {
                    [string]$bindingMainDomain = $httpPublish.MainDomain
                }

                # set binding, if no port is specified do not explicitly set port (more beautiful log/verbose/....)
                if (!$Port) {
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
                continue listenerLoop
            }
            # set listening URL - trim start to avoid double // in listener URI
            [string]$httpListenerUri = ('{0}{1}' -f $($httpListener.Prefixes), $uriPath.TrimStart('/'))
            # set start and end time based on TTL
            [dateTime]$startTime = Get-Date
            [dateTime]$endTime = $startTime.AddSeconds($TimeToLive)

            # time to interact with the listener
            Write-verbose -Message ('{0}httpListener started with {1} seconds timeout' -f $(Get-Date -Format $logTimeFormat), $TimeToLive)
            Write-verbose -Message ('{0}' -f $httpListenerUri)

            try {
                # inform ACME server that challenge is ready  - suppress verbose output, it just fills the console
                Write-verbose -Message ('{0}Send-ChallengeAck to {1}' -f $(Get-Date -Format $logTimeFormat), $httpPublish.HTTP01Url)
                $null = Send-ChallengeAck $httpPublish.HTTP01Url -Verbose:$false

                # enter listening loop - as long as listener is listening this loops run
                while ($httpListener.IsListening) {

                    # get context async so we can do other logic while listener is running
                    $contextTask = $httpListener.GetContextAsync()

                    # other logic
                    while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {
                        # get runtime in seconds
                        $runTime = $TimeToLive - (New-TimeSpan -Start (Get-Date) -End $endTime).TotalSeconds.ToString("00")
                        # write progressbar with timout so we don't sit in the dark while listener is running
                        if ($TimeToLive -ne 0) {
                            Write-Progress -Activity 'http listener' -Status $httpListenerUri -CurrentOperation 'waiting for validation' -PercentComplete (($runTime / $TimeToLive) * 100)
                        }
                        # process timeout - if timeout is 0 server runs until challenge is valid
                        if (($TimeToLive -ne 0) -and ($endTime -lt (Get-Date))) {
                            Write-verbose -Message ('{0}timeout reached, stopping WebServer' -f $(Get-Date -Format $logTimeFormat))
                            $httpListener.Stop()
                            # return to foreach loop
                            continue listenerLoop
                        }
                        # check challenge state ever 5 seconds- suppress verbose output, it just fills the console
                        if (($runTime % 5) -eq $false) {
                            Write-verbose ('{0}checking HTTP01Status for {1}' -f $(Get-Date -Format $logTimeFormat), $httpPublish.MainDomain)
                            if ($(Get-PAOrder -Refresh -Verbose:$false |
                                        Get-PAAuthorizations -Verbose:$false |
                                        Where-Object -FilterScript {$_.fqdn -eq $httpPublish.MainDomain} |
                                        Select-Object -ExpandProperty 'HTTP01Status'
                                ) -eq 'valid') {
                                Write-verbose -Message ('{0}challenge succeeded, stopping WebServer' -f $(Get-Date -Format $logTimeFormat))
                                $httpListener.Stop()
                                # return to foreach loop
                                continue listenerLoop
                            }
                        }
                    }

                    # get actual request context
                    $context = $contextTask.GetAwaiter().GetResult()

                    # short - if requested url matches answer
                    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq $uriPath) {
                        # verbose out response
                        Write-verbose -Message ('{0}challenge sent to {1}' -f $(Get-Date -Format $logTimeFormat), $context.Request.UserHostAddress )

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
                        Write-verbose -Message ('{0}invalid path request from {1} to {2}' -f $(Get-Date -Format $logTimeFormat), $context.Request.UserHostAddress, $context.Request.Url )

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
            }
            finally {
                # initial integration to capture CTRL+C and stop listener - will also fetch unexpected behavior
                if ($httpListener.IsListening) {
                    Write-verbose -Message ('script abortion or unexpected behavior, stopping httpListener')
                    $httpListener.Stop()
                }
            }
        }
    }
    end {
        # finished, New-PACertificate can be executed. Return PAAuthorizations for MainDomain if output may be used in a variable/pipe
        return (
            Get-PAOrder -MainDomain $MainDomain -Refresh -Verbose:$false |
                Get-PAAuthorizations -Verbose:$false
        )
    }





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