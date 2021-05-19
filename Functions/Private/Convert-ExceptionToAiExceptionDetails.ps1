function Convert-ExceptionToAiExceptionDetails
{
    <#
    .SYNOPSIS
        Converts an exception class object into an Application Insights formatted exception details record.

    .DESCRIPTION
        Converts an exception class object into an Application Insights formatted exception details record.

    .PARAMETER Exception
        Specify the actual exception object to send.

    .EXAMPLE
        C:\> Convert-ExceptionToAiExceptionDetails -Exception $Error[0].Exception
        Converts the specified Exception object into an ExceptionDetails record.
    #>
    [CmdletBinding()]
    Param
    (
		[Parameter(
            Mandatory=$true,
            HelpMessage='Specify the exception object to send. This should be an actual Exception class and not a PowerShell ErrorRecord.')]
		[System.Exception]
		[ValidateNotNull()]
		$Exception
    )
    Process
    {
        $ExceptionDetails = New-Object -TypeName 'System.Collections.Generic.List[PSCustomObject]';
        $ParentExceptionId = 0;

        while ($true)
        {
            $CurrentExceptionId = $Exception.GetHashCode();
            
            $exInfo = [PSCustomObject]@{
                'id' = $CurrentExceptionId
                'outerId' = $ParentExceptionId
                'typeName' = ($Exception.GetType().FullName)
                'message' = $Exception.Message
            };

            if( $Exception.TargetSite -and $Exception.TargetSite.Module -and $Exception.TargetSite.Module.Assembly ) {
                $ParsedStack = Convert-StackTraceToAiStackFrames -Assembly $Exception.TargetSite.Module.Assembly.ToString() -StackTrace $Exception.StackTrace;
            } else {
                $ParsedStack = Convert-StackTraceToAiStackFrames -Assembly "Unknown Assembly" -StackTrace "at Missing stack trace";
            }         

            if ($ParsedStack -and $ParsedStack.Count -gt 0)
            {
                $exInfo | Add-Member -MemberType NoteProperty -Name 'hasFullStack' -Value $true;
                $exInfo | Add-Member -MemberType NoteProperty -Name 'parsedStack' -Value $ParsedStack;
            }

            $ExceptionDetails.Add($exInfo);

            # advance to the next exception in the tree

            if ($Exception.InnerException)
            {
                $Exception = $Exception.InnerException;
                $ParentExceptionId = $CurrentExceptionId;
            }
            else
            {
                break;
            }
        }

        Write-Output -InputObject $ExceptionDetails;
    }
}