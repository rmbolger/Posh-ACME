class AcmeException : System.Exception
{
    [PSObject]$Data

    AcmeException($Message,$Data,$Exception) : base($Message,$Exception) {
        $this.Data = $Data
    }
}
