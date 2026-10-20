using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.Nist;
using Org.BouncyCastle.Asn1.Pkcs;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.Pkcs;

namespace CryptoHelper;

[Cmdlet(VerbsCommon.Get, "CsrDetail")]
[OutputType(typeof(PSObject))]
public sealed class GetCsrDetailCommand : PSCmdlet
{
    private static readonly DerObjectIdentifier ExtensionRequestOid =
        PkcsObjectIdentifiers.Pkcs9AtExtensionRequest;
    private static readonly DerObjectIdentifier OcspMustStapleOid =
        new("1.3.6.1.5.5.7.1.24");

    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public string Pem { get; set; } = string.Empty;

    protected override void ProcessRecord()
    {
        // Parse the PEM input and extract the CSR object
        using var input = new System.IO.StringReader(Pem);
        var reader = new PemReader(input);
        if (reader.ReadObject() is not Pkcs10CertificationRequest csr)
        {
            throw new ArgumentException("The PEM input must contain a certificate request.", nameof(Pem));
        }

        // convert the CSR to Base64Url and determine the key length
        string base64Url = ToBase64Url(csr.GetEncoded());
        string keyLength = GetKeyLength(csr.GetPublicKey());

        // extract the domain names from the CSR's subject and SAN extensions
        var domain = new List<string>();
        string? commonName = csr.GetCertificationRequestInfo().Subject.GetValueList(X509Name.CN).FirstOrDefault();
        if (!string.IsNullOrEmpty(commonName))
        {
            domain.Add(commonName);
        }

        var attributes = csr.GetCertificationRequestInfo().Attributes;
        // exit early if there are no attributes in the CSR
        if (attributes.Count == 0)
        {
            if (domain.Count == 0)
            {
                throw new ArgumentException("No Common Name (CN) or Subject Alternative Name (SAN) extensions found in certificate request.");
            }

            WriteWarning("No Certificate Attributes found in CSR.");
            WriteResult(base64Url, keyLength, domain, false);
            return;
        }

        // locate the extension request attribute and extract the extensions sequence
        X509Extensions? extensions = null;
        foreach (Asn1Encodable encodedAttribute in attributes)
        {
            AttributePkcs attribute = AttributePkcs.GetInstance(encodedAttribute);
            if (attribute.AttrType.Equals(ExtensionRequestOid))
            {
                extensions = X509Extensions.GetInstance(attribute.AttrValues[0]);
                break;
            }
        }

        // exit early if there are no extensions in the CSR
        if (extensions is null)
        {
            if (domain.Count == 0)
            {
                throw new ArgumentException("No Common Name (CN) or Subject Alternative Name (SAN) extensions found in certificate request.");
            }

            WriteWarning("No Certificate Extensions sequence found in CSR.");
            WriteResult(base64Url, keyLength, domain, false);
            return;
        }

        // extract the SAN extension if present
        X509Extension? sanExtension = extensions.GetExtension(X509Extensions.SubjectAlternativeName);
        if (sanExtension is not null)
        {
            // parse the SAN extension to extract the general names
            var generalNames = GeneralNames.GetInstance(
                Asn1Object.FromByteArray(sanExtension.Value.GetOctets()));
            foreach (GeneralName generalName in generalNames.GetNames())
            {
                string? name = GetSanValue(generalName);
                if (name is null)
                {
                    WriteWarning($"Unsupported SAN type with TagNo {generalName.TagNo} found in certificate request.");
                }
                else if (!domain.Any(existing => string.Equals(existing, name, StringComparison.OrdinalIgnoreCase)))
                {
                    domain.Add(name);
                }
            }
        }

        // ensure that at least one domain name was extracted from the CSR
        if (domain.Count == 0)
        {
            throw new ArgumentException("No Common Name (CN) or Subject Alternative Name (SAN) extensions found in certificate request.");
        }

        // extract the OCSP Must Staple extension if present
        X509Extension? ocspExtension = extensions.GetExtension(OcspMustStapleOid);
        bool ocspMustStaple = ocspExtension is not null &&
            BitConverter.ToString(ocspExtension.Value.GetOctets()).Replace("-", "") == "3003020105";
        WriteResult(base64Url, keyLength, domain, ocspMustStaple);
    }

    private static string GetKeyLength(AsymmetricKeyParameter publicKey)
    {
        if (publicKey is RsaKeyParameters rsaKey)
        {
            return rsaKey.Modulus.BitLength.ToString();
        }

        if (publicKey is ECPublicKeyParameters ecKey)
        {
            var supportedCurves = new[]
            {
                ("P-256", "ec-256"),
                ("P-384", "ec-384"),
                ("P-521", "ec-521")
            };

            foreach ((string curveName, string keyLength) in supportedCurves)
            {
                if (ecKey.Parameters.Curve.Equals(NistNamedCurves.GetByName(curveName).Curve))
                {
                    return keyLength;
                }
            }

            throw new ArgumentException($"Unsupported ECC curve. {ecKey.Parameters.Curve}");
        }

        throw new ArgumentException("Unsupported key type.");
    }

    private static string? GetSanValue(GeneralName generalName)
    {
        if (generalName.TagNo == GeneralName.DnsName)
        {
            return generalName.Name.ToString();
        }

        if (generalName.TagNo == GeneralName.IPAddress)
        {
            return new System.Net.IPAddress(
                Asn1OctetString.GetInstance(generalName.Name).GetOctets()).ToString();
        }

        return null;
    }

    private static string ToBase64Url(byte[] value)
    {
        return Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }

    private void WriteResult(string base64Url, string keyLength, IEnumerable<string> domain, bool ocspMustStaple)
    {
        var result = new PSObject();
        result.Properties.Add(new PSNoteProperty("Domain", domain.ToArray()));
        result.Properties.Add(new PSNoteProperty("KeyLength", keyLength));
        result.Properties.Add(new PSNoteProperty("OCSPMustStaple", ocspMustStaple));
        result.Properties.Add(new PSNoteProperty("Base64Url", base64Url));
        WriteObject(result);
    }
}
