# probably-stolen-modding
This is a beginner friendly introduction about developing mods for Probably Stolen. Read this before reading the Advanced Guide.

## Table of Contents
- [probably-stolen-modding](#probably-stolen-modding)
  - [Table of Contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Folder Setup](#folder-setup)
- [Creating your first Mod for Probably Stolen](#creating-your-first-mod-for-probably-stolen)
    - [Create the mod project](#create-the-mod-project)
    - [Edit TestMod.csproj](#edit-testmodcsproj)
    - [Create your manifest.xml](#create-your-manifestxml)
    - [Write your mod](#write-your-mod)
    - [Build the mod](#build-the-mod)
  - [Install and Test the Mod](#install-and-test-the-mod)
    - [Create the mod folder](#create-the-mod-folder)
    - [Run the game and activate the mod](#run-the-game-and-activate-the-mod)

## Requirements

To start developing mods for Probably Stolen, you will need:
- A digital copy of Probably Stolen in order to access the .dll files
- Some knowledge of programming in C#
- [.NET SDK](https://dotnet.microsoft.com/download) (version 6.0 or later) installed on your machine

Probably Stolen uses Harmony to allow modders to patch in-game functions. Additionally, modders can append actions to the pre-defined hook points purposely exposed for modding. While Harmony patches are more powerful and flexible, using actions via hook points is more performant and should be preferred over Harmony patching when possible.

## Folder Setup

The `Probably Stolen/` folder referenced throughout this guide is the **game install folder**: the directory that contains `Probably Stolen.exe`. If you bought the game on Steam, you can locate it by right-clicking *Probably Stolen* in your Steam library → **Manage** → **Browse local files**.

With Steam's default install settings, this folder is typically at:

- **Windows:** `C:\Program Files (x86)\Steam\steamapps\common\Probably Stolen\`
- **macOS:** `~/Library/Application Support/Steam/steamapps/common/Probably Stolen/`
- **Linux:** `~/.steam/steam/steamapps/common/Probably Stolen/`

If you installed Steam or the game to a different drive or library, the path will reflect that location instead. Use "Browse local files" to confirm.

Recommended folder setup:

The Mods folder is used to let the game discover ready-to-install mods.
The Modding folder is used for mod developers.

```
Probably Stolen/
├── Probably Stolen.exe
├── Mods/
│   └── TestMod/
│       ├── manifest.xml
│       └── TestMod.dll
└── Modding/
    └── TestMod/
        ├── TestMod.cs
        └── TestMod.csproj
```

# Creating your first Mod for Probably Stolen

If not done already, create a Modding folder in your Probably Stolen root folder (same place where Probably Stolen.exe is).

### Create the mod project

Using the command line while in the Modding folder:
```bash
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

### Create your manifest.xml

**`manifest.xml` is mandatory.** Every mod must include one in the root of its mod folder; without it, the game will skip the folder entirely and your mod will not load. This file contains all the metadata about your mod.

```
Probably Stolen/
├── Probably Stolen.exe
└── Modding/
    └── TestMod/
        ├── TestMod.cs
        └── TestMod.csproj
        └── manifest.xml
```

Create a file named `manifest.xml` and fill in your mod's information:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Manifest>
  <ID>test_mod</ID>
  <Name>Test Mod</Name>
  <Author>YourName</Author>
  <ModVersion>1.0</ModVersion>
  <Description>A test mod for demonstration purposes.</Description>
  <GameVersions>
    <Version>047</Version>
  </GameVersions>
  <Prerequisites />
</Manifest>
```

Field descriptions:
- **ID**: A unique identifier for your mod. Use lowercase letters and underscores (e.g. `my_cool_mod`). This is required; the game will skip your mod folder if it is missing.
- **Name**: The display name shown in the mod menu.
- **Author**: Your name or username.
- **ModVersion**: The version of your mod.
- **Description**: A short description of what your mod does.
- **GameVersions**: The list of game versions your mod is compatible with. Add one `<Version>` entry per supported version.
- **Prerequisites**: The IDs of other mods that must be loaded before yours. Leave the tag empty (`<Prerequisites />`) if there are none. Add one `<Mod>` entry per dependency:

```xml
<Prerequisites>
  <Mod>some_other_mod_id</Mod>
</Prerequisites>
```

### Write your mod

Open `TestMod.cs` with a text editor or any IDE of your choice and replace the content with the following.

```csharp
using System;
using UnityEngine;
using HarmonyLib;

namespace TestMod
{
    public class Class1 : IMod
    {
        private ModLog log;

        public void Init(ModManifest manifest)
        {
            log = new ModLog(manifest);
            log.Log("Hello from Test Mod! The modding system works!");
        }

        public void OnEnable()
        {
            log.Log("Test Mod enabled.");
        }

        public void OnDisable()
        {
            log.Log("Test Mod disabled. Goodbye!");
        }
    }
}
```

The loader reads your mod's name, ID, author, and other details from `manifest.xml` and passes the parsed `ModManifest` to your `Init` method.

Your mod class implements three lifecycle methods that the loader calls at specific points:

- **`Init(ModManifest manifest)`**: called once when the game starts and your mod is loaded. Use it for one-time setup: store the `manifest` reference if you need it later, construct your `ModLog`, cache references, and prepare any resources your mod will need.
- **`OnEnable()`**: called right after `Init`
- **`OnDisable()`**: called when the game is shutting down (and, in the future, when the mod is turned off).

> ⚠️ **All three of these methods run from the main menu**, where the mod loader lives. No gameplay systems are initialized until the player loads a save file, so do not try to read save data, spawn items, or interact with in-game managers from `Init` or `OnEnable`; they will not exist yet. 

### Build the mod

Go into your mod's directory and open a command prompt there.

```bash
cd TestMod
dotnet build -c Release
```

The output DLL will be at: `TestMod/bin/Release/netstandard2.1/TestMod.dll`

## Install and Test the Mod

### Create the mod folder

```
Probably Stolen/
├── Probably Stolen.exe
└── Mods/
    └── TestMod/
        ├── manifest.xml      ← your manifest file
        └── TestMod.dll       ← copy from build output
```

Copy the `TestMod.dll` file and your `manifest.xml` into the mod folder. Both files are required.

### Run the game and activate the mod

Launch the game. If everything is set up correctly, your mod should be visible in the mod menu. Enable your mod and restart the game. After restarting, your mod will be active. Open the console via the F8 key, scroll up. If your mod is working, it will display `[Test Mod]: Hello from Test Mod! The modding system works!`.
