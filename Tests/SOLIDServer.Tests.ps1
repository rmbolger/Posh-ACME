Describe 'SOLIDServer SHA3 fallback' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '../Posh-ACME/Posh-ACME.psd1') -Force
        $pluginPath = Join-Path $PSScriptRoot '../Posh-ACME/Plugins/SOLIDServer.ps1'
    }

    AfterAll {
        Remove-Module Posh-ACME -ErrorAction Ignore
    }

    It 'Uses CryptoHelper when native SHA3 is unavailable' -Skip:$IsCoreCLR {
        $hash = InModuleScope Posh-ACME -Parameters @{ PluginPath = $pluginPath } {
            . $PluginPath
            Get-SHA3_256 'abc'
        }
        $hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
    }
}
