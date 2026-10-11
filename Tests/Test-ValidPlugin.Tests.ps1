Describe "Test-ValidPlugin" {

    BeforeAll {
        $env:POSHACME_HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    It "Returns true for valid plugins" -TestCases @(
        @{ Plugin = 'Route53' }
        @{ Plugin = 'Manual' }
        @{ Plugin = 'Route53','Manual' }
    ) {
        InModuleScope Posh-ACME -Parameters @{ Plugin = $Plugin } {
            param($Plugin)
            Test-ValidPlugin $Plugin | Should -BeTrue
        }
    }

    It "Returns false for invalid plugins without ThrowOnFail" -TestCases @(
        @{ Plugin = 'NotARealPlugin' }
        @{ Plugin = 'Route53','NotARealPlugin' }
    ) {
        InModuleScope Posh-ACME -Parameters @{ Plugin = $Plugin } {
            param($Plugin)
            Test-ValidPlugin $Plugin | Should -BeFalse
        }
    }

    It "Throws for invalid plugins with ThrowOnFail" {
        InModuleScope Posh-ACME {
            { Test-ValidPlugin 'Route53','NotARealPlugin' -ThrowOnFail } |
                Should -Throw "NotARealPlugin plugin not found*"
        }
    }
}