using namespace System.IO
using namespace System.Management.Automation
using namespace System.Reflection

# Resolve the cmdlet through $ExecutionContext to ensure we don't load a
# shadowed version of Import-Module.
$importModule = $ExecutionContext.InvokeCommand.GetCommand(
    'Microsoft.PowerShell.Core\Import-Module', [CommandTypes]::Cmdlet)

if (-not $IsCoreCLR) {
    # PowerShell 5.1 has no concept of an Assembly Load Context so it will
    # just load the module assembly directly.
    $modulePath = [Path]::Combine($PSScriptRoot, 'bin', 'net471', 'CryptoHelper.dll')
    $innerMod = & $importModule -Name $modulePath -ErrorAction Stop -PassThru
}
else {
    # This is used to load the loader assembly in the Default ALC which then
    # creates an ALC for the module and any dependencies of that module to be
    # loaded in that ALC.
    $loaderPath = [Path]::Combine($PSScriptRoot, 'bin', 'net6.0', 'CryptoHelper.Loader.dll')
    $loaderType = 'CryptoHelper.Loader.LoadContext' -as [type]
    $isReload = $null -ne $loaderType
    if (-not $loaderType) {
        $null = [Assembly]::LoadFrom($loaderPath)
        $loaderType = 'CryptoHelper.Loader.LoadContext' -as [type]
    }
    elseif ($loaderType.Assembly.Location -ne $loaderPath) {
        # Assemblies cannot be unloaded so once a version of this module is
        # loaded in the process it is the only one that can be used.
        $msg = "CryptoHelper is already loaded from '$($loaderType.Assembly.Location)'. Start a new PowerShell process to load a different copy."
        $err = [ErrorRecord]::new(
            [InvalidOperationException]::new($msg),
            'ModuleAlreadyLoadedFromDifferentPath',
            [ErrorCategory]::ResourceExists,
            $PSScriptRoot)
        throw $err
    }

    $mainModule = $loaderType::Initialize()
    $innerMod = & $importModule -Assembly $mainModule -PassThru:$isReload -ErrorAction Stop
}

if ($innerMod) {
    # Bug in pwsh, Import-Module in an assembly will pick up a cached instance
    # and not call the same path to set the nested module's cmdlets to the
    # current module scope. This is only technically needed if someone is
    # calling 'Import-Module -Name ALCLoader -Force' a second time. The first
    # import is still fine.
    # https://github.com/PowerShell/PowerShell/issues/20710
    $addExportedCmdlet = [PSModuleInfo].GetMethod(
        'AddExportedCmdlet',
        [BindingFlags]'Instance, NonPublic')
    $addExportedAlias = [PSModuleInfo].GetMethod(
        'AddExportedAlias',
        [BindingFlags]'Instance, NonPublic')
    foreach ($cmd in $innerMod.ExportedCmdlets.Values) {
        $addExportedCmdlet.Invoke($ExecutionContext.SessionState.Module, @(, $cmd))
    }
    foreach ($alias in $innerMod.ExportedAliases.Values) {
        $addExportedAlias.Invoke($ExecutionContext.SessionState.Module, @(, $alias))
    }
}
