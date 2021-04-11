function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(Mandatory)]
        [String]$EasyNameUserEmail,
        [Parameter(Mandatory)]
        [SecureString]$EasyNameUserPassword,
        $ExtraParams
    )

    # Do work here to add the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Add a DNS TXT record to <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Adds a TXT record for the specified site with the specified value.
    #>
    
    $EasynameURLs = Easyname-GetEndPoints
    $EasynameWebSession = Easyname-GetWebSession
    $EasynameCookies = $EasynameWebSession.Cookies.GetCookies($EasynameURLs.login) 
    $EasynameCsrfToken = $EasynameCookies["CSRF-TOKEN"].Value
    $EasynameLoggedIn = Easyname-Login
    
    if ($EasynameLoggedIn) {
                
        $DomainList = Easyname-GetDomains
        
        # The appended "http://" string on the url Parameter is only needed becouse the foreign function needs it for the RexEx-Part
        $DomainId = ($DomainList | Where-Object { $_.DomainName -eq (Get-RootDomain -url ("http://" + $RecordName)) }).DomainId

        $CurrentDomainRecords = Easyname-GetCurrentDomainRecords -DomainId $DomainId
        
        if ($RecordName -notin $CurrentDomainRecords.Name) {
            # Add Record
            
            $domaindata = @{
                id       = ""
                name     = $RecordName.Split('.')[0]
                type     = "TXT"
                content  = $TxtValue
                priority = "10"
                ttl      = "360"
            }
            
            $create_response = Invoke-WebRequest -WebSession $EasynameWebSession -Uri $EasynameURLs.dns_create_entry.Replace("{}", $DomainId) -Method Post -Body $domaindata @script:UseBasic

            # Create HTML file Object
            $HTML = New-Object -Com "HTMLFile"
            # Write HTML content according to DOM Level2 
            $HTML.IHTMLDocument2_write($create_response.Content)
            
            $HttpError = ($HTML.all | Where-Object { $_.className -eq "feedback-message--error" }).textContent
            $HttpSuccess = ($HTML.all | Where-Object { $_.className -eq "feedback-message--success" }).textContent
            if ($HttpError) {
                throw "$HttpError"
            }
            Write-Verbose($HttpSuccess)
        }
        else {
            # Update Record
            $RecordId = ($CurrentDomainRecords | Where-Object { $RecordName -eq $_.Name }).RecordId

            $domaindata = @{
                id       = $RecordId
                name     = $RecordName.Split('.')[0]
                type     = "TXT"
                content  = $TxtValue
                priority = "10"
                ttl      = "360"
            }

            [regex]$pattern = "{}"
            $EasyNameUpdateUrl = $EasynameURLs.dns_update_entry
            $EasyNameUpdateUrl = $pattern.Replace($EasyNameUpdateUrl, $DomainId, 1)
            $EasyNameUpdateUrl = $pattern.Replace($EasyNameUpdateUrl, $RecordId, 1)

            $update_response = Invoke-WebRequest -WebSession $EasynameWebSession -Uri $EasyNameUpdateUrl -Method Post -Body $domaindata @script:UseBasic

            # Create HTML file Object
            $HTML = New-Object -Com "HTMLFile"
            # Write HTML content according to DOM Level2 
            $HTML.IHTMLDocument2_write($update_response.Content)
            
            $HttpError = ($HTML.all | Where-Object { $_.className -eq "feedback-message--error" }).textContent
            $HttpSuccess = ($HTML.all | Where-Object { $_.className -eq "feedback-message--success" }).textContent
            if ($HttpError) {
                throw "$HttpError"
            }
            Write-Verbose($HttpSuccess)
        }
    }
}

