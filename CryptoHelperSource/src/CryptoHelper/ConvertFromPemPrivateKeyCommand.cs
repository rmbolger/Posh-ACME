using System;
using System.Management.Automation;
using System.Security.Cryptography;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Math.EC.Multiplier;
using Org.BouncyCastle.Security;

namespace CryptoHelper;

[Cmdlet(VerbsData.ConvertFrom, "PemPrivateKey")]
[OutputType(typeof(AsymmetricAlgorithm))]
public sealed class ConvertFromPemPrivateKeyCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public string Pem { get; set; } = string.Empty;

    protected override void ProcessRecord()
    {
        object? parsed;
        using (var input = new System.IO.StringReader(Pem))
        {
            var reader = new Org.BouncyCastle.OpenSsl.PemReader(input);
            parsed = reader.ReadObject();
        }

        AsymmetricAlgorithm key = parsed switch
        {
            // PKCS1 or SEC1
            AsymmetricCipherKeyPair keyPair => ConvertKeyPair(keyPair),
            // PKCS8 RSA
            RsaPrivateCrtKeyParameters rsaPrivate => ConvertRsa(rsaPrivate),
            // PKCS8 EC
            ECPrivateKeyParameters ecPrivate => ConvertEc(ecPrivate),
            _ => throw new ArgumentException("The PEM input must contain a supported RSA or EC private key.", nameof(Pem))
        };

        WriteObject(key);
    }

    private static RSA ConvertRsa(RsaPrivateCrtKeyParameters privateKey)
    {
        RSA rsa = RSA.Create();
        // RSAParameters requires D to be the same length as Modulus and the rest of the
        // private params to be half that length. But like the EC D value above, calling
        // ToByteArrayUnsigned() on the BouncyCastle values drops any leading zero bytes
        // which makes ImportParameters throw "Bad Data". BouncyCastle's own converter
        // takes care of the padding for us.
        rsa.ImportParameters(DotNetUtilities.ToRSAParameters(privateKey));
        return rsa;
    }

    private static ECDsa ConvertEc(ECPrivateKeyParameters privateKey)
    {
        var multiplier = new FixedPointCombMultiplier();
        var publicPoint = multiplier.Multiply(privateKey.Parameters.G, privateKey.D).Normalize();
        byte[] x = publicPoint.AffineXCoord.GetEncoded();
        byte[] y = publicPoint.AffineYCoord.GetEncoded();
        byte[] d = privateKey.D.ToByteArrayUnsigned();
        if (d.Length > x.Length)
        {
            throw new ArgumentException("The EC private key has an invalid scalar length.", nameof(privateKey));
        }

        // For named curves (which is all we're currently using), D must have the same
        // length as X/Y params. But D doesn't have a GetEncoded() method which takes care
        // of padding the byte array like X/Y. So we must ensure the correct padding manually.
        byte[] paddedD = new byte[x.Length];
        Buffer.BlockCopy(d, 0, paddedD, paddedD.Length - d.Length, d.Length);

        var parameters = new ECParameters
        {
            Q = new ECPoint { X = x, Y = y },
            D = paddedD,
            Curve = GetCurve(privateKey.Parameters.Curve.FieldSize)
        };

        ECDsa ecdsa = ECDsa.Create();
        ecdsa.ImportParameters(parameters);
        return ecdsa;
    }

    private static AsymmetricAlgorithm ConvertKeyPair(AsymmetricCipherKeyPair keyPair)
    {
        return keyPair.Private switch
        {
            RsaPrivateCrtKeyParameters rsaPrivate => ConvertRsa(rsaPrivate),
            ECPrivateKeyParameters ecPrivate => ConvertEc(ecPrivate),
            _ => throw new ArgumentException("The PEM input must contain a supported RSA or EC private key.", nameof(keyPair))
        };
    }

    private static ECCurve GetCurve(int fieldSize)
    {
        return fieldSize switch
        {
            256 => ECCurve.NamedCurves.nistP256,
            384 => ECCurve.NamedCurves.nistP384,
            521 => ECCurve.NamedCurves.nistP521,
            _ => throw new ArgumentException($"Unsupported curve field size: {fieldSize}", nameof(fieldSize))
        };
    }
}
