function Add-DnsTxtInfoblox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$IBServer,
        [Parameter(Mandatory)]
        [pscredential]$IBCred,
        [string]$IBView='default',
        [switch]$IBIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $apiUrl = "https://$IBServer/wapi/v1.0/record:txt?name=$RecordName&text=$TxtValue&ttl=0&view=$IBView"

    try {
        # ignore cert validation for the duration of the call
        if ($IBIgnoreCert) { [CertValidation]::Ignore() }

        # send the POST
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Credential $IBCred

        Write-Host "TXT Record created: $response"

    } catch {
        $response = $_.Exception.Response

        if ($response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {

            # get the response body so we can pull out the WAPI's error message
            $stream = $response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();

            Write-Verbose $responseBody
            $wapiErr = ConvertFrom-Json $responseBody
            throw [Exception] "$($wapiErr.Error)"

        } else {
            # just re-throw everything else
            throw
        }
    } finally {
        # return cert validation back to normal
        if ($IBIgnoreCert) { [CertValidation]::Restore() }
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to Infoblox

    .DESCRIPTION
        Add a DNS TXT record to Infoblox

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IBServer
        The IP or hostname of the Infoblox server.

    .PARAMETER IBCred
        Credentials for Infoblox that have permission to write TXT records to the specified zone.

    .PARAMETER IBView
        The name of the DNS View for the specified zone. Defaults to 'default'.

    .PARAMETER IBIgnoreCert
        Use this switch to prevent certificate errors when your Infoblox server is using a self-signed or other untrusted SSL certificate. When passing parameters via hashtable, set it as a boolean such as @{IBIgnoreCert=$true}.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>$pluginArgs = @{IBServer='gridmaster.example.com'; IBCred=$cred; IBView='External'; IBIgnoreCert=$true}
        PS C:\>Add-DnsTxtInfoblox '_acme-challenge.site1.example.com' 'asdfqwer12345678' @pluginArgs

        Adds a TXT record for the specified site/value using a hashtable to pass plugin specific parameters.
    #>
}

function Remove-DnsTxtInfoblox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$IBServer,
        [Parameter(Mandatory)]
        [pscredential]$IBCred,
        [string]$IBView='default',
        [switch]$IBIgnoreCert,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    try {
        # ignore cert validation for the duration of the call
        if ($IBIgnoreCert) { [CertValidation]::Ignore() }

        # query the _ref for the txt record object we want to delete
        $checkUrl = "https://$IBServer/wapi/v1.0/record:txt?name=$RecordName&text=$TxtValue&view=$IBView"
        $response = Invoke-RestMethod -Uri $checkUrl -Method Get -Credential $IBCred

        if ($response -and $response.'_ref') {

            # delete the record
            $delUrl = "https://$IBServer/wapi/v1.0/$($response.'_ref')"
            $response = Invoke-RestMethod -Uri $delUrl -Method Delete -Credential $cred
            Write-Host "TXT Record deleted: $response"
        }

    } catch {
        $response = $_.Exception.Response

        if ($response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {

            # get the response body so we can pull out the WAPI's error message
            $stream = $response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();

            Write-Verbose $responseBody
            $wapiErr = ConvertFrom-Json $responseBody
            throw [Exception] "$($wapiErr.Error)"

        } else {
            # just re-throw everything else
            throw
        }
    } finally {
        # return cert validation back to normal
        if ($IBIgnoreCert) { [CertValidation]::Restore() }
    }

    <#
    .SYNOPSIS
        Remove a DNS TXT record from Infoblox

    .DESCRIPTION
        Remove a DNS TXT record from Infoblox

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER IBServer
        The IP or hostname of the Infoblox server.

    .PARAMETER IBCred
        Credentials for Infoblox that have permission to write TXT records to the specified zone.

    .PARAMETER IBView
        The name of the DNS View for the specified zone. Defaults to 'default'.

    .PARAMETER IBIgnoreCert
        Use this switch to prevent certificate errors when your Infoblox server is using a self-signed or other untrusted SSL certificate. When passing parameters via hashtable, set it as a boolean such as @{IBIgnoreCert=$true}.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $cred = Get-Credential
        PS C:\>$pluginArgs = @{IBServer='gridmaster.example.com'; IBCred=$cred; IBView='External'; IBIgnoreCert=$true}
        PS C:\>Remove-DnsTxtInfoblox '_acme-challenge.site1.example.com' 'asdfqwer12345678' @pluginArgs

        Removes a TXT record for the specified site/value using a hashtable to pass plugin specific parameters.
    #>
}

function Save-DnsTxtInfoblox {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Nothing to do. Infoblox doesn't require a save step

    <#
    .SYNOPSIS
        Not required for Infoblox.

    .DESCRIPTION
        Infoblox does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}

# Enable the ability to ignore cert validation
if (-not ([System.Management.Automation.PSTypeName]'CertValidation').Type)
{
    Add-Type @"
        using System.Net;
        using System.Net.Security;
        using System.Security.Cryptography.X509Certificates;
        public class CertValidation
        {
            static bool IgnoreValidation(object o, X509Certificate c, X509Chain ch, SslPolicyErrors e) {
                return true;
            }
            public static void Ignore() {
                ServicePointManager.ServerCertificateValidationCallback = IgnoreValidation;
            }
            public static void Restore() {
                ServicePointManager.ServerCertificateValidationCallback = null;
            }
        }
"@
}
