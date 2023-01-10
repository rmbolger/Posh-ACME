How To Use the IONOS DNS Plugin

This plugin works against the IONOS DNS provider.
It is assumed that you have already setup an account and created the DNS zone(s) you will be working against.

Setup
You will need to generate an API Token if you haven't already done so.
Follow the guide provided by IONOS https://developer.hosting.ionos.de/docs/getstarted 

Using the Plugin
You will need to provide the API Public Prefix to IONOSPublicPrefix and
the API Secret to IONOSTokenSecure



$pArgs = @{
	IONOSPublicPrefix = (Read-Host 'API Public Prefix')
	IONOSTokenSecure = (Read-Host 'API Secret' -AsSecureString)
	}
	
New-PACertificate example.com -Plugin IONOS -PluginArgs $pArgs
