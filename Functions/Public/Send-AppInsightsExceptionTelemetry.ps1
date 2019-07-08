function Send-AppInsightsExceptionTelemetry
{
    <#
    .SYNOPSIS
        Sends exception telemetry to an Azure Application Insights instance.

    .DESCRIPTION
        Sends exception telemetry to an Azure Application Insights instance. This function uses the Azure Application Insights REST API instead of a compiled client library, so it works without additional dependencies.

		NOTE: Telemetry ingestion to Azure Application Insights typically has a ~2-3 minute delay due to the eventual-consistency nature of the service.

    .PARAMETER InstrumentationKey
        Specify the instrumentation key of your Azure Application Insights instance. This determines where the data ends up.

    .PARAMETER Exception
        Specify the actual exception object to send.

    .PARAMETER CustomProperties
        Optionally specify additional custom properties, in the form of a hashtable (key-value pairs) that should be logged with this telemetry.

    .EXAMPLE
        C:\> Send-AppInsightsEventTelemetry -InstrumentationKey <guid> -Exception $Error[0].Exception
        Sends exception telemetry to application insights for the most recently logged PowerShell Error.

	.EXAMPLE
        C:\> Send-AppInsightsEventTelemetry -InstrumentationKey <guid> -Exception $Error[0].Exception -CustomProperties @{ 'CustomProperty1'='abc'; 'CustomProperty2'='xyz' }
        Sends exception telemetry to application insights for the most recently logged PowerShell Error, with additional custom properties.
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
            HelpMessage='Specify the exception object to send. This should be an actual Exception class and not a PowerShell ErrorRecord.')]
		[System.Exception]
		[ValidateNotNull()]
		$Exception,

		[Parameter(Mandatory=$false)]
		[Hashtable]
		$CustomProperties
    )
    Process
    {
		# app insights has a single endpoint where all incoming telemetry is processed.
		# documented here: https://github.com/microsoft/ApplicationInsights-Home/blob/master/EndpointSpecs/ENDPOINT-PROTOCOL.md
        
		$AppInsightsIngestionEndpoint = $MyInvocation.MyCommand.Module.PrivateData.Constants.AppInsightsIngestionEndpoint
		
		# prepare custom properties
		# convert the hashtable to a custom object, if properties were supplied.
		
		if ($PSBoundParameters.ContainsKey('CustomProperties') -and $CustomProperties.Count -gt 0)
		{
			$customPropertiesObj = [PSCustomObject]$CustomProperties
		}
		else
		{
			$customPropertiesObj = [PSCustomObject]@{}
		}

        # prepare the exceptions info.
        # this parses the exceptions and inner exceptions with stack traces and turns them into a format friendly for app insights.

        $exceptionDetails = Convert-ExceptionToAiExceptionDetails -Exception $Exception
        
		# prepare the REST request body schema.
		# NOTE: this schema represents how events are sent as of the app insights .net client library v2.9.1.
		# newer versions of the library may change the schema over time and this may require an update to match schemas found in newer libraries.
		
		$bodyObject = [PSCustomObject]@{
			'name' = "Microsoft.ApplicationInsights.$InstrumentationKey.Exception"
			'time' = ([System.dateTime]::UtcNow.ToString('o'))
			'iKey' = $InstrumentationKey
			'tags' = [PSCustomObject]@{
				'ai.cloud.roleInstance' = $ENV:COMPUTERNAME
				'ai.internal.sdkVersion' = 'AzurePowerShellUtilityFunctions'
			}
			'data' = [PSCustomObject]@{
				'baseType' = 'ExceptionData'
				'baseData' = [PSCustomObject]@{
					'ver' = '2'
					'exceptions' = $exceptionDetails
					'properties' = $customPropertiesObj
				}
			}
		}

		# convert the body object into a json blob.
		# prepare the headers
		# send the request

		$bodyAsCompressedJson = $bodyObject | ConvertTo-JSON -Depth 20 -Compress
		$headers = @{
			'Content-Type' = 'application/x-json-stream';
		}

		Invoke-RestMethod -Uri $AppInsightsIngestionEndpoint -Method Post -Headers $headers -Body $bodyAsCompressedJson
    }
}