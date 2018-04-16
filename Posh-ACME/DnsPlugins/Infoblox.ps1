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
        $Splat
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
        $Splat
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

}

function Save-DnsTxtInfoblox {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $Splat
    )

    # Infoblox doesn't require a save step
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
