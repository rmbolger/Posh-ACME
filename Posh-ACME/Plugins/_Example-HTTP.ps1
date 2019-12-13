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
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add plugin specific parameters after $Body and before
    # $ExtraParams. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to publish the specified $Body text at the appropriate
    # URL using the $Domain and $Token values. If needed, you can build
    # the full URL like this:
    #
    #     $publishUrl = "http://$($Domain)/.well-known/acme-challenge/$($Token)"
    #
    # Remember to add @script:UseBasic to all calls to
    # Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Publish an HTTP challenge to <My HTTP Server/Provider>

    .DESCRIPTION
        Description for <My HTTP Server/Provider>

    .PARAMETER Domain
        The fully qualified domain name to publish the challenge for.

    .PARAMETER Token
        The token value associated with this specific challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-HttpChallenge 'example.com' 'TOKEN' 'body-value'

        Adds an HTTP challenge for the specified domain, token, and body value.
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
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add plugin specific parameters after $Body and before
    # $ExtraParams. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to unpublish the specified $Body text from the appropriate
    # URL using the $Domain and $Token values. If needed, you can build
    # the full URL like this:
    #
    #     $publishUrl = "http://$($Domain)/.well-known/acme-challenge/$($Token)"
    #
    # Remember to add @script:UseBasic to all calls to
    # Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Unpublish an HTTP challenge from <My HTTP Server/Provider>

    .DESCRIPTION
        Description for <My HTTP Server/Provider>

    .PARAMETER Domain
        The fully qualified domain name to publish the challenge for.

    .PARAMETER Token
        The token value associated with this specific challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-HttpChallenge 'example.com' 'TOKEN' 'body-value'

        Removes an HTTP challenge for the specified domain, token, and body value.
    #>
}

function Save-HttpChallenge {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add plugin specific parameters before $ExtraParams.
    # Make sure their names are unique across all existing
    # plugins. But make sure common ones across this plugin
    # are the same.

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the HTTP provider. In that case, just
    # leave the function body empty.

    <#
    .SYNOPSIS
        Commits changes for pending HTTP challenges published to <My HTTP Server/Provider>

    .DESCRIPTION
        Description for <My HTTP Server/Provider>

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-HttpChallenge

        Commits changes for pending HTTP challenges published.
    #>
}

############################
# Helper Functions
############################

# Add additional functions here if necessary.

# Try to follow verb-noun naming guidelines.
# https://msdn.microsoft.com/en-us/library/ms714428

# Add a commented link to API docs if they exist.
