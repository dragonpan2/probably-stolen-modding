# Probably Stolen：模组制作指南

English version: [ModdingGuide.md](ModdingGuide.md)

本指南涵盖模组开发的进阶主题，并假定你已经读过 [README.zh-CN.md](README.zh-CN.md) 快速入门。模组社区规则见 [CodeOfConduct.zh-CN.md](CodeOfConduct.zh-CN.md)。游戏更新后要升级模组？请查看 [APIChanges.zh-CN.md](APIChanges.zh-CN.md) 了解模组 API 的变化。

> **免责声明。** 本指南在 AI 辅助下撰写，并经开发者审阅。代码片段和 API 名称都对照过游戏源码，但仍可能有疏漏。如果这里的内容与游戏的实际行为不符，请以游戏为准，并通过社区渠道反馈，以便我们修正指南。

## 目录
- [Probably Stolen：模组制作指南](#probably-stolen模组制作指南)
  - [目录](#目录)
  - [示例项目](#示例项目)
  - [用 ModLog 记录日志](#用-modlog-记录日志)
  - [开发工具](#开发工具)
    - [添加你自己的调试按钮](#添加你自己的调试按钮)
  - [对存档负责](#对存档负责)
  - [已支持与不支持的模组功能](#已支持与不支持的模组功能)
    - [✅ 原生支持](#-原生支持)
    - [❌ 不支持](#-不支持)
  - [模组资源](#模组资源)
    - [物品精灵图](#物品精灵图)
    - [声音](#声音)
    - [其他贴图](#其他贴图)
    - [纸张贴图](#纸张贴图)
    - [本地化](#本地化)
    - [如何知道资源已就绪](#如何知道资源已就绪)
  - [钩子点](#钩子点)
    - [订阅钩子](#订阅钩子)
    - [通过物品目录钩子添加物品](#通过物品目录钩子添加物品)
    - [可用钩子](#可用钩子)
  - [掉落表](#掉落表)
    - [权重](#权重)
    - [从代码编辑掉落表](#从代码编辑掉落表)
    - [用 JSON 文件编辑掉落表](#用-json-文件编辑掉落表)
    - [响应掷取](#响应掷取)
    - [在控制台中查看掉落表](#在控制台中查看掉落表)
  - [保存模组数据](#保存模组数据)
  - [自定义 UI](#自定义-ui)
  - [纸质手册](#纸质手册)
    - [用编辑器制作手册](#用编辑器制作手册)
    - [手册文件](#手册文件)
    - [给手册绑定代码](#给手册绑定代码)
    - [用代码构建手册](#用代码构建手册)
    - [原版美术与你自己的美术](#原版美术与你自己的美术)
  - [机器窗口](#机器窗口)
  - [游戏选项](#游戏选项)
  - [人脉升级](#人脉升级)
  - [起始方案](#起始方案)
  - [起始天赋](#起始天赋)
  - [难度](#难度)
  - [夜间地点](#夜间地点)
  - [模组配置](#模组配置)
  - [能力声明与扫描器](#能力声明与扫描器)
    - [声明能力](#声明能力)
    - [一律拒绝的情况](#一律拒绝的情况)
    - [发布前自查](#发布前自查)
    - [玩家看到什么](#玩家看到什么)
    - [开发者模式](#开发者模式)
    - [不声明能力也能读写文件](#不声明能力也能读写文件)
  - [Steam 创意工坊](#steam-创意工坊)
    - [用 steamcmd 发布](#用-steamcmd-发布)
  - [Harmony 补丁](#harmony-补丁)
    - [补丁会自动应用](#补丁会自动应用)
    - [Postfix：在原方法之后运行](#postfix在原方法之后运行)
    - [Prefix：在原方法之前运行](#prefix在原方法之前运行)
    - [Finalizer：即使原方法抛出异常也会运行](#finalizer即使原方法抛出异常也会运行)
    - [Transpiler：改写原方法的 IL（进阶）](#transpiler改写原方法的-il进阶)
  - [故障排查](#故障排查)

---

## 示例项目

📁 完整的示例模组项目与本指南一起收录在本仓库中。它们是完整、可构建的模组，你可以打开、研究并改造。当这里的代码片段不足以让你看清各部分如何组合成一个完整项目时，就去参考它们。

🛠️ 要开始你自己的模组，在游戏文件夹（与 `Probably Stolen.exe` 同级）运行本仓库中的 `create-mod.bat`。它会询问 ID、名称、作者、版本、描述和目标游戏版本，然后生成一个项目：正确的 `manifest.xml`（包含必填的 `<Assemblies>` 和 `<Capabilities />` 元素）、一个 `IMod` 入口类、资源文件夹，以及每次编译后把模组安装到 `Mods\` 的构建步骤。仅限 Windows；手动步骤见 [README](README.zh-CN.md)。

---

## 用 ModLog 记录日志

请使用 `ModLog` 而不是 `Debug.Log`，这样你的消息会自动带上模组名前缀。玩家和其他模组作者在阅读控制台时就能轻松分辨某一行日志来自哪个模组。

用 `Init` 中收到的 `ModManifest` 构造一个 `ModLog` 并复用它：

```csharp
using UnityEngine;

namespace MyMod
{
    public class MyMod : IMod
    {
        private ModLog log;

        public void Init(ModManifest manifest)
        {
            log = new ModLog(manifest);

            log.Log("Mod initialized");           // [My Mod]: Mod initialized
            log.Warning("Something looks odd");   // [My Mod]: Something looks odd  (warning)
            log.Error("Something went wrong");    // [My Mod]: Something went wrong (error)
        }

        public void OnEnable() { }
        public void OnDisable() { }
    }
}
```

控制台输出中方括号里的前缀来自清单文件的 `<Name>`。如果你在代码的其他地方需要模组的 ID、版本或其他元数据，请保存 `Init` 传入的 `manifest` 引用并从中读取。

---

## 开发工具

Probably Stolen 内置了两个在开发和测试模组时必不可少的工具。

- 🐛 **调试控制台（`F8`）**：打开一个显示全部日志输出的控制台，包括 `ModLog`、`Debug.Log`、警告和错误。用它确认模组已加载、观察钩子点触发，以及在出错时阅读堆栈跟踪。你的模组自己的 `Debug.Log` 和 `ModLog` 输出始终显示，模组加载器的输出也一样；游戏本身的信息日志默认隐藏，需在 **F9 > Command > Toggle Verbose Log** 中开启（警告和错误始终显示）。
- 🛠️ **开发菜单（`F9`）**：打开一个包含许多对模组开发和测试有用的功能的菜单，例如生成物品、触发事件、查看游戏状态。用于复现边缘情况，而不必一路玩到那里。按钮分为五列：Store（商店）、Command（命令）、Spawn（生成）、Special（特殊）和 Modding（模组工具：纸质手册编辑器、重新载入手册、资源查看器；见[纸质手册](#纸质手册)）。

### 添加你自己的调试按钮

你的模组可以把自己的按钮放到 F9 菜单上，与内置按钮并列。在 `OnEnable` 中注册；菜单打开时会读取它们（如果菜单已经打开，则会自动重建）。每个按钮都会以提示框显示你的模组 ID，方便测试者知道它来自哪里。

```csharp
public void OnEnable()
{
    ModHelper.AddDebugFunction("my_mod_id", ModHelper.DEBUG_CATEGORY_SPAWN, "Spawn My Widget", () =>
    {
        ModHelper.MoveItemToInventory(ModHelper.SpawnItem("my_mod_id.widget"));
    });

    // tall: true 让按钮高度加倍，适合你最常按的那个。
    ModHelper.AddDebugFunction("my_mod_id", ModHelper.DEBUG_CATEGORY_COMMAND, "Reset My Mod State", ResetState, tall: true);
}

public void OnDisable()
{
    ModHelper.RemoveDebugFunctions("my_mod_id");
}
```

- `AddDebugFunction(modId, category, name, action, tall = false)`：`category` 是 `ModHelper.DEBUG_CATEGORY_STORE / COMMAND / SPAWN / SPECIAL / MODDING / MARKETING` 之一（其他值会落入 Special 并给出警告）。前四个是 F9 主面板的列；`MODDING` 和 `MARKETING` 是独立窗口，从主面板 Special 列的“Modding Panel”“Marketing Panel”按钮打开。`name` 请控制在三四个词以内；过长的名称会缩小以适应按钮。
- `RemoveDebugFunctions(modId)` 移除你的模组注册的全部按钮，并返回移除的数量。
- 你的回调抛出的异常会被捕获并记录到 F8 控制台，所以一个坏掉的按钮不会把整个菜单拖垮。
- 受限构建中不存在 F9 菜单，这两个调用在那里不做任何事。

---

## 对存档负责

玩家的存档是永久的，属于玩家。作为模组作者，你要对模组与存档的交互方式负责。

**绝对不要：**
- 删除存档文件
- 悄悄损坏存档（例如写入会导致载入失败的无效数据）

**如果你的模组会影响存档：**
- 在玩家安装之前，在模组描述中清楚地警告
- 提供安全的卸载路径：说明玩家在禁用你的模组之前需要做什么才能不丢失进度

**经验法则：** 除非事先明确说明，玩家应该能够在不丢失进度的情况下禁用你的模组。

---

## 已支持与不支持的模组功能

下面的"支持"指游戏为此提供了专门的 API，本指南有记录，并且我们会在更新中保持它可用。其他一切仍然可以通过 Harmony 做到，但要靠你自己：游戏更新可能毫无预兆地弄坏它，本指南也帮不上忙。

### ✅ 原生支持

- **带自定义精灵图的模组物品**：向游戏添加新物品，包括它们的美术资源（[钩子点](#通过物品目录钩子添加物品)、[模组资源](#模组资源)）
- **顾客生成**：通过 `OnGenerateCustomer*` 钩子在顾客生成时修改它，钩子会把 `StoreClientManager` 交给你（[钩子点](#可用钩子)）
- **掉落表编辑**：把你的物品放进游戏的掉落表、修改或移除已有掉落，或者添加全新的表，可通过代码或 JSON 文件完成（[掉落表](#掉落表)）
- **自定义 UI**：用游戏的控件从代码构建你自己的窗口和面板（设置、查看器、计数器）（[自定义 UI](#自定义-ui)）
- **纸质手册**：游戏纸张风格的指南、名片和单页，用游戏内编辑器排版并保存为 JSON，附带打开它的物品（[纸质手册](#纸质手册)）
- **机器窗口**、**游戏选项**、**人脉升级**、**起始方案与天赋**、**难度**、**夜间地点与事件**：下文各有专门小节
- **模组配置与模组数据**：带生成面板的类型化设置、按局保存的键值存储，以及你自己文件夹中的文件（[模组配置](#模组配置)、[保存模组数据](#保存模组数据)）

### ❌ 不支持

- **新的顾客精灵图和新的客户阵营**：没有注册它们的 API；生成钩子只能修改游戏已经生成的内容
- **改动现有 UI**：重构或替换内置界面；请改为添加你自己的窗口
- **改动商店的布局或核心循环**：柜台、昼夜周期、议价
- **大修型模组**：一次触及许多系统的大规模重做

- **地下交易所的模组交易**：向地下交易所添加新的交易
- **特殊物品**：可检视物品和鉴定物品

不支持的功能可能在以后的更新中得到支持。这个列表中的任何内容仍然可以尝试用 Harmony 补丁实现。请做好每次游戏更新后自行维护的准备，并记住[能力规则](#能力声明与扫描器)：对游戏代码打补丁是免费的，但反射进引擎或系统类型属于需要声明的能力。

---

## 模组资源

把图片和音频文件放进模组文件夹中指定名称的子文件夹，加载器会在启动时自动读取；你不需要写任何加载代码。每个资源以**不含扩展名的文件名**作为键（例如 `health_pack.png` → 键 `health_pack`）。

```
Mods/
└── MyMod/
    ├── manifest.xml
    ├── MyMod.dll
    ├── preview.png             → 可选，选中你的模组时显示在"模组"菜单中（创意工坊物品改为显示其创意工坊预览图）
    ├── Textures/
    │   ├── banner.png          → 通用贴图，键 "banner"
    │   ├── Items/
    │   │   └── health_pack.png → 物品精灵图，键 "health_pack"
    │   └── Paper/
    │       └── my_page.png     → 纸质手册美术（背景、插图），键 "my_page"
    ├── Sounds/
    │   └── ding.wav            → 声音，键 "ding"
    ├── Localization/
    │   ├── en.csv              → "en" 语言的文本
    │   └── fr.csv              → "fr" 语言的文本
    ├── LootTables/
    │   └── drops.json          → 掉落表编辑，见"掉落表"
    └── Books/
        └── fuel_guide.json     → 一本纸质手册，见"纸质手册"
```

> ⚠️ **每个模组都需要 DLL，而且清单里要列出来。** 除了 `manifest.xml`，文件夹中还必须至少有一个 DLL（放在模组文件夹或其 `Assemblies/` 子文件夹中），其中有一个实现了 `IMod` 的类；每个要加载的 DLL 都必须写在清单的 `<Assemblies>` 下，没列出的 DLL 永远不会被加载。只有资源不构成模组：没有这样 DLL 的文件夹不会出现在"模组"菜单中，控制台会改为记录 `[你的模组名] Error: ...`。清单还需要 `<Capabilities>` 元素，见[能力声明与扫描器](#能力声明与扫描器)。

> ⚠️ **文件夹名必须完全一致，且扫描不递归。** 物品精灵图必须*直接*放在 `Textures/Items/` 下；纸张美术*直接*放在 `Textures/Paper/` 下；声音*直接*放在 `Sounds/` 下；本地化文件*直接*放在 `Localization/` 下；掉落文件*直接*放在 `LootTables/` 下；手册*直接*放在 `Books/` 下。放在 `Textures/Sprites/` 或任何嵌套子文件夹中的 PNG 会被静默忽略。支持的图片格式：`.png`、`.jpg`。支持的音频：`.wav`、`.ogg`、`.mp3`。本地化：`.csv`。掉落表和手册：`.json`。

每个模组都会记录它加载了什么，你可以在 F8 控制台中确认：

```
[ModLoader] My Mod: 1 texture(s), 1 item sprite(s), 1 paper sprite(s) loaded
[ModLoader] My Mod: 2 locale(s), 34 localization entries loaded
[PaperUI] My Mod: 1 book(s) loaded
[ModLoader] My Mod: 1 sound(s) loaded
```

### 物品精灵图

物品美术放在 `Textures/Items/` 下，会按像素画导入（点采样过滤、无 mipmap）。用 `SetSpriteAndShapeFromMod` 把它绑定到物品上，传入你的**模组 `<ID>`** 和**文件名键**：

```csharp
GameItem item = ItemDirectory.CreateEmptyItem("health_pack");
item.name = "Health Pack";
item.shortDescription = "Restores a bit of health.";
item.SetSpriteAndShapeFromMod("my_mod_id", "health_pack");  // (modId, spriteKey)
```

`SetSpriteAndShapeFromMod` 做两件事：设置物品的精灵图，并根据图片中不透明的像素推导物品的**网格形状**（它在背包中占据的格子）。透明区域变成空格子，所以 L 形的画会得到 L 形的物品。每个背包格子是 `gridSize` 像素见方，请按网格来定尺寸（例如 64 像素网格下的 2×1 物品就是一张 128×64 的图）。

> 模组 ID 是 `manifest.xml` 中的 `<ID>`，**不是**模组文件夹名。找不到精灵图时会在控制台给出警告，物品会回退到"未知"占位图。

### 声音

`Sounds/` 中的每个文件都会以 **`<modId>:<key>`** 为标识自动注册到游戏的音频系统，例如模组 `my_mod_id` 中的 `ding.wav` 变成 `my_mod_id:ding`。因为你的声音走的是游戏自己的音频通道，它们会遵循玩家的音量设置和暂停状态。绝对不要用你自己的 `AudioSource` 播放。

可以在任何时刻播放声音（钩子处理函数、Harmony 补丁、你的物品逻辑）：

```csharp
ModHelper.PlaySound("my_mod_id", "ding");   // 通用音效通道
ModHelper.PlaySound2("my_mod_id", "ding");  // 第二通道（倒水之类的动作使用）
ModHelper.PlaySound3("my_mod_id", "ding");  // 第三通道（枪声使用；可通过 AudioManager.Instance.StopPlay3() 停止）
```

找不到声音时，三个方法都返回 `false` 并在控制台记录警告。每个通道同一时间只播放一个声音：在某个通道上开始新声音会切断该通道正在播放的内容，所以可能重叠的声音请使用不同通道。

你还可以给物品配上自己的声音。物品以标识字段的形式携带声音（`soundDragStart`、`soundDragEnd`、`soundSelect`、`soundUse`、`soundActivate`、`soundContainerOpen`、`soundContainerClose`、`soundToggle`），这些字段和内置标识一样接受模组标识：

```csharp
item.soundDragStart = ModHelper.GetSoundIdentifier("my_mod_id", "leather_drag");
item.soundUse       = ModHelper.GetSoundIdentifier("my_mod_id", "potion_gulp");
```

（要复用游戏内置的声音，改为赋值 `AudioHelper` 中的常量，例如 `item.soundUse = AudioHelper.EAT`。）

### 其他贴图

通用贴图（`Textures/` 下、`Items/` 之外）会被载入内存，但游戏**没有内置 API 为你显示它们**；它们供你自己的代码使用。通过 `ModLoader.Mods` 访问：

```csharp
var mod = ModLoader.Mods.Find(m => m.Manifest.ID == "my_mod_id");
Texture2D tex = mod.Textures["banner"];
// 自行绘制 `tex`
```

（原始的 `AudioClip` 也可以通过 `mod.Sounds` 在那里拿到，但请优先使用 `ModHelper.PlaySound`，这样玩家的音频设置才会生效。）

要在特定的游戏时刻触发它，请结合[钩子点](#钩子点)或 [Harmony 补丁](#harmony-补丁)。

### 纸张贴图

[纸质手册](#纸质手册)用的美术放在 `Textures/Paper/` 中：背景、插图、按钮图标。文件会作为平滑的 UI 精灵图载入（双线性过滤、无 mipmap、每单位 100 像素，与原版纸张美术一致），以文件名为键，所以你的模组的手册可以直接引用它们（`"background": "my_page"`、`"sprite": "cartridge_clean"`），其他模组的手册则用 `"my_mod_id:my_page"`。同样的键在自定义 UI 构建器中也可用（`AddImage("my_mod_id:my_page")`）。拉伸背景用的九宫格边距在手册文件中声明，而不是在图片上。请按屏幕上想要尺寸的一半来绘制：纸质手册默认以 2 倍显示美术，和原版指南一样。

### 本地化

本地化是**可选的**。如果你的模组只有英文，可以完全跳过本节，直接赋纯字符串（`item.name = "Health Pack";`）。一个不错的折中：只提供一个 `en.csv` 并照样使用 `ModHelper.GetLocalized`；模组行为完全相同，但改文案不需要重新构建，而且之后任何人都可以通过添加一个 CSV 文件贡献翻译，无需改代码。

翻译以每种语言一个 CSV 文件的形式放在 `Localization/` 下，以**语言代码**命名（`en.csv`、`fr.csv` 等）。游戏目前支持下列语言，文件名必须使用这些精确的代码：

| 语言 | 代码 |
|---|---|
| 英语 | `en` |
| 法语 | `fr` |
| 德语 | `de` |
| 俄语 | `ru` |
| 中文 | `zh` |
| 日语 | `ja` |
| 西班牙语 | `es` |
| 葡萄牙语（巴西） | `ptBR` |
| 韩语 | `ko` |
| 意大利语 | `it` |

（其他名字的文件会被加载但永远不会被解析到。不确定时，用 `ModHelper.GetCurrentLocale().Identifier.Code` 打印当前语言代码。）

每行一条：键、一个逗号、然后是文本。UTF-8，无表头行。空行和以 `#` 开头的行会被忽略。

```csv
# en.csv
health_pack_name,Health Pack
health_pack_desc,"Restores health, cures bleeding, and smells faintly of mint."
merchant_line,"She said ""no refunds"" and meant it."
days_left,Expires in {0} day(s)
trade_offer,"{0} offers {1} credits for it."
multi_line,First line\nSecond line
```

格式规则：

- **第一个逗号**之后的一切都属于文本，所以文本中不加引号的逗号也没问题。因此键不能包含逗号；请只用字母、数字和下划线。
- 文本可以选择用双引号包起来（电子表格导出会自动这么做）。引号内用 `""` 表示一个字面的 `"`。
- 用 `\n` 表示换行。每行一条；值内部的真实换行不受支持。

用 `ModHelper.GetLocalized` 读取条目。它先解析当前语言，再回退到 `en`，最后返回键本身（并给出一次性的控制台警告），所以缺少翻译永远不会崩溃或显示空白：

```csharp
item.name = ModHelper.GetLocalized("my_mod_id", "health_pack_name");
item.shortDescription = ModHelper.GetLocalized("my_mod_id", "health_pack_desc");

// 额外参数用 string.Format 插入：{0} 是第一个参数，{1} 是第二个，依此类推
string label = ModHelper.GetLocalized("my_mod_id", "days_left", 3);
// -> "Expires in 3 day(s)"

string offer = ModHelper.GetLocalized("my_mod_id", "trade_offer", clientName, price);
// -> "Vera offers 250 credits for it."
```

> 只支持带编号的 `string.Format` 占位符（`{0}`、`{1}` 等）。Unity 的 **Smart Strings**（命名占位符、复数规则、`choose()`）是游戏内置字符串表的功能，模组条目**不能**使用。需要复数形式时，请使用不同的键（例如 `days_left_one` / `days_left_many`）并在代码中选择。

本地化文件与其他资源一起加载，在 `Init`/`OnEnable` 之后。任何[钩子](#钩子点)触发时它们都已就绪，所以在物品工厂或钩子处理函数中解析字符串总是安全的；在 `Init`/`OnEnable` 中调用 `GetLocalized` 则不安全。

### 如何知道资源已就绪

资源在 `Init`/`OnEnable` 运行**之后**才加载完成：贴图和本地化在所有模组初始化后立即加载，声音则在之后的几帧里异步加载。所以 `OnEnable` 里的 `mod.Sounds["ding"]` 会是空的。如果你在启动时（而不是游戏过程中按需）就需要资源，请订阅 `ModHook.OnModAssetsLoaded`。它在每个已启用模组的*全部*贴图、物品精灵图、声音和本地化条目都进入内存后触发一次：

```csharp
public void OnEnable()  => ModHook.OnModAssetsLoaded += OnAssetsLoaded;
public void OnDisable() => ModHook.OnModAssetsLoaded -= OnAssetsLoaded;

void OnAssetsLoaded(LoadedMod mod)
{
    if (mod.Manifest.ID != "my_mod_id") return; // 它会为每个模组触发，检查是不是你的
    log.Log($"All assets ready: {mod.Sounds.Count} sound(s), {mod.Sprites.Count} sprite(s)");
}
```

在 `OnModItemDirectoryInit` 中用 `SetSpriteAndShapeFromMod` 绑定的物品精灵图不需要这个；那里的精灵图查找发生在游戏过程中，远在加载完成之后。

---

## 钩子点

钩子点是游戏在固定时刻触发的事件：存档载入、顾客生成、卷帘门打开、提示框构建等等。订阅一个钩子就能让你的代码在那个时刻运行，**无需修补任何东西**。这是扩展游戏的首选方式：它比 Harmony 快，而且在游戏更新时远不容易失效。只有在没有钩子覆盖你的需求时才去用 [Harmony](#harmony-补丁)。

所有钩子都是静态类 `ModHook` 上的 C# 事件。

### 订阅钩子

在 `OnEnable` 中订阅，在 `OnDisable` 中取消订阅。每个处理函数的签名与钩子匹配；有的带参数，有的没有：

```csharp
public class MyMod : IMod
{
    private ModLog log;

    public void Init(ModManifest manifest) => log = new ModLog(manifest);

    public void OnEnable()
    {
        ModHook.OnGameLoadedNormal  += OnGameLoaded;
        ModHook.OnShutterOpenedEarly += OnShutterOpened;
    }

    public void OnDisable()
    {
        ModHook.OnGameLoadedNormal  -= OnGameLoaded;
        ModHook.OnShutterOpenedEarly -= OnShutterOpened;
    }

    void OnGameLoaded()    => log.Log("A save just finished loading.");
    void OnShutterOpened() => log.Log("The store just opened.");
}
```

> 与在主菜单运行的 `Init`/`OnEnable` 不同，钩子在**游戏过程中**触发：钩子运行时游戏系统已经存在，所以可以安全地生成物品、读取存档状态、访问管理器。

**异常是隔离的。** 每个订阅者都在自己的 try/catch 中运行：如果你的处理函数抛出异常，错误会带着你的模组名记录到控制台，其他模组的处理函数（以及游戏本身）不受影响地继续。这是一张安全网，不是许可证；记录下来的异常仍然意味着你的模组有问题，所以开发时请留意 F8 控制台中的 `[ModHook]` 错误。

**顺序层级。** 许多钩子分为多个层级，让多个模组可以相对彼此定位。选择与你需要的先后顺序匹配的层级：

- 顾客生成：`VeryEarly → Early → Normal → Late → VeryLate`
- 游戏载入：`Init → Early → Normal → Late`
- 其他大多数：`Early → Late`

如果与其他模组的相对顺序对你无所谓，用 `Normal`（或 `Early`）层级。

### 通过物品目录钩子添加物品

`OnModItemDirectoryInit` 是注册新物品、使其可按 ID 生成的方式。它把模组物品目录交给你；调用 `Add(id, factory)` 并传入构建物品的函数：

```csharp
public void OnEnable()  => ModHook.OnModItemDirectoryInit += RegisterItems;
public void OnDisable() => ModHook.OnModItemDirectoryInit -= RegisterItems;

void RegisterItems(ModItemDirectory dir)
{
    dir.Add("health_pack", () =>
    {
        GameItem item = ItemDirectory.CreateEmptyItem("health_pack");
        item.name = "Health Pack";
        item.SetSpriteAndShapeFromMod("my_mod_id", "health_pack");
        return item;
    });
}
```

注册后，可以在任何地方用 `ModHelper.SpawnItem("health_pack")` 生成它。

**放置生成的物品。** `SpawnItem` 返回的 `GameItem` 还不在任何地方；把它交给下面之一，它们会像游戏自己那样把物品放进商店的容器（有空位时）：

| 辅助方法 | 物品去向 |
|---|---|
| `ModHelper.MoveItemToInventory(item)` | 玩家背包 |
| `ModHelper.MoveItemToFrontCounter(item)` / `MoveItemToBackCounter(item)` | 前柜台或后柜台 |
| `ModHelper.MoveItemToDisplayCase(item)` | 展示柜 |
| `ModHelper.MoveItemToTrash(item)` | 垃圾桶 |
| `ModHelper.MoveItemToAfterhours(item)` | 夜间背包（玩家夜出带回的东西） |

`ModHelper.SetItemOwnerShip(item, isOwn)` 把物品标记为玩家的（true）或顾客的（false）并返回它，因此可以链式调用：`ModHelper.MoveItemToFrontCounter(ModHelper.SetItemOwnerShip(ModHelper.SpawnItem("health_pack"), false))`。`ModHelper.SetSource(item, modId, modName)` 以标签（`ModHelper.MOD_ID_TAG` / `MOD_NAME_TAG`）把你的模组 ID 和名称盖在物品上，这样你的代码或其他模组可以通过 `item.GetTagReadonly(ModHelper.MOD_ID_TAG).GetString()` 知道物品来自哪里。游戏本身不读取它们；由你的纸质手册生成的物品自带这些标签，其他物品只有你调用时才有。这些辅助方法需要一局已载入的游戏：主菜单中商店的容器尚不存在，所以在 `Init` 或 `OnEnable` 中调用会抛出 `NullReferenceException`。请在 `OnGameLoadedInit` 之类的钩子里或你自己的 UI 中调用。

### 可用钩子

把 `*` 替换为层级名，例如 `ModHook.OnGenerateCustomerVeryEarly`、`ModHook.OnShutterClosedLate`。

| 钩子 | 层级 | 触发时机 | 处理函数接收 |
|---|---|---|---|
| `OnModItemDirectoryInit` | 无 | 物品目录初始化（在此注册物品） | `ModItemDirectory` |
| `OnGenerateCustomer*` | VeryEarly … VeryLate | 正在生成一名商店顾客 | `StoreClientManager` |
| `OnGameLoaded*` | Init … Late | 存档载入完成 | 无 |
| `OnShutterOpened*` / `OnShutterClosed*` | Early, Late | 商店卷帘门打开 / 关闭 | 无 |
| `OnGoingSleep*` / `OnWakingUp*` | Early, Late | 玩家入睡 / 醒来 | 无 |
| `OnLeavingStore*` / `OnReturningStore*` | Early, Late | 玩家离开 / 返回店面 | 无 |
| `OnHandlingNightlyServices*` | Early, Late | 处理夜间维护 | 无 |
| `OnPlaceInventorInventoryItem*` | Early, Late | 物品被放入背包 | `List<GameItem>` |
| `OnCreateTooltip*` / `OnCreateDevTooltip*` | Early, Late | 正在构建物品提示框（追加你自己的行） | `RichTextBuilder`, `GameItem` |
| `OnModAssetsLoaded` | 无 | 某个模组的资源（贴图、物品精灵图、声音、本地化）全部加载完成（每个已启用模组触发一次；检查是不是你的模组） | `LoadedMod` |
| `OnLootTablesLoaded` | 无 | 掉落表已加载且所有模组编辑已应用（每次场景加载一次） | 无 |
| `OnLootRolled` | 无 | 某张掉落表被掷取；设置 `context.itemId` 可覆盖结果（[详情](#响应掷取)） | `LootRollContext` |
| `OnModConfigApplied` | 无 | 玩家在某个模组的配置面板中按下"应用"且有内容改变（[详情](#模组配置)）；检查 ID 是不是你的 | `string`（模组 ID） |
| `OnNetworkUpgradeUnlocked` | 无 | 某个人脉升级被购买（或可重复的升级被使用），在其效果运行之后（[详情](#人脉升级)） | `string`（升级 ID） |
| `OnNewGameStarted` | 无 | 新的一局开始：所选方案的初始物品和起始天赋已放置（[详情](#起始方案)）；载入存档时不触发 | `string`（方案 ID） |
| `OnDifficultyApplied` | 无 | 一局以某个难度开始或某个存档载入；在这里应用难度的自定义效果（[详情](#难度)） | `string`（难度 ID） |
| `OnAfterhourArrive*` / `OnAfterhourLeave*` | Early, Late | 玩家到达 / 离开一个夜间地点，原版或模组的均可（[详情](#夜间地点)） | `string`（地点 ID） |
| `OnAfterhourEventStarted` / `OnAfterhourEventEnded` | 无 | 某个夜间地点上的临时事件开始 / 结束 | `string`（地点 ID）、`string`（事件 ID） |
| `OnPaperOpened` | 无 | 某本纸质手册的面板已构建：第一次打开时，以及之后每次重新载入或重建时；在这里绑定动作和元素句柄（[详情](#纸质手册)）。`ModHelper.OnPaperOpened(modId, bookId, callback)` 是针对单本手册的形式 | `string`（"modId:bookId"）、`PaperUI` |

---

## 掉落表

随机掉落（拾荒所得、供应商货物、部分顾客带来的东西）都从具名的**掉落表**中掷取：带权重的物品 ID 列表。**表组**是带权重的掉落表列表；掷取表组时先选一张表，再掷取那张表。模组可以向已有表添加物品、修改或移除条目、注册新的表和表组，可以从代码完成，也可以完全不写代码、用一个 JSON 文件完成。

编辑与游戏数据分开存储，并在每次表加载时重新应用，所以它们能在场景切换后保留、永不修改游戏文件，而且可以在任何时候进行，包括在任何表存在之前的 `OnEnable` 中。

原版 ID（实时列表，包括其他模组的添加，在[控制台](#在控制台中查看掉落表)里一条 `loot-list` 就能看到）：

| 掉落表 | 用途 |
|---|---|
| `junkTable` | 废料和垃圾 |
| `materialTable` | 制作材料 |
| `packedFoodTable` | 廉价包装食品（供应商货物、食品顾客、补货的冰箱） |
| `householdTable` | 家居用品 |
| `medicalTable`、`dumpingGroundMedical` | 医疗用品 |
| `toolTable` | 工具 |
| `makeshiftWeaponTable` | 简易武器 |
| `t1moduleTable`、`t2moduleTable`、`allModuleTable` | 按等级划分的模块 |
| `accessCardTable` | 门禁卡 |
| `POI_dumpingGround` | 远征兴趣点（ID 是 POI，不是物品） |

| 表组 | 用途 |
|---|---|
| `dumpingGroundTG` | 垃圾场拾荒 |
| `dumpingGroundFreshTG` | 垃圾场新鲜拾荒 |

### 权重

每个条目都有一个权重，条目的概率等于它的权重除以所在表的总权重。原版表经过缩放，使条目**总和为 1000**，这让权重很容易读：

| 权重 | 在未改动的原版表中的概率 |
|---|---|
| `100` | 约 10% |
| `10` | 约 1% |
| `1` | 约 0.1% |
| `0.5` | 约 0.05% |

权重是相对的，所以添加条目会稀释其他条目：向原版表添加权重 `10` 会让你的物品得到 10 / 1010，即 0.99%，并让其他所有条目同样缩小 1%。小数也可以。权重 `0` 会让条目留在表中但永远不会被掷出；添加权重为 0 或更小的条目会被拒绝。

### 从代码编辑掉落表

在 `OnEnable` 中调用；不需要等待任何东西。把你的清单 `<ID>` 作为第一个参数传入，这样控制台就能显示每处编辑来自哪个模组。

```csharp
public void OnEnable()
{
    // 把你的物品放进垃圾堆，约占 1% 的掷取
    ModHelper.AddLootEntry("my_mod_id", "junkTable", "my_item", 10);

    // 让某个已有掉落更稀有，或者完全移除
    ModHelper.SetLootWeight("my_mod_id", "packedFoodTable", "cup_noodle", 20);
    ModHelper.RemoveLootEntry("my_mod_id", "packedFoodTable", "zerochew");

    // 一张新表，然后让它在垃圾场拾荒中占一份
    ModHelper.RegisterLootTable("my_mod_id", "my_table", ("my_item", 700), ("my_rare_item", 300));
    ModHelper.AddLootGroupEntry("my_mod_id", "dumpingGroundTG", "my_table", 50);
}
```

规则：

- 对已在表中的物品调用 `AddLootEntry` 会**替换它的权重**，而不是添加重复项。
- 如果 ID 已存在，`RegisterLootTable` 会失败（并给出控制台警告）。要从零重建一张原版表，先调用 `ClearLootTable`，再添加条目。
- 表组有一套名字里带 `Group` 的相同调用：`RegisterLootGroup`、`AddLootGroupEntry`、`RemoveLootGroupEntry`、`SetLootGroupWeight`、`ClearLootGroup`。它们的条目是掉落表 ID。
- 添加物品 ID 时不做检查。请通过 [`OnModItemDirectoryInit`](#通过物品目录钩子添加物品) 注册你的物品；未知 ID 会掷出"未知"占位物品。
- 关于错误编辑的每条警告都以 `[LootRegistry]` 开头并标明你的模组。

要自己掷取或查看一张表：`ModHelper.RollLootTable(id)` 返回一个物品 ID，`ModHelper.SpawnFromLootTable(id)` 生成它，`ModHelper.GetLootEntries(id)` 返回条目的快照，包括权重和添加每条的模组（原版条目的 `sourceModId` 为 `null`）。表组版本：`RollLootGroup`、`SpawnFromLootGroup`、`GetLootGroupEntries`。

### 用 JSON 文件编辑掉落表

同样的编辑可以以数据的形式提供。把一个或多个 `.json` 文件直接放进模组文件夹中的 `LootTables/` 文件夹；它们与其他资源一起加载，每处编辑都归属于你的模组。三个顶层列表中的任何一个都可以省略。

```json
{
  "tables": [
    { "id": "my_table", "entries": [ { "id": "my_item", "weight": 700 }, { "id": "my_rare_item", "weight": 300 } ] }
  ],
  "groups": [
    { "id": "my_group", "entries": [ { "id": "my_table", "weight": 800 }, { "id": "junkTable", "weight": 200 } ] }
  ],
  "patches": [
    {
      "table": "junkTable",
      "add": [ { "id": "my_item", "weight": 10 } ],
      "remove": [ "rusty_can" ],
      "setWeight": [ { "id": "cup_noodle", "weight": 20 } ]
    },
    { "group": "dumpingGroundTG", "add": [ { "id": "my_table", "weight": 50 } ] },
    { "table": "accessCardTable", "clear": true, "add": [ { "id": "my_card", "weight": 1000 } ] }
  ]
}
```

- `tables` 和 `groups` 创建新列表；`patches` 编辑已有列表（原版的或任何模组的，包括你自己 `tables` 里的）。
- 一个 patch 只能指定 `table` 或 `group` 之一。patch 内部先执行 `clear`，然后是 `add`、`remove`、`setWeight`。
- 文件内的顺序是先 tables，再 groups，然后 patches；多个文件按字母顺序应用。请先注册一张表，再对它打补丁或加入表组。
- 加载器会记录 `[ModLoader] My Mod: 1 loot file(s): 1 table(s), 1 group(s), 3 patch(es) loaded`；无法读取的文件会被跳过，并给出指明文件名的错误。

### 响应掷取

`ModHook.OnLootTablesLoaded` 在表已存在且所有模组编辑都已应用后触发，所以这是用 `GetLootEntries` 读取一张表最终状态的时机。

`ModHook.OnLootRolled` 在任何表的每次掷取之后触发，带一个 `LootRollContext`：`tableId`、`groupId`（选中该表的表组，直接掷取时为 `null`）和 `itemId`。给 `itemId` 赋值即可替换结果：

```csharp
public void OnEnable()  => ModHook.OnLootRolled += OnLootRolled;
public void OnDisable() => ModHook.OnLootRolled -= OnLootRolled;

void OnLootRolled(LootRollContext context)
{
    // 每二十次拾荒所得中有一次变成你的物品，无论来自哪张表
    if (context.groupId == "dumpingGroundTG" && UnityEngine.Random.value < 0.05f)
        context.itemId = "my_item";
}
```

普通的掉落改动请优先用权重而不是这个钩子；它在每次掷取时运行，而且后面的模组会看到你设置的值。

### 在控制台中查看掉落表

F8 控制台有两个命令。`loot-list` 打印所有表和表组；`loot-list <id>` 打印某一张，包括实际百分比以及每个条目由哪个模组添加或修改；`loot-roll <id> [count]` 掷取它并统计结果。

```
> loot-list junkTable
Loot table 'junkTable': 9 entries, total weight 1010 (vanilla tables sum to 1000)
  rusty_can                        weight   250.000   24.752%
  ...
  my_item                          weight    10.000    0.990%  (added by my_mod_id)

> loot-roll junkTable 1000
Loot table 'junkTable', 1000 roll(s):
  rusty_can                            244   24.40%
  ...
```

如果你的物品没有出现在 `loot-list` 中，说明表 ID 写错了或编辑被拒绝了；请在控制台中查找 `[LootRegistry]` 警告。

---

## 保存模组数据

模组经常需要记住一些不属于某个物品的东西：任务进度、计数器、标志、一小块设置数据。`ModHelper` 为每个模组提供一个随玩家本局游戏一起保存的键值存储。

```csharp
// 写入。键按你的模组 ID 隔离命名空间，所以名字随意。
ModHelper.SetModDataInt("my_mod_id", "deliveries", 3);
ModHelper.SetModDataFloat("my_mod_id", "reputation", 0.75f);
ModHelper.SetModDataBool("my_mod_id", "met_courier", true);
ModHelper.SetModData("my_mod_id", "route", JsonUtility.ToJson(routeState));

// 读取，并为从未写入过的键提供回退值。
int deliveries = ModHelper.GetModDataInt("my_mod_id", "deliveries", 0);
float reputation = ModHelper.GetModDataFloat("my_mod_id", "reputation", 0f);
bool met = ModHelper.GetModDataBool("my_mod_id", "met_courier");
RouteState route = JsonUtility.FromJson<RouteState>(ModHelper.GetModData("my_mod_id", "route", "{}"));

// 整理
ModHelper.HasModData("my_mod_id", "route");
ModHelper.RemoveModData("my_mod_id", "route");
ModHelper.GetModDataKeys("my_mod_id");   // 你存过的每个键，不含前缀
ModHelper.ClearModData("my_mod_id");     // 清除你的模组在本局中存的一切
```

规则：

- **按局保存。** 数据是存档槽的一部分：每次游戏保存（每晚）时写入，载入时恢复，新游戏时为空。玩家入睡之前写的任何东西都会进当晚的存档。保存之后的写入保留在内存中，进入下一次存档。
- **在一局游戏载入期间可用。** 从 `ModHook.OnGameLoadedInit` 开始可以读取。在主菜单中或一局游戏载入之前的调用不做任何事并返回回退值，写入时会给出警告。
- **值是字符串。** 游戏永远不需要知道你的类型，所以即使你的模组更新或被移除，存档依然能载入。结构化数据请自行序列化为 JSON；`JsonUtility` 最简单。`Int`、`Float` 和 `Bool` 辅助方法会为你做格式化和解析，与文化设置无关。
- **禁用的模组保留其数据。** 模组被关闭时不会清理任何东西，所以重新启用会恢复其状态。如果你的模组想要一个干净的开始，请自己调用 `ClearModData`。
- **保持小巧。** 这个存储在每次保存时都会写入。几 KB 没问题；不要往里塞大块数据或每帧的数据。
- **它不是用来存物品数据的。** 属于某个特定物品的东西应放在该物品的标签上（`item.ModifyTag` / `GetTagReadonly`），它们随物品保存并跟随物品移动。

**文件。** 对于不按局保存的数据（缓存、导出、玩家手动编辑的东西），`ModHelper` 提供了无需 `files` 能力的文件辅助方法：`ReadModFileText` / `ReadModFileBytes` / `ModFileExists` 读取你的模组文件夹（`GetModFolder` 告诉你它在哪里）；`GetModDataFolder`、`ModDataFileExists`、`ReadModDataFileText` / `Bytes`、`WriteModDataFileText` / `Bytes`、`DeleteModDataFile` 和 `ListModDataFiles` 读写存档位置下属于你的文件夹。只接受相对路径。示例和规则见[不声明能力也能读写文件](#不声明能力也能读写文件)。

---

## 自定义 UI

模组可以通过 `CustomUIManager` 在运行时构建自己的窗口（设置面板、查看器、计数器等），它是建立在游戏 UI 预制件之上的 C# 链式构建器。模组一侧不需要 Unity 项目、预制件或任何编辑器工作；游戏提供控件，你用代码把它们组合起来。

```csharp
CustomUIManager.Window("my_mod_id.settings", "My Mod Settings", CustomUIManager.LAYER_PAPER)
    .SetSize(400, 300)
    .SetDraggable(true)
    .AddLabel("General")
    .AddToggle("Enable feature", true, v => featureOn = v, id: "feature")
    .AddSlider(0f, 100f, 50f, v => amount = v, wholeNumbers: true, id: "amount")
    .AddInput("Enter a name...", "", v => name = v)
    .AddDropdown(new[] { "Low", "Medium", "High" }, 1, i => quality = i)
    .AddProgressBar(0.3f, id: "progress")
    .AddImage("my_mod_id:health_pack")   // 来自 Textures/Items 的物品精灵图
    .BeginRow()
        .AddFlexibleSpace()
        .AddButton("Apply", Apply).WithTooltip("Saves the settings")
        .AddButton("Close", () => CustomUIManager.Instance.CloseWindow("my_mod_id.settings"))
    .End()
    .Show();
```

- `CustomUIManager.Window(id, title, layer)` 开始一个窗口，并替换任何同 ID 的已有窗口。请给 ID 加上你的模组 ID 前缀，以避免与其他模组冲突。`Show()` 结束链式调用并返回一个 `CustomUIWindow`；`GetWindow()` 则以隐藏状态返回它。
- 控件：`AddLabel`、`AddButton`、`AddImage`、`AddToggle`、`AddSlider`、`AddInput`、`AddDropdown`、`AddProgressBar`、`AddSpace`、`AddFlexibleSpace`。给任何之后想更新的控件传一个 `id`。`AddInput` 的 `onChanged` 在回车或失去焦点时触发；传 `onTyping` 可获得逐字回调。要实时筛选列表，不要在该回调里重建窗口（会让输入框失去焦点）：在创建列表容器的 `Begin` 调用之后读取 `builder.CurrentContainer`，之后用 `CustomUIBuilder.ClearContainer(host)` 清空，再用 `new CustomUIBuilder(CustomUIManager.Instance, window, host)` 重新填充。
- 布局：`BeginRow` / `BeginColumn` / `BeginGrid(columns, cellWidth, cellHeight)` / `BeginScroll(height)`，每个都用 `End()` 结束。`BeginRow(spacing, alignment)` 和 `BeginColumn(spacing, alignment)` 可传入 `TextAnchor` 来对齐子元素（默认 `UpperLeft`；`UpperCenter` 可让图标居中于其标签上方）。标签页：`BeginTabs()`，然后每个标签页一组 `BeginTab("Name") ... End()`，最后 `EndTabs()`。
- 窗口选项：`SetSize`、`SetPosition`、`Center`、`SetDraggable`、`SetCloseOnEscape`、`OnClose(callback)`。`WithTooltip(text)` 给最后添加的元素附加一个悬停提示。
- 层（layer）决定由哪个画布承载窗口：游戏场景中的 `LAYER_PAPER`（书籍和文档，大多数普通 UI）、`LAYER_FRONT`、`LAYER_REAR`、`LAYER_META`（选项和退出菜单），主菜单中的 `LAYER_MENU`，以及 `LAYER_OVERLAY`，即管理器自己的、跨场景保留的画布。场景层上的窗口会随场景销毁，所以需要时请重建它们，例如在 `ModHook.OnGameLoadedNormal` 中。指向当前场景中不存在的层时会回退到覆盖层并给出警告。

之后通过句柄更新窗口：

```csharp
CustomUIWindow window = CustomUIManager.Instance.GetWindow("my_mod_id.settings");
window.Get("progress").SetProgress(0.7f, "70%");
window.Get("feature").SetBool(false);      // 静默；传 notify: true 才会触发回调
bool on = window.Get("feature").GetBool();
window.Hide(); window.Show(); window.Close(); // Close 会销毁并注销窗口
```

元素的 setter 是空安全的：对一个标签调用滑块方法只会记录警告并且什么都不做，所以写错的 ID 永远不会把异常抛进游戏的 UI 循环。`AddImage("key")` 和 `SetSprite("key")` 既接受游戏自己的精灵图键，也接受 `"modId:spriteName"` 形式的模组物品精灵图（精灵图键是 `Textures/Items/` 中的文件名，见[物品精灵图](#物品精灵图)）。

经验法则：

- 构建之前先用 `CustomUIManager.Instance != null` 做保护。
- 使用模组精灵图的 UI 不要早于 [`ModHook.OnModAssetsLoaded`](#如何知道资源已就绪) 构建。
- `SetCloseOnEscape` 是可选开启的，因为游戏在商店场景中也会全局处理 Escape；请在窗口打开的状态下测试是否冲突。

---

## 纸质手册

纸质手册（paper book）就是游戏里那些纸张风格的面板：从背包里打开的鉴定指南、名片和单页。一本手册由一张固定背景、放在你指定位置的文字、图片和按钮、一页或多页内容，以及原版的纸张外框（关闭和缩放按钮、翻页按钮、页码、纸张音效）组成。你的模组把手册作为 JSON 文件放在 `Books/` 中，用游戏内的纸质手册编辑器制作；只有需要行为时才写代码（一个会做事的按钮、一个运行时填入的数值）。手册可以声明打开它的文档物品，所以一个纯指南模组完全不需要写物品代码。

### 用编辑器制作手册

1. 启用你的模组启动游戏（`Mods/` 下一个带 `manifest.xml` 和 DLL 的本地文件夹），然后载入一个存档：纸质手册只存在于商店场景。
2. 按 `F9`，在 **Modding** 列点击 **Paper Editor**。在 **Book** 标签页的 *New book* 下选择你的模组，输入一个 ID（字母、数字、下划线），选一个起点（空白笔记本、鉴定指南、教程单页或名片），如果想用自己的美术，从模组的 `Textures/Paper/` 中选一张背景。**Create and edit** 会写入 `Mods/<你的模组>/Books/<id>.json` 并打开它。
3. 搭建页面。**Palette** 可以添加各种原版文字样式的文本、来自任意精灵图的图片（选择器列出原版纸张美术和你自己的）、文字按钮和图标按钮、把子元素纵向堆叠的流式区域（flow），以及外框部件。在手册本身上：点击选中，拖动移动，角和边的把手调整大小，在空白纸面上拖动框选，Shift 追加选择，方向键微调（Shift 为 10），Alt 拖动移动整个面板。元素会吸附到网格、其他元素的边和中心以及页面中心（按住 Ctrl 跳过吸附）。**Inspector** 编辑选中元素的字段；**Elements** 按绘制顺序列出元素并提供锁定和可见开关；**Tools** 有对齐、分布、统一尺寸、层级、撤销与重做、缩放、语言预览和快捷键列表。
4. 每次修改都会在一秒内保存到 JSON 文件，面板立即更新。用文本编辑器修改文件也一样：游戏会检测到变化并重建已打开的手册。**Check** 标签页列出问题（缺失的精灵图、溢出的文字、重复的 ID……），**Screenshot page** 在文件旁保存一张 PNG，可作为创意工坊预览图。
5. **Pages** 添加和重排页面，并管理模板：一种带命名槽位（slot）的共享布局，每一页填入自己的内容（标题、正文、一张插图）。起点自带原版指南、教程单页和名片的布局作为内置模板；*Create from the selected page elements* 可以创建你自己的模板。
6. 想复用原版外观，在 Palette 中开启 **Inspect mode**，从背包打开任意原版指南或名片并悬停在上面：编辑器会报出精灵图、文字样式、尺寸和颜色，**Add like this** 把一个等价的元素放进你的手册。

坐标使用*设计单位*：背景图片的像素，原点在左上角，y 向下。可以在图像编辑器里量好位置直接填入，也可以直接拖。原版纸张美术以一半尺寸绘制、在屏幕上以 2 倍显示（笔记本背景是 314x402 像素，显示为 628x804）；你放在 `Textures/Paper/` 中的背景默认同样按 2 倍显示。字号也是设计单位，所以正文大约是 7.5。

### 手册文件

```json
{
  "id": "fuel_guide",
  "title": "Fuel Guide",
  "background": "notebook_manual",
  "width": 628, "height": 804,
  "chrome": [
    { "type": "button", "id": "close", "action": "close", "x": 297, "y": 2.5, "w": 14, "h": 15 },
    { "type": "button", "id": "flip_left", "action": "flip_left", "x": 124, "y": 380, "w": 16, "h": 16 },
    { "type": "button", "id": "flip_right", "action": "flip_right", "x": 176, "y": 380.5, "w": 14, "h": 15 },
    { "type": "text", "id": "page_indicator", "action": "page_indicator", "style": "page_number", "align": "center", "valign": "middle", "x": 140.5, "y": 374, "w": 33, "h": 25 }
  ],
  "pages": [
    {
      "name": "Page 1",
      "template": "guide_page",
      "slots": { "title": "Plasma Cartridge Appraisal Guide", "body": "Plasma cartridges are the standard fuel..." }
    },
    {
      "name": "Page 2",
      "elements": [
        { "type": "text", "x": 28, "y": 49, "w": 262, "h": 21, "text": "Cartridge Condition", "style": "title", "align": "center" },
        { "type": "image", "x": 80, "y": 90, "w": 160, "h": 62, "sprite": "my_mod_id:cartridge_clean" },
        { "type": "text", "id": "price", "x": 80, "y": 156, "w": 160, "h": 12, "text": "", "preview": "150 Credits", "style": "caption", "align": "center" },
        { "type": "button", "x": 120, "y": 340, "w": 80, "h": 18, "text": "Refresh", "action": "refresh" }
      ]
    }
  ],
  "item": { "id": "fuel_guide", "name": "Fuel Guide", "description": "How to price plasma cartridges.", "value": 50 }
}
```

手册字段：`id`（默认为文件名）、`title`（仅编辑器使用）、`background`（原版精灵图名，如 `notebook_manual`、`guide_reworked`、`tutorial_sheet`、`business_card_template`、`exchange`、`test_strips`；你的 `Textures/Paper/` 中的文件名；或 `"modId:name"`）、`width`/`height`（显示尺寸；对原版背景填 0 则沿用原版尺寸）、`designWidth`/`designHeight`（覆盖坐标空间；0 表示背景的像素尺寸）、`border`（`[左, 下, 右, 上]`，拉伸背景用的九宫格边距）、`posX`/`posY`（面板打开的位置，相对屏幕中心的偏移；原版指南用 -450, 0）、`sounds`、`draggable`、`zoomable`（默认 true）、`chrome`（每一页都绘制的元素）、`templates`、`pages`、`item`。

元素字段：`type`（`text`、`image`、`button`、`flow`、`line`）、`id`、`x`、`y`、`w`、`h`、`visible`、`locked`（仅编辑器）、`raycast`（文字和图片默认不拦截点击，设为 true 才拦截）。文字：`text` 或 `loc`（你的 `Localization/*.csv` 中的键，优先于 `text`）、`translations`（按语言代码给出的文字，如 `{"zh": "..."}`，选中该语言时使用；少量文字不想做 csv 时很方便）、`style`、`fontSize`（0 沿用样式字号）、`align`（`left`、`center`、`right`）、`valign`（`top`、`middle`、`bottom`）、`color`（`#rrggbb`）、`wrap`、`autoHeight`（随文字增高）、`preview`（仅编辑器显示的示例，用于由代码填入的文字）。图片：`sprite`、`fit`（`stretch`、`fit`、`native`）、`scale`（native 模式下按像素尺寸乘以该倍数绘制；整数倍能保持像素画清晰）、`color`（着色）、`silhouette`（把所有不透明像素涂成 `color`，即一个平涂的剪影）、`fill`（`#rrggbb`，填充精灵图轮廓所包围的透明像素；开局职业图标是为青色圆底绘制的深色圆环，放在深色背景上时需要设置它）。线条：从 `x`、`y` 到 `x2`、`y2`，`thickness`（粗细）、`arrow`（`none`、`end`、`start`、`both`）、`arrowSize`（箭头大小）、`color`（留空为墨色）。按钮：`action`（你在代码中绑定的名字；`close`、`zoom`、`flip_left`、`flip_right` 由手册自己处理）、文字按钮用 `text`（蓝色底板）、图标按钮用 `sprite` 和可选的 `hoverSprite`。流式区域：`spacing`、`align`；子元素把 `flow` 设为该区域的 ID，会被纵向堆叠（文字高度由内容决定）。模板元素可以带 `slot` 名；页面的 `slots` 映射填充它们（文字填文本，图片填精灵图键）。

物品字段：`id`（物品标识，用 `ModHelper.SpawnItem` 生成）、`name`/`nameLoc`、`description`/`descriptionLoc`、`sprite`（原版物品图集中的 `atlas/sprite`，默认 `items_misc/manual1`，或 `Textures/Items/` 中的文件名）、`value`、`important`（不可被偷，默认 true）。该物品是一份文档：阅读它就打开手册。

文字样式：`header`（"Station Trade Commission" 印章，Tektur）、`title`（Noto Sans Medium）、`section` 和 `body`（Noto Serif）、`caption` 和 `label`（Noto Sans Bold）、`serif_title`（Noto Serif Bold）、`handwritten` 和 `page_number`（Caveat）、`stamp`（红色 LCD 风格）、`button`（文字按钮标签），以及 Meta 面板的深色选项界面风格：`meta_header`（粗体）、`meta_body`、`meta_warning`。样式对应字体角色，所以会和游戏其他部分一样按语言切换字体。

### 给手册绑定代码

布局在 JSON 里，行为在 C# 里。手册在第一次打开时构建，之后每次重新载入都会重建，所以请在 `OnPaperOpened` 中绑定，而不是启动时只绑一次：

```csharp
public void OnEnable()
{
    ModHelper.OnPaperOpened("my_mod_id", "fuel_guide", ui =>
    {
        ui.OnAction("refresh", () => ui.SetText("price", $"{CurrentPrice()} Credits"));
        ui.OnPageShown((book, page) => { if (page == 1) book.SetText("price", $"{CurrentPrice()} Credits"); });
    });
}
```

- `ModHelper.OpenPaper(modId, bookId)` 打开一本手册（或把它提到最前）并返回 `PaperUI`；`ClosePaper`、`IsPaperOpen`、`GetOpenPaper` 顾名思义。`ModHelper.SpawnPaperItem(modId, bookId)` 生成声明的物品；`ModHelper.GetPaperBookIds(modId)` 列出你的手册；`ModHelper.RemovePaperBooks(modId)` 注销你模组的所有手册（已打开的面板会关闭）并返回数量。
- 在 `PaperUI` 上：`OnAction(name, callback)` 绑定按钮，`Get(id)` 返回带常用 setter 的元素句柄（`SetText`、`SetSprite`、`SetVisible`、`OnClick`……），`SetText(id, text)` 和 `SetSprite(id, key)` 是快捷方式，还有 `FlipTo(page)`、`CurrentPage`、`PageCount`、`Hide()`、`Close()`，以及事件 `PageShown`、`Closed`、`ActionFired`。
- `ModHook.OnPaperOpened(string fullId, PaperUI ui)` 是同一信号的全局形式（"modId:bookId"）。
- 手册随模组资源一起注册，晚于 `OnEnable`，所以在文件载入之前就在 `OnEnable` 中调用 `OnPaperOpened` 是安全的。

### 用代码构建手册

手册也可以完全用代码、用同样的字段构建，适合运行时生成的页面：

```csharp
PaperUI ui = ModHelper.CreatePaper("my_mod_id", "recipes", "notebook_manual")
    .AddPage("Recipes", template: "guide_page")
        .SetSlot("title", "House Recipes")
        .SetSlot("body", "Mix two parts water with one part regret.")
    .AddPage("Notes")
        .AddText(28, 49, 262, 21, "Notes", PaperTextStyle.TITLE, align: "center")
        .AddTextBelow("A paragraph under the title, growing with its text.")
        .AddImage(80, 200, 160, 62, "my_mod_id:still", fit: "fit")
        .AddButton(120, 340, 80, 18, "Brew", Brew)
    .Show();
```

`CreatePaper` 给手册配上原版外框；`SetChrome(close, zoom, flip, pageIndicator)` 修改它，`SetSize` 和 `SetPosition` 摆放它。`ModHelper.RegisterPaperBook(modId, data)` 注册你自己解析或构建的数据（`ModHelper.ParsePaperBook(json)`），这样它和文件手册一样拥有 ID、物品和 `OnPaperOpened`。编辑器的 **Copy C#** 按钮会把当前手册的链式写法复制到剪贴板。

### 原版美术与你自己的美术

精灵图选择器以及 `background` / `sprite` 键接受原版纸质面板使用的所有精灵图，按精灵图名称：背景（`notebook_manual`、`guide_reworked`、`guide`、`tutorial_sheet`、`business_card_template`、`exchange`、`test_strips`、`mentors_notes`……）、外框按钮（`paper_buttons_close1`、`paper_buttons_screen_0`、`paper_buttons_l_1`、`paper_buttons1`、`blue_button_2x`）、指南页眉（`guide_logo`）以及原版指南的插图。**F9 > Modding > Paper Sprite Picker** 可以浏览它们并复制键。你自己的美术放在模组的 `Textures/Paper/` 中（PNG 或 JPG，作为平滑的 UI 精灵图载入），按文件名引用，或在其他模组的手册中用 `"my_mod_id:name"` 引用。`Textures/Items/` 中的物品精灵图也可以用。另外两类：原版物品精灵图写作 `图集/名称`（`items_aquaculture/tilapia_large1`、`items_misc/manual1`；调色板中的 *Item sprite from the game atlases* 按钮会列出它们），以及深色选项界面的外框，写作 `meta_` 加精灵图名称（`meta_panel` 是九宫格底板，也可以用作背景；`meta_seperator`、`meta_checkbox`……），以及按名称引用的开局职业图标（`icons_apprentice`、`icons_aquaculture`……）。

控制台命令（F8）：`paper-list`、`paper-open <id>`、`paper-close [id]`、`paper-reload`、`paper-edit [id]`、`paper-item <id>`。F9 的 Modding 列有 **Reload Mod Books**，用于游戏运行中新增或修改的文件。

---

## 机器窗口

带内容窗口的物品（机器、容器、工作台）打开的窗口由代码用游戏的 Machinery 控件搭建：一排带标签的面板，每个面板放一个物品栏或一组控件。你自己的机器用同一个构建器，外观就和原版一致。

```csharp
GameSlotInventory battery = new GameSlotInventory();
GameGridInventory modules = new GameGridInventory(MachineHelper.DEFAULT_MODULE_BAY_CONFIG, MachineHelper.DEFAULT_MODULE_BAY_WIDTH);
GameGridInventory input   = new GameGridInventory(6, 4);

MachineryProgressBar progress = new MachineryProgressBar(0f);
MachineryText status = MachineryText.Status("status", "idle");
MachineryButton start = new MachineryButton("Start", () => { /* 运行机器 */ });

PixelWindow window = MachineHelper.CreateMachineryWindow(canMove: true,
    MachineHelper.PowerPanel(battery),                              // 电池图标标签，节点 0
    MachineHelper.Panel("Modules", modules, "module"),              // 文字标签，节点 1
    MachineHelper.Panel("Input", input, "input"),
    MachineHelper.Panel("Control", MachineryStack.Vertical(start, progress, status), "control"));

item.SetContentWindow(window);
MachineHelper.SetupBatterySlot(battery, item);
```

- `MachineHelper.Panel(label, content, role)` 把物品栏（或装着槽位的 `GridPixelElement`）放进标签板下方的凹槽区；其他元素（堆叠、按钮、标签页）原样放入。`PowerPanel` 和 `NotePanel` 使用设计稿的电池和便签图标；`IconPanel(sprite, content, role)` 接受你自己的精灵（`"modId:spriteName"` 键可通过 `CustomUIManager.Instance.GetSprite` 取得）。
- 控件：`MachineryButton`（文字、图标或两者；`SetDescription` 设置提示；`Enable` / `Disable` / `Hide`）、`MachineryRadioButton`（开关；`MachineryRadioGroup` 保证只有一个开启；`MachineryRadioList(captions, selected, onChanged)` 是带说明文字的一列）、`MachineryProgressBar`（`SetValue(0..1)`、`SetColor`）、`MachinerySlider`（`SetRange(min, max, step)` 或 `SetSteps(n)` 加 `GetInt`；`onChanged`、`onReleased`）、`MachineryTabs`（`AddTab(caption, page)`）、`MachineryText`（单行，支持富文本）。
- 布局：`MachineryStack.Vertical(...)` / `Horizontal(...)` 按间距堆叠元素；竖直堆叠会把按钮、滑块、进度条和文字拉伸到面板宽度。`window.AddHeaderButton(new MachineryButton(icon, callback))` 在关闭叉的左侧加一个按钮。
- 之后读取机器的物品栏：`MachineHelper.GetBodyStorage(item, i)` 返回窗口主体从左到右第 i 个物品栏或网格（`GetBatterySlot`、`GetModuleInv`、`GetSlot` 都基于它），或者用 `((MachineryPanelRow)window.childElement).GetPanel("role")`。
- 面板顺序就是物品栏的存档顺序。模组发布后，新面板只能加在末尾，不要调整已有面板的顺序，否则存档里的物品会落到错误的物品栏。
- 经典窗口外观仍可用 `new PixelWindow(canMove)` 获得；Machinery 风格是 `new PixelWindow(canMove, style: WindowStyle.Machinery)`，可挂任何元素（裸物品栏会由窗口自己画出一块面板和凹槽区）。

---

## 游戏选项

你的模组可以把自己的设置放进游戏的"选项"窗口（商店中的 Escape 菜单 > 选项，主菜单中的选项），与内置选项并列。你只需注册条目；游戏用自己的控件绘制它们，窗口打开时通过你的 getter 填充，玩家按下"应用"时调用你的 setter。

```csharp
public void OnEnable()
{
    // 你自己的分区（或使用 ModHelper.OPTION_SECTION_GAMEPLAY / AUDIO / DISPLAY / DIALOGUE / KEYBIND 加入内置分区）。
    ModHelper.AddGameOptionSection("my_mod_id", "settings", () => "My Mod");

    ModHelper.AddGameOptionToggle("my_mod_id", "settings", "fast_courier",
        () => ModHelper.GetLocalized("my_mod_id", "option_fast_courier"),
        () => fastCourier,
        v => { fastCourier = v; PlayerPrefs.SetInt("my_mod_id.fast_courier", v ? 1 : 0); },
        tooltip: () => "Couriers arrive twice as fast.");

    ModHelper.AddGameOptionSlider("my_mod_id", "settings", "spawn_rate",
        () => "Spawn rate", () => spawnRate, v => spawnRate = v, min: 0f, max: 2f);

    ModHelper.AddGameOptionDropdown("my_mod_id", "settings", "difficulty",
        () => "Difficulty", () => new[] { "Easy", "Normal", "Hard" }, () => difficulty, i => difficulty = i);

    // 按键绑定：一个显示当前按键的按钮，点击后等待下一次按键（Escape 取消）。
    // 放进 ModHelper.OPTION_SECTION_KEYBIND 可与游戏自带的绑定并列。用 Input.GetKeyDown(hotkey) 轮询。
    ModHelper.AddGameOptionKeyBind("my_mod_id", ModHelper.OPTION_SECTION_KEYBIND, "open_panel",
        () => "Open my panel", () => hotkey, k => { hotkey = k; PlayerPrefs.SetInt("my_mod_id.hotkey", (int)k); });
}

public void OnDisable()
{
    ModHelper.RemoveGameOptions("my_mod_id");
}
```

规则：

- **值由你保管。** 游戏只通过 getter 读取、通过 setter 写入，所以请把它存在合适的地方：全局偏好用 `PlayerPrefs` 或 ES3，与本局游戏绑定的用[模组数据](#保存模组数据)。getter 在每次窗口打开时运行；setter 只在"应用"时运行，玩家还在拖动滑块时不会调用。
- **标签、提示和下拉选项都是函数**，每次窗口打开时重新求值，所以 `() => ModHelper.GetLocalized(...)` 能跟随语言切换。提供 tooltip 会在标签旁加一个信息图标。
- **ID 有命名空间。** `optionId` 和你自己的分区 ID 在内部都会加上模组 ID 前缀，因此不会与其他模组冲突。重复注册同一个 ID 会替换之前的条目。`RemoveGameOption(modId, optionId)` 和 `RemoveGameOptions(modId)` 可以再移除它们。`ModHelper.GameOptionId(modId, optionId)` 返回游戏内部使用的带前缀 id（`"modId:optionId"`），用于极少数需要按完整 id 匹配条目的场合。
- **顺序**为分区内的注册顺序；你的分区排在内置分区之后。
- **按键绑定**会拒绝 Escape、数字键以及窗口中其他绑定行已占用的按键，且只能捕获键盘按键。玩家选择按键期间，游戏自己的快捷键保持静默；你的也应如此：`KeyBindHelper.SuppressHotkeys` 为 true 时跳过轮询。
- 可在 `OnEnable` 中调用；窗口每次打开都会重新构建。

只有当某个设置确实属于游戏自身的选项时才使用它。关于你模组本身的设置请放进模组自己的配置面板，见下文。

## 人脉升级

"Wild 的人脉"（Wild's Network）是玩家购买各种好处（新供应商、服务、许可证）的升级商店。你的模组可以往里面添加自己的升级：注册一条定义，窗口就会把它画进正确的卡片和标签页，并处理价格、人情与现金支付、前置条件、冷却和存档状态。不需要手工排版。

```csharp
public void OnEnable()
{
    ModHelper.AddNetworkUpgrade("my_mod_id", "my_mod_id.COURIER",
        cost: 400,
        subtitle: "Supplier",                          // 所在的卡片
        title: () => ModHelper.GetLocalized("my_mod_id", "network_courier_title"),
        description: () => ModHelper.GetLocalized("my_mod_id", "network_courier_desc"),
        onUnlock: () => courierUnlocked = true,
        iconKey: "my_mod_id:courier_icon",              // 你 Textures/Items 中的精灵图
        prerequisites: new[] { NetworkUpgrade.BUY_REFERAL });

    // 可重复的升级：冷却结束后可再次使用，类似"销毁证据"。
    ModHelper.AddNetworkUpgrade("my_mod_id", "my_mod_id.BRIBE",
        cost: 250, subtitle: "Favor",
        title: () => "贿赂检查员",
        description: () => "跳过下一次检查。",
        onUnlock: () => skipNextInspection = true,
        cooldownDays: 7,
        alreadyBought: () => "检查员已经被买通了。");

    // 放在你自己的标签页上的升级。
    ModHelper.SetNetworkTabLabel("my_mod", () => "我的模组");
    ModHelper.AddNetworkUpgrade("my_mod_id", "my_mod_id.DRONE", 800, "Logistics",
        () => "送货无人机", () => "货物提前一天送达。", () => droneUnlocked = true,
        tab: "my_mod");
}

public void OnDisable()
{
    ModHelper.RemoveNetworkUpgrades("my_mod_id");
}
```

窗口的摆放规则：

- **标签页。** `tab` 留空表示第一个标签页（"基础"，所有原版升级都在这里）。其他任意字符串会创建同名标签页，使用相同字符串的升级共享它；`SetNetworkTabLabel` 为它提供翻译后的标签，否则直接显示原始字符串。
- **卡片。** `subtitle` 决定标签页内的卡片。复用原版副标题（`Introduction`、`Favor`、`Informant`、`Referral`、`Service`、`Permit`、`Supplier`）即加入该卡片；用你自己的字符串则新建一张卡片，`subtitleLabel` 可为自定义副标题提供翻译。`recommended: true` 会在该标签页顶部的金色"推荐"横幅中再显示一份该升级（升级仍留在自己的卡片里；两份会一起选中和高亮）。卡片三格宽，装满后按行增长。
- **链条。** 同一卡片内的前置条件会在两个格子之间从左到右画出连接线。前置条件在其他卡片上也可以，只是改为在描述栏中列出。
- **图标。** `iconKey` 走与 `AddImage` 相同的查找（你的 `"modId:spriteName"` 物品精灵图）。不提供时，窗口先找与 ID 同名的原版图标，再退回到"推荐"图标。72x72 像素正好填满格子。
- **文本提供函数**在每次窗口打开时重新求值，所以 `() => ModHelper.GetLocalized(...)` 能跟随语言切换。

规则：

- **在 `Init` 或 `OnEnable` 中注册。** 新游戏会在那时创建该升级，载入的存档会在载入时补上它。升级的状态（是否购买、冷却、当前价格）随本局存档按其 ID 保存，所以请保持 ID 稳定且唯一：加上你的模组 ID 前缀。
- **`onUnlock` 每次购买运行一次**，在玩家付款之后（先扣人情，再扣现金）。可重复的升级（`cooldownDays` 大于零）每次使用都会运行它，并在冷却后重新可用。订阅 `ModHook.OnNetworkUpgradeUnlocked(id)` 可响应任何升级（原版或模组）被购买。
- **移除**（`RemoveNetworkUpgrades`）只会把升级从窗口拿掉；存档中记住的内容保留，所以之后重新启用的模组能找回已购买的内容。
- 用 `ModHelper.IsNetworkUpgradeUnlocked(id)` 读取状态，原版 ID 也可用 `NetworkUpgrade.IsUnlocked(id)`。`ModHelper.GetNetworkUpgrade(id)` 返回本局中的副本（状态、当前 `cost`、冷却）；在 `onUnlock` 中提高它的 `cost`，可以让可重复的升级每次使用都更贵，原版的人情升级就是这样做的。
- 本局不认识的前置条件 ID（打错字，或来自已停用模组的升级）按未解锁处理，只记录一次日志，不会让窗口出错。
- `ModHelper.OpenWildNetwork()` / `CloseWildNetwork()` 可从你自己的代码打开和关闭窗口（商店场景、已载入存档），例如从自定义按钮或对话中。

---

## 起始方案

新游戏的"专精"（Specialization）步骤会在一条图标栏中列出各个起始方案（学徒、销赃者、枪匠……）。你的模组可以添加自己的方案：注册一条定义，界面就会把它排在原版方案之后显示，带上你的图标、名称、标签、描述和"初始拥有"各行。玩家以它开局时，你的 `onStart` 会在商店场景中运行，时机与原版方案放置初始物品相同。

```csharp
public void OnEnable()
{
    ModHelper.AddStartingScenario("my_mod_id", "my_mod_id.courier",
        title: () => ModHelper.GetLocalized("my_mod_id", "scenario_courier_title"),
        description: () => ModHelper.GetLocalized("my_mod_id", "scenario_courier_body"),
        startWith: new System.Func<string>[]
        {
            () => ModHelper.GetLocalized("my_mod_id", "scenario_courier_gear1"),
            () => "一批包裹存货",
        },
        onStart: () =>
        {
            ModHelper.MoveItemToInventory(ModHelper.SpawnItem("satchel"));
            ModHelper.MoveItemToInventory(ModHelper.SpawnItem("my_mod_id.parcel"));
            ModHelper.AddCredit(-100, false);
        },
        iconKey: "my_mod_id:courier_icon",          // 你 Textures/Items 中的精灵图
        tag: () => "进阶开局",                       // 可选：名称旁的一行短标签
        tagTone: StartingScenario.TagTone.Warning); // Positive（绿）、Warning（橙）、Danger（红）
}

public void OnDisable()
{
    ModHelper.RemoveStartingScenarios("my_mod_id");
}
```

规则：

- **在 `Init` 或 `OnEnable` 中注册**，要在玩家打开"新游戏"之前。本局存档按 ID 记住方案（`StartType.MODDED` 加上 ID），所以请保持 ID 稳定且唯一：加上你的模组 ID 前缀。用某个方案开始、而该模组之后被移除的存档仍能载入；在载入列表中它会显示为"损坏的存档"，直到模组回来。
- **`onStart` 只运行一次**，在新的一局于商店场景开始时：基础商店已经存在，起始天赋的物品紧随其后。在这里生成并放置物品（`SpawnItem`、`MoveItemToInventory`、`AddCredit`……）。异常会被捕获并记录。载入存档时不会运行它；那种情况请用 `ModHook.OnGameLoaded*`。
- **图标。** `iconKey` 走与 `AddImage` 相同的查找（`"modId:spriteName"`）。原版图标是 19x19、自带圆形边框的精灵图，以 2 倍绘制；任何精灵图都会缩放到格子中的 38x38。不提供时显示学徒的图标。
- **`skipIntro`** 让该方案总是跳过序章（销赃者、枪匠、化学家和一无所有都是如此）。**`comingSoon`** 会显示它，但"继续"按钮不可用。
- "初始拥有"各行是纯文本（原版的关键词配色不会复现）。每个文本提供函数在界面每次打开时重新求值，所以 `() => ModHelper.GetLocalized(...)` 能跟随语言切换。
- `ModHelper.GetStartingScenarioId()` / `IsStartingScenario(id)` 可得知本局以哪个方案开始。原版 ID：`apprentice`、`water_merchant`、`junker`、`fence`、`hydroponic_farmer`、`gunsmith`、`chemist`、`organ_trader`、`rock_bottom`、`street_food_vendor`、`rancher`、`moonshiner`、`pharmacist`。`ModHook.OnNewGameStarted(id)` 在每局新游戏放置完初始物品后触发，原版或模组方案都会。
- `ModHelper.OpenNewGameSpecialization()` / `CloseNewGameSpecialization()` 可从你自己的代码打开和关闭该窗口（主菜单场景）。

---

## 起始天赋

新游戏的"天赋"（Perks）步骤会列出玩家可以挑选的起始天赋（节俭、糟糕的租约、哨兵……）。你的模组可以添加自己的天赋：注册一条定义，界面就会把它和原版天赋一起按点数排序列出，悬停提示中显示你的图标、名称和描述。玩家的选择随本局存档保存；由你的模组自己读回并施加效果。

```csharp
public void OnEnable()
{
    ModHelper.AddStartingPerk("my_mod_id", "my_mod_id.night_owl",
        cost: 1,                                        // 正面天赋消耗点数
        type: StartingPerk.StartingPerkType.POSITIVE,
        name: () => ModHelper.GetLocalized("my_mod_id", "perk_night_owl_name"),
        description: () => ModHelper.GetLocalized("my_mod_id", "perk_night_owl_desc"),
        iconKey: "my_mod_id:night_owl_icon");           // 一张白色 32x32 精灵图，按类型着色

    ModHelper.AddStartingPerk("my_mod_id", "my_mod_id.clumsy",
        cost: -1,                                       // 负面天赋提供点数
        type: StartingPerk.StartingPerkType.NEGATIVE,
        name: () => "笨手笨脚",
        description: () => "你总是摔东西。易碎物品更容易损坏。",
        incompatiblePerks: new[] { "my_mod_id.night_owl", StartingPerkList.ALERT });

    ModHook.OnNewGameStarted += scenarioId =>
    {
        if (ModHelper.IsStartingPerkActive("my_mod_id.clumsy")) clumsy = true;
    };
    ModHook.OnGameLoadedNormal += () => clumsy = ModHelper.IsStartingPerkActive("my_mod_id.clumsy");
}

public void OnDisable()
{
    ModHelper.RemoveStartingPerks("my_mod_id");
}
```

规则：

- **在 `Init` 或 `OnEnable` 中注册**，要在玩家打开"新游戏"之前。保持 ID 稳定且唯一（加上你的模组 ID 前缀）：选择按 ID 保存在本局中，用某个天赋开局、而该模组之后被移除的存档会保留该 ID 但没有效果。
- **点数。** 玩家有 3 点和 4 个栏位。正面天赋消耗点数（`cost` 大于零），负面天赋提供点数（`cost` 小于零），中性天赋免费（`cost` 为 0，`StartingPerkType.NEUTRAL`）。`extraPerkSlots` 在被选中时增加栏位，类似"多彩人物"。`incompatiblePerks` 列出不能与你的天赋同时选择的天赋 ID（原版 ID 是 `StartingPerkList` 的常量）。
- **效果由你实现。** 游戏只记录选择。在 `ModHook.OnNewGameStarted` 和 `ModHook.OnGameLoaded*` 中用 `ModHelper.IsStartingPerkActive(id)`（或 `GetStartingPerkIds()`）读取，然后施加天赋的效果。
- **图标。** `iconKey` 走与 `AddImage` 相同的查找（`"modId:spriteName"`）。原版图标是白色 32x32 的图形；界面以 2 倍绘制并按类型着色：绿色（正面）、红色（负面）或琥珀色（中性）。不提供时显示通用天赋图标。
- `mindEditable: true` 允许"心智重编程器"在游戏中途添加或移除该天赋，与原版的心智类天赋相同。
- 文本提供函数在每次提示框打开时重新求值，所以 `() => ModHelper.GetLocalized(...)` 能跟随语言切换。
- `ModHelper.OpenNewGamePerks()` / `CloseNewGamePerks()` 可从你自己的代码打开和关闭该窗口（主菜单场景，选好起始方案之后）。

---

## 难度

难度是一组规则数值，游戏在所有与难度相关的地方读取它们：房租上涨、夜间服务费、Wild 的人情、安保压力，以及各种引导开关。原版难度有 Price Gouge（`cozy`，顺序 100）、Mark Up（`normal`，200）、Thin Margins（`hard`，300）和 Red Ink（`challenge`，400）。你的模组可以添加新难度或修改已有难度；选择界面按顺序列出它们，并根据与普通难度不同的规则生成每个难度的说明。

```csharp
public void OnEnable()
{
    // 介于普通和困难之间的新难度，以普通难度的数值为起点。
    ModHelper.AddDifficulty("my_mod_id", "my_mod_id.lean", order: 250,
        title: () => ModHelper.GetLocalized("my_mod_id", "difficulty_lean_title"),
        subtitle: () => "精简模式",
        configure: rules =>
        {
            rules.rentIncreaseMultiplier = 1.08f;
            rules.tradeFavorRate = 0.02f;
            rules.wildBailout = false;
        },
        notes: new System.Func<string>[] { () => "供应商晚一天补货" }, // 你自己的效果
        iconKey: "my_mod_id:lean_plate");                                 // 卡片的 164x164 图片（可选）

    // 注释背后的效果：在以该难度开始或载入存档时应用。
    ModHook.OnDifficultyApplied += id => slowRestock = id == "my_mod_id.lean";

    // 或者调整原版难度。
    ModHelper.ModifyDifficulty(Difficulty.HARD, d => d.rules.vendorPermitFee = 1000);
}

public void OnDisable()
{
    ModHelper.RemoveDifficulties("my_mod_id");
}
```

规则：

- **在 `Init` 或 `OnEnable` 中注册。** 保持 ID 稳定且唯一（加上你的模组 ID 前缀）：本局存档会保存该 ID。以某个难度开始、而该模组之后被移除的存档会按普通难度进行。
- **`configure` 编辑的是副本**，来自 `basedOn` 指定的难度（默认 `Difficulty.NORMAL`；`Difficulty.HARD` 则从困难开始）。`DifficultyRules` 的每个字段都在 `Difficulty.cs` 中有说明：加价、房租上涨、房租宽限、服务费倍率与首夜加价、鉴定和许可证价格、新顾客折扣、人情比例、安保压力步进、预警、满压力时的游戏结束、救济、提醒、提示。
- **卡片。** 选择界面显示你的 `title`（28 像素大写）、其下的 `subtitle`、效果列表，以及（提供 `iconKey` 时）一张 164x164 的图片（没有时显示占位框）。
- **效果列表是自动生成的。** 界面为每个与普通难度不同的规则组显示一行（"夜间服务费更高"、"交易不再获得 Wild 的人情"……）。`notes` 可为规则无法表达的效果添加行；这些效果请在 `ModHook.OnDifficultyApplied(id)` 中自行实现，它在一局开始和存档载入时触发。
- `ModHelper.GetDifficultyId()`、`GetDifficultyRules()` 和 `IsDifficultyAtLeast(id)`（按顺序比较：`IsDifficultyAtLeast(Difficulty.HARD)` 在困难和挑战难度下都为 true）可得知本局的难度。跳过序章和无尽模式是独立的开关，不属于难度。
- `ModifyDifficulty` 作用于共享的定义，因此两个修改同一规则的模组会互相看到对方的值；最后运行的那个生效。

---

## 夜间地点

卷帘门关闭后，玩家在交通界面选择一个目的地（垃圾场、配给站、杰克逊博士处）。你的模组可以添加自己的地点：注册一个地点后，只要 `isDiscovered` 返回真，界面就会把它排在原版地点之后，显示你的标题和图片。前往那里会运行共享的外出流程（离开商店、显示夜间背包并放入所选的背包），然后运行你的 `onArrive`，再显示你的面板；面板上的返回按钮会经由你的 `onLeave` 把玩家带回商店。

```csharp
public void OnEnable()
{
    var mine = ModHelper.AddAfterhourLocation("my_mod_id", "my_mod_id.black_dock",
        title: () => ModHelper.GetLocalized("my_mod_id", "black_dock_title"),
        imageKey: "my_mod_id:black_dock_card",        // 来自你 Textures 的精灵图，显示在卡片上（296x168）
        backgroundKey: "my_mod_id:black_dock_scene",  // 面板背后的场景（与原版一样为 960x540）
        ambienceId: "my_mod_id.dock",                 // 声音加载完成后在下方注册
        isDiscovered: () => ModHelper.GetModDataBool("my_mod_id", "dock_found"),
        onArrive: () => ModLog.Log("welcome to the dock"),
        buildPanel: builder =>
        {
            builder.AddLabel("今晚的码头很安静。");
            builder.AddButton("搜查货箱", () =>
            {
                ModHelper.MoveItemToAfterhours(ModHelper.SpawnItem("scrap_metal"));
            });
        });

    mine.allowsHazardousWaste = true;                 // 在这里背包可以接受危险废物
    mine.leaveWarning = () => "码头工人会收走你留下的东西。";

    ModHook.OnModAssetsLoaded += mod =>
    {
        if (mod.Manifest.ID != "my_mod_id") return;
        ModHelper.RegisterAfterhourAmbience("my_mod_id", "my_mod_id.dock", "dock_loop");  // Sounds/dock_loop.ogg
    };

    // 你的地点（或原版地点）上的临时事件。卡片会列出一个地点上所有进行中的事件：
    // 标题、可选的描述，以及以项目符号列出的效果；效果的修正值由相关机制读取
    // （所有进行中事件的值会相加）。
    ModHelper.AddAfterhourEvent("my_mod_id", "my_mod_id.fresh_dump", AfterhourLocation.DUMPING_GROUND,
        title: () => "新鲜垃圾", durationDays: 2,
        description: () => "一辆运输车刚倒下一批新货。",
        effects: new[]
        {
            ModHelper.AfterhourEffect(() => "找到垃圾的几率降低 50%", "junk_chance", -50f, AfterhourEffectPolarity.Good),
            ModHelper.AfterhourEffect(() => "受伤几率提高 25%", "injury_chance", 25f, AfterhourEffectPolarity.Bad),
            ModHelper.AfterhourEffect(() => "码头工人在盯着你"),   // 纯文本，中性
        },
        dailyChancePercent: 10f);
}

public void OnDisable()
{
    ModHelper.RemoveAfterhourLocations("my_mod_id");
    ModHelper.RemoveAfterhourEvents("my_mod_id");
}
```

规则：

- **在 `Init` 或 `OnEnable` 中注册。** ID 会被存档（访问次数、计数器、进行中的事件都保存在它名下），所以要保持稳定，并以你的模组 ID 作前缀。`AddAfterhourLocation` 返回它注册的 `DelegateAfterhourLocation`：地点的每个选项都是它的字段（`backgroundSortingOrder`、`usesAfterhourBag`、`showsStoreCounters` 及 `frontCounterPosition` / `backCounterPosition`、`allowsHazardousWaste`、`countsDumpedWaste`、`onTick`、`panelTitle`、`leaveWarning`、`isAvailable`）。你也可以自己继承 `AfterhourLocation`，再传给 `AddAfterhourLocation(location)`。
- **`onArrive` 和 `onLeave` 在黑屏期间运行**，分别在共享的准备之后和共享的返回之前。不要自己打开或关闭背包和商店窗口；用 `SpawnItem` 和 `MoveItemToAfterhours` 生成该地点提供的东西，用 `CustomUIManager` 打开你自己的窗口（返回时它们会随其他窗口一起关闭）。`onTick` 在玩家停留期间每帧运行。
- **面板**由你的 `buildPanel(CustomUIBuilder)` 构建（标签、按钮、开关、滑块、图片：见自定义 UI），返回按钮会加在你的控件之后。`ReturnFromAfterhour()` 可以从你自己的控件返回。模组如果自己构建了面板 GameObject，可以设置 `panelObject`，游戏会激活它而不再生成面板（这时它需要自己的返回控件）。
- **图片与场景。** `imageKey` 和 `backgroundKey` 使用与 `AddImage` 相同的查找方式（`"modId:spriteName"`）。卡片把图片裁剪到 296x168 并保持比例；场景精灵图绘制在原点，排序顺序为 `backgroundSortingOrder`（默认 20；原版美术为 960x540）。模组如果自己构建了场景 GameObject，可以改为设置 `stageObject`，玩家停留期间游戏会激活它。没有图片时卡片显示占位板。
- **`isAvailable`** 返回假时卡片变灰并显示"不可用"，不能前往；`isDiscovered` 返回假时则不显示。两者在每次打开界面时都会询问。
- **我在哪里。** `ModHelper.IsOutsideStore()` 和 `GetCurrentAfterhourLocationId()`；`GetAfterhourLocation(id)` 返回任意地点（原版或模组）的定义，未知 id 返回 null；钩子 `ModHook.OnAfterhourArriveEarly / Late` 和 `OnAfterhourLeaveEarly / Late` 对每个地点（包括原版的 `AfterhourLocation.DUMPING_GROUND`、`COMMISSARY`、`DR_JACKSON`）都会带着地点 ID 触发。
- **状态。** `GetAfterhourVisits(id)`、`GetAfterhourCounter(id, key)` / `SetAfterhourCounter(id, key, value)` 随本局存档保存在地点 ID 名下。
- **事件。** 一个地点上可以同时运行多个事件。带 `dailyChancePercent` 的 `AddAfterhourEvent` 会在它尚未运行时于每天开始自动开始（用 `maxConcurrentEvents` 限制地点上的数量），带 `weekdays`（`AfterhourWeekday.Wednesday`……）的则在空间站一周的那些日子开始（第 1 天是周一；有计划事件开始的那天不会出现随机事件）；`closesLocation: true` 会让地点在事件进行期间不可用（卡片变灰、不能前往，事件仍会列出）；`StartAfterhourEvent(eventId, days)` 从代码添加一个（已在运行的则延长），`EndAfterhourEvent(eventId)` 结束一个，`EndAllAfterhourEvents(locationId)` 结束全部；`IsAfterhourEventActive(eventId)`、`GetActiveAfterhourEventIds(locationId)` 和 `GetAfterhourModifier(locationId, key)`（所有进行中事件之和）读取它们；你自己的机制读取你自己的修正值名称。原版修正值都是在游戏已有几率基础上的相对百分比（效果行写作"几率提高 / 降低 X%"）：垃圾场读取 `injury_chance`（缩放两种受伤几率）、`junk_chance`（缩放战利品掷骰中垃圾表的权重，负值表示更少垃圾）和 `loot_double_chance`（加到扫描仪双倍战利品几率上的百分点）；另有两个不是几率：`injury_immunity`（大于 0 时完全不会受伤）和 `scav_attempts`（每晚固定增加的搜刮次数）。杰克逊博士处读取 `inventor_sell_price`（他店内售价的相对变化），配给站读取 `commissary_restock_percent_of_max`（每天开始时按每件物品最大库存的百分比补货）。原版事件（`fresh_dump`、`georgio_assistance`、`special_stock`、`jackson_discount`、`commissary_burglary`、`fresh_restock`）就使用它们。卡片上的标题在所有效果都有利时为绿色，都不利时为红色，混合时为橙色（传入 `tone` 可强制指定）；剩余天数显示在描述之后。`ModHook.OnAfterhourEventStarted / Ended` 带着地点 ID 和事件 ID 触发。F9 控制台的 `afterhour-events`、`afterhour-event-start` 和 `afterhour-event-end` 可用于测试。

---

## 模组配置

你的模组可以拥有自己的设置面板和一个保存设置的文件，而无需编写任何 UI 或文件代码。定义一次条目，运行时读取它们的值，剩下的由游戏完成：保存、下次启动时恢复，并在"模组"菜单中你的模组的齿轮按钮后面为它们绘制一个配置面板。

```csharp
public class MyMod : IMod
{
    ConfigEntry<float>  courierSpeed;
    ConfigEntry<bool>   fastDelivery;
    ConfigEntry<string> theme;
    ConfigEntry<Difficulty> difficulty;

    public void Init(ModManifest manifest)
    {
        ModConfig config = ModHelper.GetConfig(manifest.ID);

        courierSpeed = config.Define("courier_speed", 1f, "General", () => "Courier speed",
            min: 0.1f, max: 3f, tooltip: () => "Multiplier on courier travel time.");
        fastDelivery = config.Define("fast_delivery", false, "General", () => "Fast delivery");
        theme        = config.Define("theme", "Classic", "Look", () => "Theme",
            choices: new[] { "Classic", "Neon", "Paper" });
        difficulty   = config.DefineEnum("difficulty", Difficulty.Normal, "Gameplay", () => "Difficulty",
            requiresRestart: true);

        courierSpeed.OnChanged += v => RecalculateRoutes();
    }

    void SomewhereLater()
    {
        float speed = courierSpeed.Value;   // 始终是当前已保存的值
        if (fastDelivery.Value) { ... }
    }
}
```

每种条目在面板中对应的控件：

| 定义 | 控件 |
|---|---|
| `bool` | 开关 |
| 带 `min` 和 `max` 的 `int` / `float` | 滑块（`int` 为整数） |
| 不带范围的 `int` / `float` | 文本框，按下"应用"时解析 |
| 带 `choices` 的 `string` | 下拉框 |
| 不带选项的 `string` | 文本框 |
| `DefineEnum<T>` | 枚举名称的下拉框 |

规则：

- **在 `Init`（或 `OnEnable`）中定义。** `Define` 返回时已保存的值已经生效，所以第一次读取 `Value` 就是正确的。键按模组隔离，随意命名即可。
- **值保存在每个模组各自的一个文件中**：`<persistentDataPath>/ModConfigs/<你的模组ID>.json`，一份可读的键值对列表。它在创意工坊更新后仍然保留，且对所有存档槽共用（与本局游戏绑定的数据请用[模组数据](#保存模组数据)）。玩家可以编辑或删除它；缺失的键取默认值，超出范围的数字会被截断，无法解析的值回退到默认值并给出警告，你的模组不再定义的键会被保留。
- **变化通过 `OnChanged` 到达**：玩家在面板中按下"应用"时触发（每个实际改变的条目一次）、你的代码调用 `entry.Set(value)` 时，或 `config.ResetToDefaults()` 时。加载时绝不触发。`ModHook.OnModConfigApplied(modId)` 在每次"应用"时触发一次，供偏好一次性刷新的模组使用。
- **`requiresRestart: true`** 标记只在启动时读取的值；应用后面板会提示玩家重启。
- **标签和提示都是函数**，在构建面板时求值，所以 `() => ModHelper.GetLocalized(...)` 能跟随语言切换。提供 tooltip 会在标签旁加一个信息图标。分区字符串按原样作为标题显示。
- 面板有**恢复默认**（把默认值填入控件；按"应用"前不会生效）和**应用**。可从主菜单的"模组"菜单进入；目前没有游戏内入口。
- 只有**已激活**的模组会运行 `Init`，因此未激活模组的齿轮按钮不可用。

---

## 能力声明与扫描器

模组 DLL 与游戏本体拥有同样的权限，所以游戏无法让一个模组变得"安全"。游戏做的是：把玩家点击**启用**变成一个知情的决定，并准确记住批准的是什么。玩家启用你的模组时，游戏会读取你的 DLL（不加载它们），在写入批准之前按以下顺序检查：

1. 文件夹中的每个 DLL 都列在 `<Assemblies>` 中（未列出的 DLL 会被运行时不经扫描直接加载）；
2. 开发者的远程封禁名单和紧急暂停（被发现有恶意的模组会在数小时内于所有玩家的机器上被拒绝，无需游戏更新）；
3. 所列的每个 DLL 都存在，且没有使用游戏或框架程序集的名字（`0Harmony`、`Assembly-CSharp`、`UnityEngine.*`、`Steamworks.NET`、`mscorlib` 等）；
4. 代码中没有下文[一律拒绝的情况](#一律拒绝的情况)；
5. 你的代码触及的一切都被清单中的 `<Capabilities>` 元素覆盖。

批准会记录清单和所列 DLL 的哈希。此后只要文件仍然一致，或者变化了但没有新增能力，模组就会在每次启动时加载。

### 声明能力

`<Capabilities>` 是必填项，对大多数模组来说是空的：`<Capabilities />`。物品、机器、钩子、对游戏代码的 Harmony 补丁、配置、模组数据、精灵图、音效、本地化、掉落文件、手册、自定义 UI：这些都不需要任何能力。只有当你的代码用到下表所列内容时才需要声明。

| 能力 | 触发条件 | 无需能力的替代方案 |
|---|---|---|
| `files` | `System.IO.File`、`FileStream`、`Directory`、`FileInfo`、`DirectoryInfo`、以路径打开的 `StreamReader` / `StreamWriter`、传入路径的 `XDocument` / `XmlDocument` / `XmlReader` / `XmlWriter`、`ZipFile`、内存映射文件、Windows 注册表（`Registry`）、`ScreenCapture`、`AssetBundle`、`UnityEngine.Windows.File`；Easy Save：`ES3File`、`ES3Writer`、`ES3Reader`、`ES3Directory`、带路径或两个字符串（键和文件）的 `ES3` 方法、`new ES3Settings(path)` 和 `settings.path =`（按键的 `ES3.Save(key, value)` 是免费的） | 设置用 `ModHelper.GetConfig`，局内数据用 `SetModData`，文件用 `ReadModFile*` 和 `*ModDataFile*`（见下文） |
| `network` | `System.Net.*`（`HttpClient`、`WebClient`、套接字；`WebUtility` 和 `IPAddress` 除外）、`UnityWebRequest`、`WWW`、`Ping`、Steam 的 HTTP 与网络 API | 无，请声明 |
| `process` | `System.Diagnostics.Process`、`ProcessStartInfo`、`Application.OpenURL`（它调用 ShellExecute，可以启动程序） | 无，请声明 |
| `dynamic-code` | `Assembly.Load*`、`AppDomain.Load`、`Reflection.Emit`、`Activator.CreateInstanceFrom`、`Activator.CreateInstance(assemblyName, ...)`、编译表达式树（`Expression.Compile()`）、`BinaryFormatter` 及其他 `Formatters` 反序列化器、`CSharpCodeProvider` | 无，请声明 |
| `native` | `DllImport`、`unsafe` 代码与指针、`calli`、`Marshal`、`UnsafeUtility` | 无，请声明 |
| `reflection-external` | `Type.GetType`、`GetMethod` / `GetField` / `GetProperty` / `InvokeMember`、`Assembly.GetType` / `GetTypes`、使用**拼接出的**名称或类型的 `AccessTools` 或 `Traverse`，或者字面名称位于 `System.`、`UnityEngine.`、`HarmonyLib.`、`Steamworks.`、`ES3` 之下；C# 的 `dynamic` 关键字（它编译为运行时绑定器） | 用 `typeof(GameItem)` 或游戏类型的字面名称反射游戏类型：这是免费的 |

只有游戏自己的类型（`Assembly-CSharp`）和你自己的类型可以自由反射。扫描器会沿 IL 回溯到产生类型或名称的那条指令；无法判断时（值来自变量、分支、方法调用）按"拼接"处理，所以请优先写 `AccessTools.Method(typeof(PlayerStore), "ModCash")` 而不是用字符串拼出的 `AccessTools.Method("PlayerStore:ModCash")`，优先用 `typeof(X)` 而不是 `someObject.GetType()`。

多声明是允许的，玩家只是会看到更长的列表。用到却没声明会导致启用被拒绝，并列出发现的内容。

### 一律拒绝的情况

有些模式无论清单怎么写都会拒绝启用，因为正常模组不需要它们：

- 嵌入资源是可执行文件，或任何看起来像加密数据的资源（高熵且不是已知的图片、音频、文本或 `.resources` 格式）；
- 指向浏览器配置、Steam 登录文件、Discord 数据或加密货币钱包的字符串常量；
- 1024 个或更多 base64 字符组成的字符串常量（隐藏的载荷）；
- 传入字面 `null` id 的 `Harmony.UnpatchAll()`（它会移除所有模组的补丁，包括游戏自己的修复）；
- 针对游戏模组加载器或信任代码的 Harmony 补丁或反射：`ModLoader`、`ModTrust`、`ModTrustRecord`、`ModFingerprint`、`ModTrustList`、`ModScanner`、`ModCapability`、`ModSecurityDebug`；
- 自带 `0Harmony`、MonoMod 或 Cecil，或任何与游戏程序集同名的 DLL（包括游戏已经附带的库，例如 `Newtonsoft.Json`）。请引用游戏自带的副本；
- 文件夹中有 `<Assemblies>` 未列出的 DLL，或者所列 DLL 引用了既不是游戏的、也未列出的程序集。运行时会不经扫描直接从你的文件夹加载这种文件，所以整个模组会被拒绝，直到清单把它列出来。

你捆绑的第三方库会像你自己的代码一样被扫描，而且必须列出。其中许多在内部使用反射或 `Reflection.Emit`，这就需要写进你的 `<Capabilities>`；请优先使用游戏已经附带的库。图片、音频、JSON、XML 或 `.resources` 文件作为嵌入资源没有问题。

### 发布前自查

打开控制台（F8），运行 `mod-scan <你的模组ID>`（任何已列出的模组，启用与否均可）或 `mod-scan <文件夹路径>`。它会打印所列程序集、文件夹中未列出的 DLL、扫描了多少方法、清单声明的能力（`declared`）、扫描器检测到的能力（`detected`）、每条发现（格式为 `能力: 类型.方法 -> 引用了什么`）、所有一律拒绝的标记、某个 DLL 无法读取时的 `ERROR:` 行，以及一行 `fingerprint:`，即这个确切版本的哈希，批准记录和开发者名单引用的就是它。修改清单直到 `declared` 覆盖 `detected` 且没有一律拒绝的标记。如果某条发现出乎意料，方法名告诉你该看哪里；大多数 `reflection-external` 发现改用 `typeof(...)` 就能消除。

像玩家一样测试时还有两个有用的命令：`mod-trust` 列出这台电脑上记录的批准（哈希、能力、开发者模式，创意工坊模组还有物品和发布者 id）以及本次会话中每个模组的信任状态；`mod-trust-list` 显示开发者远程名单的状态。F8 控制台是 Quantum Console：`user-commands` 列出游戏自己的命令（`loot-list`、`mod-scan` 等），`all-commands` 列出全部命令，包括引擎级的。

**发布前**过一遍这份清单：`mod-scan` 无问题、`<Capabilities>` 不多于实际需要、每个 DLL 都列在 `<Assemblies>` 中、没有捆绑游戏已经附带的库、`<ModVersion>` 已递增。玩家的批准记录了你文件的哈希：不新增能力的更新继续加载，新增能力的更新要等每位玩家重新审核，所以请在首次发布前而不是之后决定好你的能力。

### 玩家看到什么

- **启用**一个 `<Capabilities>` 为空的模组直接生效。声明了能力的模组会向玩家显示确认框，用通俗的话列出这些能力（"访问互联网"、"启动其他程序或打开链接"等），并提醒这样的模组能做玩家能做的任何事；被开发者列入验证名单的版本会跳过这个确认框。被拒绝的模组会显示原因。
- 详情面板显示你的能力和批准状态：在某日批准、已更新但无新增能力、已由开发者验证，或者未加载的原因。
- **更新**：文件完全一致则加载。文件变化但没有新增能力也会加载，面板会注明已更新。文件变化且新增了能力，或新版本未通过扫描，则不会加载；该行显示警告，面板提供**审核并启用**按钮，重新执行启用检查。请在首次发布前规划好能力：之后再新增会打断每一位玩家。
- **停用**会撤回批准；下次启用会重新经过检查。
- 在远程**封禁名单**上的模组无法启用，在已启用它的机器上会在下次启动时被关闭，并显示原因（正在运行的副本会一直运行到那次重启）。紧急情况下，开发者可以暂停全部模组加载直到修复发布；"模组"菜单会说明，面板会显示"未加载：模组加载已被开发者暂停"。
- 第一次打开"模组"菜单时，游戏仍会告诉玩家模组可能包含代码。

### 开发者模式

在本地（`Mods/` 中）开发模组时，每次重新编译都会改变哈希。模组启用过一次之后，本地模组的详情面板会出现**开发者模式**按钮：打开后，该文件夹的每次重新编译都会在启动时直接加载而无需重新批准，即使新版本用到了你尚未声明的能力（只有扫描器直接拒绝时控制台才会警告）。它不覆盖两件事：文件夹中 `<Assemblies>` 未列出的 DLL 仍然会阻止模组加载；下一次**启用**或**审核并启用**仍然按完整规则检查，所以发布前请运行 `mod-scan`。它按模组、按电脑生效，默认关闭。创意工坊副本永远没有它；接管已订阅物品 id 的本地文件夹必须先以本地模组的身份批准一次，按钮才会出现。

### 不声明能力也能读写文件

`ModHelper` 提供的辅助方法只在两个文件夹内活动，所以只用它们的模组无需声明任何能力：

```csharp
// 只读：你的模组文件夹（Mods/<文件夹> 或创意工坊物品）。只接受相对路径。
string notes = ModHelper.ReadModFileText("my_mod_id", "Data/notes.txt");      // 不存在时返回 null
byte[] blob  = ModHelper.ReadModFileBytes("my_mod_id", "Data/table.bin");
bool has     = ModHelper.ModFileExists("my_mod_id", "Data/notes.txt");

// 读写：存档位置下属于你的文件夹（persistentDataPath/ModData/my_mod_id/）。
ModHelper.WriteModDataFileText("my_mod_id", "cache/prices.json", json);
string cached = ModHelper.ReadModDataFileText("my_mod_id", "cache/prices.json");
ModHelper.DeleteModDataFile("my_mod_id", "cache/prices.json");
List<string> files = ModHelper.ListModDataFiles("my_mod_id");
string folder = ModHelper.GetModDataFolder("my_mod_id");                      // 需要展示路径时用
```

绝对路径、空路径或逃出文件夹的路径（`../`）会抛出 `ArgumentException`。不要往模组文件夹里写入：Steam 每次更新都会覆盖创意工坊文件夹。与一局游戏绑定的数值仍应使用 `SetModData`（见[保存模组数据](#保存模组数据)）；设置请用[模组配置](#模组配置)。

---

## Steam 创意工坊

玩家除了从 `Mods/` 文件夹获取模组，也可以从游戏的 Steam 创意工坊页面获取。一个创意工坊物品就是一个模组文件夹，与[模组资源](#模组资源)中描述的完全一致，根目录带有 `manifest.xml`；游戏会用与本地模组相同的加载器从 Steam 的安装位置加载它。你的代码不需要任何改动。

玩家看到的是：

- 已订阅的物品会出现在"模组"菜单中，带有 Steam 图标，并且初始为**未激活**。玩家像激活其他模组一样激活它，然后需要重启游戏才会生效。游戏运行期间订阅的物品会在下次启动后出现。
- "模组"菜单显示该物品的创意工坊预览图（即你上传的 `previewfile`，见下文）。物品文件夹中的 `preview.png` 只在 Steam 没有预览图或离线时使用。没有任何图片的模组不显示横幅。
- "模组"菜单中的**取消订阅所选**会移除一个创意工坊模组：它的行会立即消失并被停用，Steam 会删除其文件。如果它正在运行，会一直运行到游戏重启。"激活"旁边的 Steam 按钮会打开该物品的创意工坊页面（在 Steam 游戏内界面中打开；如果关闭了游戏内界面，则在浏览器中打开）。
- 游戏启动时已订阅但尚未下载的物品会在后台下载；"模组"菜单会显示还有多少个正在下载，它们会在下次重启后出现。
- 如果 `Mods/` 中的本地文件夹与某个已订阅物品有相同的 `<ID>`，将使用本地副本并忽略创意工坊副本。第一次用本地副本启动时，它会显示为"未加载：自你批准后已更改（它现在来自与已批准副本不同的地方）"：点一次**审核并启用**，之后它的**开发者模式**按钮才会出现。这就是你在不取消订阅的情况下测试自己模组新版本的方式。"模组"菜单会在该本地模组上注明这一点，它的 Steam 按钮和"取消订阅"作用于该创意工坊物品（取消订阅后本地副本保留）。
- 第一次打开"模组"菜单时，游戏会提醒玩家模组可能包含代码。请记住这一点：一个行为不端的模组会损害所有模组作者的声誉。

创意工坊仅在正式版游戏上可用，试玩版没有。

### 用 steamcmd 发布

游戏中没有上传按钮。物品通过 Valve 的 `steamcmd` 工具发布，需要使用一个拥有本游戏的 Steam 账号：

1. 安装 [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD)，确保你的模组文件夹根目录有 `manifest.xml`，最好再放一个小于 1 MB 的 `preview.png`。
2. 编写一个物品描述文件，例如 `my_mod.vdf`：

```
"workshopitem"
{
    "appid"            "4348910"
    "publishedfileid"  "0"
    "contentfolder"    "C:\\Games\\ProbablyStolen\\Mods\\MyMod"
    "previewfile"      "C:\\Games\\ProbablyStolen\\Mods\\MyMod\\preview.png"
    "visibility"       "0"
    "title"            "My Mod"
    "description"      "What the mod does."
    "changenote"       "First release"
}
```

`publishedfileid` 为 `0` 时创建新物品。`visibility`：`0` 公开，`1` 仅好友，`2` 隐藏（第一次测试请用隐藏）。

3. 运行：

```
steamcmd +login <你的Steam账号> +workshop_build_item "C:\path\to\my_mod.vdf" +quit
```

steamcmd 会打印新物品的 ID 并把它写回 `.vdf`。请保留该文件：填入 ID 后再次运行同一命令即为**更新**已有物品，订阅者会自动收到新版本。首次上传还需要在 Steam 网站上接受一次创意工坊法律协议。

提示：清单中的 `<GameVersions>` 是"模组"菜单用来给兼容性着色的依据，更新时请保持最新；把你的模组依赖的其他模组列在 `<Prerequisites>` 中，并在创意工坊描述里也提一下，因为 Steam 不会自动订阅它们。

---

## Harmony 补丁

> ⚠️ **有原生钩子时优先用钩子。** Harmony 有可测量的运行时开销，而且比原生模组 API 对游戏更新更敏感。如果某个[钩子点](#钩子点)覆盖了你的需求，就用它。只有当没有钩子暴露你想介入的时刻时才用 Harmony；这正是它的用途。

Harmony 是一个运行时修补库，让你能在游戏中任意方法之前、之后注入代码，或者替换它。[README.zh-CN.md](README.zh-CN.md) 快速入门中的 `.csproj` 已经包含了 `0Harmony.dll` 引用。

### 补丁会自动应用

你不需要自己调用 `Harmony.PatchAll()`。游戏会扫描每个已加载的模组程序集，并应用它找到的每个 `[HarmonyPatch]` 类。只要声明补丁类（见下文），模组一启用它们就会生效。

> ⚠️ **模组扫描器如何看待补丁。** 修补游戏代码不需要声明任何能力。玩家启用模组时有三种情况会被直接拒绝：针对加载器或信任代码（`ModLoader`、`ModTrust*`、`ModFingerprint`、`ModScanner`、`ModCapability`、`ModSecurityDebug`）的补丁；传入字面 `null` id 调用的 `Harmony.UnpatchAll()`（它会移除所有模组的补丁）；以及自带 `0Harmony.dll`。请使用游戏自带的副本。应用你补丁的 `Harmony` 实例由加载器持有（`ModLoader.Mods.Find(m => m.Manifest.ID == "my_mod_id").HarmonyInstance`，id 为 `"mod.my_mod_id"`）；如果你为手动应用的补丁创建了自己的实例，请用它自己的 id 撤销，绝不要不带 id。通过 `AccessTools` 或反射触及 Unity、.NET 或 Harmony 内部，或者在运行时用字符串拼出类型和成员名，都算作 `reflection-external` 能力；`typeof(游戏类型)` 和游戏类型的字面名称是免费的。详情见[能力声明与扫描器](#能力声明与扫描器)。

### Postfix：在原方法之后运行

**Postfix** 在原方法完成后运行。用它观察结果；当方法有返回值时，可以添加一个名为 `__result` 的 `ref` 参数来读取或修改返回值。（`GenerateClient` 返回 `void`，所以下面的例子只做观察。）

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class PrintLog
{
    // Postfix 在原方法之后运行。
    static void Postfix()
    {
        Debug.Log("[TestMod] StoreClientManager.GenerateClient called.");
    }
}
```

### Prefix：在原方法之前运行

**Prefix** 在原方法之前运行。返回 `false` 会完全跳过原方法；返回 `true`（或 `void`）则让它正常运行。

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class SkipClient
{
    static bool Prefix()
    {
        Debug.Log("[TestMod] Skipping client generation.");
        return false; // 原方法不会运行
    }
}
```

### Finalizer：即使原方法抛出异常也会运行

**Finalizer** 在原方法之后运行，即使它抛出了异常。用它做清理，或者吞掉、替换异常。返回 `null` 吞掉异常；返回一个 `Exception` 实例则替换它。

```csharp
[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class SwallowErrors
{
    static Exception Finalizer(Exception __exception)
    {
        if (__exception != null)
        {
            Debug.LogError($"[TestMod] GenerateClient threw: {__exception.Message}");
        }

        return null; // 吞掉异常，让游戏继续运行
    }
}
```

### Transpiler：改写原方法的 IL（进阶）

**Transpiler** 在原方法运行之前改写它的 IL 指令。这是最强大的补丁类型，也是最脆弱的；游戏的小更新就可能让匹配特定操作码模式的 transpiler 失效。只有当 Prefix / Postfix / Finalizer 无法表达你的需求时才用它。

```csharp
using System.Collections.Generic;
using HarmonyLib;

[HarmonyPatch(typeof(StoreClientManager), nameof(StoreClientManager.GenerateClient))]
public static class TweakClient
{
    static IEnumerable<CodeInstruction> Transpiler(IEnumerable<CodeInstruction> instructions)
    {
        foreach (var instr in instructions)
        {
            // 在这里检查、替换或插入 IL。
            // 这个直通实现原样返回原始 IL。
            yield return instr;
        }
    }
}
```

完整参考请见 [Harmony 文档](https://harmony.pardeike.net/)，包括注入参数名（`__instance`、`__state`、`___privateField` 等）。

---

## 故障排查

先打开 **F8 控制台**：每个模组都会记录它的加载结果、资源数量以及修补了多少个 Harmony 方法，全部带有 `[ModLoader]` 或你的模组名前缀。

| 症状 | 可能原因 |
|---|---|
| 模组没有出现在模组菜单中 | 清单缺失或无效，加载器跳过了该文件夹：模组根目录没有 `manifest.xml`，`<ID>` 为空或无效（只允许字母、数字、`_`、`-`、`.`），缺少 `<Assemblies>` 或 `<Capabilities>` 元素，`<Assemblies>` 下没有 `<Assembly>`，程序集路径是绝对路径、含有 `..` 或不以 `.dll` 结尾，能力名称未知（这些都记录为 `[ModLoader] ...`），或者所列 DLL 不存在、所列 DLL 中没有实现 `IMod` 的类（记录为 `[你的模组名] Error: ...`）。启动日志会指出确切问题。 |
| 模组出现了但什么都没发生 | 模组没有启用，或者启用后没有重启。**启用、禁用和重新排序都要到下次启动才生效。** |
| 模组已启用，但显示警告图标和"未加载：……" | 这次启动信任检查没有放行它。*尚未在这台电脑上批准*：选中它并点击**审核并启用**。*自你批准后已更改（原因）*：你的文件以需要重新批准的方式变化了；原因是以下之一："新版本需要新的能力"、"新版本使用了未声明的能力"、"新版本被模组扫描器拒绝"、"文件夹中包含清单未列出的 DLL"、"它现在来自与已批准副本不同的地方"或"它是另一个创意工坊物品"（本地副本与订阅之间切换）、"无法检查它的文件"（DLL 被你的编译或杀毒软件锁定）。按提示修正，再**审核并启用**。*已被开发者封禁*：该版本在远程封禁名单上。*模组加载已被开发者暂停*：面向所有人的紧急暂停，你这边无需做任何事。开发本地模组时，在详情面板打开**开发者模式**，重新编译就无需这一步。 |
| 启用被拒绝：使用了清单未声明的能力（"uses capabilities its manifest does not declare"） | 在 F8 控制台运行 `mod-scan <id>`：每条发现都指出方法和它触及的 API。要么在 `<Capabilities>` 中声明该能力，要么改用无需能力的替代方案（见[声明能力](#声明能力)中的表格）。大多数 `reflection-external` 发现改用 `typeof(游戏类型)` 代替字符串就能消除。 |
| 启用被拒绝：被模组扫描器拒绝（"refused by the mod scanner"），或文件夹中有清单未列出的 DLL（"DLLs in its folder that its manifest does not list"） | 一律拒绝的情况：文件夹中有未列出的 DLL，或引用了既不是游戏的也未列出的程序集；嵌入了可执行文件或加密资源；可疑的字符串常量；传入 `null` id 的 `UnpatchAll()`；针对加载器的补丁；或自带 `0Harmony`。`mod-scan` 会指出是哪一条。见[一律拒绝的情况](#一律拒绝的情况)。 |
| 控制台中出现 `[你的模组名] Error: ...`，模组菜单中你的模组旁有警告图标 | 你的 DLL 加载失败（缺少它引用的库，或目标框架不对），某个 DLL 使用了游戏程序集的名字，或者 `Init`、`OnEnable` 或某个 Harmony 补丁抛出了异常。这一行写明了异常，后面紧跟完整的堆栈跟踪。`Mods/` 文件夹中的模组加载失败时，控制台会在启动时自动打开（创意工坊模组只显示警告图标）。该模组仍留在已启用列表中，方便你停用它。 |
| 代码改动没有生效 | 你复制的是旧 DLL。重新构建（`dotnet build -c Release`）；用 `create-mod.bat` 创建的项目会自动安装到 `Mods\`，否则把 `bin/Release/netstandard2.1/` 中新鲜的 DLL 复制到模组文件夹。然后看一下模组菜单：重新编译会改变哈希，没有打开**开发者模式**时模组可能在等待**审核并启用**。 |
| 我捆绑的库被拒绝，或迫使我声明能力 | 你附带的每个 DLL 都必须列在 `<Assemblies>` 中，并且会像你的代码一样被扫描。游戏已经附带的库（`0Harmony`、`Newtonsoft.Json`、Unity 程序集）完全不能捆绑；请引用游戏的副本。其他在内部使用 `Reflection.Emit` 或反射的库，会让这些能力变成你需要声明的能力。 |
| 物品显示"未知"占位精灵图 | 传给 `SetSpriteAndShapeFromMod` 的 `spriteKey` 或模组 ID 不匹配。键是**文件名**（不含扩展名和文件夹）；ID 是你清单中的 `<ID>`，**不是**文件夹名。检查控制台中的 `item sprite(s) loaded` 数量。 |
| 某个精灵图文件被完全忽略 | 它没有*直接*放在 `Textures/Items/` 下（子文件夹不会被扫描），或者它不是 `.png`/`.jpg`。 |
| `PlaySound` 返回 false / 警告 `Audio identifier ... was not found` | 模组 ID 或声音键不匹配。完整标识是 `<清单 ID>:<不含扩展名的文件名>`。检查控制台中的 `sound(s) loaded` 数量。声音也会在启动后几帧才加载完成（如果播放得很早，请[等待它们](#如何知道资源已就绪)）。 |
| `GetLocalized` 返回键本身 | 当前语言的 CSV 或 `en.csv` 中没有该键的条目，或者文件名与游戏的语言代码不匹配。查找一次性的 `[ModHelper]` 警告，并检查控制台中的 `localization entries loaded` 数量。 |
| 警告 `requires '<id>' which is not loaded/enabled` | 你的清单在 `<Prerequisites>` 中列出的模组没有启用。启用它，或者去掉这个依赖。 |
| Harmony 补丁从不运行 | 目标类型/方法名写错了，或者模组被禁用了；补丁只在启动时应用于**已启用**的模组。 |
| 我的物品从不掉落 | 在控制台运行 `loot-list <tableId>`。如果条目不在，说明表 ID 写错了或编辑被拒绝了（查找指明你的模组的 `[LootRegistry]` 警告）。如果在，检查百分比：原版表中权重 `10` 约为 1%。 |
| 警告 `[LootRegistry] ... which does not exist` | 你的编辑或 JSON 文件中的表或表组 ID 与任何表都不匹配。`loot-list` 会打印所有 ID。注册自己的表时，先注册，再对它打补丁或加入表组。 |
