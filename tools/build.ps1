param(
    [string]$PackageName = "mediapipe-silicon",
    [string]$PackageVersion = "0.9.2.1",
    [string]$PackageUrl = "https://github.com/cansik/mediapipe-silicon",
    [string]$BuildPath = "./build",
    [string]$DistPath = "./dist",
    [string]$LibPath = "./libs",
    [string]$MediaPipeRepository = "https://github.com/google/mediapipe.git",
    [string]$MediaPipeBranch = "v0.9.2.1",
    [switch]$SkipRepositorySetup = $False,
    [switch]$OnlyInstallDependencies = $False,
    [switch]$Clean = $False
)

function Replace-In-File([string]$InputFile, $Tokens)
{
    $content = Get-Content -Path $InputFile -Raw

    foreach ($key in $Tokens.Keys)
    {
        $content = $content.Replace($key, $Tokens[$key])
    }

    Set-Content -Path $InputFile -Value $content
}

function Try-Resolve-Path([string]$Path)
{
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Create-Dir-If-Needed([string]$Path)
{
    if (!(Test-Path $Path))
    {
        New-Item -Path $Path -ItemType Directory
    }
}

function Find-File-Or-Exit([string]$Path, [string]$ErrorMessage = "")
{
    [array]$files = Get-ChildItem $Path
    if ($files.Length -eq 0)
    {
        Write-Host -ForegroundColor Red "Could not find a file matching '$Path'. $ErrorMessage"
        exit 1
    }
    return $files[0]
}

# resolve paths
$BuildPath = Try-Resolve-Path $BuildPath
$DistPath = Try-Resolve-Path $DistPath
$LibPath = Try-Resolve-Path $LibPath

# Global variables
$BDistPlatformName = ""
$IsMacOSArm64 = $IsMacOS -And ($( arch ) -eq "arm64")
$LinkOpenCV = $False

Write-Host -ForegroundColor Blue "Mediapipe Build Script"
Write-Host -ForegroundColor Blue "Python version: $(python --version)"
Write-Host -ForegroundColor Blue "building $PackageName in $BuildPath..."

# install os specific pre-requisites and set path
$env:GLOG_logtostderr = 1

# create lib path
Create-Dir-If-Needed -Path $LibPath

# clean build path if necessary
if (-Not$SkipRepositorySetup)
{
    if (Test-Path $BuildPath)
    {
        Push-Location $BuildPath
        Write-Host -ForegroundColor Yellow "Cleaning bazel..."
        bazel clean
        Pop-Location

        Remove-Item -Recurse -Force -Path $BuildPath
    }
}

if ($IsMacOS)
{
    brew install git wget cmake protobuf bazelisk opencv@3
    brew uninstall --ignore-dependencies glog

    pip install delocate

    $BrewPrefix = $( brew --prefix )
    $OpenCVPrefix = $( brew --prefix opencv@3 )
    $LinkOpenCV = $true

    Write-Host -ForegroundColor Green "Found brew at $BrewPrefix"
    Write-Host -ForegroundColor Green "Found opencv@3 at $OpenCVPrefix"

    if ($IsMacOSArm64)
    {
        $BDistPlatformName = "macosx-12_0-arm64"
    }
    else
    {
        $BDistPlatformName = "macosx_12_0_x86_64"
    }

    # setting local opencv variables
    $env:PATH = "$OpenCVPrefix/bin:$( $env:PATH )"
    $env:LDFLAGS = "-L$OpenCVPrefix/lib"
    $env:CPPFLAGS = "-I$OpenCVPrefix/include"
    $env:PKG_CONFIG_PATH = "$OpenCVPrefix/lib/pkgconfig"
}
elseif ($IsWindows)
{
    # choco install -y --force bazel --version=5.1.0
    choco install -y bazelisk protoc
    choco install opencv --version=3.4.10 --params="/InstallationPath:$LibPath"

    # extend path with zip folder name
    $WinOpenCVBuildPath = Join-Path $LibPath "opencv/build"

    # add opencv to environment variables
    $env:OPENCV_DIR = Join-Path $WinOpenCVBuildPath "bin"

    Write-Host "OpenCV Installation Directory ($WinOpenCVBuildPath):"
    ls $WinOpenCVBuildPath
}
elseif ($IsLinux)
{
    sudo apt install -y protobuf-compiler
    sudo apt install -y cmake
    sudo apt install -y python3-dev

    sudo apt-get install -y libopencv-core-dev libopencv-highgui-dev libopencv-calib3d-dev libopencv-features2d-dev libopencv-imgproc-dev libopencv-video-dev
    sudo apt-get install -y libopencv-contrib-dev

    pip install auditwheel
}

if ($OnlyInstallDependencies)
{
    Write-Host -ForegroundColor Blue "Installed dependencies only. Now exiting build script!"
    exit 0
}


if (-Not$SkipRepositorySetup)
{
    # clone repository to build
    git clone --recurse-submodules --shallow-submodules --depth 1 --branch $MediaPipeBranch $MediaPipeRepository $BuildPath
}

Push-Location $BuildPath

if ($Clean)
{
    Write-Host -ForegroundColor Yellow "Cleaning bazel..."
    bazel clean
}

# install pre-requisites
pip install wheel
pip install six
pip install -r requirements.txt

if (-Not$SkipRepositorySetup)
{
    # rename project and setup workspace
    Replace-In-File -InputFile "setup.py" -Tokens @{
        "name='mediapipe'" = "name='$PackageName'";
        "__version__ = 'dev'" = "__version__ = '$PackageVersion'";
        "url='https://github.com/google/mediapipe'" = "url='$PackageUrl'"
    }

    if ($IsMacOS)
    {
        Replace-In-File -InputFile "WORKSPACE" -Tokens @{
            "/usr/local" = "$BrewPrefix";
        }
    }

    if ($IsWindows)
    {
        Create-Dir-If-Needed -Path $WinOpenCVBuildPath
        $EscapedWinOpenCVBuildPath = $WinOpenCVBuildPath.Replace("\", "\\")
        Write-Host "Escaped OpenCV Build Path: $EscapedWinOpenCVBuildPath"

        Replace-In-File -InputFile "WORKSPACE" -Tokens @{
            "C:\\opencv\\build" = "$EscapedWinOpenCVBuildPath";
        }
    }

    if ($LinkOpenCV)
    {
        Replace-In-File -InputFile "setup.py" -Tokens @{
            "self.link_opencv = False" = "self.link_opencv = True";
        }
    }
}

# clear dist
if (Test-Path "dist")
{
    Remove-Item -Path "dist/*.whl" -Force
}

# build
if ($IsLinux -And -Not$LinkOpenCV)
{
    Write-Host -BackgroundColor Blue "setting up opencv..."
    sh ./setup_opencv.sh
}

python setup.py gen_protos
if ($BDistPlatformName -eq "")
{
    python setup.py bdist_wheel
}
else
{
    python setup.py bdist_wheel --plat-name $BDistPlatformName
}

Push-Location "dist"

# find wheel file
$WheelFile = Find-File-Or-Exit -Path "*.whl" -ErrorMessage "Please check if build did work."

# post-process wheel
if ($IsMacOS)
{
    delocate-wheel -v $WheelFile
}
elseif ($IsWindows)
{

}
elseif ($IsLinux)
{
    # repaire wheel
    # auditwheel repair $WheelFile -w "."

    # remove original wheel
    # Remove-Item -Path $WheelFile -Force

    # find repaired wheel
    # $WheelFile = Find-File-Or-Exit -Path "*.whl" -ErrorMessage "Please check if auditwheel did work."
}

# copy file to dist
Create-Dir-If-Needed -Path $DistPath
$OutputPath = Join-Path $DistPath $WheelFile.Name
Copy-Item -Force $WheelFile -Destination $OutputPath

Pop-Location
Pop-Location

Write-Host -ForegroundColor Green "Wheel created at: $OutputPath"
Write-Host -ForegroundColor Blue "Done!"