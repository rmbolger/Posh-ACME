Get-Module Posh-ACME | Remove-Module -Force
Import-Module $PSScriptRoot\..\Posh-ACME\Posh-ACME.psm1 -Force

Describe "Extract-DomainsFromCSR" {
  InModuleScope Posh-ACME {
    #Tests
    Context "CSR with CN missing in SAN section" {
      $Test_CN_Missing_in_SAN=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_CN_Missing_in_SAN -Value "-----BEGIN CERTIFICATE REQUEST-----`nMIICyzCCAbMCAQAwRjELMAkGA1UEBhMCQUExETAPBgNVBAgMCHJhaW5ib3dzMQ8w`nDQYDVQQHDAZmbHlpbmcxEzARBgNVBAMMCmdvb2dsZS5jb20wggEiMA0GCSqGSIb3`nDQEBAQUAA4IBDwAwggEKAoIBAQC0qnQwkwiSO1x53XOxpECoszv1ez1HvUt/oh0s`nsb4+7XvxgWZy+jYbD3Kkn+PHRIu3gf1Hx+qcF9+N2Zz6S/620lEKgbMezWCp9ef/`n1b40s1ShdnS6NSFVbATSNZpTd/DARFLH9X0gNAJ+8LevQgduNKUzCB2HSwBAD8N5`nDv3zg3OAyYf1cTSQ2GT3NMC5JcVRmtEzKzwfSMEfX9lf0zq7ze1b4K+58XBpZeKP`nC/YI5TvHJa0Nb9afFj1OnOrfqx6WgndB7MuwsGJQY5JFFwzgmkfp8QuW+IIeo88G`nTeFoWI0WA9t3/iBRLp9z5mzLNy2eD3Jd+yOTqULeOv1jHgKfAgMBAAGgQDA+Bgkq`nhkiG9w0BCQ4xMTAvMC0GA1UdEQQmMCSCDW1pY3Jvc29mdC5jb22CDWFsdGF2aXN0`nYS5jb22HBAECAwQwDQYJKoZIhvcNAQELBQADggEBAHd20UUxhQOqSp2DKYsJfRMA`nq6LtPSiQYiDtAeTctf7x9HSd+lxpm0NalGq0WdPZtnEHFCoID0a2bH3j/CNp0opI`nOg6OSS1iy/7WINONXnU4XoeNTvzTQ6GswC8zIrfE/1exJssJbaQD9DotXICz298S`nmHpGbzNp0DQSZMKLQHGXJXvrl2iOfieZueKkZqBI4+jji2dgVfNTdTPeiSR4q6gy`nmRgBRpENWoK5o7uTluYnu+/xhWuugnIg0hbHPkUFlAZwIiVo3SiRl3uw1Pgyg0ww`nvb7lZypMqJVXs3DDQCeIL63ZTGPx3lpjS5b1G2cvPPWOdXGVIG0oP7kAiL8DVyc=`n-----END CERTIFICATE REQUEST-----"
      It "Test domain count" {Extract-DomainsFromCSR -CSRPath $Test_CN_Missing_in_SAN |Should -HaveCount 3}
      It "First domain" {Extract-DomainsFromCSR -CSRPath $Test_CN_Missing_in_SAN|Select -First 1 |Should Be 'google.com'}
      Remove-Item -Path $Test_CN_Missing_in_SAN
    }
    Context "CSR with CN in SAN section" {
      $Test_Correct_CN_and_SAN=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_Correct_CN_and_SAN -Value "-----BEGIN CERTIFICATE REQUEST-----`nMIIC5DCCAcwCAQAwUzELMAkGA1UEBhMCQkIxEjAQBgNVBAgMCXNvbWV3aGVyZTEN`nMAsGA1UEBwwEb3ZlcjEMMAoGA1UECgwDdGhlMRMwEQYDVQQDDApnb29nbGUuY29t`nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAp7EZJCpmto7VRqKI76Nl`nVP6HEb4nyIPMFRRDYOPRTNenBaJ+cCm52yVZPg4RdJc0nmile4z00GCgOGFt5TV+`nxkc4h5POOpm1Np4qo8h8CjXD6O89Z6b3jPSZlk2Fh2ktnTpOgCi24TGyUa5YAnkV`nmN0baXI5aWBZjDMyXR9TYiuRiumJWek+6Ufzho5pyX93mbTD6pT0HH1LaeTY6i+U`ngDkAItPXJwPXEbcAUCqWAPKnFY3bJ9gUhv/YDLWENAxULo8V4SwWLqNCehWwgyCp`nrk9BWyPnFv/PrXPx6nUKf/PipSAT4PL6H88y8iyTLIPn/X2/lvLWfXRGILKCdz+a`nDwIDAQABoEwwSgYJKoZIhvcNAQkOMT0wOzA5BgNVHREEMjAwggpnb29nbGUuY29t`ngg1taWNyb3NvZnQuY29tgg1BbHRhVmlzdGEuY29thwQBAgMEMA0GCSqGSIb3DQEB`nCwUAA4IBAQBp48wlu+FMc1XT9C60Tj0eXvcJxgJ20CK3zB2GdUpnyRwyCWex2Ad1`n+4iKlDhxC37dteXGDR7ggZNVVyoSvxs80rupvSMZNkkmPns9UO2Rwc4bv/vubzlS`nkKe2yKTwchalRyivnZezuSH7a1awxBEGZLWOPd+EdzmgWX8s3yDU3oOig84wqEkQ`nT7VuZnGqOw6CjGhF8BLq/HKzqsQpI+GpbQ4v3X0wKYW002gAc1smDOr38t5eOUwN`nID3SWluCTwZU6Y6GYJ+1Aam1tXA8t+6hh862TH8Y1BqMlRISU/04OKB9+LvrfeiE`nnhqIWKPPfGkRgiizMd2fO3VI8O6DeAFf`n-----END CERTIFICATE REQUEST-----"
      It "Test domain count" {Extract-DomainsFromCSR -CSRPath $Test_Correct_CN_and_SAN |Should -HaveCount 3}
      It "First domain" {Extract-DomainsFromCSR -CSRPath $Test_Correct_CN_and_SAN|Select -First 1 |Should Be 'google.com'}
      Remove-Item -Path $Test_Correct_CN_and_SAN
    }
    Context "CSR with no CN but correct SAN section" {
      $Test_No_CN=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_No_CN -Value "-----BEGIN CERTIFICATE REQUEST-----`nMIICzzCCAbcCAQAwPjELMAkGA1UEBhMCQUExEjAQBgNVBAgMCVNvbWV3aGVyZTEN`nMAsGA1UEBwwEb3ZlcjEMMAoGA1UECgwDdGhlMIIBIjANBgkqhkiG9w0BAQEFAAOC`nAQ8AMIIBCgKCAQEAwozb60zn4s3BYuFY2YC6K8CV1m4l2OC/j+bAvuApMv5slo9w`na51c4GC01xjuD1M4EduTY6mzAlX3+eSp+o5R5O6YmYqDWKjy7J54G4yTac/SHGf7`nnaegMkKWRqa4HWHZdujJSUN9jbPXbBxyIqy9O91KEh+n3hQ2I7Gtn8DYLrgqGK7/`nb6IMh3gvEAY+Nl8QEdz0qF+IKZWt/d7yHtrDpKx+YuNzzvObqyON9D2YOPajl4Ct`n2FZiIWJ/kKUFaCsUK1erayVKyQPByTKYLKPrGvOH3Ut5WfyJHOY0MGqaEl8e2Ze9`nYrs+Vv6fZLm4BkiiWcA+GSjL+MVrITbN7OALxQIDAQABoEwwSgYJKoZIhvcNAQkO`nMT0wOzA5BgNVHREEMjAwggpnb29nbGUuY29tgg1taWNyb3NvZnQuY29tgg1BbHRh`nVmlzdGEuY29thwQBAgMEMA0GCSqGSIb3DQEBCwUAA4IBAQB+5kMcIsS4ngD1S+Kn`n3dAVnMGvZ7+PNDLUiCispVT4GU6ovyZU6CsvJ1Fr5GdIts5q+ZabDC/lUTvWG0ZD`n7kAY5nAdsQ3HN5nprebfDlZL6c89HxyWYYHthT5yZxD3+JaI9bwxJGuYYEoWLSBX`nfM1ewMWviOtMCB7KUmnRs5YckRP+EVrBCET9OJ5DoxyqsAa6A5/puBqFR7L4HY16`nw/r2+KN5HmT+EWxG+rmWkJFVFfE+kO4ql/WZwjFGxFlBAwGVf7UB3TF1GGsRi8NH`nK0n1RxWDrgLe0fXL2Qr89KgoG+l75VHCUsIyKxZ9PK//2rbk17xDw+Poq6P9v6Nb`nJslp`n-----END CERTIFICATE REQUEST-----"
      It "Test domain count" {Extract-DomainsFromCSR -CSRPath $Test_No_CN |Should -HaveCount 3}
      It "First domain" {Extract-DomainsFromCSR -CSRPath $Test_No_CN|Select -First 1 |Should Be 'google.com'}
      Remove-Item -Path $Test_No_CN
    }
    Context "Broken CSR" {
      $Test_BrokenCSR=[System.IO.Path]::GetTempFileName()
      Set-Content -Path $Test_BrokenCSR -Value "-----BEGIN CERTIFICATE REQUEST-----`nLoremIpsumDolorSitAmet`n-----END CERTIFICATE REQUEST-----"
      It "Get out of here" {{Extract-DomainsFromCSR -CSRPath $Test_BrokenCSR }|Should -Throw}
      Remove-Item $Test_BrokenCSR
    }
  }
}