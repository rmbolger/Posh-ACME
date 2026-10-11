---
external help file: Posh-ACME-help.xml
Module Name: Posh-ACME
online version: https://poshac.me/docs/v4/Functions/Get-PublishedPersistChallenge/
schema: 2.0.0
---

# Get-PublishedPersistChallenge

## Synopsis

Get the list of dns-persist-01 records previously published from this system.

## Syntax

```powershell
Get-PublishedPersistChallenge [<CommonParameters>]
```

## Description

Use this to review what dns-persist-01 records have been published from this Posh-ACME configuration. This is a local only cache, not a live check of your infrastructure, and could be out of date if changes were made outside the context of Posh-ACME or this system.

The results can be piped to [Unpublish-DnsPersistChallenge](Unpublish-DnsPersistChallenge.md) or [Publish-DnsPersistChallenge](Publish-DnsPersistChallenge.md).

## Examples

### Example 1: Get the list

```powershell
Get-PublishedPersistChallenge
```

Get all previously published records.

### Example 2: Unpublish a subset

```powershell
Get-PublishedPersistChallenge | ?{ $_.Domain -like '*example.com' } | Unpublish-DnsPersistChallenge
```

Unpublish all records associated with `example.com`

## Parameters

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Publish-DnsPersistChallenge](Publish-DnsPersistChallenge.md)
[Unpublish-DnsPersistChallenge](Unpublish-DnsPersistChallenge.md)
