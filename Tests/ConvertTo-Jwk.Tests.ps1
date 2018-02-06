Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "ConvertTo-Jwk" {
    InModuleScope Posh-ACME {

        Context "Generic Bad Input Errors" {
            It "should throw on string input" {
                { ConvertTo-Jwk 'asdf' } | Should -Throw
            }
            It "should throw on null input" {
                { ConvertTo-Jwk $null } | Should -Throw
            }
            It "should throw on int input" {
                { ConvertTo-Jwk 1234 } | Should -Throw
            }
        }

        # create some known good RSA keys
        $rsa2048Priv = New-Object Security.Cryptography.RSACryptoServiceProvider 2048
        $rsa2048Pub = New-Object Security.Cryptography.RSACryptoServiceProvider
        $rsa2048Pub.ImportParameters($rsa2048Priv.ExportParameters($false))
        $rsa3072Priv = New-Object Security.Cryptography.RSACryptoServiceProvider 3072
        $rsa3072Pub = New-Object Security.Cryptography.RSACryptoServiceProvider
        $rsa3072Pub.ImportParameters($rsa3072Priv.ExportParameters($false))
        $rsa4096Priv = New-Object Security.Cryptography.RSACryptoServiceProvider 4096
        $rsa4096Pub = New-Object Security.Cryptography.RSACryptoServiceProvider
        $rsa4096Pub.ImportParameters($rsa4096Priv.ExportParameters($false))

        Context "RSA 2048 Pub/Priv Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa2048Priv } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa2048Priv
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa2048Priv.ExportParameters($true)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has correct 'd'" {
                $resultObj.d | Should -BeExactly (ConvertTo-Base64Url $origParams.D)
            }
            It "has correct 'p'" {
                $resultObj.p | Should -BeExactly (ConvertTo-Base64Url $origParams.P)
            }
            It "has correct 'q'" {
                $resultObj.q | Should -BeExactly (ConvertTo-Base64Url $origParams.Q)
            }
            It "has correct 'dp'" {
                $resultObj.dp | Should -BeExactly (ConvertTo-Base64Url $origParams.DP)
            }
            It "has correct 'dq'" {
                $resultObj.dq | Should -BeExactly (ConvertTo-Base64Url $origParams.DQ)
            }
            It "has correct 'qi'" {
                $resultObj.qi | Should -BeExactly (ConvertTo-Base64Url $origParams.InverseQ)
            }

        }

        Context "RSA 2048 Pub/Priv -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa2048Priv -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa2048Priv -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa2048Priv.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 2048 Public Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa2048Pub } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa2048Pub
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa2048Pub.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 2048 Public -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa2048Pub -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa2048Pub -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa2048Pub.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 3072 Pub/Priv Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa3072Priv } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa3072Priv
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa3072Priv.ExportParameters($true)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has correct 'd'" {
                $resultObj.d | Should -BeExactly (ConvertTo-Base64Url $origParams.D)
            }
            It "has correct 'p'" {
                $resultObj.p | Should -BeExactly (ConvertTo-Base64Url $origParams.P)
            }
            It "has correct 'q'" {
                $resultObj.q | Should -BeExactly (ConvertTo-Base64Url $origParams.Q)
            }
            It "has correct 'dp'" {
                $resultObj.dp | Should -BeExactly (ConvertTo-Base64Url $origParams.DP)
            }
            It "has correct 'dq'" {
                $resultObj.dq | Should -BeExactly (ConvertTo-Base64Url $origParams.DQ)
            }
            It "has correct 'qi'" {
                $resultObj.qi | Should -BeExactly (ConvertTo-Base64Url $origParams.InverseQ)
            }

        }

        Context "RSA 3072 Pub/Priv -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa3072Priv -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa3072Priv -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa3072Priv.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 3072 Public Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa3072Pub } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa3072Pub
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa3072Pub.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 3072 Public -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa3072Pub -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa3072Pub -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa3072Pub.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 4096 Pub/Priv Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa4096Priv } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa4096Priv
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa4096Priv.ExportParameters($true)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has correct 'd'" {
                $resultObj.d | Should -BeExactly (ConvertTo-Base64Url $origParams.D)
            }
            It "has correct 'p'" {
                $resultObj.p | Should -BeExactly (ConvertTo-Base64Url $origParams.P)
            }
            It "has correct 'q'" {
                $resultObj.q | Should -BeExactly (ConvertTo-Base64Url $origParams.Q)
            }
            It "has correct 'dp'" {
                $resultObj.dp | Should -BeExactly (ConvertTo-Base64Url $origParams.DP)
            }
            It "has correct 'dq'" {
                $resultObj.dq | Should -BeExactly (ConvertTo-Base64Url $origParams.DQ)
            }
            It "has correct 'qi'" {
                $resultObj.qi | Should -BeExactly (ConvertTo-Base64Url $origParams.InverseQ)
            }

        }

        Context "RSA 4096 Pub/Priv -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa4096Priv -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa4096Priv -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa4096Priv.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 4096 Public Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa4096Pub } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa4096Pub
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa4096Pub.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }

        Context "RSA 4096 Public -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $rsa4096Pub -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $rsa4096Pub -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'RSA'
            }
            $origParams = $rsa4096Pub.ExportParameters($false)
            It "has correct 'e'" {
                $resultObj.e | Should -BeExactly (ConvertTo-Base64Url $origParams.Exponent)
            }
            It "has correct 'n'" {
                $resultObj.n | Should -BeExactly (ConvertTo-Base64Url $origParams.Modulus)
            }
            It "has no 'd'"  { 'd'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'p'"  { 'p'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'q'"  { 'q'  | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dp'" { 'dp' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'dq'" { 'dq' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has no 'qi'" { 'qi' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }

        }


        # create some known good EC keys
        $ec256Priv = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.2.840.10045.3.1.7'))
        $ec256Pub = [Security.Cryptography.ECDsa]::Create()
        $ec256Pub.ImportParameters($ec256Priv.ExportParameters($false))
        $ec384Priv = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.34'))
        $ec384Pub = [Security.Cryptography.ECDsa]::Create()
        $ec384Pub.ImportParameters($ec384Priv.ExportParameters($false))
        $ec521Priv = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.35'))
        $ec521Pub = [Security.Cryptography.ECDsa]::Create()
        $ec521Pub.ImportParameters($ec521Priv.ExportParameters($false))

        Context "EC 256 Pub/Priv Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec256Priv } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec256Priv
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-256'
            }
            $origParams = $ec256Priv.ExportParameters($true)
            It "has correct 'd'" {
                $resultObj.d | Should -BeExactly (ConvertTo-Base64Url $origParams.D)
            }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 256 Pub/Priv -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec256Priv -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec256Priv -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-256'
            }
            $origParams = $ec256Priv.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 256 Public Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec256Pub } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec256Pub
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-256'
            }
            $origParams = $ec256Pub.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 256 Public -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec256Pub -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec256Pub -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-256'
            }
            $origParams = $ec256Pub.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 384 Pub/Priv Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec384Priv } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec384Priv
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-384'
            }
            $origParams = $ec384Priv.ExportParameters($true)
            It "has correct 'd'" {
                $resultObj.d | Should -BeExactly (ConvertTo-Base64Url $origParams.D)
            }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 384 Pub/Priv -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec384Priv -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec384Priv -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-384'
            }
            $origParams = $ec384Priv.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 384 Public Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec384Pub } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec384Pub
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-384'
            }
            $origParams = $ec384Pub.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 384 Public -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec384Pub -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec384Pub -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-384'
            }
            $origParams = $ec384Pub.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 521 Pub/Priv Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec521Priv } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec521Priv
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-521'
            }
            $origParams = $ec521Priv.ExportParameters($true)
            It "has correct 'd'" {
                $resultObj.d | Should -BeExactly (ConvertTo-Base64Url $origParams.D)
            }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 521 Pub/Priv -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec521Priv -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec521Priv -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-521'
            }
            $origParams = $ec521Priv.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 521 Public Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec521Pub } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec521Pub
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-521'
            }
            $origParams = $ec521Pub.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

        Context "EC 521 Public -PublicOnly Tests" {

            It "should not throw" {
                { ConvertTo-Jwk $ec521Pub -PublicOnly } | Should -Not -Throw
            }
            $result = ConvertTo-Jwk $ec521Pub -PublicOnly
            It "is parseable JSON" {
                { $result | ConvertFrom-Json } | Should -Not -Throw
            }
            $resultObj = $result | ConvertFrom-Json
            It "has correct 'kty'" {
                $resultObj.kty | Should -BeExactly 'EC'
            }
            It "has correct 'crv'" {
                $resultObj.crv | Should -BeExactly 'P-521'
            }
            $origParams = $ec521Pub.ExportParameters($false)
            It "has no 'd'" { 'd' | Should -Not -BeIn $resultObj.PSObject.Properties.Name }
            It "has correct 'x'" {
                $resultObj.x | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.X)
            }
            It "has correct 'y'" {
                $resultObj.y | Should -BeExactly (ConvertTo-Base64Url $origParams.Q.Y)
            }

        }

    }
}
