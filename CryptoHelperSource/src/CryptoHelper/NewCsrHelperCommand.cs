using System;
using System.Collections.Generic;
using System.IO;
using System.Collections;
using System.Management.Automation;
using System.Text;
using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.Nist;
using Org.BouncyCastle.Asn1.Pkcs;
using Org.BouncyCastle.Asn1.Sec;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.Asn1.X9;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Math.EC.Multiplier;
using Org.BouncyCastle.Pkcs;
using Org.BouncyCastle.Security;
using Org.BouncyCastle.X509.Extension;

namespace CryptoHelper;

[Cmdlet(VerbsCommon.New, "CsrHelper")]
[OutputType(typeof(PSObject))]
public sealed class NewCsrHelperCommand : PSCmdlet
{
    [Parameter(Mandatory = true)]
    public string KeyLength { get; set; } = string.Empty;

    [Parameter(Mandatory = true)]
    [AllowEmptyString]
    public string Subject { get; set; } = string.Empty;

    [Parameter()]
    public IDictionary[] Identifiers { get; set; } = Array.Empty<IDictionary>();

    [Parameter()]
    public bool OCSPMustStaple { get; set; }

    [Parameter()]
    [AllowNull]
    [AllowEmptyString]
    public string? PrivateKeyPem { get; set; }

    protected override void ProcessRecord()
    {
        AsymmetricCipherKeyPair keyPair;
        string? privateKeyPem = null;
        string signatureAlgorithm;

        // hydrate or generate the private key
        if (PrivateKeyPem is not null)
        {
            keyPair = ReadKeyPair(PrivateKeyPem);
            signatureAlgorithm = GetSignatureAlgorithm(KeyLength);
        }
        else
        {
            WriteVerbose("Creating new private key for the certificate request.");
            (keyPair, signatureAlgorithm) = GenerateKeyPair(KeyLength);
            privateKeyPem = ExportPrivateKey(keyPair);
        }

        // init the subject
        X509Name subject = string.IsNullOrEmpty(Subject)
            ? X509Name.GetInstance(new DerSequence())
            : new X509Name(Subject);

        // prep the extensions
        var extensions = new Dictionary<DerObjectIdentifier, X509Extension>
        {
            // Not a CA certificate
            [X509Extensions.BasicConstraints] = new X509Extension(
                false,
                new DerOctetString(new BasicConstraints(false))),
            // Key usage: DigitalSignature and optionally KeyEncipherment for non-EC keys
            [X509Extensions.KeyUsage] = new X509Extension(
                true,
                new DerOctetString(new KeyUsage(
                    KeyUsage.DigitalSignature |
                    (KeyLength.StartsWith("ec-", StringComparison.OrdinalIgnoreCase)
                        ? 0
                        : KeyUsage.KeyEncipherment)))),
            // Subject Key Identifier
            [X509Extensions.SubjectKeyIdentifier] = new X509Extension(
                false,
                new DerOctetString(X509ExtensionUtilities.CreateSubjectKeyIdentifier(keyPair.Public)))
        };

        // build the SAN list
        var generalNames = new List<GeneralName>();
        foreach (IDictionary identifier in Identifiers)
        {
            string type = identifier.Contains("type") ? identifier["type"]?.ToString() ?? string.Empty : string.Empty;
            string value = identifier.Contains("value") ? identifier["value"]?.ToString() ?? string.Empty : string.Empty;
            if (type == "dns")
            {
                generalNames.Add(new GeneralName(GeneralName.DnsName, value));
            }
            else if (type == "ip")
            {
                generalNames.Add(new GeneralName(GeneralName.IPAddress, value));
            }
            else
            {
                WriteWarning($"Skipping unexpected identifier type '{type}' with value '{value}'.");
            }
        }
        // add the SAN extension if any names were added
        if (generalNames.Count > 0)
        {
            extensions[X509Extensions.SubjectAlternativeName] = new X509Extension(
                false,
                new DerOctetString(new GeneralNames(generalNames.ToArray())));
        }

        // add the OCSP Must-Staple extension if requested
        if (OCSPMustStaple)
        {
            WriteDebug("Adding OCSP Must-Staple");
            extensions[new DerObjectIdentifier("1.3.6.1.5.5.7.1.24")] = new X509Extension(
                false,
                new DerOctetString(new byte[] { 0x30, 0x03, 0x02, 0x01, 0x05 }));
        }

        // create the extension set attribute for the CSR
        var extensionSet = new DerSet(
            new AttributePkcs(
                PkcsObjectIdentifiers.Pkcs9AtExtensionRequest,
                new DerSet(new X509Extensions(extensions))));

        // create the request object
        var request = new Pkcs10CertificationRequest(
            signatureAlgorithm,
            subject,
            keyPair.Public,
            extensionSet,
            keyPair.Private);

        // build the output object
        byte[] requestBytes = request.GetEncoded();
        var result = new PSObject();
        result.Properties.Add(new PSNoteProperty("PrivateKeyPem", privateKeyPem));
        result.Properties.Add(new PSNoteProperty("RequestPem", ToPem("CERTIFICATE REQUEST", requestBytes)));
        result.Properties.Add(new PSNoteProperty("Base64Url", ToBase64Url(requestBytes)));
        WriteObject(result);
    }

