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
        if ([String]::IsNullOrWhiteSpace($script:Dir.Folder)) { return }

        $ids = (Get-ChildItem -Path $script:Dir.Folder | Where-Object { $_ -is [IO.DirectoryInfo] }).BaseName
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
        if ([String]::IsNullOrWhiteSpace($script:Acct.Folder)) { return }

        # grab the list of MainDomains in this account
        $jsonPaths = Join-Path $script:Acct.Folder '*\order.json'
        $names = Get-ChildItem $jsonPaths | Get-Content -Raw | ConvertFrom-Json | Select-Object -ExpandProperty MainDomain

        if ($wordToComplete -ne [String]::Empty) {
            $wordToComplete = "^$([regex]::Escape($wordToComplete))"
        }
        $names | Where-Object { $_ -match $wordToComplete } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $MainDomainCommands = 'Get-PAOrder','Set-PAOrder','Remove-PAOrder','Get-PACertificate','Revoke-PACertificate','Get-PAPluginArgs','Invoke-HttpChallengeListener','Submit-Renewal'
    Register-ArgumentCompleter -CommandName $MainDomainCommands -ParameterName 'MainDomain' -ScriptBlock $MainDomainCompleter

    # Order Name
    $OrderNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # nothing to auto complete if we don't have an account selected
        if ([String]::IsNullOrWhiteSpace($script:Acct.Folder)) { return }

        $names = (Get-ChildItem -Path $script:Acct.Folder -Directory).BaseName
        if ($wordToComplete -ne [String]::Empty) {
            $wordToComplete = "^$([regex]::Escape($wordToComplete))"
        }
        $names | Where-Object { $_ -match $wordToComplete } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $OrderNameCommands = 'Get-PAOrder','New-PAOrder','Set-PAOrder','Remove-PAOrder','Get-PACertificate','New-PACertificate','Revoke-PACertificate','Get-PAPluginArgs','Invoke-HttpChallengeListener','Submit-Renewal'
    Register-ArgumentCompleter -CommandName $OrderNameCommands -ParameterName 'Name' -ScriptBlock $OrderNameCompleter

    # DirectoryUrl
    $DirUrlCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # combine the existing servers with the available shortcuts to cycle through
        $dirJsonPaths = Join-Path (Get-ConfigRoot) '*\dir.json'
        $choices = $(
            Get-ChildItem $dirJsonPaths | Get-Content -Raw | ConvertFrom-Json | Select-Object -Expand location
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
            Get-ChildItem $dirJsonPaths | Get-Content -Raw | ConvertFrom-Json | Select-Object -Expand location
        )

        $choices | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $DirUrlExistingCommands = 'Get-PAServer','Remove-PAServer'
    Register-ArgumentCompleter -CommandName $DirUrlExistingCommands -ParameterName 'DirectoryUrl' -ScriptBlock $DirUrlCompleterExisting

    # PAServer Name
    $DirNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # grab the existing server folders to sort through
        $dirJsonPaths = Join-Path (Get-ConfigRoot) '*\dir.json'
        $choices = Get-ChildItem $dirJsonPaths | ForEach-Object { $_.Directory.BaseName }
        $choices | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $DirNameCommands = 'Get-PAServer','Set-PAServer','Remove-PAServer'
    Register-ArgumentCompleter -CommandName $DirNameCommands -ParameterName 'Name' -ScriptBlock $DirNameCompleter

    # (Order)Profile
    $OrderProfileCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # grab the existing server folders to sort through
        $choices = (Get-PAProfile).Profile
        $choices | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $OrderProfileCommands = 'Get-PAProfile','New-PAOrder','New-PACertificate'
    Register-ArgumentCompleter -CommandName $OrderProfileCommands -ParameterName 'Profile' -ScriptBlock $OrderProfileCompleter

}
