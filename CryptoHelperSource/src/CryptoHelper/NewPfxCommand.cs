using System;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;
using Org.BouncyCastle.Asn1.Pkcs;
using Org.BouncyCastle.Asn1.Nist;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.Pkcs;
using Org.BouncyCastle.Security;
using Org.BouncyCastle.X509;

namespace CryptoHelper;

[Cmdlet(VerbsCommon.New, "Pfx")]
[OutputType(typeof(byte[]))]
public sealed class NewPfxCommand : PSCmdlet
{
    [Parameter(Mandatory = true)]
    public string CertificatePem { get; set; } = string.Empty;

    [Parameter(Mandatory = true)]
    public string PrivateKeyPem { get; set; } = string.Empty;

    [Parameter()]
    public string[] ChainPem { get; set; } = Array.Empty<string>();

    [Parameter()]
    [AllowEmptyString]
    public string FriendlyName { get; set; } = string.Empty;

    [Parameter()]
    [AllowEmptyString]
    public string Password { get; set; } = string.Empty;

    [Parameter()]
    public SwitchParameter UseModernPfxEncryption { get; set; }

    [Parameter()]
    public SwitchParameter UsePfxDerEncoding { get; set; }

    protected override void ProcessRecord()
    {
        X509Certificate certificate = ReadCertificate(CertificatePem);
        AsymmetricKeyParameter privateKey = ReadPrivateKey(PrivateKeyPem);

        // BouncyCastle won't let use use a null value for a cert/key alias in the PFX file
        // and Windows in some cases doesn't like the empty string default. So we'll use
        // the subject CN value unless something non-empty was passed in.
        string friendlyName = FriendlyName;
        if (string.IsNullOrWhiteSpace(friendlyName))
        {
            friendlyName = certificate.SubjectDN.GetValueList(X509Name.CN).Cast<string>().FirstOrDefault()
                ?? throw new ArgumentException("A friendly name is required when the certificate subject has no CN.", nameof(FriendlyName));
        }

        // create a new Pkcs12Store
        var storeBuilder = new Pkcs12StoreBuilder();
        storeBuilder.SetCertAlgorithm(PkcsObjectIdentifiers.PbeWithShaAnd3KeyTripleDesCbc);
        storeBuilder.SetReverseCertificates(false);

        // set optional DER encoding
        if (UsePfxDerEncoding)
        {
            storeBuilder.SetUseDerEncoding(true);
        }

        // The private key algorithm option affects compatibility with various versions
        // of OpenSSL. The default, "RC2-40-CBC", works with 1.0.x and 1.1.x, but not
        // 3.x unless additional "legacy" parameters are used. The modern option,
        // "AES256 with SHA256" is not supported on 1.0.x.
        if (UseModernPfxEncryption)
        {
            // Use PKCS5 Scheme 2 with AES256CBC and HMAC-SHA256
            storeBuilder.SetKeyAlgorithm(
                NistObjectIdentifiers.IdAes256Cbc,
                PkcsObjectIdentifiers.IdHmacWithSha256
            );
        }
        else
        {
            // Use legacy RC2-40-CBC
            storeBuilder.SetKeyAlgorithm(PkcsObjectIdentifiers.PbewithShaAnd40BitRC2Cbc);
        }

        Pkcs12Store store = storeBuilder.Build();
        // add the private key and certificate to the store
        store.SetKeyEntry(
            friendlyName,
            new AsymmetricKeyEntry(privateKey),
            new[] { new X509CertificateEntry(certificate) });

        // add any chain certificates to the store
        foreach (string chainCertificatePem in ChainPem)
        {
            X509Certificate chainCertificate = ReadCertificate(chainCertificatePem);
            Match commonName = Regex.Match(chainCertificate.SubjectDN.ToString(), "CN=([^,]+)");
            // use the common name as the alias if available, otherwise fall back to the serial number
            string alias = commonName.Success ? commonName.Groups[1].Value : chainCertificate.SerialNumber.ToString();
            store.SetCertificateEntry(alias, new X509CertificateEntry(chainCertificate));
        }

        // save the PFX to a memory stream and return the byte array
        using var output = new MemoryStream();
        store.Save(output, Password.ToCharArray(), new SecureRandom());
        WriteObject(output.ToArray(), enumerateCollection: false);
    }

    private static X509Certificate ReadCertificate(string pem)
    {
        using var input = new StringReader(pem);
        var reader = new PemReader(input);
        return reader.ReadObject() as X509Certificate
            ?? throw new ArgumentException("The PEM input must contain an X.509 certificate.", nameof(pem));
    }

    private static AsymmetricKeyParameter ReadPrivateKey(string pem)
    {
        using var input = new StringReader(pem);
        var reader = new PemReader(input);
        object? parsed = reader.ReadObject();
        if (parsed is AsymmetricCipherKeyPair keyPair)
        {
            return keyPair.Private;
        }

        if (parsed is AsymmetricKeyParameter key && key.IsPrivate)
        {
            return key;
        }

        throw new ArgumentException("The PEM input must contain an RSA or EC private key.", nameof(pem));
    }
}
