Get-Module Posh-ACME | Remove-Module -Force
Import-Module Posh-ACME -Force

Describe "ConvertFrom-Jwk" {

    InModuleScope Posh-ACME {

        It "throws on bad JSON" {
            { 'asdf' | ConvertFrom-Jwk } | Should -Throw
        }
        It "throws on missing 'kty' #1" {
            { 1 | ConvertFrom-Jwk } | Should -Throw
        }
        It "throws on missing 'kty' #2" {
            { '{}' | ConvertFrom-Jwk } | Should -Throw
        }
        It "throws on missing 'kty' #3" {
            { '{"key1"="asdf"}' | ConvertFrom-Jwk } | Should -Throw
        }
        It "throws on empty 'kty'" {
            { '{"kty"=""}' | ConvertFrom-Jwk } | Should -Throw
        }
        It "throws on invalid 'kty'" {
            { '{"kty"="asdf"}' | ConvertFrom-Jwk } | Should -Throw
        }
        It "throws on whitespace 'kty'" {
            { '{"kty"="   "}' | ConvertFrom-Jwk } | Should -Throw
        }

        Context "RSA Tests" {

            $goodJwk = '{"kty":"RSA",' +
            '"n":"ofgWCuLjybRlzo0tZWJjNiuSfb4p4fAkd_wWJcyQoTbji9k0l8W26mPddxHmfHQp-Vaw-4qPCJrcS2mJPMEzP1Pt0Bm4d4QlL-yRT-SFd2lZS-pCgNMsD1W_YpRPEwOWvG6b32690r2jZ47soMZo9wGzjb_7OMg0LOL-bSf63kpaSHSXndS5z5rexMdbBYUsLA9e-KXBdQOS-UTo7WTBEMa2R2CapHg665xsmtdVMTBQY4uDZlxvb3qCo5ZwKh9kG4LT6_I5IhlJH7aGhyxXFvUK-DWNmoudF8NAco9_h9iaGNj8q2ethFkMLs91kzk2PAcDTW9gb54h4FRWyuXpoQ",' +
            '"e":"AQAB",' +
            '"d":"Eq5xpGnNCivDflJsRQBXHx1hdR1k6Ulwe2JZD50LpXyWPEAeP88vLNO97IjlA7_GQ5sLKMgvfTeXZx9SE-7YwVol2NXOoAJe46sui395IW_GO-pWJ1O0BkTGoVEn2bKVRUCgu-GjBVaYLU6f3l9kJfFNS3E0QbVdxzubSu3Mkqzjkn439X0M_V51gfpRLI9JYanrC4D4qAdGcopV_0ZHHzQlBjudU2QvXt4ehNYTCBr6XCLQUShb1juUO1ZdiYoFaFQT5Tw8bGUl_x_jTj3ccPDVZFD9pIuhLhBOneufuBiB4cS98l2SR_RQyGWSeWjnczT0QU91p1DhOVRuOopznQ",' +
            '"p":"4BzEEOtIpmVdVEZNCqS7baC4crd0pqnRH_5IB3jw3bcxGn6QLvnEtfdUdiYrqBdss1l58BQ3KhooKeQTa9AB0Hw_Py5PJdTJNPY8cQn7ouZ2KKDcmnPGBY5t7yLc1QlQ5xHdwW1VhvKn-nXqhJTBgIPgtldC-KDV5z-y2XDwGUc",' +
            '"q":"uQPEfgmVtjL0Uyyx88GZFF1fOunH3-7cepKmtH4pxhtCoHqpWmT8YAmZxaewHgHAjLYsp1ZSe7zFYHj7C6ul7TjeLQeZD_YwD66t62wDmpe_HlB-TnBA-njbglfIsRLtXlnDzQkv5dTltRJ11BKBBypeeF6689rjcJIDEz9RWdc",' +
            '"dp":"BwKfV3Akq5_MFZDFZCnW-wzl-CCo83WoZvnLQwCTeDv8uzluRSnm71I3QCLdhrqE2e9YkxvuxdBfpT_PI7Yz-FOKnu1R6HsJeDCjn12Sk3vmAktV2zb34MCdy7cpdTh_YVr7tss2u6vneTwrA86rZtu5Mbr1C1XsmvkxHQAdYo0",' +
            '"dq":"h_96-mK1R_7glhsum81dZxjTnYynPbZpHziZjeeHcXYsXaaMwkOlODsWa7I9xXDoRwbKgB719rrmI2oKr6N3Do9U0ajaHF-NKJnwgjMd2w9cjz3_-kyNlxAr2v4IKhGNpmM5iIgOS1VZnOZ68m6_pbLBSp3nssTdlqvd0tIiTHU",' +
            '"qi":"IYd7DHOhrWvxkwPQsRM2tOgrjbcrfvtQJipd-DlcxyVuuM9sQLdgjVk2oy26F0EmpScGLq2MowX7fhd_QJQ3ydy5cY7YIBi87w93IKLEdfnbJtoOPLUW0ITrJReOgo1cq9SbsxYawBgfp_gh6A5603k2-ZQwVK0JKSHuLFkuQ3U"' +
            '}'
            $goodJwkObj = $goodJwk | ConvertFrom-Json

            It "throws on missing 'e'" {
                $missingE = $goodJwkObj | Select kty,n | ConvertTo-Json -Compress
                { $missingE | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on whitespace 'e'" {
                $whitespaceE = $goodJwkObj | Select kty,n,@{L='e';E={'   '}} | ConvertTo-Json -Compress
                { $whitespaceE | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on invalid 'e'" {
                $invalidE = $goodJwkObj | Select kty,n,@{L='e';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidE | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on missing 'n'" {
                $missingN = $goodJwkObj | Select kty,e | ConvertTo-Json -Compress
                { $missingN | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on whitespace 'n'" {
                $whitespaceN = $goodJwkObj | Select kty,e,@{L='n';E={'   '}} | ConvertTo-Json -Compress
                { $whitespaceN | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on invalid 'n'" {
                $invalidN = $goodJwkObj | Select kty,e,@{L='n';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidN | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on invalid 'd'" {
                $invalidD = $goodJwkObj | Select kty,e,n,@{L='d';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidD | ConvertFrom-Jwk } | Should -Throw
            }

            # Test missing each one of these p,q,dp,dq,qi
            It "throws on incomplete priv key params #1" {
                $incompletePriv = $goodJwkObj | Select kty,e,n,d,q,dp,dq,qi | ConvertTo-Json -Compress
                { $incompletePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on incomplete priv key params #2" {
                $incompletePriv = $goodJwkObj | Select kty,e,n,d,p,dp,dq,qi | ConvertTo-Json -Compress
                { $incompletePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on incomplete priv key params #3" {
                $incompletePriv = $goodJwkObj | Select kty,e,n,d,p,q,dq,qi | ConvertTo-Json -Compress
                { $incompletePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on incomplete priv key params #4" {
                $incompletePriv = $goodJwkObj | Select kty,e,n,d,p,q,dp,qi | ConvertTo-Json -Compress
                { $incompletePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on incomplete priv key params #5" {
                $incompletePriv = $goodJwkObj | Select kty,e,n,d,p,q,dp,dq | ConvertTo-Json -Compress
                { $incompletePriv | ConvertFrom-Jwk } | Should -Throw
            }

            # Test whitespace in each one of these p,q,dp,dq,qi
            It "throws on whitespace priv key params #1" {
                $whitespacePriv = $goodJwkObj | Select kty,e,n,d,q,dp,dq,qi,@{L='p';E={'   '}} | ConvertTo-Json -Compress
                { $whitespacePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on whitespace priv key params #2" {
                $whitespacePriv = $goodJwkObj | Select kty,e,n,d,p,dp,dq,qi,@{L='q';E={'   '}} | ConvertTo-Json -Compress
                { $whitespacePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on whitespace priv key params #3" {
                $whitespacePriv = $goodJwkObj | Select kty,e,n,d,p,q,dq,qi,@{L='dp';E={'   '}} | ConvertTo-Json -Compress
                { $whitespacePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on whitespace priv key params #4" {
                $whitespacePriv = $goodJwkObj | Select kty,e,n,d,p,q,dp,qi,@{L='dq';E={'   '}} | ConvertTo-Json -Compress
                { $whitespacePriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on whitespace priv key params #5" {
                $whitespacePriv = $goodJwkObj | Select kty,e,n,d,p,q,dp,dq,@{L='qi';E={'   '}} | ConvertTo-Json -Compress
                { $whitespacePriv | ConvertFrom-Jwk } | Should -Throw
            }

            # Test invalid in each one of these p,q,dp,dq,qi
            It "throws on invalid priv key params #1" {
                $invalidPriv = $goodJwkObj | Select kty,e,n,d,q,dp,dq,qi,@{L='p';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidPriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on invalid priv key params #2" {
                $invalidPriv = $goodJwkObj | Select kty,e,n,d,p,dp,dq,qi,@{L='q';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidPriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on invalid priv key params #3" {
                $invalidPriv = $goodJwkObj | Select kty,e,n,d,p,q,dq,qi,@{L='dp';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidPriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on invalid priv key params #4" {
                $invalidPriv = $goodJwkObj | Select kty,e,n,d,p,q,dp,qi,@{L='dq';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidPriv | ConvertFrom-Jwk } | Should -Throw
            }
            It "throws on invalid priv key params #5" {
                $invalidPriv = $goodJwkObj | Select kty,e,n,d,p,q,dp,dq,@{L='qi';E={'12345'}} | ConvertTo-Json -Compress
                { $invalidPriv | ConvertFrom-Jwk } | Should -Throw
            }
            
        }

    }

}