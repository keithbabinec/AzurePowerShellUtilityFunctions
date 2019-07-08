function Convert-StackTraceToAiStackFrames
{
    <#
    .SYNOPSIS
        Converts a strack trace string into an Application Insights formatted stack frame collection.

    .DESCRIPTION
        Converts a strack trace string into an Application Insights formatted stack frame collection.

    .PARAMETER Assembly
        Provide the name and version of the assembly.

    .PARAMETER StackTrace
        Specify the stack trace as a string.

    .EXAMPLE
        C:\> Convert-StackTraceToAiStackFrames -Assembly $Error[0].Exception.TargetSite.Module.Assembly.ToString() -StackTrace $Error[0].Exception.StackTrace
        Converts the stack trace into a stack frame collection.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Provide the name and version of the assembly.")]
        [System.String]
        $Assembly,

		[Parameter(Mandatory=$false)]
		[System.String]
		$StackTrace
    )
    Process
    {
        $frames = New-Object -TypeName 'System.Collections.Generic.List[PSCustomObject]'

        if (![System.String]::IsNullOrWhiteSpace($StackTrace))
        {
            $splitStack = $StackTrace.Split([System.Environment]::NewLine)
            $currentLevel = 0

            foreach ($line in $splitStack)
            {
                if (![System.String]::IsNullOrWhiteSpace($line))
                {
                    $trimmedLine = $line.Trim()

                    if ($trimmedLine.StartsWith("at "))
                    {
                        $frame = [PSCustomObject]@{
                            'level' = $currentLevel
                            'method' = $trimmedLine.Substring(3)
                            'assembly' = $Assembly
                            'line' = 0
                        }

                        $frames.Add($frame)
                        $currentLevel++
                    }
                }
            }
        }

        Write-Output -InputObject $frames
    }
}