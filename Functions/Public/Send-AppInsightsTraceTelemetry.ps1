function Send-AppInsightsTraceTelemetry
{
    <#
    .SYNOPSIS
        Sends trace telemetry to an Azure Application Insights instance.

    .DESCRIPTION
        Sends trace telemetry to an Azure Application Insights instance. This function uses the Azure Application Insights REST API instead of a compiled client library, so it works without additional dependencies.

		NOTE: Telemetry ingestion to Azure Application Insights typically has a ~2-3 minute delay due to the eventual-consistency nature of the service.

    .PARAMETER InstrumentationKey
        Specify the instrumentation key of your Azure Application Insights instance. This determines where the data ends up.

    .PARAMETER Message
        Specify the message to log.

    .PARAMETER Severity
        Specify the message severity. Acceptable values are Verbose, Information, Warning, Error, and Critical.

    .PARAMETER CustomProperties
        Optionally specify additional custom properties, in the form of a hashtable (key-value pairs) that should be logged with this telemetry.

    .EXAMPLE
        C:\> Send-AppInsightsTraceTelemetry -InstrumentationKey <guid> -Message 'This is an informational logging message.' -Severity Information
        Sends trace telemetry to application insights.

	.EXAMPLE
        C:\> Send-AppInsightsTraceTelemetry -InstrumentationKey <guid> -Message 'This is a warning logging message.' -Severity Warning -CustomProperties @{ 'CustomProperty1'='abc'; 'CustomProperty2'='xyz' }
        Sends trace telemetry to application insights, with additional custom properties tied to this event.
    #>
    [CmdletBinding()]
    Param
    (
		[Parameter(
            Mandatory=$true,
            HelpMessage='Specify the instrumentation key of your Azure Application Insights instance. This determines where the data ends up.')]
		[System.Guid]
		[ValidateScript({$_ -ne [System.Guid]::Empty})]
		$InstrumentationKey,

		[Parameter(
            Mandatory=$true,
            HelpMessage='Specify the message to log.')]
		[System.String]
		[ValidateNotNullOrEmpty()]
		$Message,

        [Parameter(
            Mandatory=$true,
            HelpMessage='Specify the message severity. Acceptable values are Verbose, Information, Warning, Error, and Critical.')]
		[System.String]
		[ValidateSet('Verbose','Information','Warning','Error','Critical')]
		$Severity,

		[Parameter(Mandatory=$false)]
		[Hashtable]
		$CustomProperties
    )
    Process
    {
		# app insights has a single endpoint where all incoming telemetry is processed.
		# documented here: https://github.com/microsoft/ApplicationInsights-Home/blob/master/EndpointSpecs/ENDPOINT-PROTOCOL.md
        
		$AppInsightsIngestionEndpoint = $MyInvocation.MyCommand.Module.PrivateData.Constants.AppInsightsIngestionEndpoint;
		
		# prepare custom properties
		# convert the hashtable to a custom object, if properties were supplied.
		
		if ($PSBoundParameters.ContainsKey('CustomProperties') -and $CustomProperties.Count -gt 0)
		{
			$customPropertiesObj = [PSCustomObject]$CustomProperties;
		}
		else
		{
			$customPropertiesObj = [PSCustomObject]@{};
		}

		# prepare the REST request body schema.
		# NOTE: this schema represents how traces are sent as of the app insights .net client library v2.9.1.
		# newer versions of the library may change the schema over time and this may require an update to match schemas found in newer libraries.
		
		$bodyObject = [PSCustomObject]@{
			'name' = "Microsoft.ApplicationInsights.$InstrumentationKey.Trace"
			'time' = ([System.dateTime]::UtcNow.ToString('o'))
			'iKey' = $InstrumentationKey
			'tags' = [PSCustomObject]@{
				'ai.cloud.roleInstance' = $ENV:COMPUTERNAME
				'ai.internal.sdkVersion' = 'AzurePowerShellUtilityFunctions'
			}
			'data' = [PSCustomObject]@{
				'baseType' = 'MessageData'
				'baseData' = [PSCustomObject]@{
					'ver' = '2'
					'message' = $Message
                    'severityLevel' = $Severity
					'properties' = $customPropertiesObj
				}
			}
		};

		# convert the body object into a json blob.
		$bodyAsCompressedJson = $bodyObject | ConvertTo-JSON -Depth 10 -Compress;

		# prepare the headers
		$headers = @{
			'Content-Type' = 'application/x-json-stream';
		};

		# send the request
		Invoke-RestMethod -Uri $AppInsightsIngestionEndpoint -Method Post -Headers $headers -Body $bodyAsCompressedJson;
    }
}