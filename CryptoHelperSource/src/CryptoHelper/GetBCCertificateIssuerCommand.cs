using System;
using System.IO;
using System.Management.Automation;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.X509;

namespace CryptoHelper;

[Cmdlet(VerbsCommon.Get, "BCCertificateIssuer")]
[OutputType(typeof(string))]
public sealed class GetBCCertificateIssuerCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public string Pem { get; set; } = string.Empty;

    protected override void ProcessRecord()
    {
        using var input = new StringReader(Pem);
        var reader = new PemReader(input);
        if (reader.ReadObject() is not X509Certificate certificate)
        {
            throw new ArgumentException("The PEM input must contain an X.509 certificate.", nameof(Pem));
        }

        foreach (string issuer in certificate.IssuerDN.GetValueList(X509Name.CN))
        {
            WriteObject(issuer);
        }
    }
}
