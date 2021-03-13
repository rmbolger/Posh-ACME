Describe "ConvertTo-Base64Url" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    It "Encodes string values properly" {
        InModuleScope Posh-ACME {
            ConvertTo-Base64Url ''       | Should -Be ''
            ConvertTo-Base64Url 'f'      | Should -Be 'Zg'
            ConvertTo-Base64Url 'fo'     | Should -Be 'Zm8'
            ConvertTo-Base64Url 'foo'    | Should -Be 'Zm9v'
            ConvertTo-Base64Url 'foob'   | Should -Be 'Zm9vYg'
            ConvertTo-Base64Url 'fooba'  | Should -Be 'Zm9vYmE'
            ConvertTo-Base64Url 'foobar' | Should -Be 'Zm9vYmFy'
            ConvertTo-Base64Url '????'   | Should -Be 'Pz8_Pw'
            ConvertTo-Base64Url '>>>>'   | Should -Be 'Pj4-Pg'
        }
    }

    It "Encodes byte values properly" {
        InModuleScope Posh-ACME {
            ConvertTo-Base64Url ([byte[]]@(62,62,62,62)) | Should -Be 'Pj4-Pg'
            ConvertTo-Base64Url @() | Should -Be ''
        }
    }

    It "Encodes strings from pipeline" {
        InModuleScope Posh-ACME {
            'asdf','qwer' | ConvertTo-Base64Url | Should -Be 'YXNkZg','cXdlcg'
        }
    }

    It "Encodes sample RFC7515 values" {
        InModuleScope Posh-ACME {
            # RFC 7515 examples
            "{`"typ`":`"JWT`",`r`n `"alg`":`"HS256`"}" | ConvertTo-Base64Url | Should -Be 'eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9'
            "{`"iss`":`"joe`",`r`n `"exp`":1300819380,`r`n `"http://example.com/is_root`":true}" | ConvertTo-Base64Url | Should -Be 'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
        }
    }

}
