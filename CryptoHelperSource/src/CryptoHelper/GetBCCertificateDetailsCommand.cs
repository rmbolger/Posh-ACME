using System;
using System.Collections.Generic;
using System.Net;
using System.Security.Cryptography;
using System.Management.Automation;
using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.X509;

namespace CryptoHelper;

[Cmdlet(VerbsCommon.Get, "BCCertificateDetails")]
[OutputType(typeof(PSObject))]
public sealed class GetBCCertificateDetailsCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public string Pem { get; set; } = string.Empty;

    protected override void ProcessRecord()
    {
        // parse the cert with PemReader
        using var input = new System.IO.StringReader(Pem);
        var reader = new PemReader(input);
        if (reader.ReadObject() is not X509Certificate certificate)
        {
            throw new ArgumentException("The PEM input must contain an X.509 certificate.", nameof(Pem));
        }

        // grab the SANs
        var altNames = new List<string>();
        foreach (IList<object> name in certificate.GetSubjectAlternativeNames() ?? Array.Empty<IList<object>>())
        {
            int tag = (int)name[0];
            string value = (string)name[1];
            if (tag == GeneralName.DnsName)
            {
                altNames.Add(value);
            }
            else if (tag == GeneralName.IPAddress)
            {
                var addressBytes = new byte[(value.Length - 1) / 2];
                for (int index = 0; index < addressBytes.Length; index++)
                {
                    addressBytes[index] = Convert.ToByte(value.Substring(1 + index * 2, 2), 16);
                }
                altNames.Add(new IPAddress(addressBytes).ToString());
            }
        }

        // compute the thumbprint
        byte[] encodedCertificate = certificate.GetEncoded();
        using var sha1 = SHA1.Create();
        string thumbprint = BitConverter.ToString(sha1.ComputeHash(encodedCertificate)).Replace("-", "");

        // derive the ARI ID
        // https://letsencrypt.org/2024/04/25/guide-to-integrating-ari-into-existing-acme-clients#step-3-constructing-the-ari-certid
        // https://www.ietf.org/archive/id/draft-ietf-acme-ari-03.html#name-the-renewalinfo-resource
        string? ariId = null;
        Asn1OctetString? akiExtension = certificate.GetExtensionValue(X509Extensions.AuthorityKeyIdentifier);
        if (akiExtension is not null)
        {
            Asn1OctetString? keyIdentifier = AuthorityKeyIdentifier.GetInstance(akiExtension.GetOctets()).KeyIdentifier;
            if (keyIdentifier is not null)
            {
                string encodedKeyIdentifier = ToBase64Url(keyIdentifier.GetOctets());
                string encodedSerial = ToBase64Url(certificate.SerialNumber.ToByteArray());
                ariId = $"{encodedKeyIdentifier}.{encodedSerial}";
            }
        }

        // output the results
        var result = new PSObject();
        result.Properties.Add(new PSNoteProperty("Subject", certificate.SubjectDN.ToString()));
        result.Properties.Add(new PSNoteProperty("NotBefore", certificate.NotBefore.ToLocalTime()));
        result.Properties.Add(new PSNoteProperty("NotAfter", certificate.NotAfter.ToLocalTime()));
        result.Properties.Add(new PSNoteProperty("Thumbprint", thumbprint));
        result.Properties.Add(new PSNoteProperty("ARIId", ariId));
        result.Properties.Add(new PSNoteProperty("Serial", certificate.SerialNumber.ToString()));
        result.Properties.Add(new PSNoteProperty("AllSANs", altNames.ToArray()));
        WriteObject(result);
    }

    private static string ToBase64Url(byte[] value)
    {
        return Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }
}
