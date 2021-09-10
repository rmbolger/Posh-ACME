# External Account Binding

Some ACME certificate authorities such as [ZeroSSL](https://zerossl.com/) and [ssl.com](https://www.ssl.com/) have an existing account management system separate from ACME accounts. In order to create a new ACME account with these providers you must register with some extra information in order to link the new ACME account with the external account. This is known as External Account Binding (EAB).

## Get EAB Credentials

You will obviously need to have or sign up for an account with the CA first in order to bind your ACME account to it. These providers will usually have some sort of API management page to generate or view EAB credentials for ACME use. Searching "ACME" in their support site is a good way to find it.

The credentials will include at least two values. The first is a "Key" or "Key ID" that could be any string value. The second is "HMAC" or "HMAC Key" that is a Base64 encoded value. Rarely, they may also provide an HMAC algorithm identifier such as `HS256` or `HMAC with SHA-256`.

!!! note
    Some providers allow you to re-use EAB credentials to create multiple ACME accounts. Others require a new set of EAB credentials be generated for each ACME account.

## Creating the ACME Account

EAB parameters are only supported on `New-PAAccount`, so you won't be able to use `New-PACertificate` until you create the account separately. Here's an example.

```powershell
$eabKID = 'xxxxxxxx'
$eabHMAC = 'yyyyyyyy'
New-PAAccount -ExtAcctKID $eabKID -ExtAcctHMACKey $eabHMAC -Contact 'me@example.com' -AcceptTOS
```

If they provided an algorithm identifier other than `HS256`, you would specify it using `-ExtAcctAlgorithm`. Posh-ACME supports `HS256`, `HS384` and `HS512`.

Once the account is created, you can proceed to create new orders and certificates as normal. You won't need the EAB credentials again unless you're creating a new account or possibly recovering an existing account on another system.
