using namespace System.IO
using namespace System.Management.Automation
using namespace System.Reflection

$importModule = $ExecutionContext.InvokeCommand.GetCommand(
    'Microsoft.PowerShell.Core\Import-Module', [CommandTypes]::Cmdlet)

if (-not $IsCoreCLR) {
    $modulePath = [Path]::Combine($PSScriptRoot, 'bin', 'net471', 'CryptoHelper.dll')
    $innerModule = & $importModule -Name $modulePath -ErrorAction Stop -PassThru
}
else {
    $loaderPath = [Path]::Combine($PSScriptRoot, 'bin', 'net6.0', 'CryptoHelper.Loader.dll')
    $loaderType = 'CryptoHelper.Loader.LoadContext' -as [type]
    $isReload = $null -ne $loaderType
    if (-not $loaderType) {
        $null = [Assembly]::LoadFrom($loaderPath)
        $loaderType = 'CryptoHelper.Loader.LoadContext' -as [type]
    }
    elseif ($loaderType.Assembly.Location -ne $loaderPath) {
        throw "CryptoHelper is already loaded from '$($loaderType.Assembly.Location)'. Start a new process to load a different copy."
    }

    $moduleAssembly = $loaderType::Initialize()
    $innerModule = & $importModule -Assembly $moduleAssembly -PassThru:$isReload -ErrorAction Stop
}

if ($innerModule) {
    $addCmdlet = [PSModuleInfo].GetMethod('AddExportedCmdlet', [BindingFlags]'Instance, NonPublic')
    foreach ($cmdlet in $innerModule.ExportedCmdlets.Values) {
        $addCmdlet.Invoke($ExecutionContext.SessionState.Module, @(, $cmdlet))
    }
}
