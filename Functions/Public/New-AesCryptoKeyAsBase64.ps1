function New-AesCryptoKeyAsBase64
{
    <#
    .SYNOPSIS
        Generates a new cryptographically random 256-bit AES crypto key, formatted as a Base64 string.

    .DESCRIPTION
        Generates a new cryptographically random 256-bit AES crypto key, formatted as a Base64 string. This function is useful for API operations that require a new fresh key to be generated and supplied from the client.

    .PARAMETER AadClientAppId
        The AAD client application ID.

    .EXAMPLE
        C:\> New-AesCryptoKeyAsBase64
        Returns a new 256-bit AES crypto key, formatted as a Base64 string.
    #>
    [CmdletBinding()]
    Param
    (
    )
    Process
    {
        # new instance of the AES crypto .net class
        # it auto-generates a new IV and Key on class instantiation...
        $aes = New-Object -TypeName 'System.Security.Cryptography.AesManaged';

        # convert the crypto key (byte array) to the desired format and return it
        $result = [System.Convert]::ToBase64String($aes.Key);
        Write-Output -InputObject $result;
    }
}