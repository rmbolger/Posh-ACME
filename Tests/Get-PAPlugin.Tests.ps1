Describe "Get-PAPlugin" {

    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..\Posh-ACME\Posh-ACME.psd1') -Force
    }

    It "Returns the DNSExit plugin details" {
        $result = Get-PAPlugin DNSExit

        $result | Should Not BeNullOrEmpty
        $result.Name | Should Be 'DNSExit'
        $result.ChallengeType | Should Be 'dns-01'
        $result.Path | Should Match 'DNSExit\.ps1$'
    }

    It "Returns the DNSExit plugin parameter metadata" {
        $result = Get-PAPlugin DNSExit -Params

        $result | Should Not BeNullOrEmpty

        $paramNames = @($result.Parameter | Sort-Object -Unique)
        ($paramNames -contains 'DNSExitApiKey') | Should Be $true
        ($paramNames -contains 'DNSExitDomain') | Should Be $true
        ($paramNames -contains 'DNSExitTTL') | Should Be $true
        ($paramNames -contains 'DNSExitApiUri') | Should Be $true

        $apiKeyParam = $result | Where-Object { $_.Parameter -eq 'DNSExitApiKey' } | Select-Object -First 1
        $apiKeyParam.ParameterType | Should Be ([securestring])
        $apiKeyParam.IsMandatory | Should Be $true

        $domainParam = $result | Where-Object { $_.Parameter -eq 'DNSExitDomain' } | Select-Object -First 1
        $domainParam.ParameterType | Should Be ([string[]])
        $domainParam.IsMandatory | Should Be $true
    }
}
