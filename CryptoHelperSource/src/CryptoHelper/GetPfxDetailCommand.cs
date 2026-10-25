using System;
using System.Linq;
using System.Management.Automation;
using Org.BouncyCastle.Asn1;
using Org.BouncyCastle.Asn1.Cms;
using Org.BouncyCastle.Asn1.Pkcs;
using Org.BouncyCastle.Asn1.X509;
using Pkcs12Pfx = Org.BouncyCastle.Asn1.Pkcs.Pfx;

namespace CryptoHelper;

[Cmdlet(VerbsCommon.Get, "PfxEncodingDetail")]
[OutputType(typeof(PSObject))]
public sealed class GetPfxEncodingDetailCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    public byte[] Pfx { get; set; } = Array.Empty<byte>();

    protected override void ProcessRecord()
    {
        Pkcs12Pfx pfx = Pkcs12Pfx.GetInstance(Asn1Object.FromByteArray(Pfx));
        string? keyEncryptionAlgorithm = null;
        string? keyEncryptionScheme = null;
        string? keyEncryptionPrf = null;

        AuthenticatedSafe authenticatedSafe = AuthenticatedSafe.GetInstance(
            Asn1OctetString.GetInstance(pfx.AuthSafe.Content).GetOctets());

        foreach (Org.BouncyCastle.Asn1.Pkcs.ContentInfo contentInfo in authenticatedSafe.GetContentInfo())
        {
            if (!CmsObjectIdentifiers.Data.Equals(contentInfo.ContentType))
            {
                continue;
            }

            Asn1Sequence safeBags = Asn1Sequence.GetInstance(Asn1Object.FromByteArray(
                Asn1OctetString.GetInstance(contentInfo.Content).GetOctets()));

            foreach (Asn1Encodable encodedBag in safeBags)
            {
                SafeBag safeBag = SafeBag.GetInstance(encodedBag);
                if (PkcsObjectIdentifiers.Pkcs8ShroudedKeyBag.Equals(safeBag.BagID))
                {
                    EncryptedPrivateKeyInfo encryptedKey = EncryptedPrivateKeyInfo.GetInstance(safeBag.BagValue);
                    AlgorithmIdentifier encryptionAlgorithm = encryptedKey.EncryptionAlgorithm;
                    keyEncryptionAlgorithm = encryptionAlgorithm.Algorithm.Id;

                    if (encryptionAlgorithm.Algorithm.Id == "1.2.840.113549.1.5.13")
                    {
                        PbeS2Parameters pbeParameters = PbeS2Parameters.GetInstance(encryptionAlgorithm.Parameters);
                        keyEncryptionScheme = pbeParameters.EncryptionScheme.Algorithm.Id;
                        Pbkdf2Params pbkdf2 = Pbkdf2Params.GetInstance(pbeParameters.KeyDerivationFunc.Parameters);
                        keyEncryptionPrf = pbkdf2.Prf.Algorithm.Id;
                    }
                }
            }
        }

        var result = new PSObject();
        result.Properties.Add(new PSNoteProperty("KeyEncryptionAlgorithm", keyEncryptionAlgorithm));
        result.Properties.Add(new PSNoteProperty("KeyEncryptionScheme", keyEncryptionScheme));
        result.Properties.Add(new PSNoteProperty("KeyEncryptionPrf", keyEncryptionPrf));
        result.Properties.Add(new PSNoteProperty(
            "IsDerEncoded",
            Pfx.SequenceEqual(pfx.GetEncoded("DER"))));
        WriteObject(result);
    }
}
