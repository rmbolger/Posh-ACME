# Note: These tests depend on knowing the paramters associated with some of the actual
# DNS plugins. So if the parameters in the plugins change, the tests will need updating
# as well.

Describe "Export-PluginArgs" {

    BeforeAll {
        # copy a fake config root to the test drive
        Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "No account" {
        It "Throws" {
            InModuleScope Posh-ACME {
                Mock Get-PAAccount {}
                { Export-PluginArgs 'fakedomain' 'Route53' @{} } | Should -Throw "*No ACME account*"
            }
        }
    }

    Context "Order doesn't exist" {
        It "Throws" {
            InModuleScope Posh-ACME {
                $pargs = @{R53ProfileName='fake-profile'}
                { Export-PluginArgs 'fakedomain' Route53 $pargs }          | Should -Throw
                { Export-PluginArgs 'fakedomain' Route53,Infoblox $pargs } | Should -Throw
            }
        }
    }

    Context "No existing plugin data" {

        BeforeAll {
            # switch to the test account with no plugin data
            '22222' | Out-File 'TestDrive:\acme.test\current-account.txt'
            InModuleScope Posh-ACME { Import-PAConfig }
            $jsonPath = 'TestDrive:\acme.test\22222\!.example.org\pluginargs.json'
        }

        BeforeEach {
            Remove-Item $jsonPath -Force -EA Ignore
        }

        It "Saves all plugin-specific args" -TestCases @(
            @{ splat=@{ Plugin='Route53'; PluginArgs=@{} } }
            @{ splat=@{ Plugin='Route53'; PluginArgs=@{bad1='asdf'} } }
            @{ splat=@{ Plugin='Route53'; PluginArgs=@{R53AccessKey='asdf';bad1='asdf'} } }
            @{ splat=@{ Plugin='Route53'; PluginArgs=@{R53AccessKey='asdf';R53SecretKeyInsecure='qwer';bad1='asdf'} } }
            @{ splat=@{ Plugin='Route53'; PluginArgs=@{R53AccessKey='asdf';R53SecretKeyInsecure='qwer';bad1='1234';bad2=5678} } }
            @{ splat=@{ Plugin='Route53'; PluginArgs=@{R53AccessKey='asdf';R53SecretKeyInsecure='qwer'} } }
            @{ splat=@{ Plugin='Route53'; PluginArgs=@{R53AccessKey='asdf'} } }
            @{ splat=@{ Plugin='AcmeDns','DeSEC'; PluginArgs=@{ACMEServer='asdf';DSTTL=123;bad1='asdf';bad2=456} } }
        ) {
            InModuleScope Posh-ACME -Parameters @{Splat=$splat} {
                param($Splat)
                Export-PluginArgs '*.example.org' @Splat
            }

            $jsonPath | Should -Exist
            { Get-Content $jsonPath -Raw | ConvertFrom-Json } | Should -Not -Throw

            $result = Get-PAPluginArgs $splat.MainDomain
            $paramAllowed = $splat.Plugin | ForEach-Object { Get-PAPlugin $_ -Param } |
                Select-Object -Expand Parameter | Sort-Object -Unique

            # everything from the original PluginArgs should match
            $splat.PluginArgs.GetEnumerator() | ForEach-Object {
                if ($_.Key -in $paramAllowed) {
                    $result[$_.Key] | Should -Be $_.Value
                } else {
                    $result[$_.Key] | Should -BeNullOrEmpty
                }
            }
        }

        It "Exports All Supported Data Types" {
            $secstring = ConvertTo-SecureString 'secstring' -AsPlainText -Force
            $pArgs = @{
                ACMEServer = 'string'
                ACMEAllowFrom = 'a','b','c'
                ACMERegistration = @{
                    'domain1' = @('d','e','f')
                    'domain2' = @('g','h','i')
                }
                DSTTL = 123
                DSToken = $secstring
                IBCred = [pscredential]::new('admin1',$secstring)
                IBIgnoreCert = $true
            }
            InModuleScope Posh-ACME -Parameters @{PArgs=$pArgs} {
                param($PArgs)
                Export-PluginArgs '*.example.org' -Plugin 'AcmeDns','DeSEC','Infoblox' -PluginArgs $PArgs
            }

            $jsonPath | Should -Exist
            { Get-Content $jsonPath -Raw | ConvertFrom-Json } | Should -Not -Throw

            $json = Get-Content $jsonPath -Raw | ConvertFrom-Json

            $json.ACMEServer               | Should -Be 'string'
            $json.ACMEAllowFrom            | Should -HaveCount 3
            $json.ACMEAllowFrom            | Should -Be 'a','b','c'
            $json.ACMERegistration.domain1 | Should -Not -BeNullOrEmpty
            $json.ACMERegistration.domain1 | Should -HaveCount 3
            $json.ACMERegistration.domain1 | Should -Be 'd','e','f'
            $json.ACMERegistration.domain2 | Should -Not -BeNullOrEmpty
            $json.ACMERegistration.domain2 | Should -HaveCount 3
            $json.ACMERegistration.domain2 | Should -Be 'g','h','i'
            $json.DSTTL                    | Should -Be 123
            $json.IBIgnoreCert             | Should -BeTrue

            $json.DSToken.origType | Should -Be 'securestring'
            $token = $json.DSToken.value | ConvertTo-SecureString
            $tokenPlain = [pscredential]::new('u',$token).GetNetworkCredential().Password
            $tokenPlain            | Should -Be 'secstring'

            $json.IBCred.origType | Should -Be 'pscredential'
            $json.IBCred.user     | Should -Be 'admin1'
            $pass = $json.IBCred.pass | ConvertTo-SecureString
            $passPlain = [pscredential]::new('u',$pass).GetNetworkCredential().Password
            $passPlain            | Should -Be 'secstring'
        }
    }

    Context "Existing Plugin Data" {

        BeforeAll {
            # switch to the test account with no plugin data
            '22222' | Out-File 'TestDrive:\acme.test\current-account.txt'
            InModuleScope Posh-ACME { Import-PAConfig }
            $jsonPath = 'TestDrive:\acme.test\22222\!.example.org\pluginargs.json'
        }

        BeforeEach {
            Remove-Item $jsonPath -Force -EA Ignore
        }

        It "Replaces 1 param set with another" {
            $set1 = @{ R53ProfileName = 'xxxxx' }
            $set2 = @{ R53AccessKey = 'yyyyy'; R53SecretKeyInsecure='zzzzz' }

            $set1 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{PArgs=$set2} {
                param($PArgs)
                Export-PluginArgs '*.example.org' -Plugin 'Route53' -PluginArgs $PArgs
            }

            $result = Get-PAPluginArgs
            $result.R53ProfileName       | Should -BeNullOrEmpty
            $result.R53AccessKey         | Should -Be 'yyyyy'
            $result.R53SecretKeyInsecure | Should -Be 'zzzzz'

            $set2 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{PArgs=$set1} {
                param($PArgs)
                Export-PluginArgs '*.example.org' -Plugin 'Route53' -PluginArgs $PArgs
            }

            $result = Get-PAPluginArgs
            $result.R53ProfileName       | Should -Be 'xxxxx'
            $result.R53AccessKey         | Should -BeNullOrEmpty
            $result.R53SecretKeyInsecure | Should -BeNullOrEmpty
        }

        It "Only replaces param sets for specified plugins" {

            $set1 = @{ R53ProfileName = 'xxxxx'; Fake1='asdf'; ACMEServer='qwer' }
            $set2 = @{ R53AccessKey = 'yyyyy'; R53SecretKeyInsecure='zzzzz'; ACMEServer='newvalue' }

            $set1 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{PArgs=$set2} {
                param($PArgs)
                Export-PluginArgs '*.example.org' -Plugin 'Route53' -PluginArgs $PArgs
            }

            $result = Get-PAPluginArgs
            $result.R53ProfileName       | Should -BeNullOrEmpty
            $result.Fake1                | Should -Be 'asdf'
            $result.ACMEServer           | Should -Be 'qwer'
            $result.R53AccessKey         | Should -Be 'yyyyy'
            $result.R53SecretKeyInsecure | Should -Be 'zzzzz'

            $set1 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{PArgs=$set2} {
                param($PArgs)
                Export-PluginArgs '*.example.org' -Plugin 'Route53','AcmeDns' -PluginArgs $PArgs
            }

            $result = Get-PAPluginArgs
            $result.R53ProfileName       | Should -BeNullOrEmpty
            $result.Fake1                | Should -Be 'asdf'
            $result.ACMEServer           | Should -Be 'newvalue'
            $result.R53AccessKey         | Should -Be 'yyyyy'
            $result.R53SecretKeyInsecure | Should -Be 'zzzzz'

        }
    }

}
