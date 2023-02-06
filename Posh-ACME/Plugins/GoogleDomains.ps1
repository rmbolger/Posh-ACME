function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$RootDomain,
        [Parameter(Mandatory, Position = 3)]
        [securestring]$AccessToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # get the plaintext version of the token
    $AccessKeyInsecure = [pscredential]::new('a', $AccessToken).GetNetworkCredential().Password

    $apiRoot = "https://acmedns.googleapis.com/v1/acmeChallengeSets/$($RootDomain)"

    $jsonPayload = @{
            accessToken = $AccessKeyInsecure
            recordsToAdd = @(
                    @{
                        fqdn=$RecordName
                        digest=$TxtValue
                   }
            )
          } | ConvertTo-Json

    # add new record
    try {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        Invoke-RestMethod "$($apiRoot):rotateChallenges" -Method POST -Body $jsonPayload -ContentType 'application/json' -ErrorAction Stop | Out-Null
    }
    catch { throw }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Google Domains

    .DESCRIPTION
        Add a DNS TXT record to Google Domains

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.
    
    .PARAMETER RootDomain
        The root domain being managed, as shown in Google Domains

    .PARAMETER AccessToken
        The API Token Secret

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $accessToken = Read-Host "Access Token" -AsSecureString
        PS C:\>Add-DnsTxt '_acme-challenge.example.com' 'txt-value' 'example.com' $accessToken

        Adds a TXT record for the specified site with the specified value on Windows.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        [Parameter(Mandatory, Position = 2)]
        [string]$RootDomain,
        [Parameter(Mandatory, Position = 3)]
        [securestring]$AccessToken,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

      # get the plaintext version of the token
      $AccessTokenInsecure = [pscredential]::new('a', $AccessToken).GetNetworkCredential().Password

      $apiRoot = "https://acmedns.googleapis.com/v1/acmeChallengeSets/$($RootDomain)"

      $jsonPayload = @{
            accessToken = $AccessTokenInsecure
            recordsToRemove = @(
                    @{
                        fqdn=$RecordName
                        digest=$TxtValue
                    }
            )
        } | ConvertTo-Json

      # add new record
      try {
          Write-Verbose "Deleting a TXT record for $RecordName with value $TxtValue"
          Invoke-RestMethod "$($apiRoot):rotateChallenges" -Method POST -Body $jsonPayload -ContentType 'application/json' -ErrorAction Stop | Out-Null
      }
      catch { throw }

    <#
    .SYNOPSIS
        Remove an ACME Challenge DNS TXT record from Google Domains.

    .DESCRIPTION
       Remove an ACME Challenge DNS TXT record from Google Domains.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    ..PARAMETER RootDomain
        The root domain being managed, as shown in Google Domains

    .PARAMETER AccessToken
        The API Token Secret

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $accessToken = Read-Host "Access Token" -AsSecureString
        PS C:\>Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' 'example.com' $accessToken

        Remove a TXT record for the specified site with the specified value on Windows.
    #>
    }