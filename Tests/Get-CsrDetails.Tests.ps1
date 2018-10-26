Get-Module Posh-ACME | Remove-Module -Force
Import-Module $PSScriptRoot\..\Posh-ACME\Posh-ACME.psm1 -Force

Describe "Extract-DomainsFromCSR" {
  InModuleScope Posh-ACME {
    #Tests
    Context "CSR with CN missing in SAN section" {
      $Test_CN_Missing_in_SAN=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_CN_Missing_in_SAN -Value "-----BEGIN CERTIFICATE REQUEST-----
MIIE3DCCAsQCAQAwVzELMAkGA1UEBhMCQUExEjAQBgNVBAgMCVNvbWV3aGVyZTEN
MAsGA1UEBwwEb3ZlcjEQMA4GA1UECgwHcmFpbmJvdzETMBEGA1UEAwwKZ29vZ2xl
LmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKgbmA331u+tRLL9
bBBptLY8OQELTsQpJR1kTPtIK9Oyhb9bRo/UL5lWJSMiaQLvkABgbdxKzFyPt4Hh
R+kTDubRmvvFS/AK14xv15w40enVGulNdypVxZ9W6Uavhnje+BhEvpyCB7vO4Q/o
VanMp3dISs0kHp/IxZLRy76x2wv8eOEfP0e4M+PIgSZ+3RVikasvIXFLkIfO5hFt
lajZTwuW1Tp+i8tkO8olEGrCnUgU66SyIZsjQXJGuNHK8MPttXZ1Y/8NSvCoYCCl
mmQiGj5HZOdd6v32ZHqjhkRtM5M0zI4aTU7oCcAlEvZpPEbOWPlIYgaER24lnmse
X5JWWHlknlHa3x6r4MxMux4acUwlPVxlk3g41c03YxQHkPLPII1VMV9FXB+qDe4k
X5ilkI8X4WsvTcJqlAD+pEECv9zuNh1WDICuzeZqfLreR5Gb9lWyehfaU1WM///5
uHb+cef7NugE46k8UkJ8yQ9t2aAh6i9IFYgEtUUdUPA6zDToSB82IJAB1aDoLoIE
sk+sAaSlQ6Y2uB+L8WhHyVvfqKx5dlWisyR9kRkxaoPJpqazYnBEK2z3bxYtWp9c
oMus08fznLd82100hHWz3bgTatgo3AmakW+xD3YUE7JDKElgMwcUgwEKhjvQkAnP
RiOVz9riYNcEVmQfeeziCzE/Mai5AgMBAAGgQDA+BgkqhkiG9w0BCQ4xMTAvMC0G
A1UdEQQmMCSCDW1pY3Jvc29mdC5jb22CDWFsdGF2aXN0YS5jb22HBAECAwQwDQYJ
KoZIhvcNAQELBQADggIBAJRzYcsQrdTyG1iBjvjah258oXdSVfo+k0kI6+OpkGRB
xqxJWFW+COHBgomn8+v2hY/12XU8apejuSIwdmwqg0gic8PYdROmsL/KrrViNLMv
+sQs4gPj8Ks90vGYAkr24InCF78ccjNqnN2Kvpo0rGwQ8p5062hc7o/KZDAUSGml
Z7rlz/fuwbnakE9lXtEBMDdyoWerBp9lAcUc5JHpcKRP/dswwrW/wtg+BoxZ8wTv
o3lFQsSqftkPGY3KPVDv6pobph9oPdx0FJPh08friKDiQ0spO/2vnUjmP16ib348
2Yh15GkXBNxgDQyF9jKG+k9xgjaKOh2pO7HpvxvIaAUac5pn6TPAwxSWysmC6SdX
QC9oTrWxyZvSy3jXs4wg4b4INvad5Qwt0TSzrJ0tlJVLB2Pu205MfFTgs0NKdh+Y
MT+ZlSHt983uhyYVllooJkhxu5GiK9JmX2Mf/DA0nsZ1hq9E1EGDEYg/FpjbRAi3
G/2gvCULrN2NOzbSaOqH4/iRhneulGthpDIRCbm/vj6pXQnpwIIYB+La1M21pEoZ
Pph2B+E2zDl+vh8F4ntFCuf7dijlvxJjK2tlyBqinbvJ7hWOVut8KR4H/9m+WelV
bfPqjWpn5X1ogrzpwffs3AOV1+9vTVDdKVllq1c1P+lsFfvHEAYPrUgpotuxfxZz
-----END CERTIFICATE REQUEST-----
"
      It "Test domain count" {(Get-CsrDetails -CSRPath $Test_CN_Missing_in_SAN).Domain |Should -HaveCount 3}
      It "First domain" {(Get-CsrDetails -CSRPath $Test_CN_Missing_in_SAN).Domain|Select -First 1 |Should Be 'google.com'}
      It "Keylength" {(Get-CsrDetails -CSRPath $Test_CN_Missing_in_SAN).KeyLength |Should Be 4096}
      Remove-Item -Path $Test_CN_Missing_in_SAN
    }
    Context "CSR with CN in SAN section" {
      $Test_Correct_CN_and_SAN=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_Correct_CN_and_SAN -Value "-----BEGIN CERTIFICATE REQUEST-----`nMIIC5DCCAcwCAQAwUzELMAkGA1UEBhMCQkIxEjAQBgNVBAgMCXNvbWV3aGVyZTEN`nMAsGA1UEBwwEb3ZlcjEMMAoGA1UECgwDdGhlMRMwEQYDVQQDDApnb29nbGUuY29t`nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp7EZJCpmto7VRqKI76Nl`nVP6HEb4nyIPMFRRDYOPRTNenBaJ+cCm52yVZPg4RdJc0nmile4z00GCgOGFt5TV+`nxkc4h5POOpm1Np4qo8h8CjXD6O89Z6b3jPSZlk2Fh2ktnTpOgCi24TGyUa5YAnkV`nmN0baXI5aWBZjDMyXR9TYiuRiumJWek+6Ufzho5pyX93mbTD6pT0HH1LaeTY6i+U`ngDkAItPXJwPXEbcAUCqWAPKnFY3bJ9gUhv/YDLWENAxULo8V4SwWLqNCehWwgyCp`nrk9BWyPnFv/PrXPx6nUKf/PipSAT4PL6H88y8iyTLIPn/X2/lvLWfXRGILKCdz+a`nDwIDAQABoEwwSgYJKoZIhvcNAQkOMT0wOzA5BgNVHREEMjAwggpnb29nbGUuY29t`ngg1taWNyb3NvZnQuY29tgg1BbHRhVmlzdGEuY29thwQBAgMEMA0GCSqGSIb3DQEB`nCwUAA4IBAQBp48wlu+FMc1XT9C60Tj0eXvcJxgJ20CK3zB2GdUpnyRwyCWex2Ad1`n+4iKlDhxC37dteXGDR7ggZNVVyoSvxs80rupvSMZNkkmPns9UO2Rwc4bv/vubzlS`nkKe2yKTwchalRyivnZezuSH7a1awxBEGZLWOPd+EdzmgWX8s3yDU3oOig84wqEkQ`nT7VuZnGqOw6CjGhF8BLq/HKzqsQpI+GpbQ4v3X0wKYW002gAc1smDOr38t5eOUwN`nID3SWluCTwZU6Y6GYJ+1Aam1tXA8t+6hh862TH8Y1BqMlRISU/04OKB9+LvrfeiE`nnhqIWKPPfGkRgiizMd2fO3VI8O6DeAFf`n-----END CERTIFICATE REQUEST-----"
      It "Test domain count" {(Get-CsrDetails -CSRPath $Test_Correct_CN_and_SAN).domain |Should -HaveCount 3}
      It "First domain" {(Get-CsrDetails -CSRPath $Test_Correct_CN_and_SAN).Domain|Select -First 1 |Should Be 'google.com'}
      It "Keylength" {(Get-CsrDetails -CSRPath $Test_Correct_CN_and_SAN).KeyLength |Should Be 2048}
      Remove-Item -Path $Test_Correct_CN_and_SAN
    }
    Context "CSR with no CN but correct SAN section" {
      $Test_No_CN=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_No_CN -Value "-----BEGIN CERTIFICATE REQUEST-----`nMIICzzCCAbcCAQAwPjELMAkGA1UEBhMCQUExEjAQBgNVBAgMCVNvbWV3aGVyZTEN`nMAsGA1UEBwwEb3ZlcjEMMAoGA1UECgwDdGhlMIIBIjANBgkqhkiG9w0BAQEFAAOC`nAQ8AMIIBCgKCAQEAwozb60zn4s3BYuFY2YC6K8CV1m4l2OC/j+bAvuApMv5slo9w`na51c4GC01xjuD1M4EduTY6mzAlX3+eSp+o5R5O6YmYqDWKjy7J54G4yTac/SHGf7`nnaegMkKWRqa4HWHZdujJSUN9jbPXbBxyIqy9O91KEh+n3hQ2I7Gtn8DYLrgqGK7/`nb6IMh3gvEAY+Nl8QEdz0qF+IKZWt/d7yHtrDpKx+YuNzzvObqyON9D2YOPajl4Ct`n2FZiIWJ/kKUFaCsUK1erayVKyQPByTKYLKPrGvOH3Ut5WfyJHOY0MGqaEl8e2Ze9`nYrs+Vv6fZLm4BkiiWcA+GSjL+MVrITbN7OALxQIDAQABoEwwSgYJKoZIhvcNAQkO`nMT0wOzA5BgNVHREEMjAwggpnb29nbGUuY29tgg1taWNyb3NvZnQuY29tgg1BbHRh`nVmlzdGEuY29thwQBAgMEMA0GCSqGSIb3DQEBCwUAA4IBAQB+5kMcIsS4ngD1S+Kn`n3dAVnMGvZ7+PNDLUiCispVT4GU6ovyZU6CsvJ1Fr5GdIts5q+ZabDC/lUTvWG0ZD`n7kAY5nAdsQ3HN5nprebfDlZL6c89HxyWYYHthT5yZxD3+JaI9bwxJGuYYEoWLSBX`nfM1ewMWviOtMCB7KUmnRs5YckRP+EVrBCET9OJ5DoxyqsAa6A5/puBqFR7L4HY16`nw/r2+KN5HmT+EWxG+rmWkJFVFfE+kO4ql/WZwjFGxFlBAwGVf7UB3TF1GGsRi8NH`nK0n1RxWDrgLe0fXL2Qr89KgoG+l75VHCUsIyKxZ9PK//2rbk17xDw+Poq6P9v6Nb`nJslp`n-----END CERTIFICATE REQUEST-----"
      It "Test domain count" {(Get-CsrDetails -CSRPath $Test_No_CN).Domain |Should -HaveCount 3}
      It "First domain" {(Get-CsrDetails -CSRPath $Test_No_CN).Domain |Select -First 1 |Should Be 'google.com'}
      It "Keylength" {(Get-CsrDetails -CSRPath $Test_No_CN).KeyLength |Should Be 2048}
      Remove-Item -Path $Test_No_CN
    }
    Context "Broken CSR" {
      $Test_BrokenCSR=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_BrokenCSR -Value "-----BEGIN CERTIFICATE REQUEST-----`nLoremIpsumDolorSitAmet`n-----END CERTIFICATE REQUEST-----"
      It "Get out of here" {{Get-CsrDetails -CSRPath $Test_BrokenCSR }|Should -Throw}
      Remove-Item $Test_BrokenCSR
    }
  }
}