# The version of Invoke-RestMethod included with PowerShell Core 6 now has a
# native -SkipCertificateCheck parameter. So we don't always need to mess around with
# ServicePointManager anymore. But rather than checking $PSVersionTable.PSEdition,
# we're going to explicitly check the parameter list of Invoke-RestMethod.
if ('SkipCertificateCheck' -notin (Get-Command Invoke-RestMethod).Parameters.Keys) {

    $script:SkipCertSupported = $false

    # Add our custom type for manipulating .NET cert validation
    if (-not ([System.Management.Automation.PSTypeName]'CertValidation').Type)
    {
        Add-Type @"
            using System.Net;
            using System.Net.Security;
            using System.Security.Cryptography.X509Certificates;
            public class CertValidation
            {
                static bool IgnoreValidation(object o, X509Certificate c, X509Chain ch, SslPolicyErrors e) {
                    return true;
                }
                public static void Ignore() {
                    ServicePointManager.ServerCertificateValidationCallback += IgnoreValidation;
                }
                public static void Restore() {
                    ServicePointManager.ServerCertificateValidationCallback -= IgnoreValidation;
                }
            }
"@
    }

} else {
    # remember that we can use SkipCertificateCheck
    $script:SkipCertSupported = $true
}

# The version of Invoke-RestMethod included with PowerShell Core 6 now has a native
# -SslProtocol parameter. According to the docs, it defaults to supporting all
# protocols "supported by the system". So we shouldn't need to tweak the supported
# protocols in [Net.ServicePointManager] like we do for the Desktop edition.
if ('SslProtocol' -notin (Get-Command Invoke-RestMethod).Parameters.Keys) {

    # In all of the PowerShell environments tested so far, the set of supported TLS protocols
    # configured by default in .NET seem to only include SSLv3 and TLSv1.0. So even if .NET
    # supports using things like TLS 1.1 or 1.2, cmdlets like Invoke-RestMethod will be limited
    # to TLS 1.0 unless the setting is overridden (per session).
    #
    # To give users a more secure default when using this module and try to prevent potential errors
    # when running against servers that have disabled TLS 1.0, we will change the default set
    # of protocols to include all protocol types beyond 1.0 (or currently configured max level)
    # supported in the current installed .NET framework.
    $currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__,[Net.SecurityProtocolType]::Tls.value__)
    $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTls }
    $newTlsTypes | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }

}
