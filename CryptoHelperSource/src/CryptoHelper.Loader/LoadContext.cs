using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;

namespace CryptoHelper.Loader;

public sealed class LoadContext : AssemblyLoadContext
{
    private static readonly object Sync = new();
    private static LoadContext? instance;
    private readonly Assembly loaderAssembly = typeof(LoadContext).Assembly;
    private readonly AssemblyDependencyResolver resolver;
    private readonly Assembly moduleAssembly;

    private LoadContext(string modulePath) : base("CryptoHelper", isCollectible: false)
    {
        resolver = new AssemblyDependencyResolver(modulePath);
        moduleAssembly = LoadFromAssemblyPath(modulePath);
    }

    protected override Assembly? Load(AssemblyName assemblyName)
    {
        if (AssemblyName.ReferenceMatchesDefinition(loaderAssembly.GetName(), assemblyName))
        {
            return loaderAssembly;
        }

        string? path = resolver.ResolveAssemblyToPath(assemblyName);
        return path is null ? null : LoadFromAssemblyPath(path);
    }

    protected override IntPtr LoadUnmanagedDll(string unmanagedDllName)
    {
        string? path = resolver.ResolveUnmanagedDllToPath(unmanagedDllName);
        return path is null ? IntPtr.Zero : LoadUnmanagedDllFromPath(path);
    }

    public static Assembly Initialize()
    {
        lock (Sync)
        {
            if (instance is null)
            {
                string loaderPath = typeof(LoadContext).Assembly.Location;
                string modulePath = Path.Combine(Path.GetDirectoryName(loaderPath)!, "CryptoHelper.dll");
                instance = new LoadContext(modulePath);
            }

            return instance.moduleAssembly;
        }
    }
}
