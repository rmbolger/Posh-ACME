# Environment Variable Reference

Posh-ACME supports a few environment variables that can change the module's behavior. Some must be defined prior to the initial import of the module into your PowerShell session. If the module is already loaded when you set them, you can force a reload using `Import-Module Posh-ACME -Force`.

Here is a reference for what is currently supported.

| Name                        | Minimum</br>Posh-ACME Version | Required at</br>Module Load | Description |
| ----                        | :---------------------------: | :-------------------------: | ----------- |
| POSHACME_HOME               | 3.2.0                         | :white_check_mark:          | Change the default config location. ([Guide](Using-an-Alternate-Config-Location.md)) |
| POSHACME_PLUGINS            | 4.7.0                         | :white_check_mark:          | Load custom plugins. ([Guide](Using-Custom-Plugins.md)) |
| POSHACME_SHOW_PROGRESS      | 4.11.0                        | :x:                         | Show progress bar during DNS propagation delay timer. Must exist as any non-null or empty value. |
| POSHACME_VAULT_NAME         | 4.11.0                        | :x:                         | SecretManagement Vault Name to store Posh-ACME secrets. ([Guide](Using-SecretManagement.md)) |
| POSHACME_VAULT_PASS         | 4.11.0                        | :x:                         | (Optional) Password required to unlock the vault specified by POSHACME_VAULT_NAME. |
| POSHACME_VAULT_SECRETPREFIX | 4.11.0                        | :x:                         | (Optional) Custom name prefix to use for Posh-ACME created secrets. |
