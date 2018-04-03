function Get-PAAuthorizations {
    [OutputType('PoshACME.PAAuthorization')]
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Order',Mandatory,Position=0,ValueFromPipeline)]
        [PSTypeName('PoshACME.PAOrder')]$Order,
        [Parameter(ParameterSetName='URLs',Mandatory,Position=0)]
        [string[]]$URLs
    )

    if ('Order' -eq $PSCmdlet.ParameterSetName) {

        Get-PAAuthorization $Order.authorizations

    } else {

        Get-PAAuthorization $URLs

    }

}
