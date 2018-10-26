function Extract-DomainsFromCSR {
  [CmdletBinding()]
  param (
    [ValidateScript({if(Test-Path $_){$true}else{Throw "Invalid path to CSR given: $_"}})]
    [Parameter(ParameterSetName=’FromCSR’,Mandatory)]
    [string]$CSRPath
  )
  Process {
    Try {
      $CSRSteamReader = [System.IO.StreamReader]::new($CSRPath)
      $CSRReqPem = [Org.BouncyCastle.OpenSsl.PEMReader]::new($CSRSteamReader)
      $CSRReq = $CSRReqPem.ReadObject()
    }
    Catch
    {
      $CSRSteamReader.Dispose()
      Throw 'CSR is not in correct format'
    }
    $CSRInfo = $CSRReq.GetCertificationRequestInfo()
    $CSRSteamReader.Dispose()
    $Domain = $CSRInfo.Subject -replace ".*?CN=([^,]*)(,.*|$)",'$1'
    if ($Domain -ne $CSRInfo.Subject) {
      Write-Verbose "Found $domain in CommonName"
    } else {
      Write-Verbose "Did not find any domain in CommonName"
    }
    #THIS IS UGLY, But I could not figure it out :(
    $ASN1 = (($CSRInfo.Attributes |Where-Object {  $_.'Id' -eq '1.2.840.113549.1.9.14'})[1][0]|Where-Object {  $_.'Id' -eq '2.5.29.17'})[1][0]
    $hex = [regex]::Split($ASN1.tostring().Substring(1),'(..)')|?{$_ -ne ''}|ForEach {[Convert]::ToInt64($_,16)}
    #Skip the first hex and then 1,2 hex (depending on length)
    if (($hex[1] -band 0xF0) -eq 0XF0) {
      $hex = $hex[3..$hex.Length]
    } else {
      $hex = $hex[2..$hex.Length]
    }
    $dnsnames = @()
    For($i=0;$i -lt $hex.Length;$i++){
      if ($hex[$i] -eq 0x82) { # Only do 0x82 which is DNS-NAME, 0x87 is IP which isnt allowed by Lets Encrypt.
        $currentname = ''
        For($j=$i+2;$j -lt $i+($hex[$i+1]+2);$j++){
          $currentname += [string][char]$hex[$j]
        }
        Write-Verbose "Found $currentname in Subject Alternate Names"
        $dnsnames += $currentname
      }
    }
    if ($Domain -eq $CSRInfo.Subject) {
      return $dnsnames[0..$dnsnames.count]
    } else {
      $returndomains = @($domain)
      $returndomains += ($dnsnames[0..$dnsnames.count]|Where-Object {$_ -ne $domain})
      return $returndomains
    }
  }
}
