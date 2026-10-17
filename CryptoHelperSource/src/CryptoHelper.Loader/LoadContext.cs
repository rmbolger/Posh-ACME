using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;

namespace CryptoHelper.Loader;

public sealed class LoadContext : AssemblyLoadContext
{
    private static LoadContext? s_instance;
    private static readonly object s_sync = new();
    private readonly Assembly _thisAssembly = typeof(LoadContext).Assembly;
    private readonly Assembly _moduleAssembly;
    private readonly AssemblyDependencyResolver _resolver;

    private LoadContext(string modulePath) : base("CryptoHelper", isCollectible: false)
    {
        _resolver = new AssemblyDependencyResolver(modulePath);
        _moduleAssembly = LoadFromAssemblyPath(modulePath);
    }

    protected override Assembly? Load(AssemblyName assemblyName)
    {
        // Checks to see if we are trying to access our current assembly
        // (CryptoHelper.Loader). If so return the already loaded assembly object
        // so there is only one copy of it in the process.
        if (AssemblyName.ReferenceMatchesDefinition(_thisAssembly.GetName(), assemblyName))
        {
            return _thisAssembly;
        }

        // Returning null will fallback to the default loading behaviour.
        string? asmPath = _resolver.ResolveAssemblyToPath(assemblyName);
        return asmPath is null ? null : LoadFromAssemblyPath(asmPath);
    }

    protected override IntPtr LoadUnmanagedDll(string unmanagedDllName)
    {
        string? libPath = _resolver.ResolveUnmanagedDllToPath(unmanagedDllName);
        return libPath is null ? IntPtr.Zero : LoadUnmanagedDllFromPath(libPath);
    }

    public static Assembly Initialize()
    {
        lock (s_sync)
        {
            if (s_instance is null)
            {
                string assemblyPath = typeof(LoadContext).Assembly.Location;
                string modulePath = Path.Combine(Path.GetDirectoryName(assemblyPath)!, "CryptoHelper.dll");
                s_instance = new LoadContext(modulePath);
            }

            return s_instance._moduleAssembly;
        }
    }
}
