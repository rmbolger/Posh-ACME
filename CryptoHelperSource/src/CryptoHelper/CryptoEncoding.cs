using System;
using System.Collections.Generic;
using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.Sec;
using Org.BouncyCastle.Asn1.X9;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Pkcs;

namespace CryptoHelper;

internal static class CryptoEncoding
{
    internal static string ToBase64Url(byte[] value)
    {
        return Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }

    internal static byte[] FromBase64Url(string value)
    {
        string base64 = value.Replace('-', '+').Replace('_', '/');
        base64 = base64.PadRight(base64.Length + ((4 - base64.Length % 4) % 4), '=');
        return Convert.FromBase64String(base64);
    }

    internal static byte[] EncodeRsaPrivateKey(RsaPrivateCrtKeyParameters privateKey)
    {
        return PrivateKeyInfoFactory.CreatePrivateKeyInfo(privateKey).GetDerEncoded();
    }

    internal static byte[] EncodeRsaLegacyPrivateKey(RsaPrivateCrtKeyParameters privateKey)
    {
        return new Org.BouncyCastle.Asn1.Pkcs.RsaPrivateKeyStructure(
            privateKey.Modulus,
            privateKey.PublicExponent,
            privateKey.Exponent,
            privateKey.P,
            privateKey.Q,
            privateKey.DP,
            privateKey.DQ,
            privateKey.QInv).GetDerEncoded();
    }

    internal static byte[] EncodeEcPrivateKey(ECPrivateKeyParameters privateKey)
    {
        return PrivateKeyInfoFactory.CreatePrivateKeyInfo(privateKey).GetDerEncoded();
    }

    internal static byte[] EncodeEcLegacyPrivateKey(ECPrivateKeyParameters privateKey, ECPublicKeyParameters publicKey)
    {
        var privateKeyInfo = new ECPrivateKeyStructure(
            privateKey.Parameters.N.BitLength,
            privateKey.D,
            new DerBitString(publicKey.Q.GetEncoded()),
            new X962Parameters(privateKey.PublicKeyParamSet));
        return privateKeyInfo.GetDerEncoded();
    }

    internal static string ToPem(string label, byte[] encoded)
    {
        string base64 = Convert.ToBase64String(encoded);
        var lines = new List<string> { $"-----BEGIN {label}-----" };
        for (int offset = 0; offset < base64.Length; offset += 64)
        {
            lines.Add(base64.Substring(offset, Math.Min(64, base64.Length - offset)));
        }
        lines.Add($"-----END {label}-----");

        return string.Join("\n", lines.ToArray()) + "\n";
    }
}
