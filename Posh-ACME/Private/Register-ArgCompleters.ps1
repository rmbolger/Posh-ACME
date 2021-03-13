function Register-ArgCompleters {
    [CmdletBinding()]
    param()

    # setup the argument completers
    # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter?view=powershell-5.1

    # Plugin name
    $PluginNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # We can't use the normal ModuleBase method to get the plugin folder here because
        # the completer script block doesn't run in the module's context.
        $names = $script:Plugins.Keys | Sort-Object
        $names | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    $PluginCommands = 'New-PACertificate','New-PAOrder','Set-PAOrder','Get-PAPlugin','Publish-Challenge','Save-Challenge','Unpublish-Challenge'
    Register-ArgumentCompleter -CommandName $PluginCommands -ParameterName 'Plugin' -ScriptBlock $PluginNameCompleter

    # Account ID
    $IDCommands = 'Get-PAAccount','Set-PAAccount','Remove-PAAccount','Export-PAAccountKey'
    Register-ArgumentCompleter -CommandName $IDCommands -ParameterName 'ID' -ScriptBlock {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # nothing to auto complete if we don't have a server selected
        if ([String]::IsNullOrWhiteSpace((Get-DirFolder))) { return }

        $ids = (Get-ChildItem -Path (Get-DirFolder) | Where-Object { $_ -is [IO.DirectoryInfo] }).BaseName
        $ids | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    # KeyLength
    $KeyLengthCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        $commonLengths = '2048','3072','4096','ec-256','ec-384'
        $commonLengths | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $KeyLengthCommands = 'Get-PAAccount','New-PAAccount','New-PAOrder','Set-PAAccount'
    Register-ArgumentCompleter -CommandName $KeyLengthCommands -ParameterName 'KeyLength' -ScriptBlock $KeyLengthCompleter
    Register-ArgumentCompleter -CommandName 'New-PACertificate' -ParameterName 'AccountKeyLength' -ScriptBlock $KeyLengthCompleter
    Register-ArgumentCompleter -CommandName 'New-PACertificate' -ParameterName 'CertKeyLength' -ScriptBlock $KeyLengthCompleter

    # MainDomain
    $MainDomainCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # nothing to auto complete if we don't have an account selected
        if ([String]::IsNullOrWhiteSpace($script:AcctFolder)) { return }

        $names = (Get-ChildItem -Path $script:AcctFolder -Directory).BaseName.Replace('!','*')
        if ($wordToComplete -ne [String]::Empty) {
            $wordToComplete = "^$($wordToComplete.Replace('*','\*').Replace('.','\.'))"
        }
        $names | Where-Object { $_ -match $wordToComplete } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $MainDomainCommands = 'Get-PACertificate','Get-PAOrder','Get-PAPluginArgs','Remove-PAOrder','Set-PAOrder','Submit-Renewal'
    Register-ArgumentCompleter -CommandName $MainDomainCommands -ParameterName 'MainDomain' -ScriptBlock $MainDomainCompleter

    # DirectoryUrl
    $DirUrlCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # combine the existing servers with the available shortcuts to cycle through
        $dirJsonPaths = Join-Path (Get-ConfigRoot) '*\dir.json'
        $choices = $(
            Get-Content $dirJsonPaths -Raw | ConvertFrom-Json | Select-Object -Expand location
            $script:WellKnownDirs.Keys
        )

        $choices | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $DirUrlCommands = 'Set-PAServer','New-PACertificate'
    Register-ArgumentCompleter -CommandName $DirUrlCommands -ParameterName 'DirectoryUrl' -ScriptBlock $DirUrlCompleter

    $DirUrlCompleterExisting = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # combine only the existing servers to cycle through
        $dirJsonPaths = Join-Path (Get-ConfigRoot) '*\dir.json'
        $choices = $(
            Get-Content $dirJsonPaths -Raw | ConvertFrom-Json | Select-Object -Expand location
        )

        $choices | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $DirUrlExistingCommands = 'Get-PAServer','Remove-PAServer'
    Register-ArgumentCompleter -CommandName $DirUrlExistingCommands -ParameterName 'DirectoryUrl' -ScriptBlock $DirUrlCompleterExisting



}
