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
        [Parameter(Mandatory)]
        [string]$WRPath,
        [switch]$WRExactPath,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # expand any relative path params
    $WRPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($WRPath)

    # build the appropriate output folder path
    if ($WRExactPath) {
        $outFolder = $WRPath
    } else {
        $outFolder = Join-Path $WRPath ".well-known/acme-challenge"
    }
    Write-Debug "Creating challenge file for $Domain in $outFolder"

    # attempt to create the folder if it doesn't exist
    if (-not (Test-Path $outFolder -PathType Container)) {
        Write-Debug "Folder doesn't exist, attempting to create it."
        New-Item -Path $outFolder -ItemType Directory -ErrorAction Stop | Out-Null
    }

    $outFile = Join-Path $outFolder $Token
    Write-Debug "Writing file $outFile"
    $Body | Out-File $outFile -Encoding ascii -Force

    <#
    .SYNOPSIS
        Publish an HTTP challenge file to a web server root folder

    .DESCRIPTION
        Publish an HTTP challenge file to a web server root folder

    .PARAMETER Domain
        The fully qualified domain name to publish the challenge for.

    .PARAMETER Token
        The token value associated with this specific challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER WRPath
        The path to the web server's root folder for the specified site. Files will be written to a '.well-known/acme-challenge' subfolder unless WRExactPath is specified.

    .PARAMETER WRExactPath
        If specified, the challenge files will be written to the exact folder WRPath points to instead of a '.well-known/acme-challenge' subfolder.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-HttpChallenge 'example.com' 'TOKEN' 'body-value' -WRPath 'C:\inetpub\wwwroot'

        Adds an HTTP challenge to the specified web root location.
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
        [Parameter(Mandatory)]
        [string]$WRPath,
        [switch]$WRExactPath,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # expand any relative path params
    $WRPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($WRPath)

    # build the appropriate output file path
    if ($WRExactPath) {
        $outFile = Join-Path $WRPath $Token
    } else {
        $outFile = Join-Path $WRPath ".well-known/acme-challenge/$Token"
    }
    Write-Debug "Removing challenge file for $Domain at $outFile"

    # make sure it actually exists
    if (Test-Path $outFile -PathType Leaf) {
        Remove-Item -Path $outFile -Force -ErrorAction Stop
    } else {
        Write-Debug "File doesn't exist, nothing to do."
    }


    <#
    .SYNOPSIS
        Unpublish an HTTP challenge file from a web server root folder

    .DESCRIPTION
        Unpublish an HTTP challenge file from a web server root folder

    .PARAMETER Domain
        The fully qualified domain name to publish the challenge for.

    .PARAMETER Token
        The token value associated with this specific challenge.

    .PARAMETER Body
        The text that should make up the response body from the URL.

    .PARAMETER WRPath
        The path to the web server's root folder for the specified site. Files will be written to a '.well-known/acme-challenge' subfolder unless WRExactPath is specified.

    .PARAMETER WRExactPath
        If specified, the challenge files will be written to the exact folder WRPath points to instead of a '.well-known/acme-challenge' subfolder.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-HttpChallenge 'example.com' 'TOKEN' 'body-value' -WRPath 'C:\inetpub\wwwroot'

        Removes an HTTP challenge from the specified web root location.
    #>
}

function Save-HttpChallenge {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    <#
    .SYNOPSIS
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to commit changes to HTTP challenges.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}
