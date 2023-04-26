param(
    [String]$VenvPath = "./venv_build",
    [Parameter(ValueFromRemainingArguments = $true)][String[]]$PythonExecutables = @("python3.8", "python3.9", "python3.10", "python3.11")
)

function Activate-Venv([string]$VenvPath)
{
    if ($IsMacOS)
    {
        $scriptPath = Join-Path $VenvPath "bin/Activate.ps1"
    }
    elseif ($IsWindows)
    {
        $scriptPath = Join-Path $VenvPath "Scripts/Activate.ps1"
    }
    elseif ($IsLinux)
    {
        $scriptPath = Join-Path $VenvPath "bin/Activate.ps1"
    }

    & $scriptPath
}

function Deactivate-Venv()
{
    deactivate
}

foreach ($PythonExec in $PythonExecutables)
{
    Write-Host -ForegroundColor Blue "building for $PythonExec..."

    & $PythonExec -m venv $VenvPath
    Activate-Venv $VenvPath

    & "tools/build.ps1"

    deactivate
    Remove-Item -Force -Recurse $VenvPath
}

Write-Host -ForegroundColor Blue "Done!"