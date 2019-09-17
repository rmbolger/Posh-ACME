# How To Use the GCloud DNS Plugin

This plugin works against the [Google Cloud DNS](https://cloud.google.com/dns) provider. It is assumed that you have already setup a project, billing, and created the DNS zone(s) you will be working against. If not, check the [Cloud DNS Quickstart](https://cloud.google.com/dns/quickstart).

## Setup

We need to create a service account and give it permission to add TXT records to the zone(s) we'll be issuing certificates for.

### Create a Custom Role

It's always a good idea to limit a service account's access to only what is needed to perform its function. So rather than giving it the default `DNS Administrator` role, we'll create a custom one that is less dangerous. Start by going to the [IAM Roles](https://console.cloud.google.com/iam-admin/roles) page and make sure the correct project is selected.

- Filter the Roles for "dns" and find the `DNS Administrator` role
- Open the context menu for the role and click `Create role from this role`
- Title: `DNS Zone Editor`
- Description: `List/Read Zones and Write Zone data`
- ID: `DNSZoneEditor`
- Role launch stage: `General Availability`
- In the list of permissions, uncheck all **except** the following:
  - `dns.changes.create`
  - `dns.changes.get`
  - `dns.changes.list`
  - `dns.managedZones.get`
  - `dns.managedZones.list`
  - `dns.resourceRecordSets.create`
  - `dns.resourceRecordSets.delete`
  - `dns.resourceRecordSets.get`
  - `dns.resourceRecordSets.list`
  - `dns.resourceRecordSets.update`
- Click `Create`

This will give the account it is applied to the ability to edit all record types for all existing zones in the current project. Unfortunately, the current Google APIs don't allow us to further restrict this role so that the account can only modify TXT records or only specific zones.

### Create a Service Account

Start by going to the [Service accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page and make sure the correct project is selected.

- Click `Create service account`
- Service account name: `posh-acme`
- Role: `DNS Zone Editor`
- Check `Furnish a new private key`
  - Key type: `JSON`
- Click `Create`
- A JSON file should be automatically downloaded. **Don't lose it**.

## Using the Plugin

The only plugin argument you need is the path to the JSON account file you downloaded. The plugin will cache the contents of this file on each use in case the original gets deleted or moved. But as long as it still exists, the real file will take precedence over the cached copy so you can update it in the future if necessary.

```powershell
New-PACertificate example.com -Plugin GCloud -PluginArgs @{GCKeyFile='<path to json>'}
```

## App Engine Compatibility Note

If you're planning on uploading your certificate to Google App Engine, it has been reported that it only supports RSA based certificates. So don't use an ECC key option. It also requires the private key to be in PKCS#1 format and the module currently outputs the key as PKCS#8. You can convert it with openssl using the following command:

```
openssl rsa -in cert.key -out cert-pkcs1.key
```
