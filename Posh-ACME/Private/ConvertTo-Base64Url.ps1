function ConvertTo-Base64Url {
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(ParameterSetName='String',Mandatory,Position=0,ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Text,
        [Parameter(ParameterSetName='String')]
        [switch]$FromBase64,
        [Parameter(ParameterSetName='Bytes',Mandatory,Position=0)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    Process {

        if (!$FromBase64) {

            # get a byte array from the input string
            if ($PSCmdlet.ParameterSetName -eq 'String') {
                $Bytes = [Text.Encoding]::UTF8.GetBytes($Text)
            }

            # standard base64 encoder
            $s = [Convert]::ToBase64String($Bytes)

        } else {
            # $Text is already Base64 encoded, we just need the Url'ized version
            $s = $Text
        }

        # remove trailing '='s
        $s = $s.Split('=')[0]

        # 62nd and 63rd char of encoding
        $s = $s.Replace('+','-').Replace('/','_')

        return $s

    }

}
