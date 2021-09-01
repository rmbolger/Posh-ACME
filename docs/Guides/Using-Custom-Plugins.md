# Using Custom Plugins

Since version 4.7.0, you can optionally have Posh-ACME load plugins from a secondary location using the `POSH_ACMEPLUGINS` environment variable. This is useful because when the module is updated, you no longer need to re-deploy you custom plugins to the module's default Plugins folder.

Set the environment variable to the folder path where the custom plugin(s) live. The environment variable must exist when the module is first loaded. So if it has already been loaded in the current session, re-import it with the `-Force` parameter.

```powershell
$env:POSHACME_PLUGINS = 'C:\my\plugin\path'
Import-Module Posh-ACME -Force
```

!!! warning
    Make sure your plugin's name doesn't conflict with the name of a buit-in plugin. If it does, a warning will be thrown and that plugin will be skipped.
