# probably-stolen-modding

English version: [README.md](README.md)

这是一篇面向初学者的《Probably Stolen》模组开发入门介绍。请先阅读本文，再阅读[模组制作指南](ModdingGuide.zh-CN.md)。

## 目录
- [probably-stolen-modding](#probably-stolen-modding)
  - [目录](#目录)
  - [前提条件](#前提条件)
  - [文件夹结构](#文件夹结构)
- [为 Probably Stolen 创建你的第一个模组](#为-probably-stolen-创建你的第一个模组)
    - [创建模组项目](#创建模组项目)
    - [编辑 TestMod.csproj](#编辑-testmodcsproj)
    - [创建 manifest.xml](#创建-manifestxml)
    - [编写模组](#编写模组)
    - [构建模组](#构建模组)
  - [安装并测试模组](#安装并测试模组)
    - [创建模组文件夹](#创建模组文件夹)
    - [运行游戏并启用模组](#运行游戏并启用模组)

## 前提条件

要开始为 Probably Stolen 开发模组，你需要：
- 一份《Probably Stolen》的数字版游戏，用于获取所需的 .dll 文件
- 一定的 C# 编程知识
- 在电脑上安装 [.NET SDK](https://dotnet.microsoft.com/download)（6.0 或更高版本）

Probably Stolen 使用 Harmony 让模组作者能够修补（patch）游戏内的函数。此外，模组作者还可以在游戏专门为模组预留的钩子点（hook point）上挂接自己的逻辑。Harmony 补丁更强大、更灵活，但通过钩子点挂接逻辑性能更好，因此在可行时应优先使用钩子点，而不是 Harmony 补丁。

## 文件夹结构

本指南中提到的 `Probably Stolen/` 文件夹指的是**游戏安装目录**，也就是包含 `Probably Stolen.exe` 的那个目录。如果你是在 Steam 上购买的游戏，可以在 Steam 库中右键点击 *Probably Stolen* → **管理** → **浏览本地文件** 来找到它。

使用 Steam 默认安装设置时，该目录通常位于：

- **Windows：** `C:\Program Files (x86)\Steam\steamapps\common\Probably Stolen\`
- **macOS：** `~/Library/Application Support/Steam/steamapps/common/Probably Stolen/`
- **Linux：** `~/.steam/steam/steamapps/common/Probably Stolen/`

如果你把 Steam 或游戏安装到了其他驱动器或其他库，路径会相应变化。请用"浏览本地文件"确认。

推荐的文件夹结构：

Mods 文件夹用于让游戏发现可直接安装的模组。
Modding 文件夹供模组开发者使用。

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

# 为 Probably Stolen 创建你的第一个模组

如果还没有的话，先在 Probably Stolen 的根目录（与 Probably Stolen.exe 同级）下创建一个 Modding 文件夹。

### 创建模组项目

在 Modding 文件夹中打开命令行，执行：
```bash
dotnet new classlib -n TestMod --framework netstandard2.1
cd TestMod
```
### 编辑 TestMod.csproj

将其内容替换为：

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

### 创建 manifest.xml

**`manifest.xml` 是必需的。** 每个模组都必须在模组文件夹根目录下包含一个；没有它，游戏会直接跳过整个文件夹，你的模组不会被加载。这个文件包含模组的所有元数据。

```
Probably Stolen/
├── Probably Stolen.exe
└── Modding/
    └── TestMod/
        ├── TestMod.cs
        └── TestMod.csproj
        └── manifest.xml
```

创建一个名为 `manifest.xml` 的文件，填入你的模组信息：

```xml
<?xml version="1.0" encoding="utf-8"?>
<Manifest>
  <ID>test_mod</ID>
  <Name>Test Mod</Name>
  <Author>YourName</Author>
  <ModVersion>1.0</ModVersion>
  <Description>A test mod for demonstration purposes.</Description>
  <GameVersions>
    <Version>049</Version>
  </GameVersions>
  <Prerequisites />
</Manifest>
```

字段说明：
- **ID**：模组的唯一标识符。请使用小写字母和下划线（例如 `my_cool_mod`）。此项必填；缺失时游戏会跳过你的模组文件夹。
- **Name**：在模组菜单中显示的名称。
- **Author**：你的名字或用户名。
- **ModVersion**：模组的版本号。
- **Description**：对模组功能的简短描述。
- **GameVersions**：模组兼容的游戏版本列表。每个支持的版本写一条 `<Version>`。
- **Prerequisites**：必须在你的模组之前加载的其他模组的 ID。没有依赖时保留空标签（`<Prerequisites />`）。每个依赖写一条 `<Mod>`：

```xml
<Prerequisites>
  <Mod>some_other_mod_id</Mod>
</Prerequisites>
```

### 编写模组

用文本编辑器或任意 IDE 打开 `TestMod.cs`，将内容替换为以下代码。

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

加载器会从 `manifest.xml` 中读取模组的名称、ID、作者等信息，并把解析好的 `ModManifest` 传给你的 `Init` 方法。

你的模组类实现了三个生命周期方法，加载器会在特定时机调用它们：

- **`Init(ModManifest manifest)`**：游戏启动并加载你的模组时调用一次。用于一次性的初始化：如有需要保存 `manifest` 引用、构造 `ModLog`、缓存引用、准备模组需要的资源。
- **`OnEnable()`**：紧接在 `Init` 之后调用。
- **`OnDisable()`**：游戏关闭时调用（将来在模组被关闭时也会调用）。

> ⚠️ **这三个方法都在主菜单阶段运行**，因为模组加载器位于主菜单。在玩家载入存档之前，任何游戏玩法系统都尚未初始化，所以不要在 `Init` 或 `OnEnable` 中读取存档数据、生成物品或访问游戏内管理器；此时它们还不存在。

### 构建模组

进入模组目录并在那里打开命令提示符。

```bash
cd TestMod
dotnet build -c Release
```

输出的 DLL 位于：`TestMod/bin/Release/netstandard2.1/TestMod.dll`

## 安装并测试模组

### 创建模组文件夹

```
Probably Stolen/
├── Probably Stolen.exe
└── Mods/
    └── TestMod/
        ├── manifest.xml      ← 你的清单文件
        └── TestMod.dll       ← 从构建输出复制
```

把 `TestMod.dll` 和你的 `manifest.xml` 复制到模组文件夹中。两个文件都必不可少。

### 运行游戏并启用模组

启动游戏。如果一切设置正确，你的模组会出现在模组菜单中。启用模组并重启游戏。重启后模组即处于激活状态。按 F8 打开调试控制台（F9 打开的是开发菜单，那是另一个工具），向上滚动。如果模组正常工作，会显示 `[Test Mod]: Hello from Test Mod! The modding system works!`。
