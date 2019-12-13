function Get-CurrentPluginType { 'http-01' }

function Add-HttpChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [string]$Token,
        [Parameter(Mandatory,Position=2)]
        [string]$Body,
        [string]$WSHPort,
        [int]$WSHTimeout = 120,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Even though we're not directly using the plugin specific parameters here in the Add
    # function, we need to keep them so that things like `Get-PAPlugin WebSelfHost -Params`
    # will show the correct values to users.

    # setup a module variable to record the paths and bodies our
    # listener will response with
    if (!$script:WSHResponses) { $script:WSHResponses = @{} }

    # add the response
    $requestPath = "/.well-known/acme-challenge/$Token"
    Write-Debug "Adding response $requestPath -> $Body"
    $script:WSHResponses[$requestPath] = $Body


    <#
    .SYNOPSIS
        Publish an HTTP challenge to a self-hosted web server

    .DESCRIPTION
        Publish an HTTP challenge to a self-hosted web server. Properly using this function relies on also using the associated Save-HttpChallenge function.

    .PARAMETER Domain
        The fully qualified domain name to publish the challenge for.

    .PARAMETER Token
        The token value associated with this specific challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER WSHPort
        The TCP port the server should listen on for requests. Defaults to 80 if not specified.

    .PARAMETER WSHTimeout
        The number of seconds to leave the server running for before automatically stopping.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-HttpChallenge 'example.com' 'TOKEN' 'body-value' -WSHPort 8000

        Prepares a self-hosted HTTP challenge on the specified port. This must be followed by a call to Save-HttpChallenge in order to actually start the HTTP listener.
    #>
}

function Remove-HttpChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Domain,
        [Parameter(Mandatory,Position=1)]
        [string]$Token,
        [Parameter(Mandatory,Position=2)]
        [string]$Body,
        [string]$WSHPort,
        [int]$WSHTimeout = 120,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # setup a module variable to record the paths and bodies our
    # listener will response with
    if (!$script:WSHResponses) { $script:WSHResponses = @{} }

    $requestPath = "/.well-known/acme-challenge/$Token"

    # add the response
    if ($script:WSHResponses.ContainsKey($requestPath)) {
        Write-Debug "Removing response $requestPath"
        $script:WSHResponses.Remove($requestPath)
    }

    <#
    .SYNOPSIS
        Unpublish an HTTP challenge to a self-hosted web server

    .DESCRIPTION
        Unpublish an HTTP challenge to a self-hosted web server. Properly using this function relies on also using the associated Save-HttpChallenge function.

    .PARAMETER Domain
        The fully qualified domain name to publish the challenge for.

    .PARAMETER Token
        The token value associated with this specific challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER WSHPort
        The TCP port the server should listen on for requests. Defaults to 80 if not specified.

    .PARAMETER WSHTimeout
        The number of seconds to leave the server running for before automatically stopping.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-HttpChallenge 'example.com' 'TOKEN' 'body-value' -WSHPort 8000

        Removes a prepared self-hosted HTTP challenge on the specified port. This must be followed by a call to Save-HttpChallenge in order to actually stop the HTTP listener.
    #>
}

