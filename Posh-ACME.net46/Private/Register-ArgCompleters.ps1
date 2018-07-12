function Register-ArgCompleters {
    [CmdletBinding()]
    param()

    # setup the argument completers
    # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter?view=powershell-5.1

    # Plugin/DnsPlugin
    $PluginNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        $names = (Get-ChildItem -Path "$PSScriptRoot\..\DnsPlugins\*.ps1" -Exclude '_Example.ps1').BaseName
        $names | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }

    $PluginCommands = 'Publish-DnsChallenge','Unpublish-DnsChallenge','Save-DnsChallenge','Get-DnsPluginHelp'
    Register-ArgumentCompleter -CommandName $PluginCommands -ParameterName 'Plugin' -ScriptBlock $PluginNameCompleter
    $DnsPluginCommands = 'New-PACertificate','Submit-ChallengeValidation','Set-PAOrder'
    Register-ArgumentCompleter -CommandName $DnsPluginCommands -ParameterName 'DnsPlugin' -ScriptBlock $PluginNameCompleter

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

        $commonLengths = '2048','4096','ec-256','ec-384'
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

    $MainDomainCommands = 'Get-PACertificate','Get-PAOrder','Remove-PAOrder','Set-PAOrder','Submit-Renewal'
    Register-ArgumentCompleter -CommandName $MainDomainCommands -ParameterName 'MainDomain' -ScriptBlock $MainDomainCompleter

}
