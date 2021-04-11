# How To Use the Easy Plugin

This plugin works against the [Easyname](https://www.easyname.com) hosting provider. It is assumed that you have already setup an account with a domain registered.

**Note:** The Easyname REST API exposes currently (April 2021) only a limited set of DNS Management capabilities which are primary targeted at there profesional or comercial users for buy, transfer, delete, ownership changes, and contact management operations. There is no abillity to create, delete or update DNS Records for a particular domain. At least no support which is documented in there official [API Documentation](https://api-docs.easyname.com/#easyname-api) or there [PHP SDK](https://github.com/easyname/php-sdk).

So in order to manipulated DNS records, this plugin relies on good old webscraping which comes with some additional caveats. The Easyname Website may change over time and potentially break this plugin. Please don't rely on it for mission critical things, or at least, be aware of that fact!

## Caveats and Limitations

In order for the Webscraping to work, this Plugin utilize the [IHTMLDocument2 interface](https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/aa752574(v=vs.85)) and [.dotnet mshtml.HTMLDocumentClass](https://docs.microsoft.com/en-us/dotnet/api/system.windows.forms.htmldocument?view=net-5.0) which may not work on PS Core environments. In addition ``IHTMLDocument2`` may perhaps need an office installation or at least the presence of ``mshtml.dll``. More information can be found [here](https://www.mssqltips.com/sqlservertip/6617/powershell-parse-html-code-sql-server-build-numbers/). Please also be aware of the Office licensing topic!

## Using the Plugin

The Easyname Username and Password are associated with the `EasyNameUserEmail` and `EasyNameUserPassword` parameters. 

## Obtain a Certificate
```powershell
$EasyNameUserPassword = ConvertTo-SecureString '0123456789ABCD!' -AsPlainText -Force
$pArgs = @{ EasyNameUserEmail='user@example.com'; EasyNameUserPassword=$EasyNameUserPassword; }
New-PACertificate -Domain example.com -Plugin Easyname -PluginArgs $pArgs
```

## Testing the Plugin
```powershell
$EasyNameUserPassword = ConvertTo-SecureString '0123456789ABCD!' -AsPlainText -Force
$pArgs = @{ EasyNameUserEmail='user@example.com'; EasyNameUserPassword=$EasyNameUserPassword; }

# Get a reference to the current account
$acct = Get-PAAccount

# Publish (create) the acme dns Challange "_acme-challenge.example.com"
Publish-Challenge example.com -Account $acct -Token faketoken -Plugin Easyname -PluginArgs $pArgs -Verbose

# UnPublish (delete) the acme dns Challange "_acme-challenge.example.com"
UnPublish-Challenge example.com -Account $acct -Token faketoken -Plugin Easyname -PluginArgs $pArgs -Verbose
```

# Development Notice

I usally don't use powershell to scrape the web or do heavy Web/REST-Stuff with it. So if someone comes up with a better approach instead of relying on ``IHTMLDocument2 interface`` and ``IHTMLDocument2`` it would be much appreciated.

**corresponding expressions**
> $HttpError = ($HTML.all | Where-Object { $_.className -eq "feedback-message--error" }).textContent

> $HttpSuccess = ($HTML.all | Where-Object { $_.className -eq "feedback-message--success" }).textContent

> $DomainList = $HTML.all | Where-Object { $_.className -eq "entity--domain" } | Select-Object $expDomainName, $expDomainID

> $DomainTableRows = $HTML.all | Where-Object { $_.className -eq "entity--dns-record" }

> $RecordId = $element.getElementsByClassName("button--naked vers--compact theme--error") | Select-Object -ExpandProperty outerHTML

## helper functions

### Internal Functions

```powershell Easyname-GetWebSession()
instantiates a Websession Object
```

```powershell Easyname-Login()
website login and CSRF Token retrieval
```

```powershell Easyname-GetDomains()
retrieves a list of all tlds, associates with the given account.
```

```powershell Easyname-GetCurrentDomainRecords($DomainId)
retrieves a list of the internal recordid's from the given domain identifier.
```

```powershell Easyname-GetEndPoints()
returns a Hashtable Object, holding the specific Easyname Domain Management Endpoint URIs.
```

```powershell Easyname-GetEndPoints()
returns a Hashtable Object, holding the specific Easyname Domain Management Endpoint URIs.
```

### Foreign Functions
This a functions from external sources. Links to the source a given in the PS Comments.

```powershell Get-PlainPassword($Password)
returns a plain string from a Powershell Secure String.
```

```powershell Get-RootDomain($url)
returns the root domain of a given URI string using an array of eTLDs for matching.

See eTLD (effective top-level domain) or PSL (Public Suffix List) for further Information. The eTLD-Array may need periodic updates from a PSL!
```

### Experimental Rest API Functions

There are also internal functions realated to the currently useless Easyname Rest API. See the Plugin SourceCode for further information.

* Authorization Related
   *   Get-StringHash
   *   ConvertTo-Base64
   *   Get-XUserAuthenticationHeader
* Easyname-GetDomainsRestfull -> Showcase using the Easyname Rest API to retrieve the list of Available Domains. 