    private static (AsymmetricCipherKeyPair KeyPair, string SignatureAlgorithm) GenerateKeyPair(string keyLength)
    {
        var random = new SecureRandom();
        if (keyLength.StartsWith("ec-", StringComparison.OrdinalIgnoreCase))
        {
            if (!int.TryParse(keyLength.Substring(3), out int keySize))
            {
                throw new ArgumentException($"Unsupported key type: {keyLength}", nameof(keyLength));
            }

            string signatureAlgorithm = GetSignatureAlgorithm(keyLength);
            var curveOid = NistNamedCurves.GetOid($"P-{keySize}");
            if (curveOid is null)
            {
                throw new ArgumentException($"Unsupported EC key size: {keyLength}", nameof(keyLength));
            }

            var generator = new ECKeyPairGenerator();
            generator.Init(new ECKeyGenerationParameters(curveOid, random));
            return (generator.GenerateKeyPair(), signatureAlgorithm);
        }

        if (!int.TryParse(keyLength, out int rsaKeySize))
        {
            throw new ArgumentException($"Unsupported key type: {keyLength}", nameof(keyLength));
        }

        var rsaGenerator = new RsaKeyPairGenerator();
        rsaGenerator.Init(new KeyGenerationParameters(random, rsaKeySize));
        return (rsaGenerator.GenerateKeyPair(), "SHA256WITHRSA");
    }

    private static string GetSignatureAlgorithm(string keyLength)
    {
        return keyLength.ToLowerInvariant() switch
        {
            "ec-256" => "SHA256WITHECDSA",
            "ec-384" => "SHA384WITHECDSA",
            "ec-521" => "SHA512WITHECDSA",
            _ when keyLength.StartsWith("ec-", StringComparison.OrdinalIgnoreCase) =>
                throw new ArgumentException($"Unsupported EC key size: {keyLength}", nameof(keyLength)),
            _ => "SHA256WITHRSA"
        };
    }

    private static AsymmetricCipherKeyPair ReadKeyPair(string pem)
    {
        using var input = new StringReader(pem);
        var reader = new Org.BouncyCastle.OpenSsl.PemReader(input);
        object? parsed = reader.ReadObject();
        if (parsed is AsymmetricCipherKeyPair keyPair)
        {
            return keyPair;
        }

        if (parsed is RsaPrivateCrtKeyParameters rsaPrivate)
        {
            var publicKey = new RsaKeyParameters(false, rsaPrivate.Modulus, rsaPrivate.PublicExponent);
            return new AsymmetricCipherKeyPair(publicKey, rsaPrivate);
        }

        if (parsed is ECPrivateKeyParameters ecPrivate)
        {
            var multiplier = new FixedPointCombMultiplier();
            var point = multiplier.Multiply(ecPrivate.Parameters.G, ecPrivate.D);
            var publicKey = new ECPublicKeyParameters("EC", point, ecPrivate.PublicKeyParamSet);
            return new AsymmetricCipherKeyPair(publicKey, ecPrivate);
        }

        throw new ArgumentException("The PEM input must contain a supported RSA or EC private key.", nameof(pem));
    }

    private static string ExportPrivateKey(AsymmetricCipherKeyPair keyPair)
    {
        if (keyPair.Private is ECPrivateKeyParameters ecPrivate && keyPair.Public is ECPublicKeyParameters ecPublic)
        {
            int orderBitLength = ecPrivate.Parameters.N.BitLength;
            var parameters = new X962Parameters(ecPrivate.PublicKeyParamSet);
            var publicKey = new DerBitString(ecPublic.Q.GetEncoded());
            var privateKey = new ECPrivateKeyStructure(orderBitLength, ecPrivate.D, publicKey, parameters);
            return ToPem("EC PRIVATE KEY", privateKey.GetDerEncoded());
        }

        if (keyPair.Private is RsaPrivateCrtKeyParameters rsaPrivate)
        {
            return ToPem("PRIVATE KEY", PrivateKeyInfoFactory.CreatePrivateKeyInfo(rsaPrivate).GetDerEncoded());
        }

        throw new ArgumentException("Unsupported private key type.", nameof(keyPair));
    }

    private static string ToPem(string label, byte[] encoded)
    {
        string base64 = Convert.ToBase64String(encoded);
        var pem = new StringBuilder();
        pem.Append("-----BEGIN ").Append(label).Append("-----\n");
        for (int index = 0; index < base64.Length; index += 64)
        {
            pem.Append(base64, index, Math.Min(64, base64.Length - index)).Append('\n');
        }
        pem.Append("-----END ").Append(label).Append("-----\n");
        return pem.ToString();
    }

    private static string ToBase64Url(byte[] value)
    {
        return Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }
}
