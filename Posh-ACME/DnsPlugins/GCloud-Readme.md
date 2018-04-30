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

### Create a Service Account

Start by going to the [Service accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page and make sure the correct project is selected.

- Click `Create service account`
- Service account name: `posh-acme`
- Role: `DNS Zone Editor`
- Check `Furnish a new private key`
  - Key type: `JSON`
- Click `Create`
- A JSON file should be automatically downloaded. **Don't lose it**.
