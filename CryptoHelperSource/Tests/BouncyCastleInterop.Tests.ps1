Describe 'CryptoHelper with an earlier 2.x BouncyCastle.Cryptography already loaded' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
    BeforeAll {
        $packageRoot = if ($env:NUGET_PACKAGES) { $env:NUGET_PACKAGES } else {
            Join-Path ([Environment]::GetFolderPath('UserProfile')) '.nuget/packages'
        }
        $framework = if ($PSVersionTable.PSEdition -eq 'Core') { 'net6.0' } else { 'net461' }
        $olderDll = Join-Path $packageRoot "bouncycastle.cryptography/2.2.1/lib/$framework/BouncyCastle.Cryptography.dll"
        if (-not (Test-Path $olderDll)) {
            $cacheDir = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.cache/Posh-ACME/test-assets/bouncycastle.cryptography/2.2.1'
            $olderDll = Join-Path $cacheDir "lib/$framework/BouncyCastle.Cryptography.dll"
            if (-not (Test-Path $olderDll)) {
                New-Item -ItemType Directory -Path (Split-Path $olderDll) -Force | Out-Null
                $archivePath = Join-Path $cacheDir "$([guid]::NewGuid()).nupkg"
                try {
                    Invoke-WebRequest -Uri 'https://api.nuget.org/v3-flatcontainer/bouncycastle.cryptography/2.2.1/bouncycastle.cryptography.2.2.1.nupkg' -OutFile $archivePath -UseBasicParsing -ErrorAction Stop
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
                    try {
                        $entry = $archive.GetEntry("lib/$framework/BouncyCastle.Cryptography.dll")
                        if (-not $entry) { throw "BouncyCastle.Cryptography 2.2.1 has no $framework assembly." }
                        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $olderDll)
                    } finally {
                        $archive.Dispose()
                    }
                } finally {
                    Remove-Item $archivePath -ErrorAction SilentlyContinue
                }
            }
        }
        $olderAssembly = [Reflection.Assembly]::LoadFrom($olderDll)
        $modulePath = Join-Path $PSScriptRoot '../../Posh-ACME/CryptoHelper/CryptoHelper.psd1'
        Import-Module $modulePath -ErrorAction Stop
    }

    It 'binds BouncyCastle by assembly identity after preloading 2.2.1' {
        'abc' | Get-Sha3Hash | Should -BeExactly '3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532'
        $request = New-Csr -KeyLength '2048' -Subject 'CN=interop.example'
        $request.RequestPem | Should -Match '-----BEGIN CERTIFICATE REQUEST-----'

        $assemblies = @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {
            $_.GetName().Name -eq 'BouncyCastle.Cryptography'
        })
        $olderAssembly | Should -BeIn $assemblies
        $olderAssembly.GetName().Version.ToString() | Should -Be '2.0.0.0'
        if ($PSVersionTable.PSEdition -eq 'Core') {
            $assemblies | Should -HaveCount 2
            $bundled = @($assemblies | Where-Object {
                [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_).Name -eq 'CryptoHelper'
            })
            [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($olderAssembly) |
                Should -Be ([Runtime.Loader.AssemblyLoadContext]::Default)
            $bundled | Should -HaveCount 1
            ([Diagnostics.FileVersionInfo]::GetVersionInfo($bundled[0].Location).FileVersion) | Should -BeLike '2.7.0.*'
        } else {
            $assemblies | Should -HaveCount 1
        }
        ([Diagnostics.FileVersionInfo]::GetVersionInfo($olderAssembly.Location).FileVersion) | Should -BeLike '2.2.1.*'
    }
}
