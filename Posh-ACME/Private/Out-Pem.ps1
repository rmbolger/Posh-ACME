using namespace Org.BouncyCastle.Asn1
using namespace Org.BouncyCastle.Asn1.Sec
using namespace Org.BouncyCastle.Asn1.X9
using namespace Org.BouncyCastle.Crypto
using namespace Org.BouncyCastle.Crypto.Parameters
using namespace Org.BouncyCastle.Pkcs

function Out-Pem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [psobject]$InputObject,
        [Parameter(Mandatory,Position=1)]
        [string]$FilePath
    )

    if ($InputObject -is [AsymmetricCipherKeyPair]) {
        $BCKeyPair = $InputObject

        if ($BCKeyPair.Private -is [ECPrivateKeyParameters]) {

            # grab the things we need to build an ECPrivateKeyStructure that includes the public key
            $privParam = $keyPair.Private
            $orderBitLength = $privParam.Parameters.N.BitLength
            $x962 = New-Object X962Parameters -ArgumentList $privParam.PublicKeyParamSet
            $pubKey = New-Object DerBitString -ArgumentList @(,$keyPair.Public.Q.GetEncoded())

            # create the structure
            $privKeyStruct = New-Object ECPrivateKeyStructure -ArgumentList $orderBitLength,$privParam.D,$pubKey,$x962

            # get the raw Base64
            $privKeyStr = [Convert]::ToBase64String($privKeyStruct.GetDerEncoded())

            # build an array with the header/footer
            $pem = @('-----BEGIN EC PRIVATE KEY-----')
            for ($i=0; $i -lt $privKeyStr.Length; $i += 64) {
                $pem += $privKeyStr.Substring($i,[Math]::Min(64,($privKeyStr.Length-$i)))
            }
            $pem += '-----END EC PRIVATE KEY-----'

        } elseif ($BCKeyPair.Private -is [RsaPrivateCrtKeyParameters]) {

            # build the PrivateKeyInfoFactory
            $rsaInfo = [PrivateKeyInfoFactory]::CreatePrivateKeyInfo($rsaPair.Private)

            # get the raw Base64
            $privKeyStr = [Convert]::ToBase64String($rsaInfo.GetDerEncoded())

            # build an array with the header/footer
            $pem = @('-----BEGIN RSA PRIVATE KEY-----')
            for ($i=0; $i -lt $privKeyStr.Length; $i += 64) {
                $pem += $privKeyStr.Substring($i,[Math]::Min(64,($privKeyStr.Length-$i)))
            }
            $pem += '-----END RSA PRIVATE KEY-----'

        } else {
            throw "Unsupported BouncyCastle KeyPair type"
        }

    } elseif ($InputObject -is [Pkcs10CertificationRequest]) {

        # get the raw Base64 encoded version
        $reqStr = [Convert]::ToBase64String($InputObject.GetEncoded())

        # build an array with the header/footer
        $pem = @('-----BEGIN NEW CERTIFICATE REQUEST-----')
        for ($i=0; $i -lt $reqStr.Length; $i += 64) {
            $pem += $reqStr.Substring($i,[Math]::Min(64,($reqStr.Length-$i)))
        }
        $pem += '-----END NEW CERTIFICATE REQUEST-----'

    } else {
        throw "Unsuppored InputObject type"
    }

    # resolve relative paths
    $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)

    # Usually, PEM files are ANSI encoded with UNIX line endings which means none of the
    # normal Powershell stuff for outputting files will work. So we'll use a .NET StreamWriter
    # instead.
    try {
        $sw = New-Object IO.StreamWriter($FilePath, $false, [Text.Encoding]::ASCII)
        $sw.NewLine = "`n"
        foreach ($line in $pem) {
            $sw.WriteLine($line)
        }
    } finally { if ($sw -ne $null) { $sw.Close() } }

}
