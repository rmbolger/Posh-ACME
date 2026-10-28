using System;
using System.Collections;
using System.Globalization;
using System.Management.Automation;
using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.Nist;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Math;

namespace CryptoHelper;

[Cmdlet(VerbsData.ConvertTo, "PemPrivateKey")]
[OutputType(typeof(string[]))]
public sealed class ConvertToPemPrivateKeyCommand : PSCmdlet
{
    [Parameter(Mandatory = true, ValueFromPipeline = true)]
    public IDictionary Jwk { get; set; } = new Hashtable();

    protected override void ProcessRecord()
    {
        string keyType = GetRequiredValue("kty");
        byte[] encodedKey;
        string pemLabel;

        if (keyType == "RSA")
        {
            var privateKey = new RsaPrivateCrtKeyParameters(
                GetBigInteger("n"),   // modulus
                GetBigInteger("e"),   // exponent
                GetBigInteger("d"),   // private exponent
                GetBigInteger("p"),   // prime1
                GetBigInteger("q"),   // prime2
                GetBigInteger("dp"),  // exponent1
                GetBigInteger("dq"),  // exponent2
                GetBigInteger("qi")); // coefficient

            encodedKey = CryptoEncoding.EncodeRsaPrivateKey(privateKey);
            pemLabel = "PRIVATE KEY";
        }
        else if (keyType == "EC")
        {
            string curveName = GetRequiredValue("crv");
            DerObjectIdentifier curveOid = NistNamedCurves.GetOid(curveName)
                ?? throw new ArgumentException($"Unsupported JWK curve: {curveName}", nameof(Jwk));
            var curve = NistNamedCurves.GetByOid(curveOid);
            var x = GetBigInteger("x"); // x coordinate
            var y = GetBigInteger("y"); // y coordinate
            var d = GetBigInteger("d"); // private key value
            var publicKey = new ECPublicKeyParameters("EC", curve.Curve.CreatePoint(x, y), curveOid);
            var privateKey = new ECPrivateKeyParameters("EC", d, curveOid);
            encodedKey = CryptoEncoding.EncodeEcPrivateKey(privateKey, publicKey);
            pemLabel = "EC PRIVATE KEY";
        }
        else
        {
            throw new ArgumentException($"Unsupported JWK key type: {keyType}", nameof(Jwk));
        }

        WriteObject(CryptoEncoding.ToPemLines(pemLabel, encodedKey), enumerateCollection: false);
    }

    private string GetRequiredValue(string name)
    {
        if (!Jwk.Contains(name) || Jwk[name] is null)
        {
            throw new ArgumentException($"Invalid JWK. Missing '{name}' parameter.", nameof(Jwk));
        }

        string value = Convert.ToString(Jwk[name], CultureInfo.InvariantCulture) ?? string.Empty;
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException($"Invalid JWK. Missing '{name}' parameter.", nameof(Jwk));
        }

        return value;
    }

    private BigInteger GetBigInteger(string name)
    {
        return new BigInteger(1, CryptoEncoding.FromBase64Url(GetRequiredValue(name)));
    }
}
