function Get-PAAuthorizations {
    [CmdletBinding()]
    [OutputType('PoshACME.PAAuthorization')]
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
