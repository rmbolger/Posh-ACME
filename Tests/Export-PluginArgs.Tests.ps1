# Note: These tests depend on knowing the paramters associated with some of the actual
# DNS plugins. So if the parameters in the plugins change, the tests will need updating
# as well.

Describe "Export-PluginArgs" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    Context "No account" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # remove the current account
            Remove-Item 'TestDrive:\srvr1\current-account.txt'

            InModuleScope Posh-ACME { Import-PAConfig }
        }

        It "Throws" {
            InModuleScope Posh-ACME {
                $order = [pscustomobject]@{
                    PSTypeName = 'PoshACME.PAOrder'
                    Name = 'fakeorder'
                    MainDomain = 'fakedomain'
                    Folder = 'TestDrive:\'
                    Plugin = 'Route53'
                }
                { Export-PluginArgs -Order $order -PluginArgs @{} } | Should -Throw "*No ACME account*"
            }
        }
    }

    Context "No existing plugin data" {

        BeforeAll {
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # switch to the test account with no plugin data
            'acct2' | Out-File 'TestDrive:\srvr1\current-account.txt'
            InModuleScope Posh-ACME { Import-PAConfig }
            $jsonPath = 'TestDrive:\srvr1\acct2\!.example.org\pluginargs.json'
        }

        BeforeEach {
            Remove-Item $jsonPath -Force -EA Ignore
        }

        It "Saves all plugin-specific args" -TestCases @(
            @{ Plugin='Route53';         PArgs=@{} }
            @{ Plugin='Route53';         PArgs=@{bad1='asdf'} }
            @{ Plugin='Route53';         PArgs=@{R53AccessKey='asdf';bad1='asdf'} }
            @{ Plugin='Route53';         PArgs=@{R53AccessKey='asdf';R53SecretKeyInsecure='qwer';bad1='asdf'} }
            @{ Plugin='Route53';         PArgs=@{R53AccessKey='asdf';R53SecretKeyInsecure='qwer';bad1='1234';bad2=5678} }
            @{ Plugin='Route53';         PArgs=@{R53AccessKey='asdf';R53SecretKeyInsecure='qwer'} }
            @{ Plugin='Route53';         PArgs=@{R53AccessKey='asdf'} }
            @{ Plugin='AcmeDns','DeSEC'; PArgs=@{ACMEServer='asdf';DSTTL=123;bad1='asdf';bad2=456} }
        ) {
            $order = Get-PAOrder -Name '!.example.org'
            $order.Plugin = $Plugin

            InModuleScope Posh-ACME -Parameters @{Order=$order; PArgs=$PArgs} {
                param($Order,$PArgs)
                Export-PluginArgs -Order $order -PluginArgs $PArgs
            }

            $jsonPath | Should -Exist
            { Get-Content $jsonPath -Raw | ConvertFrom-Json } | Should -Not -Throw

            $result = $order | Get-PAPluginArgs
            $paramAllowed = $order.Plugin | ForEach-Object { Get-PAPlugin $_ -Param } |
                Select-Object -Expand Parameter | Sort-Object -Unique

            # everything from the original PluginArgs should match
            $PArgs.GetEnumerator() | ForEach-Object {
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

            $order = Get-PAOrder -Name '!.example.org'
            $order.Plugin = 'AcmeDns','DeSEC','Infoblox'

            InModuleScope Posh-ACME -Parameters @{Order=$order; PArgs=$pArgs} {
                param($Order,$PArgs)
                Export-PluginArgs -Order $Order -PluginArgs $PArgs
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
            # copy a fake config root to the test drive
            Get-ChildItem "$PSScriptRoot\TestFiles\ConfigRoot\" | Copy-Item -Dest 'TestDrive:\' -Recurse
            # switch to the test account with no plugin data
            'acct2' | Out-File 'TestDrive:\srvr1\current-account.txt'
            InModuleScope Posh-ACME { Import-PAConfig }
            $jsonPath = 'TestDrive:\srvr1\acct2\!.example.org\pluginargs.json'
        }

        BeforeEach {
            Remove-Item $jsonPath -Force -EA Ignore
        }

        It "Replaces 1 param set with another" {
            $set1 = @{ R53ProfileName = 'xxxxx' }
            $set2 = @{ R53AccessKey = 'yyyyy'; R53SecretKeyInsecure='zzzzz' }

            $order = Get-PAOrder -Name '!.example.org'
            $order.Plugin = 'Route53'

            $set1 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{Order=$order; PArgs=$set2} {
                param($Order,$PArgs)
                Export-PluginArgs -Order $Order -PluginArgs $PArgs
            }

            $result = $order | Get-PAPluginArgs
            $result.R53ProfileName       | Should -BeNullOrEmpty
            $result.R53AccessKey         | Should -Be 'yyyyy'
            $result.R53SecretKeyInsecure | Should -Be 'zzzzz'

            $set2 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{Order=$order; PArgs=$set1} {
                param($Order,$PArgs)
                Export-PluginArgs -Order $Order -PluginArgs $PArgs
            }

            $result = $order | Get-PAPluginArgs
            $result.R53ProfileName       | Should -Be 'xxxxx'
            $result.R53AccessKey         | Should -BeNullOrEmpty
            $result.R53SecretKeyInsecure | Should -BeNullOrEmpty
        }

        It "Only replaces param sets for specified plugins" {

            $set1 = @{ R53ProfileName = 'xxxxx'; Fake1='asdf'; ACMEServer='qwer' }
            $set2 = @{ R53AccessKey = 'yyyyy'; R53SecretKeyInsecure='zzzzz'; ACMEServer='newvalue' }

            $order = Get-PAOrder -Name '!.example.org'
            $order.Plugin = 'Route53'

            $set1 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{Order=$order; PArgs=$set2} {
                param($Order,$PArgs)
                Export-PluginArgs -Order $Order -PluginArgs $PArgs
            }

            $result = $order | Get-PAPluginArgs
            $result.R53ProfileName       | Should -BeNullOrEmpty
            $result.Fake1                | Should -Be 'asdf'
            $result.ACMEServer           | Should -Be 'qwer'
            $result.R53AccessKey         | Should -Be 'yyyyy'
            $result.R53SecretKeyInsecure | Should -Be 'zzzzz'

            $order.Plugin = 'Route53','AcmeDns'
            $set1 | ConvertTo-Json | Out-File $jsonPath -Encoding utf8
            InModuleScope Posh-ACME -Parameters @{Order=$order; PArgs=$set2} {
                param($Order,$PArgs)
                Export-PluginArgs -Order $Order -PluginArgs $PArgs
            }

            $result = $order | Get-PAPluginArgs
            $result.R53ProfileName       | Should -BeNullOrEmpty
            $result.Fake1                | Should -Be 'asdf'
            $result.ACMEServer           | Should -Be 'newvalue'
            $result.R53AccessKey         | Should -Be 'yyyyy'
            $result.R53SecretKeyInsecure | Should -Be 'zzzzz'

        }
    }

}
