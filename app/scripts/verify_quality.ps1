[CmdletBinding()]
param(
  [string]$FlutterSdk = 'D:/flutter/f3386/flutter',
  [switch]$CaptureScreens
)

$ErrorActionPreference = 'Stop'
$appDirectory = Split-Path -Parent $PSScriptRoot
$repositoryDirectory = Split-Path -Parent $appDirectory
$logDirectory = Join-Path $repositoryDirectory 'docs/qa'
$dartExecutable = Join-Path $FlutterSdk 'bin/cache/dart-sdk/bin/dart.exe'
$flutterSnapshot = Join-Path $FlutterSdk 'bin/cache/flutter_tools.snapshot'
if (!(Test-Path -LiteralPath $dartExecutable) -or !(Test-Path -LiteralPath $flutterSnapshot)) {
  throw 'Flutter SDK cache not found. Pass -FlutterSdk with an initialized Flutter SDK path.'
}
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

function Invoke-QualityCheck {
  param([string]$Name, [string]$Executable, [string[]]$Arguments, [string]$Directory)
  $stdoutPath = Join-Path $logDirectory ($Name + '.log')
  $stderrPath = Join-Path $logDirectory ($Name + '-error.log')
  $checkProcess = Start-Process -FilePath $Executable -ArgumentList $Arguments -WorkingDirectory $Directory -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
  Get-Content -LiteralPath $stdoutPath -Encoding UTF8 -Tail 12
  Get-Content -LiteralPath $stderrPath -Encoding UTF8
  if ($checkProcess.ExitCode -ne 0) { throw "$Name failed with exit code $($checkProcess.ExitCode). See $stdoutPath" }
}

# Run the already-installed Flutter tool directly. No SDK repair, lock deletion,
# process termination, dependency install, production credentials or deployment.
$snapshotArgument = '"' + $flutterSnapshot + '"'
Invoke-QualityCheck -Name 'analyze' -Executable $dartExecutable -Arguments @($snapshotArgument, 'analyze', '--no-pub') -Directory $appDirectory
if ($CaptureScreens) {
  Invoke-QualityCheck -Name 'layout' -Executable $dartExecutable -Arguments @($snapshotArgument, 'test', '--no-pub', '--update-goldens', '--dart-define=GENERATE_PREVIEWS=true', 'test/discovery_layout_test.dart') -Directory $appDirectory
}
Invoke-QualityCheck -Name 'flutter-tests' -Executable $dartExecutable -Arguments @($snapshotArgument, 'test', '--no-pub') -Directory $appDirectory
$nodeExecutable = (Get-Command node -ErrorAction Stop).Source
Invoke-QualityCheck -Name 'backend-tests' -Executable $nodeExecutable -Arguments @('--test') -Directory (Join-Path $repositoryDirectory 'backend')
Write-Output 'Quality checks completed.'
