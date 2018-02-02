function ConvertTo-Base64Url {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='String',Mandatory,Position=0,ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Text,
        [Parameter(ParameterSetName='Bytes',Mandatory,Position=0)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    Process {

        if ($PSCmdlet.ParameterSetName -eq 'String') {
            $Bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        }

        # standard base64 encoder
        $s = [Convert]::ToBase64String($Bytes)

        # remove trailing '='s
        $s = $s.Split('=')[0]

        # 62nd and 63rd char of encoding
        $s = $s.Replace('+','-').Replace('/','_')

        return $s
        
    }
    
}