Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "ConvertTo-Base64Url" {

    InModuleScope Posh-ACME {
        It "encodes (empty)"  { ConvertTo-Base64Url ''       | Should -Be '' }
        It "encodes 'f'"      { ConvertTo-Base64Url 'f'      | Should -Be 'Zg' }
        It "encodes 'fo'"     { ConvertTo-Base64Url 'fo'     | Should -Be 'Zm8' }
        It "encodes 'foo'"    { ConvertTo-Base64Url 'foo'    | Should -Be 'Zm9v' }
        It "encodes 'foob'"   { ConvertTo-Base64Url 'foob'   | Should -Be 'Zm9vYg' }
        It "encodes 'fooba'"  { ConvertTo-Base64Url 'fooba'  | Should -Be 'Zm9vYmE' }
        It "encodes 'foobar'" { ConvertTo-Base64Url 'foobar' | Should -Be 'Zm9vYmFy' }
        It "encodes '????'"   { ConvertTo-Base64Url '????'   | Should -Be 'Pz8_Pw' }
        It "encodes '>>>>'"   { ConvertTo-Base64Url '>>>>'   | Should -Be 'Pj4-Pg' }
        It "encodes '>>>>' bytes" {
            ConvertTo-Base64Url ([byte[]]@(62,62,62,62)) | Should -Be 'Pj4-Pg'
        }
        It "encodes empty array" {
            ConvertTo-Base64Url @() | Should -Be ''
        }
        It "encodes strings from pipeline" {
            'asdf','qwer' | ConvertTo-Base64Url | Should -Be 'YXNkZg','cXdlcg'
        }

        # RFC 7515 examples
        It "rfc7515#section-3.3 header" {
            "{`"typ`":`"JWT`",`r`n `"alg`":`"HS256`"}" | ConvertTo-Base64Url | Should -Be 'eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9'
        }
        It "rfc7515#section-3.3 payload" {
            "{`"iss`":`"joe`",`r`n `"exp`":1300819380,`r`n `"http://example.com/is_root`":true}" | ConvertTo-Base64Url | Should -Be 'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'
        }
    }
}