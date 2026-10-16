using System;
using System.Management.Automation;
using System.Text;
using Org.BouncyCastle.Crypto.Digests;

namespace CryptoHelper;

[Cmdlet(VerbsCommon.Get, "BCSha3Hash")]
[OutputType(typeof(string))]
public sealed class GetBCSha3HashCommand : PSCmdlet
{
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]
    [AllowEmptyString]
    public string InputString { get; set; } = string.Empty;

    protected override void ProcessRecord()
    {
        byte[] input = Encoding.UTF8.GetBytes(InputString);
        var sha3 = new Sha3Digest(256);
        sha3.BlockUpdate(input, 0, input.Length);
        byte[] hash = new byte[sha3.GetDigestSize()];
        sha3.DoFinal(hash, 0);
        WriteObject(BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant());
    }
}
