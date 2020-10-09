BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
}

Describe "ConvertFrom-Base64Url" {

    It "Decodes string values properly" {
        InModuleScope Posh-ACME {
            ConvertFrom-Base64Url ''         | Should -Be ''
            ConvertFrom-Base64Url 'Zg'       | Should -Be 'f'
            ConvertFrom-Base64Url 'Zm8'      | Should -Be 'fo'
            ConvertFrom-Base64Url 'Zm9v'     | Should -Be 'foo'
            ConvertFrom-Base64Url 'Zm9vYg'   | Should -Be 'foob'
            ConvertFrom-Base64Url 'Zm9vYmE'  | Should -Be 'fooba'
            ConvertFrom-Base64Url 'Zm9vYmFy' | Should -Be 'foobar'
            ConvertFrom-Base64Url 'Pz8_Pw'   | Should -Be '????'
            ConvertFrom-Base64Url 'Pj4-Pg'   | Should -Be '>>>>'
        }
    }

    It "Decodes strings from pipeline" {
        InModuleScope Posh-ACME {
            'YXNkZg','cXdlcg' | ConvertFrom-Base64Url | Should -Be 'asdf','qwer'
        }
    }

    It "Throws on invalid length" {
        InModuleScope Posh-ACME {
            { ConvertFrom-Base64Url '12345' } | Should -Throw
        }
    }

    It "returns byte[] with -AsByteArray" {
        InModuleScope Posh-ACME {
            ConvertFrom-Base64Url 'Zm9vYmFy' -AsByteArray | Should -Be ([byte[]](102,111,111,98,97,114))
        }
    }

    # Since we're using the native [Convert]::FromBase64String under the hood, we'll
    # skip testing the various combinations of characters that should throw an error.

}