function Remove-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$RecordName,
        [Parameter(Mandatory, Position = 1)]
        [string]$TxtValue,
        <#
        Add plugin specific parameters here. Make sure their names are
        unique across all existing plugins. But make sure common ones
        across this plugin are the same.
        #>
        [Parameter(Mandatory)]
        [String]$EasyNameUserEmail,
        [Parameter(Mandatory)]
        [SecureString]$EasyNameUserPassword,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    # Do work here to remove the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Remove a DNS TXT record from <My DNS Server/Provider>

    .DESCRIPTION
        Description for <My DNS Server/Provider>

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value'

        Removes a TXT record for the specified site with the specified value.
    #>

    $EasynameURLs = Easyname-GetEndPoints
    $EasynameWebSession = Easyname-GetWebSession
    $EasynameCookies = $EasynameWebSession.Cookies.GetCookies($EasynameURLs.login) 
    $EasynameCsrfToken = $EasynameCookies["CSRF-TOKEN"].Value
    $EasynameLoggedIn = Easyname-Login

    if ($EasynameLoggedIn) {
                
        $DomainList = Easyname-GetDomains
        
        # The appended "http://" string on the url Parameter is only needed becouse the foreign function needs it for the RexEx-Part
        $DomainId = ($DomainList | Where-Object { $_.DomainName -eq (Get-RootDomain -url ("http://" + $RecordName)) }).DomainId

        $CurrentDomainRecords = Easyname-GetCurrentDomainRecords -DomainId $DomainId
        
        if (($RecordName -in $CurrentDomainRecords.Name) -and ($TxtValue -in $CurrentDomainRecords.Content )) {
            # Remove Record
            $RecordId = ($CurrentDomainRecords | Where-Object { $TxtValue -eq $_.Content }).RecordId
            
            [regex]$pattern = "{}"
            $EasyNameDeleteUrl = $EasynameURLs.dns_delete_entry
            $EasyNameDeleteUrl = $pattern.Replace($EasyNameDeleteUrl, $DomainId, 1)
            $EasyNameDeleteUrl = $pattern.Replace($EasyNameDeleteUrl, $RecordId, 1)

            $EasyNameDeleteConfirmUrl = $EasynameURLs.dns_delete_entry_confirm
            $EasyNameDeleteConfirmUrl = $pattern.Replace($EasyNameDeleteConfirmUrl, $DomainId, 1)
            $EasyNameDeleteConfirmUrl = $pattern.Replace($EasyNameDeleteConfirmUrl, $RecordId, 1)

            # seems not needed anymore
            #$delete_response = Invoke-WebRequest -WebSession $EasynameWebSession -Uri $EasyNameDeleteUrl -Method Get @script:UseBasic

            $delete_response_confirm = Invoke-WebRequest -WebSession $EasynameWebSession `
                -Uri $EasyNameDeleteConfirmUrl -Method Post @script:UseBasic
                        
            # Create HTML file Object
            $HTML = New-Object -Com "HTMLFile"
            # Write HTML content according to DOM Level2 
            $HTML.IHTMLDocument2_write($delete_response_confirm.Content)
            
            $HttpSuccess = ($HTML.all | Where-Object { $_.className -eq "feedback-message--success" }).textContent
            $HttpError = ($HTML.all | Where-Object { $_.className -eq "feedback-message--error" }).textContent
            if ($HttpError) {
                throw "$HttpError"
            }
            Write-Verbose($HttpSuccess)
        }
    }
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

Function Easyname-GetWebSession() {
    <#
    .SYNOPSIS
    Return the WebSession.
    #>

    $home_response = Invoke-WebRequest -Uri $EasynameURLs.login -SessionVariable EasynameWebSession @script:UseBasic
    return $EasynameWebSession
}

Function Easyname-Login() {
    <#
    .SYNOPSIS
    Attempt to login session on easyname.
    #>
    
    $payload = @{
        emailAddress = $EasyNameUserEmail
        password     = Get-PlainPassword($EasyNameUserPassword)
    } | ConvertTo-Json

    $Headers = $EasynameWebSession.Headers
    $Headers["X-CSRF-TOKEN"] = $EasynameCsrfToken

    $login_response = Invoke-WebRequest -WebSession $EasynameWebSession -Uri $EasynameURLs.login_endpoint -Method Post -Body $payload -ContentType "application/json" @script:UseBasic
    $object = $login_response.content | ConvertFrom-Json
    
    if ($object.userId) { 
        return $true 
    } 
    else { return $false }
}

Function Easyname-GetDomains() {
    <#
        Easyname uses internal IDs for domain record configuration,
        so this retrieves a list of all tld's, associates with the given account.
    #>

    # ComputedProperties 
    $expDomainName = @{e = { $_.innerText.split()[0] }; n = "DomainName" }
    $expDomainID = @{e  = { 
            $found = $_.innerHtml -match '.*domain=(\d+)".*';
            if ($found) {
                $did = $matches[1];
            } $did }; n = "DomainId" 
    }

    $DomainList = Invoke-WebRequest -WebSession $EasynameWebSession `
        -Uri $EasynameURLs.domain_list -Method Get @script:UseBasic

    # Create HTML file Object
    $HTML = New-Object -Com "HTMLFile"
    # Write HTML content according to DOM Level2 
    $HTML.IHTMLDocument2_write($DomainList.Content)
    #$domain_table = $HTML.getElementsByTagName("table")

    $DomainList = $HTML.all | Where-Object { $_.className -eq "entity--domain" } | Select-Object $expDomainName, $expDomainID
    if ($DomainList) {
        Return $DomainList
    }
    else {
        throw "Error no Domains found. Properly authenticated?"
    }

    #Return $DomainList
}
    

Function Easyname-GetCurrentDomainRecords($DomainId) {
    $Records = Invoke-WebRequest -WebSession $EasynameWebSession `
        -Uri $EasynameURLs.dns.Replace("{}", $DomainId) -Method Get @script:UseBasic

    # Create HTML file Object
    $HTML = New-Object -Com "HTMLFile"
    # Write HTML content according to DOM Level2 
    $HTML.IHTMLDocument2_write($Records.Content)
    
    $DomainRecords = @()
    $DomainTableRows = $HTML.all | Where-Object { $_.className -eq "entity--dns-record" }
    foreach ($element in $DomainTableRows) {
        $RecordId = $element.getElementsByClassName("button--naked vers--compact theme--error") | Select-Object -ExpandProperty outerHTML 
        $RecordId -match '-(\d+\")' | Out-Null
        if ($Matches) { 
            $RecordId = $Matches[0].Trim('"-')
            Clear-Variable Matches
        }

        $record = @{
            Name     = $element.innerText.split()[0]
            Type     = $element.innerText.split()[1]
            Content  = $element.innerText.split()[2]
            TTL      = $element.innerText.split()[3]
            #RecordId = (($element.childNodes | Where-Object { $_.ClassName -eq "entity__actions  taright" }).ChildNodes | Where-Object { $null -ne $_.nameProp}).nameProp
            #RecordId = $DomainTableRows[-1].getElementsByClassName("button--naked vers--compact theme--error") | Select-Object -ExpandProperty outerHTML
            RecordId = $RecordId
        }
        $DomainRecords += New-Object psobject -Property $record
    }
    if (-not $DomainRecords) { throw "Unable to find zone for $RecordName" }
    return $DomainRecords
}

Function Easyname-GetEndPoints() {
    <#
    .SYNOPSIS
    Returns a Hashtable Object, holding the specific Easyname Domain Management Endpoint URIs.
    #>

    $EasynameURLS = @{
        login                    = "https://my.easyname.com/en/login"
        login_endpoint           = "https://my.easyname.com/en/authentication-api/login"
        domain_list              = "https://my.easyname.com/domains/"
        dashboard                = "https://my.easyname.com/en/dashboard"
        overview                 = "https://my.easyname.com/hosting/view-user.php"
        dns                      = "https://my.easyname.com/en/domain/dns/index/domain/{}/"
        dns_create_entry         = "https://my.easyname.com/en/domain/dns/create/domain/{}"
        dns_update_entry         = "https://my.easyname.com/en/domain/dns/edit/domain/{}/id/{}"
        dns_delete_entry         = "https://my.easyname.com/en/domain/dns/delete/domain/{}/id/{}"
        dns_delete_entry_confirm = "https://my.easyname.com/en/domain/dns/delete/domain/{}/id/{}/confirm/1"
    }
    return $EasynameURLS
}

Function Get-PlainPassword($Password) {
    <#
    .LINK https://stackoverflow.com/questions/28352141/convert-a-secure-string-to-plain-text
    #>
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

function Get-RootDomain($url) {
    <#
    .SYNOPSIS
    This solves the problem of extracting the root domain from a given URL.
    The challenge here is to incorporate domain semantics using an array of eTLDs during extraction.

    The eTLD (effective top-level domain)-Array may need periodic updates from a PSL (Public Suffix List)!
    
    See eTLD (effective top-level domain) or PSL (Public Suffix List) for further Information. 
    
    .PARAMETER url
    String in the format of "http://www.tld.domain" or "https://www.tld.domain"
    
    .LINK https://kimconnect.com/powershell-extract-root-domain-from-url/ 
    #>

    $domainsDictionary = @{
        '.ac'     = 'Ascension Island'
        '.ac.uk'  = 'Second-level domain for United Kingdom (.uk) and most often used for academic sites.'
        '.ad'     = 'Andorra'
        '.ae'     = 'United Arab Emirates'
        '.aero'   = 'Air Transportation Industry'
        '.af'     = 'Afghanistan'
        '.ag'     = 'Antigua and Barbuda'
        '.ai'     = 'Anguilla'
        '.al'     = 'Albania'
        '.am'     = 'Armenia'
        '.an'     = 'Netherlands Antilles'
        '.ao'     = 'Angola'
        '.aq'     = 'Antarctica'
        '.ar'     = 'Argentina'
        '.arpa'   = 'Internet infrastructure TLD'
        '.as'     = 'American Somoa'
        '.asia'   = 'Asian countries'
        '.at'     = 'Austria'
        '.au'     = 'Australia'
        '.aw'     = 'Aruba'
        '.ax'     = 'Aland Islands - part of Finland'
        '.az'     = 'Azerbaijan'
        '.ba'     = 'Bosnia and Herzegovinia'
        '.bb'     = 'Barbados'
        '.bd'     = 'Bangladesh'
        '.be'     = 'Belgium'
        '.bf'     = 'Burkina Faso'
        '.bg'     = 'Bulgaria'
        '.bh'     = 'Bahrain'
        '.bi'     = 'Burundi'
        '.biz'    = 'United States business site.'
        '.bj'     = 'Benin'
        '.bm'     = 'Bermuda'
        '.bn'     = 'Brunei Darussalam'
        '.bo'     = 'Bolivia'
        '.br'     = 'Brazil'
        '.bs'     = 'Bahamas'
        '.bt'     = 'Bhutan'
        '.bv'     = 'Bouvet Island'
        '.bw'     = 'Botswana'
        '.by'     = 'Belarus and Byelorussia'
        '.bz'     = 'Belize'
        '.ca'     = 'Canada'
        '.cat'    = 'Catalan'
        '.cc'     = 'Cocos Islands - Keelings'
        '.cd'     = 'Democratic Republic of the Congo'
        '.cf'     = 'Central African Republic'
        '.cg'     = 'Congo'
        '.ch'     = 'Switzerland'
        '.ci'     = 'Cote dIvoire'
        '.ck'     = 'Cook Islands'
        '.cl'     = 'Chile'
        '.cm'     = 'Cameroon'
        '.cn'     = 'China'
        '.co'     = 'Colombia'
        '.co.uk'  = 'Second-level domain for United Kingdom (.uk) and most often used for commercial sites.'
        '.com'    = 'United States commercial website.'
        '.coop'   = 'Business cooperatives and organizations.'
        '.cr'     = 'Costa Rica'
        '.cs'     = 'Former Czechoslovakia'
        '.cu'     = 'Cuba'
        '.cv'     = 'Cape Verde'
        '.cw'     = 'Curaçao'
        '.cx'     = 'Christmas Island'
        '.cy'     = 'Cyprus'
        '.cz'     = 'Czech Republic'
        '.dd'     = 'East Germany'
        '.de'     = 'Germany'
        '.dj'     = 'Djibouti'
        '.dk'     = 'Denmark'
        '.dm'     = 'Dominica'
        '.do'     = 'Dominican Republic'
        '.dz'     = 'Algeria'
        '.ec'     = 'Ecuador'
        '.edu'    = 'United States education site.'
        '.ee'     = 'Estonia'
        '.eg'     = 'Egypt'
        '.eh'     = 'Western Sahara'
        '.er'     = 'Eritrea'
        '.es'     = 'Spain'
        '.et'     = 'Ethiopia'
        '.eu'     = 'European Union'
        '.fi'     = 'Finland'
        '.firm'   = 'Internet site for business or firm.'
        '.fj'     = 'Fiji'
        '.fk'     = 'Falkland Islands and Malvinas'
        '.fm'     = 'Micronesia'
        '.fo'     = 'Faroe Islands'
        '.fr'     = 'France'
        '.fx'     = 'Metropolitan France'
        '.ga'     = 'Gabon'
        '.gb'     = 'Great Britain'
        '.gd'     = 'Grenada'
        '.ge'     = 'Georgia'
        '.gf'     = 'French Guiana'
        '.gg'     = 'Guernsey'
        '.gh'     = 'Ghana'
        '.gi'     = 'Gibraltar'
        '.gl'     = 'Greenland'
        '.gm'     = 'Gambia'
        '.gn'     = 'Guinea'
        '.gov'    = 'United States Government site.'
        '.gov.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for government sites.'
        '.gp'     = 'Guadeloupe'
        '.gq'     = 'Equatorial Guinea'
        '.gr'     = 'Greece'
        '.gs'     = 'South Georgia and South Sandwich Islands.'
        '.gt'     = 'Guatemala'
        '.gu'     = 'Guam'
        '.gw'     = 'Guinea-Bissau'
        '.gy'     = 'Guyana'
        '.hk'     = 'Hong Kong'
        '.hm'     = 'Heard and McDonald Islands'
        '.hn'     = 'Honduras'
        '.hr'     = 'Croatia/Hrvatska'
        '.ht'     = 'Haiti'
        '.hu'     = 'Hungary'
        '.id'     = 'Indonesia'
        '.ie'     = 'Ireland'
        '.il'     = 'Israel'
        '.im'     = 'Isle of Man'
        '.in'     = 'India'
        '.info'   = 'United States information site with no restrictions.'
        '.int'    = 'International institute site.'
        '.io'     = 'British Indian Ocean Territory'
        '.iq'     = 'Iraq'
        '.ir'     = 'Iran'
        '.is'     = 'Iceland'
        '.it'     = 'Italy'
        '.je'     = 'Jersey - Channel Islands a UK dependency'
        '.jm'     = 'Jamaica'
        '.jo'     = 'Jordan'
        '.jobs'   = 'Job related sites.'
        '.jp'     = 'Japan'
        '.ke'     = 'Kenya'
        '.kg'     = 'Kyrgyzstan'
        '.kh'     = 'Cambodia'
        '.ki'     = 'Kiribati'
        '.km'     = 'Comoros'
        '.kn'     = 'Saint Kitts and Nevis'
        '.kp'     = 'North Korea'
        '.kr'     = 'South Korea'
        '.kw'     = 'Kuwait'
        '.ky'     = 'Cayman Islands'
        '.kz'     = 'Kazakhstan'
        '.la'     = 'Laos'
        '.lb'     = 'Lebanon'
        '.lc'     = 'Saint Lucia'
        '.li'     = 'Liechtenstein'
        '.lk'     = 'Sri Lanka'
        '.lr'     = 'Liberia'
        '.ls'     = 'Lesotho'
        '.lt'     = 'Lithuania'
        '.ltd.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for limited company sites.'
        '.lu'     = 'Luxembourg'
        '.lv'     = 'Latvia'
        '.ly'     = 'Libya'
        '.ma'     = 'Morocco'
        '.mc'     = 'Monaco'
        '.md'     = 'Moldova'
        '.me'     = 'Montenegro'
        '.me.uk'  = 'Second-level domain for United Kingdom (.uk) and most often used for personal sites.'
        '.mg'     = 'Madagascar'
        '.mh'     = 'Marshall Islands'
        '.mil'    = 'United States Military site.'
        '.mk'     = 'Macedonia'
        '.ml'     = 'Mali'
        '.mm'     = 'Myanmar'
        '.mn'     = 'Mongolia'
        '.mo'     = 'Macau'
        '.mobi'   = 'Mobile devices'
        '.mod.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for military of defence sites.'
        '.mp'     = 'Northern Mariana Islands'
        '.mq'     = 'Martinique'
        '.mr'     = 'Mauritania'
        '.ms'     = 'Montserrat'
        '.mt'     = 'Malta'
        '.mu'     = 'Mauritius'
        '.museum' = 'Worldwide museums'
        '.mv'     = 'Maldives'
        '.mw'     = 'Malawi'
        '.mx'     = 'Mexico'
        '.my'     = 'Malaysia'
        '.mz'     = 'Mozambique'
        '.na'     = 'Namibia'
        '.name'   = 'Individual and family names'
        '.nato'   = 'NATO site.'
        '.nc'     = 'New Caledonia'
        '.ne'     = 'Niger'
        '.net'    = 'United States Internet administrative site. See the .net definition for alternative definitions.'
        '.net.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for network company sites.'
        '.nf'     = 'Norfolk Island'
        '.ng'     = 'Nigeria'
        '.nhs.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for national health service institutions'
        '.ni'     = 'Nicaragua'
        '.nl'     = 'Netherlands'
        '.no'     = 'Norway'
        '.nom'    = 'Personal site'
        '.np'     = 'Nepal'
        '.nr'     = 'Nauru'
        '.nt'     = 'Neutral Zone'
        '.nu'     = 'Niue'
        '.nz'     = 'New Zealand'
        '.om'     = 'Oman'
        '.org'    = 'Organization (non-profit) sites.'
        '.org.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for non-profit sites.'
        '.pa'     = 'Panama'
        '.pe'     = 'Peru'
        '.pf'     = 'French Polynesia'
        '.pg'     = 'Papua New Guinea'
        '.ph'     = 'Philippines'
        '.pk'     = 'Pakistan'
        '.pl'     = 'Poland'
        '.plc.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for public limited company sites.'
        '.pm'     = 'St. Pierre and Miquelon'
        '.pn'     = 'Pitcairn'
        '.post'   = 'sTLD (sponsored top-level domain) available exclusively for the postal sector.'
        '.pr'     = 'Puerto Rico'
        '.pro'    = 'United States professional site for accountants'
        '.ps'     = 'Palestinian territories'
        '.pt'     = 'Portugal'
        '.pw'     = 'Palau'
        '.py'     = 'Paraguay'
        '.qa'     = 'Qatar'
        '.re'     = 'Reunion'
        '.ro'     = 'Romania'
        '.rs'     = 'Republic of Serbia'
        '.ru'     = 'Russian Federation'
        '.rw'     = 'Rwanda'
        '.sa'     = 'Saudi Arabia'
        '.sb'     = 'Solomon Islands'
        '.sc'     = 'Seychelles'
        '.sch.uk' = 'Second-level domain for United Kingdom (.uk) and most often used for school sites.'
        '.sd'     = 'Sudan'
        '.se'     = 'Sweden'
        '.sg'     = 'Singapore'
        '.sh'     = 'Saint Helena'
        '.si'     = 'Slovenia'
        '.sj'     = 'Svalbard and Jan Mayen Islands'
        '.sk'     = 'Slovakia'
        '.sl'     = 'Sierra Leone'
        '.sm'     = 'San Marino'
        '.sn'     = 'Senegal'
        '.so'     = 'Somalia'
        '.sr'     = 'Suriname'
        '.ss'     = 'South Sudan'
        '.st'     = 'Sao Tome and Principe'
        '.store'  = 'United States domain for retail business site.'
        '.su'     = 'Former USSR'
        '.sv'     = 'El Salvador'
        '.sy'     = 'Syria'
        '.sz'     = 'Swaziland'
        '.tc'     = 'Turks and Caicos Islands'
        '.td'     = 'Chad'
        '.tel'    = 'Internet communication services'
        '.tf'     = 'French Southern Territory and Antarctic Lands.'
        '.tg'     = 'Togo'
        '.th'     = 'Thailand'
        '.tj'     = 'Tajikistan'
        '.tk'     = 'Tokelau'
        '.tl'     = 'East Timor'
        '.tm'     = 'Turkmenistan'
        '.tn'     = 'Tunisia'
        '.to'     = 'Tonga'
        '.tp'     = 'East Timor'
        '.tr'     = 'Turkey'
        '.travel' = 'Travel related sites.'
        '.tt'     = 'Trinidad and Tobago'
        '.tv'     = 'Tuvalu'
        '.tw'     = 'Taiwan'
        '.tz'     = 'Tanzania'
        '.ua'     = 'Ukraine'
        '.ug'     = 'Uganda'
        '.uk'     = 'United Kingdom'
        '.um'     = 'United States minor outlying islands.'
        '.us'     = 'United States'
        '.uy'     = 'Uruguay'
        '.uz'     = 'Uzbekistan'
        '.va'     = 'Vatican City State'
        '.vc'     = 'Saint Vincent and the Grenadines'
        '.ve'     = 'Venezuela'
        '.vg'     = 'British Virgin Islands'
        '.vi'     = 'United States Virgin Islands'
        '.vn'     = 'Vietnam'
        '.vu'     = 'Vanuatu'
        '.web'    = 'Internet site about the World Wide Web.'
        '.wf'     = 'Wallis and Futuna Islands'
        '.ws'     = 'Samoa'
        '.xxx'    = 'Adult entertainment domain'
        '.ye'     = 'Yemen'
        '.yt'     = 'Mayotte'
        '.yu'     = 'Yugoslavia'
        '.za'     = 'South Africa'
        '.zm'     = 'Zambia'
        '.zr'     = 'Zaire'
        '.zw'     = 'Zimbabwe'
    }

    $domain = ([uri]$url).Host
    $matchedTwoDottedDomain = $domainsDictionary.keys | Where-Object { $domain -match "$_$" } | Where-Object { $_ -match '\.\w+\.' }
    $rootDomain = if (!$matchedTwoDottedDomain) { $domain.split('.')[-2..-1] -join '.' }
    else { $domain.split('.')[-3..-1] -join '.' }
    return $rootDomain
}

################################
# Begin: Experimental REST API #
################################

<#
 The following functions are used to
 authenthicate against the Easyname REST-API

 The Easyname REST API exposes currently (April 2021) only a limited set of DNS Management capabilities.
 See the Notes in the corresponding Plugin Guide.
 
 So these functions are not used in the current Easyname Plugin. 
 Theoretically the API can be used to obtain the internal Domain ID's of a Domain.
 But the fact that the API doesen't expose ID's for individual Records makes them more or less 
 useless for the intended purpose.
#>
Function Get-StringHash { 
    param
    (
        [String] $String,
        $HashName = "MD5"
    )
    <#
    .LINK https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/generating-md5-hashes-from-text
    #>
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $StringBuilder = New-Object System.Text.StringBuilder 
  
    $algorithm.ComputeHash($bytes) | 
    ForEach-Object { 
        $null = $StringBuilder.Append($_.ToString("x2")) 
    } 
  
    $StringBuilder.ToString() 
}

Function ConvertTo-Base64 {
    <#
    .SYNOPSIS
    Converts the given string to Base64
    
    .PARAMETER String
    The String which will be converted to Base64
    
    .EXAMPLE
     ConvertTo-Base64 -String "Hello from the Posh-ACME Easyname Plugin"

     SGVsbG8gZnJvbSB0aGUgUG9zaC1BQ01FIEVhc3luYW1lIFBsdWdpbg==
    #>
    param
    (
        [String] $String
    )
    Return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($String))
}

Function Get-XUserAuthenticationHeader {
    [regex]$pattern = "%s"
    $AuthenticationSalt = $pattern.Replace($EasyNameAuthenticationSalt, $EasyNameUserId, 1)
    $AuthenticationSalt = $pattern.Replace($AuthenticationSalt, $EasyNameUserEmail, 1)
    return ConvertTo-Base64 -String (Get-StringHash -String $AuthenticationSalt)
}

Function Easyname-GetDomainsRestfull {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory)]
        [String]$EasyNameUserEmail,
        [Parameter(Mandatory)]
        [String]$EasyNameUserId,
        [Parameter(Mandatory)]
        [String]$EasyNameAuthenticationSalt,
        [Parameter(Mandatory)]
        [String]$EasyNameAPIKey,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
    Get a List of available Domains using the Easyname RestAPI

    .EXAMPLE
    $pArgs = @{EasyNameUserId = '12345'; 
               EasyNameUserEmail = 'user@example.com'; 
               EasyNameAPIKey = 'APIKey12345'; 
               EasyNameAuthenticationSalt = '12345%abcd%s6789'; 
               EasyNameSigningSalt = 'sde7jk3FrHN43kCYEP2' }
    
    $json = Easyname-GetDomainsRestfull | fl
    $json.data

    ...
    id                     : 1234567
    domain                 : example.com
    domainIdn              : example.com
    registrantContact      : 990099
    adminContact           : 990099
    techContact            : 990099
    zoneContact            : 990099
    autoRenew              : True
    transferAllowed        : False
    isTransferAwayPossible : True
    trustee                : False
    purchased              : 1970-01-01 00:00:00
    expire                 : 2099-12-31 00:00:00
    renewal                : 2099-12-31 00:00:00
    authcode               : SecretAuthCodeHere
    lastAuthcodeUpdate     : 1970-01-01 09:28:49
    ...

    .NOTES
    Showcase using the Easyname Rest API to retrieve the list of Available Domains. 

    See the Notes in the corresponding Plugin Guide.
    #> 

    $Params = @{
        "URI"     = 'https://api.easyname.com/domain/'
        "Method"  = 'GET'
        "Headers" = @{
            "Content-Type"          = 'application/json'
            "X-User-ApiKey"         = $EasyNameAPIKey
            "X-User-Authentication" = Get-XUserAuthenticationHeader  
        }
    }

    $rest_response = Invoke-RestMethod @Params
    return $rest_response
}
##############################
# End: Experimental REST API #
##############################