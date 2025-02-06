function Import-PluginDetail {
    [CmdletBinding()]
    param()

    # Cache all of the plugin details into a module variable that other
    # things can reference for easy access:
    # - Name
    # - ChallengeType
    # - Filesystem Path

    # initialize the module variable with pre-cached details for all of the
    # built-in plugins so we can avoid having to dot source them
    $script:Plugins = @{
        'AcmeDns'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'AcmeDns'}
        'Active24'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Active24'}
        'AddrTools'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'AddrTools'}
        'Akamai'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Akamai'}
        'Aliyun'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Aliyun'}
        'All-Inkl'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'All-Inkl'}
        'Aurora'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Aurora'}
        'AutoDNS'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'AutoDNS'}
        'Azure'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Azure'}
        'Beget'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Beget'}
        'BlueCat'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'BlueCat'}
        'Bunny'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Bunny'}
        'Cloudflare'           = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Cloudflare'}
        'ClouDNS'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'ClouDNS'}
        'Combell'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Combell'}
        'Constellix'           = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Constellix'}
        'CoreNetworks'         = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'CoreNetworks'}
        'DeSEC'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'DeSEC'}
        'DMEasy'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'DMEasy'}
        'DNSimple'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'DNSimple'}
        'DNSPod'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'DNSPod'}
        'DOcean'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'DOcean'}
        'DomainOffensive'      = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'DomainOffensive'}
        'Domeneshop'           = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Domeneshop'}
        'Dreamhost'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Dreamhost'}
        'DuckDNS'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'DuckDNS'}
        'Dynu'                 = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Dynu'}
        'EasyDNS'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'EasyDNS'}
        'Easyname'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Easyname'}
        'EuroDNSReseller'      = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'EuroDNSReseller'}
        'FreeDNS'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'FreeDNS'}
        'Gandi'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Gandi'}
        'GCloud'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'GCloud'}
        'GoogleDomains'        = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'GoogleDomains'}
        'GoDaddy'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'GoDaddy'}
        'Hetzner'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Hetzner'}
        'HostingDe'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'HostingDe'}
        'HurricaneElectric'    = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'HurricaneElectric'}
        'HurricaneElectricDyn' = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'HurricaneElectric'}
        'IBMSoftLayer'         = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'IBMSoftLayer'}
        'Infoblox'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Infoblox'}
        'Infomaniak'           = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Infomaniak'}
        'INWX'                 = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'INWX'}
        'IONOS'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'IONOS'}
        'ISPConfig'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'ISPConfig'}
        'LeaseWeb'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'LeaseWeb'}
        'Linode'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Linode'}
        'Loopia'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Loopia'}
        'LuaDns'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'LuaDns'}
        'Manual'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Manual'}
        'Namecheap'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Namecheap'}
        'NameCom'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'NameCom'}
        'NameSilo'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'NameSilo'}
        'NS1'                  = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'NS1'}
        'OnlineNet'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'OnlineNet'}
        'OVH'                  = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'OVH'}
        'PointDNS'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'PointDNS'}
        'Porkbun'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Porkbun'}
        'PortsManagement'      = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'PortsManagement'}
        'PowerDNS'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'PowerDNS'}
        'Rackspace'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Rackspace'}
        'Regru'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Regru'}
        'RFC2136'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'RFC2136'}
        'Route53'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Route53'}
        'Selectel'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Selectel'}
        'SimpleDNSPlus'        = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'SimpleDNSPlus'}
        'Simply'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Simply'}
        'SimplyCom'            = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'SimplyCom'}
        'SOLIDServer'          = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'SOLIDServer'}
        'SSHProxy'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'SSHProxy'}
        'TencentDNS'           = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'TencentDNS'}
        'TotalUptime'          = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'TotalUptime'}
        'UKFast'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'UKFast'}
        'WebRoot'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'http-01'; Path = ''; Name = 'WebRoot'}
        'WebSelfHost'          = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'http-01'; Path = ''; Name = 'WebSelfHost'}
        'WebsupportSK'         = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'WebsupportSK'}
        'WEDOS'                = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'WEDOS'}
        'Windows'              = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Windows'}
        'Yandex'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Yandex'}
        'Zilore'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Zilore'}
        'ZoneEdit'             = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'ZoneEdit'}
        'Zonomi'               = [pscustomobject]@{PSTypeName = 'PoshACME.PAPluginDetail'; ChallengeType = 'dns-01'; Path = ''; Name = 'Zonomi'}
    }

    $pluginDir = Join-Path $MyInvocation.MyCommand.Module.ModuleBase 'Plugins'
    Write-Debug "Loading default plugin details from $pluginDir"

    $allPluginFiles = @(Get-ChildItem (Join-Path $pluginDir '*.ps1') -Exclude '_Example*')

    # check for external plugin folder based on the POSHACME_PLUGINS environment variable
    if (-not [string]::IsNullOrWhiteSpace($env:POSHACME_PLUGINS)) {
        if (Test-Path $env:POSHACME_PLUGINS -PathType Container) {
            Write-Debug "Loading external plugin details from $($env:POSHACME_PLUGINS)"
            $allPluginFiles += @(Get-ChildItem (Join-Path $env:POSHACME_PLUGINS '*.ps1'))
        } else {
            Write-Warning "The POSHACME_PLUGINS environment variable exists but the path it points to, $($env:POSHACME_PLUGINS), does not. External plugins will not be loaded."
        }
    }

    $functionNames = @(
        'Function:Get-CurrentPluginType'
        'Function:Add-DnsTxt'
        'Function:Remove-DnsTxt'
        'Function:Save-DnsTxt'
        'Function:Add-HttpChallenge'
        'Function:Remove-HttpChallenge'
        'Function:Save-HttpChallenge'
    )

    foreach ($pFile in $allPluginFiles) {

        # remove references to previous plugin functions so we can validate
        # this one properly
        Remove-Item $functionNames -EA Ignore

        $pName = $pFile.BaseName

        if ($script:Plugins.$pName) {
            if ($script:Plugins.$pName.Path -eq [String]::Empty) {
                # this is a built-in plugin we've pre-cached the details for so we
                # can skip the dot sourcing and just add the filesystem path.
                $script:Plugins.$pName.Path = $pFile.FullName
            } else {
                # This is a custom plugin that has name conflict with a native plugin
                # Skip it
                Write-Warning "Skipped loading external plugin that has name conflict with native plugin. $($pFile.FullName)"
            }
            continue
        }

        Write-Debug "Found non-native potential plugin file $($pFile.Name)"

        # dot source it
        . $pFile.FullName

        # make sure it has the type function
        if (-not (Get-Command 'Get-CurrentPluginType' -EA Ignore)) {
            Write-Warning "$pName plugin is missing Get-CurrentPluginType function. Will not use."
            continue
        }

        # make sure it has type specific functions
        $chalType = Get-CurrentPluginType
        if ('dns-01' -eq $chalType) {
            if (-not (Get-Command 'Add-DnsTxt' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Add-DnsTxt function. Will not use."
                continue
            }
            if (-not (Get-Command 'Remove-DnsTxt' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Remove-DnsTxt function. Will not use."
                continue
            }
            if (-not (Get-Command 'Save-DnsTxt' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Save-DnsTxt function. Will not use."
                continue
            }
        } elseif ('http-01' -eq $chalType) {
            if (-not (Get-Command 'Add-HttpChallenge' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Add-HttpChallenge function. Will not use."
                continue
            }
            if (-not (Get-Command 'Remove-HttpChallenge' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Remove-HttpChallenge function. Will not use."
                continue
            }
            if (-not (Get-Command 'Save-HttpChallenge' -EA Ignore)) {
                Write-Warning "$pName plugin is missing Save-HttpChallenge function. Will not use."
                continue
            }
        } else {
            Write-Warning "$pName plugin sent unrecognized challenge type. Will not use."
            continue
        }

        # add it to the module variable
        $script:Plugins.$pName = [pscustomobject]@{
            PSTypeName = 'PoshACME.PAPluginDetail'
            Name = $pName
            ChallengeType = $chalType
            Path = $pFile.FullName
        }

    }

}
