function Get-CurrentPluginType { 'http-01' }

function Add-HttpChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Url,
        [Parameter(Mandatory,Position=1)]
        [string]$Body,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add plugin specific parameters after $Body and before
    # $ExtraParams. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to publish the specified $Body text at the specified
    # $Url. Remember to add @script:UseBasic to all calls to
    # Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Publish an HTTP challenge to <My HTTP Server/Provider>

    .DESCRIPTION
        Description for <My HTTP Server/Provider>

    .PARAMETER Url
        The URL that ACME servers will query to validate the challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-HttpChallenge 'http://example.com/.well-known/acme-challenge/TOKEN' 'body-value'

        Adds an HTTP challenge from the specified site with the specified body.
    #>
}

function Remove-HttpChallenge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Url,
        [Parameter(Mandatory,Position=1)]
        [string]$Body,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Add plugin specific parameters after $Body and before
    # $ExtraParams. Make sure their names are unique across all
    # existing plugins. But make sure common ones across this
    # plugin are the same.

    # Do work here to unpublish the specified $Body text from the specified
    # $Url. Remember to add @script:UseBasic to all calls to
    # Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Unpublish an HTTP challenge from <My HTTP Server/Provider>

    .DESCRIPTION
        Description for <My HTTP Server/Provider>

    .PARAMETER Url
        The URL that ACME servers will query to validate the challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-HttpChallenge 'http://example.com/.well-known/acme-challenge/TOKEN' 'body-value'

        Removes an HTTP challenge from the specified site with the specified body.
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

    # Do work here to publish the specified $Body text at the specified
    # $Url. Remember to add @script:UseBasic to all calls to
    # Invoke-RestMethod or Invoke-WebRequest.

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
