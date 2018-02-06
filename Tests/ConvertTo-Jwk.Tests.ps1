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


        # create some known good EC keys
        $ec256Priv = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.2.840.10045.3.1.7'))
        $ec256Pub = [Security.Cryptography.ECDsa]::Create()
        $ec256Pub.ImportParameters($ec256Priv.ExportParameters($false))
        $ec384Priv = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.34'))
        $ec384Pub = [Security.Cryptography.ECDsa]::Create()
        $ec384Pub.ImportParameters($ec384Priv.ExportParameters($false))
        $ec384Priv = [Security.Cryptography.ECDsa]::Create([Security.Cryptography.ECCurve]::CreateFromValue('1.3.132.0.35'))
        $ec521Pub = [Security.Cryptography.ECDsa]::Create()
        $ec521Pub.ImportParameters($ec521Priv.ExportParameters($false))


    }
}
