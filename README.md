# probably-stolen-modding
This is a beginner friendly guide and examples about developping mods for Probably Stolen

To start developping mods for Probably Stolen, you will need:
- Digital Copy of Probably Stolen in order to access the .dll
- Some Knowledge of programming in C#

Probably Stolen use Harmony to allowed modders to patch in game function. Additionally Modders can append Action to the pre-defined hook points purposely exposed for Modding. While Harmony Patch are more powerful and flexible, using the Action via hook points is more performant and should be used when possible instead of Harmony Patching.

Recommanded folder setup.

Mods folder is used to let the game discover the ready to install mods.
Modding folder is used for mod developpers.

```
Probably Stolen/
│── Probably Stolen.exe
├── Mods/
│   ├── TestMod/
│   │   ├── TestMod.dll
├── Modding/
│   ├── TestMod/
│   │   ├── TestMod.cs
│   │   ├── TestMod.csproj
```

# Creating your first Mod for Probably Stolen

If not done already, create a Modding folder in your Probably Stolen root folder (Same place where Probably Stolen.exe is)

### Create the mod project

Using the command line while in the Modding folder:
```bash
mkdir TestMod
cd TestMod
dotnet new classlib -n TestMod --framework netstandard2.1
cd TestMod
```
### Edit TestMod.csproj

Replace the contents with:

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>netstandard2.1</TargetFramework>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>

  <ItemGroup>
    <Reference Include="Assembly-CSharp">
      <HintPath>..\..\Probably Stolen_Data\Managed\Assembly-CSharp.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="UnityEngine">
      <HintPath>..\..\Probably Stolen_Data\Managed\UnityEngine.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="UnityEngine.CoreModule">
      <HintPath>..\..\Probably Stolen_Data\Managed\UnityEngine.CoreModule.dll</HintPath>
      <Private>false</Private>
    </Reference>
    <Reference Include="0Harmony">
      <HintPath>..\..\Probably Stolen_Data\Managed\0Harmony.dll</HintPath>
      <Private>false</Private>
    </Reference>
  </ItemGroup>

</Project>
```

### Write your mod

open TestMod.cs with a text editor or any IDE of your choice and replace the content with the following.

```csharp
using System;
using UnityEngine;
using HarmonyLib;

namespace TestMod
{
    public class Class1 : IMod
    {
        public string Name => "Test Mod";
        public string ID => "test_mod";
        public string Author => "YourName";
        public string ModVersion => "1.0";
        public string GameVersion => "045";
        public string Description => "A test mod for demonstration purposes.";
        public string Prerequisites => "";

        public void Init()
        {
            Debug.Log("[TestMod] Hello from Test Mod! The modding system works!");
        }

        public void OnDisable()
        {
            Debug.Log("[TestMod] Test Mod disabled. Goodbye!");
        }

    }
}
```

### Build the mod

Go into your mod's directory and open CMD at that directory.
 
```bash
cd TestMod
dotnet build -c Release
```
 
The output DLL will be at: `TestMod/bin/Release/netstandard2.1/TestMod.dll`

## Install and Test the Mod
 
### Create the mod folder
 
```
Probably Stolen/
│── Probably Stolen.exe
├── Mods/
│   ├── TestMod/
│   │   ├── TestMod.dll      ← copy from build output
```
 
Just copy the single `TestMod.dll` file. Nothing else needed for this simple mod.
 
### 7B: Run the game
 
Launch the game, if everything is done correctly your mod should be visible in the Mod interface. Enable your mod and restart your game. After restarting the game your mod will be active.
