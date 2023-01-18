function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$SSHServer,
        [Parameter(Mandatory)]
        [string]$SSHUser,
        [string]$SSHConfigFile="",
        [string]$SSHIdentityFile,
        [string]$SSHRemoteCommand,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $UpdateParams = @{
        Action = 'add'
        RecordName = $RecordName
        TxtValue = $TxtValue
        SSHServer = $SSHServer
        SSHUser = $SSHUser
        SSHConfigFile = $SSHConfigFile
        SSHIdentityFile = $SSHIdentityFile
        SSHRemoteCommand = $SSHRemoteCommand
    }

    Write-Verbose "Adding $RecordName with value $TxtValue"
    Send-SSHTxtUpdate @UpdateParams

    <#
    .SYNOPSIS
        Add a DNS TXT record via intermediate ssh server

    .DESCRIPTION
        Uses OpenSSH to forward a DDNS request to an ssh server

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SSHServer
        The ssh server to proxy through.

    .PARAMETER SSHUser
        The ssh user to connect as.
    
    .PARAMETER SSHConfigFile
        The optional ssh config file to use. Ssh will use the user/system default if not specified.
    
    .PARAMETER SSHIdentityFile
        The ssh identify file to use. Ssh will use the user/system default if not specified.

    .PARAMETER SSHRemoteCommand
        The optional ssh remote command to run - in general, it is recommended to use an explicit key
        where the server admin has set it to run a forced command.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -SSHServer server.acme.com -SSHUser acmeupdateuser

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$SSHServer,
        [Parameter(Mandatory)]
        [string]$SSHUser,
        [string]$SSHConfigFile="",
        [string]$SSHIdentityFile,
        [string]$SSHRemoteCommand,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $UpdateParams = @{
        Action = 'delete'
        RecordName = $RecordName
        TxtValue = $TxtValue
        SSHServer = $SSHServer
        SSHUser = $SSHUser
        SSHConfigFile = $SSHConfigFile
        SSHIdentityFile = $SSHIdentityFile
        SSHRemoteCommand = $SSHRemoteCommand
    }

    Write-Verbose "Removing $RecordName with value $TxtValue"
    Send-SSHTxtUpdate @UpdateParams

    <#
    .SYNOPSIS
        Add a DNS TXT record via intermediate ssh server

    .DESCRIPTION
        Uses OpenSSH to forward a DDNS request to an ssh server

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER SSHServer
        The ssh server to proxy through.

    .PARAMETER SSHUser
        The ssh user to connect as.
    
    .PARAMETER SSHConfigFile
        The optional ssh config file to use. Ssh will use the user/system default if not specified.
    
    .PARAMETER SSHIdentityFile
        The ssh identify file to use. Ssh will use the user/system default if not specified.

    .PARAMETER SSHRemoteCommand
        The optional ssh remote command to run - in general, it is recommended to use an explicit key
        where the server admin has set it to run a forced command.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' -SSHServer server.acme.com -SSHUser acmeupdateuser

        Adds a TXT record for the specified site with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # If necessary, do work here to save or finalize changes performed by
    # Add/Remove functions. It is not uncommon for this function to have
    # no work to do depending on the DNS provider. In that case, just
    # leave the function body empty.

    <#
    .SYNOPSIS
        Commits changes for pending DNS TXT record modifications to <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Save-DnsTxt

        Commits changes for pending DNS TXT record modifications.
    #>
}

############################
# Helper Functions
############################

# Add a commented link to API docs if they exist.

# Add additional functions here if necessary.

# Try to follow verb-noun naming guidelines.
# https://msdn.microsoft.com/en-us/library/ms714428

function Send-SSHTxtUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [ValidateSet('add','delete')]
        [string]$Action,
        [Parameter(Mandatory)]
        [string]$SSHServer,
        [Parameter(Mandatory)]
        [string]$SSHUser,
        [string]$SSHConfigFile="",
        [string]$SSHIdentityFile,
        [string]$SSHRemoteCommand,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # build ssh command string
    # ssh $SSHuser@$SSHServer [-F $SSHConfigFile] [-O IdentitiesOnly=yes -i $SSHIdentityFile] -- [$SSHRemoteCommand] $RecordName $TxtValue

    $sshArgs=@("-l", $SSHUser)
    
    # if using explicit config file
    if ( "" -ne "$SSHConfigFile" ) {
        $sshArgs+=("-F", $SSHConfigFile)
    }

    if ( "" -ne "$SSHIdentityFile" ) {
        $sshArgs+=("-o", "IdentitiesOnly=yes", "-i", "$SSHIdentityFile")
    }

    $sshArgs+=$SSHServer

    Write-Debug "ssh $sshArgs -- $SSHRemoteCommand $Action $RecordName $TxtValue"
    & ssh $sshArgs -- $SSHRemoteCommand $Action $RecordName $TxtValue
}