Describe "Import-PluginDetail" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1')
    }

    It "Uses the plugin name as the key for every plugin" {
        InModuleScope Posh-ACME {
            $mismatched = $script:Plugins.GetEnumerator() |
                Where-Object { $_.Key -ne $_.Value.Name } |
                ForEach-Object { $_.Key }

            $mismatched | Should -BeNullOrEmpty
        }
    }
}
