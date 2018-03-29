Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "New-Jws" {

    # generate some valid parameters
    $rsaKey = New-Object Security.Cryptography.RSACryptoServiceProvider 2048
    $ecKey = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.2.840.10045.3.1.7'))
    $rsaHeader = @{alg='RS256';jwk=($rsaKey | ConvertTo-Jwk -PublicOnly);nonce='fakenonce';url='https://example.com'}
    $ecHeader = @{alg='ES256';jwk=($ecKey | ConvertTo-Jwk -PublicOnly);nonce='fakenonce';url='https://example.com'}
    $payload = '{"mykey":"myvalue"}'

    Context "Parameter validation" {

        It "invalid Key type #1" {
            { New-Jws -Key 'blah' -Header $rsaHeader -Payload $payload } | Should -Throw
        }
        It "invalid Key type #2" {
            { New-Jws -Key (new-object Security.Cryptography.DSACng) -Header $rsaHeader -Payload $payload } | Should -Throw
        }
        It "invalid Header type" {
            { New-Jws -Key $rsaKey -Header 'blah' -Payload $payload } | Should -Throw
        }
        It "missing 'alg'" {
            $rsaHeader.Remove('alg')
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.alg = 'RS256'
        }
        It "invalid 'alg'" {
            $rsaHeader.alg = 'blah'
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.alg = 'RS256'
        }
        It "mis-matched 'alg' #1" {
            $rsaHeader.alg = 'ES256'
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.alg = 'RS256'
        }
        It "mis-matched 'alg' #2" {
            $ecHeader.alg = 'RS256'
            { New-Jws $ecKey $ecHeader $payload } | Should -Throw
            $ecHeader.alg = 'ES256'
        }
        It "both 'jwk' and 'kid' supplied" {
            $rsaHeader.kid = 'https://fake/account'
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.Remove('kid')
        }
        It "missing both 'jwk' and 'kid'" {
            $rsaHeader.Remove('jwk')
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.jwk = ($rsaKey | ConvertTo-Jwk -PublicOnly)
        }
        It "empty 'jwk'" {
            $rsaHeader.jwk = ''
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.jwk = ($rsaKey | ConvertTo-Jwk -PublicOnly)
        }
        It "empty 'kid'" {
            $rsaHeader.Remove('jwk')
            $rsaHeader.kid = ''
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.jwk = ($rsaKey | ConvertTo-Jwk -PublicOnly)
            $rsaHeader.Remove('kid')
        }
        It "missing 'nonce'" {
            $rsaHeader.Remove('nonce')
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.nonce = 'fakenonce'
        }
        It "empty 'nonce'" {
            $rsaHeader.nonce = ''
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.nonce = 'fakenonce'
        }
        It "missing 'url'" {
            $rsaHeader.Remove('url')
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.url = 'https://example.com'
        }
        It "empty 'url'" {
            $rsaHeader.url = ''
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Throw
            $rsaHeader.url = 'https://example.com'
        }

    }

    Context "RSA 2048 Test and Verify" {

        It "should not throw with good parameters" {
            { New-Jws $rsaKey $rsaHeader $payload } | Should -Not -Throw
        }
        $result = New-Jws $rsaKey $rsaHeader $payload
        It "result is parseable JSON" {
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }
        $jws = $result | ConvertFrom-Json
        It "'payload' is Base64Url encoded" {
            { $jws.payload | ConvertFrom-Base64Url } | Should -Not -Throw
        }
        $payload = $jws.payload | ConvertFrom-Base64Url
        It "decoded 'payload' is parseable JSON" {
            { $payload | ConvertFrom-Json } | Should -Not -Throw
        }
        It "'protected' is Base64Url encoded" {
            { $jws.protected | ConvertFrom-Base64Url } | Should -Not -Throw
        }
        $protected = $jws.protected | ConvertFrom-Base64Url
        It "decoded 'protected' is parseable JSON" {
            { $protected | ConvertFrom-Json } | Should -Not -Throw
        }
        $header = $protected | ConvertFrom-Json
        It "parsed 'alg' matches input 'alg'" {
            $header.alg | Should -BeExactly $rsaHeader.alg
        }
        It "parsed 'jwk' matches input 'jwk'" {
            ($header.jwk | ConvertTo-Json -Compress) | Should -BeExactly ($rsaHeader.jwk | ConvertTo-Json -Compress)
        }
        It "parsed 'nonce' matches input 'nonce'" {
            $header.nonce | Should -BeExactly $rsaHeader.nonce
        }
        It "parsed 'url' matches input 'url'" {
            $header.url | Should -BeExactly $rsaHeader.url
        }
        It "'signature' is Base64Url encoded" {
            { $jws.signature | ConvertFrom-Base64Url -AsByteArray } | Should -Not -Throw
        }
        $sigBytes = $jws.signature | ConvertFrom-Base64Url -AsByteArray
        $dataBytes = [Text.Encoding]::ASCII.GetBytes("$($jws.protected).$($jws.payload)")
        $pubKey = ConvertFrom-Jwk ($header.jwk | ConvertTo-Json)
        $HashAlgo = [Security.Cryptography.HashAlgorithmName]::SHA256
        $PaddingType = [Security.Cryptography.RSASignaturePadding]::Pkcs1
        It "decoded 'signature' verifies properly" {
            $pubKey.VerifyData($dataBytes,$sigBytes,$HashAlgo,$PaddingType) | Should -Be $true
        }

    }

    Context "EC 256 Test and Verify" {

        It "should not throw with good parameters" {
            { New-Jws $ecKey $ecHeader $payload } | Should -Not -Throw
        }
        $result = New-Jws $ecKey $ecHeader $payload
        It "result is parseable JSON" {
            { $result | ConvertFrom-Json } | Should -Not -Throw
        }
        $jws = $result | ConvertFrom-Json
        It "'payload' is Base64Url encoded" {
            { $jws.payload | ConvertFrom-Base64Url } | Should -Not -Throw
        }
        $payload = $jws.payload | ConvertFrom-Base64Url
        It "decoded 'payload' is parseable JSON" {
            { $payload | ConvertFrom-Json } | Should -Not -Throw
        }
        It "'protected' is Base64Url encoded" {
            { $jws.protected | ConvertFrom-Base64Url } | Should -Not -Throw
        }
        $protected = $jws.protected | ConvertFrom-Base64Url
        It "decoded 'protected' is parseable JSON" {
            { $protected | ConvertFrom-Json } | Should -Not -Throw
        }
        $header = $protected | ConvertFrom-Json
        It "parsed 'alg' matches input 'alg'" {
            $header.alg | Should -BeExactly $ecHeader.alg
        }
        It "parsed 'jwk' matches input 'jwk'" {
            ($header.jwk | ConvertTo-Json -Compress) | Should -BeExactly ($ecHeader.jwk | ConvertTo-Json -Compress)
        }
        It "parsed 'nonce' matches input 'nonce'" {
            $header.nonce | Should -BeExactly $ecHeader.nonce
        }
        It "parsed 'url' matches input 'url'" {
            $header.url | Should -BeExactly $ecHeader.url
        }
        It "'signature' is Base64Url encoded" {
            { $jws.signature | ConvertFrom-Base64Url -AsByteArray } | Should -Not -Throw
        }
        $sigBytes = $jws.signature | ConvertFrom-Base64Url -AsByteArray
        $dataBytes = [Text.Encoding]::ASCII.GetBytes("$($jws.protected).$($jws.payload)")
        $pubKey = ConvertFrom-Jwk ($header.jwk | ConvertTo-Json)
        It "decoded 'signature' verifies properly" {
            $pubKey.VerifyData($dataBytes,$sigBytes) | Should -Be $true
        }

    }

}
