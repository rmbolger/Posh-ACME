@{
    RootModule = 'CryptoHelper.psm1'
    ModuleVersion = '0.1.0'
    GUID = '960cf6f8-8d19-44fa-b98c-c98c61c24685'
    Author = 'Ryan Bolger'
    Copyright = '(c) 2026 Ryan Bolger. All rights reserved.'
    Description = 'Crypto helper functions using an assembly-isolated BouncyCastle library'
    CompatiblePSEditions = @('Desktop', 'Core')
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.1'
    FunctionsToExport = @()
    CmdletsToExport = @(
        'Get-Sha3Hash'
        'Get-CertDetail'
        'Get-CsrDetail'
        'New-CsrHelper'
        'ConvertFrom-PemPrivateKey'
    )
    VariablesToExport = @()
    AliasesToExport = @()
}
