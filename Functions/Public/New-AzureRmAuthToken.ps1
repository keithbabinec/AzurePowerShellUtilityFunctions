function New-AzureRmAuthToken
{
    <#
    .SYNOPSIS
        Creates a new authentication token for use against Azure RM REST API operations.

    .DESCRIPTION
        Creates a new authentication token for use against Azure RM REST API operations. This uses client/secret auth (not certificate auth).
        The returned output contains the OAuth bearer token and it's properties.

    .PARAMETER AadClientAppId
        The AAD client application ID.

    .PARAMETER AadClientAppSecret
        The AAD client application secret

    .PARAMETER AadTenantId
        The AAD tenant ID.

    .EXAMPLE
        C:\> New-AzureRmAuthToken -AadClientAppId <guid> -AadClientAppSecret '<secret>' -AadTenantId <guid>
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage='Please provide the AAD client application ID.')]
        [System.String]
        $AadClientAppId,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Please provide the AAD client application secret.')]
        [System.String]
        $AadClientAppSecret,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Please provide the AAD tenant ID.')]
        [System.String]
        $AadTenantId
    )
    Process
    {
        # grab app constants
        $aadUri = $MyInvocation.MyCommand.Module.PrivateData.Constants.AadAuthenticationUri;
        $resource = $MyInvocation.MyCommand.Module.PrivateData.Constants.AadAuthenticationResource;

        # load the web assembly and encode parameters
        $null = [Reflection.Assembly]::LoadWithPartialName('System.Web');
        $encodedClientAppSecret = [System.Web.HttpUtility]::UrlEncode($AadClientAppSecret);
        $encodedResource = [System.Web.HttpUtility]::UrlEncode($Resource);

        # construct and send the request
        $tenantAuthUri = $aadUri -f $AadTenantId;
        $headers = @{
            'Content-Type' = 'application/x-www-form-urlencoded';
        };
        $bodyParams = @(
            "grant_type=client_credentials",
            "client_id=$AadClientAppId",
            "client_secret=$encodedClientAppSecret",
            "resource=$encodedResource"
        );
        $body = [System.String]::Join("&", $bodyParams);

        Invoke-RestMethod -Uri $tenantAuthUri -Method POST -Headers $headers -Body $body;
    }
}