function Save-HttpChallenge {
    [CmdletBinding()]
    param(
        [string]$WSHPort,
        [int]$WSHTimeout = 120,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # setup a module variable to record the paths and bodies our
    # listener will response with
    if (!$script:WSHResponses) { $script:WSHResponses = @{} }

    # Check for an existing listener to see whether we need to start or stop
    if (-not $script:WSHListenerJob) {
        # START
        Write-Debug "No existing listener job, time to start"

        # determine the listener prefix
        $portSuffix = if ($WSHPort) { ":$WSHPort" } else { [string]::Empty }
        $prefix = 'http://+{0}/.well-known/acme-challenge/' -f $portSuffix

        Write-Debug "Starting listener job with prefix $prefix"
        $script:WSHListenerJob = Start-Job -ScriptBlock {
            param(
                [string[]]$ListenerPrefix,
                [hashtable]$KnownResponses,
                [int]$Timeout
            )

            $VerbosePreference = 'Continue'
            $DebugPreference = 'Continue'

            try {
                # create the listener and add the prefixes
                $listener = [System.Net.HttpListener]::new()
                $ListenerPrefix | ForEach-Object {
                    $listener.Prefixes.Add($_)
                }

                $listener.Start()
                $startTime = Get-Date
                Write-Debug "HttpListener started with $Timeout second timeout"
            }
            catch { throw }

            try {
                # listen loop
                while ($listener.IsListening) {

                    # get context async so we can do other logic while listener is running
                    $contextTask = $listener.GetContextAsync()

                    # check for timeout
                    while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {

                        # get runtime in seconds
                        $runTime = [Math]::Round( ((Get-Date) - $startTime).TotalSeconds, 0)

                        # process timeout - if timeout is 0 server runs until challenge is valid
                        if ($Timeout -ne 0 -and $runTime -ge $Timeout) {
                            Write-Verbose 'timeout reached, stopping HttpListener'
                            $listener.Stop()
                            return
                        }
                    }

                    # get actual request context
                    $context = $contextTask.GetAwaiter().GetResult()

                    # deal with X-Forwarded-For header to get proper remote IP
                    # for servers behind load balancers or reverse proxies
                    $remoteIP = $context.Request.RemoteEndPoint.Address.ToString()
                    if ($context.Request.Headers['X-Forwarded-For']) {
                        $remoteIP = $context.Request.Headers['X-Forwarded-For']
                    }

                    $method = $context.Request.HttpMethod.ToString()
                    $requestPath = $context.Request.RawUrl

                    # respond to the requests we're expecting
                    if ($method -eq 'GET' -and $KnownResponses[$requestPath]) {
                        $responseData = $KnownResponses[$requestPath]

                        # verbose out response
                        Write-Verbose "Responding to $remoteIP for $requestPath"
                        Write-Debug $responseData
                        #respond to the request
                        $context.Response.Headers.Add("Content-Type", "text/plain")
                        $context.Response.StatusCode = 200
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
                        $context.Response.ContentLength64 = $buffer.Length
                        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                        $context.Response.OutputStream.Close()
                    }
                    # and 404 anything else
                    else {
                        # verbose out response
                        Write-Verbose "Unexpected request from $remoteIP"
                        Write-Debug "$method $($context.Request.RawUrl)"
                        # respond to the request
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
                Write-Error "HttpListener failed: $($_.Exception.Message)"
            }
            finally {
                # initial integration to capture CTRL+C and stop listener - will also fetch unexpected behavior
                if ($listener.IsListening) {
                    Write-Verbose 'Stopping HttpListener'
                    $listener.Stop()
                }

                # dispose if necessary
                if ($null -ne $listener) {
                    $listener.Dispose()
                }
            }

        } -ArgumentList $prefix,$script:WSHResponses,$WSHTimeout

    } else {
        # STOP
        Write-Debug "Found existing listener job, time to stop"

        $job = $script:WSHListenerJob

        $job | Stop-Job

        # We're not expecting any actual results from the job, but if want Debug/Verbose
        # messages to come back through to the client. Unfortunately, there's a known issue
        # with this such that even if the user doesn't have Verbose/Debug turned on, they'll
        # still come back through and end up on the console. It's just a cosmetic annoyance
        # though and most people automating this likely won't see the spam.
        # https://github.com/PowerShell/PowerShell/issues/9585
        $job | Receive-Job | Out-Null

        $job | Remove-Job

        $script:WSHListenerJob = $null
    }

    <#
    .SYNOPSIS
        Start or Stop the HTTP listener that will host the challenges prepared with Add-HttpChallenge.

    .DESCRIPTION
        This function toggles the state of the HTTP challenge listener and must be used after all calls to Add-HttpChallenge are complete and again after all calls to Remove-HttpChallenge are complete.

    .PARAMETER WSHPort
        The TCP port the server should listen on for requests. Defaults to 80 if not specified.

    .PARAMETER WSHTimeout
        The number of seconds to leave the server running for before automatically stopping.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-HttpChallenge -WSHPort 8000

        Start or Stop the listener on the specified port.
    #>
}
