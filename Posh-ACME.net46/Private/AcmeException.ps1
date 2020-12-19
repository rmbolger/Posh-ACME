class AcmeException : System.Exception
{
    [PSObject]$Data

    AcmeException($Message,$Data) : base($Message) {
        $this.Data = $Data
    }
}
