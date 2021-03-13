function Invoke-HttpChallengeListener {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType('PoshACME.PAAuthorization')]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('domain', 'fqdn')]
        [string]$MainDomain,
        [Parameter()]
        [Alias('TTL')]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$ListenerTimeout = 120,
        [Parameter()]
        [ValidateRange(1,65535)]
        [int]$Port,
        [Parameter()]
        [string[]]$ListenerPrefixes
    )

    Begin {

        # Make sure we have an account configured
        if (-not ($acct = Get-PAAccount)) {
            try { throw "No ACME account configured. Run Set-PAAccount or New-PAAccount first." }
            catch { $PSCmdlet.ThrowTerminatingError($_) }
        }

        # account present, lets start
        # if ListenerTimeout is set to zero, write a warning
        if ($ListenerTimeout -eq 0) {
            Write-Warning 'ListenerTimeout is set to 0. If domain can''t be validated, listener will run indefinitely or until manually stopped.'
        }

        # set port suffix for http listener
        $portSuffix = if ($Port) { ":$Port" } else { [string]::Empty }

        # set TTL to at least 6 seconds to be sure at least one validation check can be executed
        if ($ListenerTimeout -ne 0 -and $ListenerTimeout -lt 6) {
            Write-Warning ('Set ListenerTimeout from {0} to 6 seconds so validation check will be executed at least once' -f $ListenerTimeout)
            $ListenerTimeout = 6
        }
    }

    Process {

        # init prevRuntime
        $prevRunTime = 0

        # get a reference to the order we're going to use
        if (-not $MainDomain) {
            # grab the current order and set $MainDomain
            $order = Get-PAOrder
            $MainDomain = $order.MainDomain
        }
        else {
            # try to get the order specified by $MainDomain
            if (-not ($order = Get-PAOrder -MainDomain $MainDomain)) {
                try { throw "No order found for domain $MainDomain" }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }

        # get pending authorizations for the order
        $openAuthorizations = @($order | Get-PAAuthorization -Verbose:$false |
            Where-Object { $_.status -eq 'pending' -and $_.HTTP01Status -eq 'pending' })

        # return if there's nothing to do
        if ($openAuthorizations.Count -eq 0) {
            Write-Warning "No pending authorizations found for Domain `"$MainDomain`""
            return
        }
        Write-Verbose ('Authorizations found with HTTP01Status pending: {0}' -f $openAuthorizations.Count)

        # create array with all necessary information for http listener
        $httpPublish = @( $openAuthorizations | Select-Object `
            'fqdn',
            'HTTP01Url',
            'HTTP01Token',
            @{L = 'subUrl'; E = { ('/.well-known/acme-challenge/{0}' -f $_.HTTP01Token) } },
            @{L = 'Body'; E = { Get-KeyAuthorization $_.HTTP01Token $acct } }
        )

        # initialize and start WebServer
        try {
            # create http listener
            $httpListener = [System.Net.HttpListener]::new()

            # add listener prefix(es)
            if (-not $ListenerPrefixes) {
                $prefix = 'http://+{0}/.well-known/acme-challenge/' -f $portSuffix
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
            $startTime = Get-Date
            Write-Verbose ('HttpListener started with {0} second timeout' -f $ListenerTimeout)
        }
        catch { throw }

        # time to interact with the listener
        try {
            # inform ACME server that challenge is ready
            foreach ($pub in $httpPublish) {
                Write-Verbose ('Send-ChallengeAck for {0}' -f $pub.fqdn)
                Write-Debug ('    {0}' -f $pub.HTTP01Url)
                if ($PSCmdlet.ShouldProcess($pub.fqdn, "Send-ChallengeAck")) {
                    Send-ChallengeAck $pub.HTTP01Url -Account $acct -Verbose:$false
                }
            }

            # enter listening loop
            while ($httpListener.IsListening) {

                # get context async so we can do other logic while listener is running
                $contextTask = $httpListener.GetContextAsync()

                # other logic
                while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) {

                    # get runtime in seconds
                    $runTime = [Math]::Round( ((Get-Date) - $startTime).TotalSeconds, 0)

                    # process timeout - if timeout is 0 server runs until challenge is valid
                    if ($ListenerTimeout -ne 0 -and $runTime -ge $ListenerTimeout) {
                        Write-Verbose 'timeout reached, stopping HttpListener'
                        $httpListener.Stop()
                        return
                    }

                    # check challenge state every 5 seconds
                    if ($prevRunTime -ne $runTime -and $runTime % 5 -eq 0) {

                        $prevRunTime = $runTime
                        Write-Verbose 'Checking authorization status'

                        # check if the published authorizations are no longer pending
                        # valid or invalid doesn't matter because we can't retry, so there's no need to wait longer
                        $completeAuths = @( $order | Get-PAAuthorization -Verbose:$false |
                            Where-Object { $_.fqdn -in $httpPublish.fqdn -and $_.status -ne 'pending' } )

                        if ($completeAuths.Count -eq $httpPublish.Count) {
                            Write-Verbose 'No pending authorizations remaining, stopping HttpListener'
                            $httpListener.Stop()
                            return
                        }
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

                # short - if requested url matches answer
                if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -in $httpPublish.subUrl) {
                    $responseData = $httpPublish | Where-Object { $_.subUrl -eq $context.Request.RawUrl }

                    # verbose out response
                    Write-Verbose ('Responding to {0} for {1}' -f $remoteIP, $responseData.fqdn)
                    Write-Debug ('    {0}' -f $responseData.Body )
                    #respond to the request
                    $context.Response.Headers.Add("Content-Type", "text/plain")
                    $context.Response.StatusCode = 200
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData.Body)
                    $context.Response.ContentLength64 = $buffer.Length
                    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $context.Response.OutputStream.Close()
                }
                # responsd with 404 to anything else
                else {
                    # verbose out response
                    Write-Verbose ('Unexpected request from {0}' -f $remoteIP)
                    Write-Debug ('    {0} {1}' -f $context.Request.HttpMethod, $context.Request.RawUrl)
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
            Write-Error ('HttpListener failed! ({0})' -f $errorMSG)
        }
        finally {

            # initial integration to capture CTRL+C and stop listener - will also fetch unexpected behavior
            if ($httpListener.IsListening) {
                Write-Verbose ('Stopping HttpListener')
                $httpListener.Stop()
            }

            # dispose if necessary
            if ($null -ne $httpListener) {
                $httpListener.Dispose()
            }

            # return PAAuthorizations for MainDomain if output may be used in a variable/pipe
            $order | Get-PAAuthorization -Verbose:$false
        }
    }

    <#
    .SYNOPSIS
        Starts a local web server to answer pending http-01 ACME challenges.

    .DESCRIPTION
        Uses System.Net.HttpListener to answer http-01 ACME challenges for the current or specified order. If MainDomain is not specified, the current Order is used.

        If running on Windows with non-admin privileges, Access Denied errors may be thrown unless a URL reservation is added using netsh that matches the HttpListener prefix that will be used. The default wildcard prefix is http://+/.well-known/acme-challenge and the netsh command might look something like this:

            netsh http add urlacl url=http://+/.well-known/acme-challenge/ user=Everyone

    .PARAMETER MainDomain
        The primary domain associated with an order.

    .PARAMETER ListenerTimeout
        The timeout in seconds for the webserver. When reached, the http listener stops regardless of challenge status.

    .PARAMETER Port
        The TCP port on which the http listener is listening. 80 by default. This parameter is ignored when ListenerPrefixes is specified.

    .PARAMETER ListenerPrefixes
        Overrides the default wildcard listener prefix with the specified prefixes instead. Be sure to include the port if necessary and a trailing '/' on all included prefixes. See https://docs.microsoft.com/en-us/dotnet/api/system.net.httplistener for details.

    .EXAMPLE
        Invoke-HttpChallengeListener

        Start listener on default port 80 for pending challenges for the current order.

    .EXAMPLE
        Invoke-HttpChallengeListener -MainDomain 'test.example.com' -Port 8080 -ListenerTimeout 30

        Start listener on port 8080 with a timeout of 30 seconds for the specified order.

    .EXAMPLE
        $prefixes = 'http://example.com/.well-known/acme-challenge/','http://www.example.com/.well-known/acme-challenge'
        PS C:\>Invoke-HttpChallengeListener -ListenerPrefixes $prefixes

        Start listener using the specified prefixes for the current order.

    .LINK
        Project: https://github.com/rmbolger/Posh-ACME

    .LINK
        Get-PAOrder

    .LINK
        Get-PAAuthorization
    #>
}
