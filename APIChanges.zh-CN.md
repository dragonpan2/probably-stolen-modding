# Probably Stolen：模组 API 变更

English version: [APIChanges.md](APIChanges.md)

按游戏更新记录模组 API 的变化，最新的在最上面。每次更新内部按重要性排序：需要你立即处理的在前，新增能力在后。完整文档见 [ModdingGuide.zh-CN.md](ModdingGuide.zh-CN.md)。

## 2026年11月8日

**必须处理**

- **声明了 `files` 或 `network` 的创意工坊模组自 2026 年 12 月 10 日起需要开发者验证。** 这两种能力加在一起就是一个完整的凭据窃取程序，而仅凭确认框并没有阻止玩家批准它们。从那天起，声明了其中之一的创意工坊模组只有当其 id 在已签名的验证名单上时才会加载（按哈希验证一个版本，或用 `"*"` 验证所有版本）；在那之前，模组菜单显示"使用了文件或互联网，且未经开发者验证"，`mod-scan` 打印一行 `VERIFICATION`，其他没有变化。发布前请在模组频道申请验证；经过验证的模组还会跳过能力确认框。`Mods/` 中的本地文件夹永远不受此限制。[详情](ModdingGuide.zh-CN.md#使用文件或互联网的创意工坊模组需要验证)
- **`ModHelper.Lookup` 取得的服务带有提供方的能力。** 只有自己的清单声明了提供方声明的全部能力的模组才能拿到另一个模组的服务；否则 `Lookup` 返回 null 并记录一次日志。没有能力的模组不能再通过 `files` 模组暴露的辅助对象写文件。想服务所有人的提供方应暴露不需要能力的服务。
- **第四种能力 `threads` 以同样的方式弃用，2026 年 12 月 10 日的更新将拒绝它。** 它是新增的，且自动检测：`new Thread` / `Thread.Start`、`ThreadPool.QueueUserWorkItem`、`System.Threading.Timer`、`System.Timers.Timer`、`Task.Run`、`new Task`、`Task.Start`、`Task.Delay`、`ContinueWith`、`Task.Factory.StartNew`、`Parallel.*`，以及在不属于你自己的 MonoBehaviour 上调用 `StartCoroutine` / `Invoke` / `InvokeRepeating`。原因在于停止：当开发者封禁某个模组或暂停全部模组时，游戏现在会立即停止它（补丁、`ModHook` 订阅、它自己类型的 MonoBehaviour、它通过 `ModHelper` 启动的协程和后台工作、它暴露的内容），而模组自己启动的线程是唯一没有人能停止的东西。替代方案全部随模组一起取消：`ModHelper.StartCoroutine(modId, routine)`、`StopCoroutine`、`StopAllCoroutines`、`Delay(modId, seconds, action)`、`RunInBackground(modId, token => work, onFinished)` 和 `RunOnMainThread(modId, action)`。在你自己的组件里，`this.StartCoroutine` 和 `Invoke` 仍然免费。12 月 10 日之前，使用了 `threads` 却没有声明的模组仍能启用：该能力会出现在玩家的确认框中，模组菜单也会警告。[详情](ModdingGuide.zh-CN.md#后台工作)
- **游戏之外的补丁目标算作 `reflection-external`。** `[HarmonyPatch(typeof(System.IO.File), "WriteAllBytes")]`、`[HarmonyPatch("UnityEngine.Application", "OpenURL")]` 或用 `AccessTools` 在系统类型上取得的目标，曾是不在调用中指名就能触及系统代码的最后一条路；现在它们和任何反射目标一样被判断（已弃用，2026 年 12 月 10 日起拒绝）。对游戏代码、你自己或前置模组的类型以及 `UnityEngine.UI`、`TMPro`、`UnityEngine.EventSystems` 的补丁是免费的。Transpiler 按它指名的内容判断：`CodeInstruction.Call(typeof(X), "Y")` 和其他静态 `CodeInstruction` 辅助方法遵循 `AccessTools` 的规则。
- **标有 `[ModRestricted]` 的游戏辅助方法自 2026 年 12 月 10 日起按其指明的规则计算。** 模组调用 `SaveFiles.RestoreFromHistory`、`QuarantineFile`、`IsSaveFileIntact` 和 `ImportFromFile` 时将算作 `files`（调用者指定路径的文件）；`PaperEditorFiles.OpenFolder` / `OpenFile` 和 `ModUIManager.OpenModFolder` 将像 `Process` 一样被拒绝（用系统外壳打开文件夹或文件）。在那之前 `mod-scan` 把这类调用列为 "files (from December 10, 2026)"，不计入任何能力。游戏代码不受影响；该特性只对扫描器说话，`mod-scan` 会显示它的原因。这个列表会随着此类辅助方法的添加而增长。[详情](ModdingGuide.zh-CN.md#一律拒绝的情况)
- **信任层自己的写入方法对模组关闭，扫描时和运行时都是。** `ModLoader.SetModEnabled`、`ReorderMods`、`ForgetMod`、`ApproveAndEnable`、`SetDeveloperMode`，`ModTrust.Approve`、`Refresh`、`Revoke`、`MarkStopped`、`SetDeveloperMode`、`StoreFolderHash`，`ModTrustList.LoadUnsigned`、`TryFetchBlocking` 和 `ModWorkshop.Unsubscribe` 过去是公开可调用的：一个模组可以不经玩家确认就批准另一个模组、撤销竞争对手的批准，或取消订阅物品。现在从模组代码调用它们是 `loader-target` 拒绝，运行时只要调用栈上有模组（Harmony 替换方法体也算）就会抛出异常。`ModLoader.Mods` 返回副本，加载器自己保存每个模组的 Harmony 实例和指纹，所以清空公开的 `LoadedMod` 字段或编辑列表不再能让模组躲过封禁或停止。对 `ModHelper`、`ModConfig`、`ModHook`、`PaperBookRegistry` 和 `ModReflect` 的审查认为其路径与归属检查是可靠的。只读取这些类的模组没有变化。
- **审计行现在也写入存档数据旁的 `mod-audit.log`**，由加载器在任何模组运行之前写入，因为任何模组都能往 Unity 日志里打印一行伪造的 `[ModLoader] audit:`。事故手册读取这个文件。主线程上的绊线命中现在在同一次调用中就停止模组，而不是等到下一帧。
- **扫描器能读懂更多反射，而不再判为拼接。** 只赋值一次的局部变量里的 `Type`，或编译器留在栈上的 `Type`，会被回溯到它的 `typeof`、`Type.GetType("...")`、`assembly.GetType("...")` 或 `AccessTools.TypeByName("...")`，所以常见的 `Type t = typeof(PlayerStore); t.GetField("x")` 是免费的。泛型 `AccessTools` 重载（`FieldRefAccess<T, F>("name")`）只按类型参数判断。`TypeByName` 或 `"Type:Member"` 字符串里的裸类型名必须是游戏或你的模组的类型，否则按拼接处理（Harmony 会把 `"Process"` 解析为系统类型）。已用若干已发布的创意工坊模组经扫描器验证。
- **对字面引擎或系统成员的反射按调用来判断。** `typeof(List<GameItem>).GetConstructor(...)`、`AccessTools.Method(typeof(string), "Concat")`、`typeof(object).GetMethod("MemberwiseClone")`：字面类型加字面成员走与直接调用相同的规则（除非该成员被拒绝或需要能力，否则免费），所以 Transpiler 和对 BCL 的 `MethodInfo` 查找不再需要 `reflection-external`。拼接出的类型或名称，以及对 `System.Type`、`System.Reflection.*` 或 Harmony 自身辅助类型的反射，仍属于 `reflection-external`。
- **来自阅读一个真实创意工坊模组的两处扫描器修正。** Harmony Transpiler 处理的 `OpCode`、`OpCodes`、`Label`、`LocalBuilder` 和 `ILGenerator` 不再算作 `dynamic-code`（没有 `DynamicMethod` 或 `TypeBuilder` 它们生成不了任何东西，后两者仍然计入），所以 Transpiler 模组不必再声明、之后又失去这项能力。`某程序集.GetType("字面名")` 之后的查找按字面名称读取，与 `Type.GetType("字面名")` 一样：在游戏程序集里探测旧版本没有的类是免费的。
- **三项扫描器与绊线加固。** 类型标记和泛型参数像调用一样被分类（`typeof(FileStream)`、`Activator.CreateInstance<WebClient>()` 算作 `files` / `network`），所以通过 `Activator` 创建文件或网络客户端不再能绕过规则。对 `[ModRestricted]` 成员的补丁按该成员的规则计算，整个 `SaveFiles` 类带有该标记：改写存档方法路径参数的 Prefix 被视同调用它。参数不是网址的 `Application.OpenURL` 现在在运行时被拦截，只要调用栈上有模组（包括被改写的游戏方法），与 `Process.Start` 一样；该模组会被停止。
- **三项加载器加固，一切正常时不可见。** 信任存储（玩家的批准记录）用每台安装独有的密钥签名：在游戏之外被编辑过的存储会丢弃全部批准（每个已启用的模组显示"审核并启用"），并保留停止记录。当有已启用的模组且缓存的信任名单超过六小时时，启动会在加载前最多等待三秒获取新名单，这样自上次启动以来被封禁的模组不会再多运行一次。每个 DLL 在 `Assembly.LoadFrom` 之前会再次计算哈希，必须与信任检查批准的一致，否则算作加载错误，所以启动期间被替换的文件永远不会加载。
- **批准现在覆盖模组文件夹中的每一个文件。** 信任记录除了清单和 DLL 的哈希之外还保存文件夹的哈希；只替换了已批准 DLL 旁边的数据文件或贴图的创意工坊更新会被视为更新（重新运行文件夹扫描，对玩家没有其他变化）。已有的批准会在下一次匹配的启动时学到文件夹哈希。远程名单和 `mod-scan` 打印的版本哈希不变。
- **`native` 和 `dynamic-code` 能力同样已弃用，同一次 2026 年 12 月 10 日的更新将拒绝它们。** 它们与 `reflection-external` 一起，是扫描器看不透的三种能力：一个 `DllImport`、一个指针或 `calli` 能在没有任何可供扫描器检查的名称的情况下运行任何东西，而运行时加载或生成的代码（`Assembly.Load`、`Reflection.Emit`、`Expression.Compile`、`Formatters` 反序列化器）是扫描器从未见过的代码。`mod-scan` 的 `DEPRECATED` 行和模组菜单的提示会指出模组用到了三者中的哪些。替代方案：为了性能而编译的表达式树改用 `ModReflect.Method<TDelegate>`（只查找一次的已绑定委托）；不带 `TypeNameHandling` 的 `Newtonsoft.Json` 和 `JsonUtility` 一直是免费的；原生代码没有替代，因为游戏模组不需要它（如果某个功能只能通过原生代码触及，请申请一个 `ModHelper` 入口）；脚本或插件框架无法在创意工坊上发布。内部使用指针或 `Reflection.Emit` 的捆绑库从那天起会导致模组被拒绝，所以请选用不这样做的库。本地开发者模式仍会加载这三种能力，供工具和实验使用。模组菜单的提示现在是"使用了下一次游戏更新将拒绝的能力（……）"（`ui_mods_issue_deprecated_capability`），12 月之后的拒绝提示是"声明了模组已不能再使用的能力"（`ui_mods_enable_refused_capability`），都会列出这些能力；`ModCapability.Unscannable` 保存这三个 id，`ModScanner.REFUSE_UNSCANNABLE_CAPABILITIES` 是开关（`REFUSE_REFLECTION_EXTERNAL` 转发到它），`FLAG_NATIVE` 和 `FLAG_DYNAMIC_CODE` 是标记 id，`ModScanResult.DeprecatedCapabilities` / `UsesDeprecatedCapability` 是结果。
- **`reflection-external` 能力已弃用，2026 年 12 月 10 日的游戏更新将直接拒绝它。** 它涵盖扫描器无法读取目标的反射：拼接出的接收者（`someObject.GetType().GetField(...)`）、运行时拼出的类型或成员名、针对 `System.`、`UnityEngine.`、`HarmonyLib.`、`Steamworks.` 或 `ES3` 之下任何内容的 `Type.GetType` 或 `AccessTools`，以及 `dynamic` 关键字。原因与上个月的 `process` 相同：玩家无法判断没人读过的代码，而这种能力正是代码躲开扫描器的方式。在 2026 年 12 月 10 日 之前你的模组仍会加载；`mod-scan` 会打印一行 `DEPRECATED`，模组菜单会在该行显示"使用了下一次游戏更新将拒绝的能力（……）"。2026 年 12 月 10 日的更新之后，这条发现成为一律拒绝的标记，声明了该能力的清单在启用时被拒绝，使用它的已批准模组会停止加载并显示"游戏更新后的模组扫描器拒绝了它"。需要改什么（`mod-scan` 会指出每一处）：用 `typeof(游戏类型)` 代替 `obj.GetType()`（一直是免费的），只有运行时才知道的内容改用 [`ModReflect`](ModdingGuide.zh-CN.md#反射)，反射进另一个模组改为 [`<Prerequisites>` 引用](ModdingGuide.zh-CN.md#依赖另一个模组)，然后从 `<Capabilities>` 中删掉该能力。UI 命名空间 `UnityEngine.UI`、`TMPro` 和 `UnityEngine.EventSystems` 通过字面名称或 `typeof` 反射是免费的，所以读取某个组件私有字段的 UI 模组不受影响。
- **另有两项加入退出中的能力**，2026 年 12 月 10 日起拒绝，在那之前只警告：COM 激活（`Type.GetTypeFromProgID`、`GetTypeFromCLSID`、`Marshal.GetActiveObject`、`BindToMoniker`）算作 `reflection-external`；在 `JsonSerializerSettings`、`JsonSerializer` 或 `[JsonProperty]` / `[JsonObject]` 特性中把 Newtonsoft 的 `TypeNameHandling` 设为 `None` 以外的值算作 `dynamic-code`。`typeof(ES3Settings)` 和其他 Easy Save 类型现在在反射中算作外部类型，与它们的字面名称一样。已批准的模组会在下次启动时再扫描一次（扫描器版本 4）；本次更新不会让任何今天能加载的模组停止加载，在那个日期之前由警告承担这项工作。

**新增**

- **`ModReflect`：由游戏检查目标的反射。** `FindType`、`Types`、`Has`、`Get` / `Set`（以及 `GetStatic` / `SetStatic`）、`Call` / `CallStatic`（按参数类型或显式 `Type[]` 选择重载）、`New`、`Method<TDelegate>` / `StaticMethod`（供高频路径使用的已绑定委托）和 `Target`（供 `harmony.Patch` 使用的 `MethodBase`）。每次查找都在调用那一刻检查成员的声明类型：游戏的类型（加载器、信任和 Easy Save 类型除外）、你自己的程序集、正在运行的前置模组的程序集，以及三个 UI 命名空间。超出范围会抛出 `ModReflectAccessException` 并记录一次日志；控制台的 `mod-reflect` 列出被拒绝的查找。不需要任何能力。[详情](ModdingGuide.zh-CN.md#反射)
- **前置模组成为真正的依赖。** 模组可以引用它在 `<Prerequisites>` 中列出的模组的 DLL：扫描器接受该引用，加载器先加载前置模组再加载依赖它们的模组（按发现顺序做稳定的拓扑排序；模组菜单的顺序不变），依赖在前置模组运行后从它的文件夹解析，绝不会从未通过自身信任检查的模组加载。缺少前置模组仍然只是警告。[详情](ModdingGuide.zh-CN.md#依赖另一个模组)
- **`ModHelper` 中的模组间通道。** `Expose(modId, key, service)` / `Lookup<T>(modId, key)` 在 `modId:key` 下共享一个对象（前置模组 DLL 定义的接口，或普通委托）；`OnMessage(listenerId, "senderId:channel", handler)`、`OffMessage` 和 `SendMessage(senderId, channel, payload)` 是即发即忘的事件总线；`IsModRunning(modId)`。模组只能以自己的身份暴露和发送（以调用栈上的模组为准），任何模组都可以查找或监听，处理器在各自的 try/catch 中运行，被停止的模组注册的一切都会被清除。
- **在你的 Transpiler 改写过的方法内部运行的代码会归到你的模组。** 游戏的运行时检查（`Process.Start` 和 Steam 绊线、`ModHelper` 对数据文件夹、服务和协程的归属规则）通过调用栈找到调用的模组；Harmony 的替换方法体过去看起来不属于任何人，现在会映射到产生它的 Transpiler 所属的模组。Prefix 和 Postfix 一直都能归属。不使用 Transpiler 的模组没有变化。
- **较小的补充。** `ModCapability.Threads`、`Retiring`（12 月更新拒绝的四种能力）、`ModScanResult.Pending`（本次更新新增规则的发现，在那个日期之前只显示不计入；本次更新之前扫描器就能检测到的能力保持原有分量）、`ModEnableCheck.PromptCapabilities`；`ModRestrictedAttribute`；`ModLoader.AssembliesOf(mod)`；devMode 控制台命令 `mod-stop <id>` 像封禁一样停止一个正在运行的模组，供测试用。`ModCapability.IsDeprecated` / `IsRefused`；`ModScanner.FLAG_REFLECTION_EXTERNAL`、`REFUSE_REFLECTION_EXTERNAL`（2026 年 12 月 10 日更新要翻转的开关）和 `ReflectionAllowedExternalPrefixes`；`ModScanResult.UsesDeprecatedReflection`；`ModLoader.PrerequisiteAssemblyNames(manifest)` 和 `ModIdOfAssembly(assembly)`；`ModReflect` 是受保护类型（针对它的补丁或反射会拒绝模组）；`unlisted-reference` 发现现在会说明前置模组的程序集本可被接受。

## 2026年11月6日

**修复**

- **模组起始天赋的图标现在在所有界面都会显示。** `ModHelper.AddStartingPerk` 的 `iconKey` 之前只有新游戏的天赋界面和本局总结会解析；日历的"状态"天赋栏和"心智重编程器"窗口只按 ID 在原版图标列表中查找，模组天赋一律显示通用天赋图标。现在四个界面共用同一套查找（`StartingPerkIconLoader.GetIcon(perk)`：先是你的 `"modId:spriteName"` 键，然后是与 ID 同名的原版图标，最后是通用图标），你这边无需改动。

## 2026年11月4日

**新增**

- **由游戏签发、给你自己服务器用的 Steam 身份验证会话票证：`ModHelper.RequestSteamAuthTicket(serverIdentity, onTicket)` 和 `CancelSteamAuthTicket()`，属于新的 `steam-auth` 能力。** 拥有服务器（多人游戏、排行榜）的模组现在可以向服务器证明玩家是真实 Steam 客户端上一个拥有本游戏的账户，这正是把盗版和模拟器副本挡在门外的办法：服务器用 `ISteamGameServer::BeginAuthSession` 验证这些字节（一个使用本游戏 App ID 的无界面游戏服务器，匿名登录，不需要任何人的密钥）。身份是服务器给你的那个，`steamid:<id>` 或 `ip:<地址>:<端口>`，票证与它绑定。每个模组一张票证，再次申请、模组被停止和游戏退出时丢弃。玩家看到的能力描述是"向该模组的在线服务证明你拥有本游戏"，琥珀色；它不包含 `steam`，`steam` 也不包含它。自己调用 `SteamUser.GetAuthSessionTicket` 仍然被拒绝。扫描器把对这两个方法的调用计为 `steam-auth`，游戏在调用发生时会再次检查清单：没有声明时返回 `false` 并记录原因。背后的类 `ModSteamAuth` 加入受保护类型：针对它的 Harmony 补丁或反射会拒绝启用。[详情](ModdingGuide.zh-CN.md#向你的服务器证明玩家的-steam-身份)
- **小改动。** `ModCapability.SteamAuth`（`"steam-auth"`）；`ModCapability.Risk.High` 现在有了用途，就是它。

## 2026年11月3日

**新增**

- **`StoreClient.onShotSurvived`**：当一枪打伤了 `survivesShot` 的顾客时立即运行（`StoreUIManager.ShootSurvivor`），在受伤动画之前，无论 `shotSurvivedDialogue` 最终是否播放：用来记录该角色挨了枪。原版用于 Lou。
- **`PlayerStore.CloseWantedPoster(string posterId)`**：按 id 关闭通缉令（状态 1，无赏金，不触发 `onCaptureAction`），用于角色不在柜台时发生的抓捕。原有的 `StoreClient` 重载不变。

## 2026 年 11 月 2 日

- **对剧情顾客使用霰弹枪：`StoreClient` 的四组新钩子。** `holsterResumesDialogue` 让拔枪时暂停顾客的对话而不是丢弃它（`DialogUIManager.PauseConversation`），收枪时从被打断处继续（`ResumeConversation`）：顾客留下而不是被打发走。`unholsterDialogue` 是顾客对枪的专属反应（null 为随机台词池，`AugHelper.GetClientReactionUnholster`）。`shotCountsAsCapture` 让保安把被击毙的无义体通缉犯视为抓捕（`AugHelper.SHOT_WANTED_CAPTURE`，`GetShootResult` 的第三种结果）：赏金、保安声望、阵营变化、回执和 `onCaptureAction`，经由 `PlayerStore.OnWantedClientShot`；`shotCaptureDialogue` 是检查之后警官的独白（SEC 台词；null 为 `StoreClientDialogList.SecShotWantedGenericDialog`）。`survivesShot` 让枪击只造成受伤而非死亡：枪口闪光和受伤帧照常播放，没有人倒下，也不会叫来保安；`shotSurvivedDialogue` 在枪放回架子后播放，必须以打发顾客结束（`StoreClientMono.SetLimpOnLeave` 放慢离开的脚步）。`forceShootable` 允许对不可打发或不可逮捕的顾客拔枪。`onShotDead` 在标准的过失杀人惩罚之后运行（`AugHelper.CleanupKill`）。原版用在 Serpico、李北文、屠夫和 Sawyer 身上。
- **被当作过失杀人击毙的通缉海报人物现在会关闭其海报**（`PlayerStore.CloseWantedPoster`：`wantedStatus` 为 1，无奖励，不调用 `onCaptureAction`），因此他们的回访像被捕后一样停止。隐藏通缉不受影响。`PlayerStore.GrantWantedCaptureReward(client, isShot)` 与 `ApplyReportFactionChange(client)` 是举报的奖励与阵营变化，现在可以单独调用。
**新增**

- **"配置"：带设置窗口的物品的右键菜单动作。** 给物品打上 `GeneralHelper.CONFIGURE_TAG` 标签并设置 `item.onConfigureSlotItemFunc`，右键菜单就只在该物品上列出**配置**（物品归玩家所有之前为灰色）并调用该钩子。激活和切换保持原有含义，所以激活会执行操作的物品仍能提供设置。包装方法是 `GameItem.MayConfigureSlotItem`、`CanConfigureSlotItem` 和 `ConfigureSlotItem`。读档时保存的物品状态会替换工厂打的标签，所以也要在 `onSlotAddItemFunc` 里再打一次（参考 `HopperHelper.CreateOutlet` 里的输出漏斗）。
- **鼠标右键和滚轮点击成为按键绑定。** `KeyBindHelper.SECONDARY_CLICK`（默认 `Mouse1`）打开物品的右键菜单、翻转或旋转手中的物品，并退出装备模式、钉选模式、容器选取、存储协调器的按键捕获和放大镜缩放；`KeyBindHelper.FLIP_ITEM_ALT`（默认 `Mouse2`）翻转手中的物品。`ItemContextHandler.triggerKey` 现在读取该绑定，不再是检视器字段。响应右键的模组应改为读取 `KeyBindHelper.GetKeyDown(KeyBindHelper.SECONDARY_CLICK)`，而不是 `Input.GetMouseButtonDown(1)`。
- **鼠标按键可以被捕获为按键绑定**，左键除外（`KeyBindHelper.IsReserved(KeyCode.Mouse0)`），你的绑定同样适用。`KeyBindHelper.KeyName` 将它们命名为 "Right Click"、"Wheel Click"、"Mouse 4" 等。捕获进行期间，鼠标按下不再传到 `InputActionManager` 的处理器（此前只有鼠标输入仍会传入）。

## 2026 年 11 月 1 日

**建议处理**

- **销毁物品现在会连同其内容窗口以及窗口里剩下的物品一起销毁。** 对容器（任何带 `contentWindow` 的物品）调用 `GameItem.Destroy()` 会销毁窗口的渲染树和其库存中的物品，之后 `item.contentWindow` 为 null。此前该窗口会隐藏着留存整个会话，并把已销毁的物品及其内容一直保留在内存中。如果某个模组先销毁容器、再通过旧窗口读取其内容，现在必须先把物品移出（`GraphUtils.TryAcceptAll` 或 `GameItem.TryUnloadAll`）。

**新增**

- **`PixelWindow.Destroy()`** 释放你自己创建的窗口（渲染树、停靠、浮层画布和根列表中的登记）。通过 `SetContentWindow` 设置的窗口无需处理：物品会一并带走它。
- **`GraphUtils.EmporiumTryAdd(node, item)` 现在会先经由进料斗转送溢出物。** 当目标容器放不下该物品时，放在该容器里的进料斗会在商店兜底链之前按夜间顺序依次得到它，每个进料斗各按自己的过滤规则判断（保留数量不适用）；出料斗所在容器的规则通过正常的接收路径生效，只被收下一部分的堆叠会继续交给下一个进料斗，没人收下的部分照旧溢出到商店。对应的公开方法是 `HopperHelper.TryRouteOverflow(GameInventory grid, GameItem item)`，供以其他方式放置产出的机器调用。原版中放不下时会销毁或丢失产出的机器（培养肉机、熔炉的第二块锭、打印机、解序仪）现在和种植机一样通过 `EmporiumTryAdd` 溢出；模组机器也应以同样方式放置产出，这样料斗才能搬运它们。
- **`StallWatchdog.Crumb(text)`** 为卡顿报告留下一条痕迹。当主线程连续五秒没有完成任何一帧时，游戏会把最近 24 条痕迹连同内存计数追加到自己的 `GameLog_*.txt` 中，并在恢复后记录持续时间。可在任何线程、在可能耗时的操作开始时调用，一条简短的文字即可。

## 2026 年 10 月 31 日（安全更新 2）

**建议处理**

- **针对 `PaperBookRegistry` 的 Harmony 补丁或反射会导致启用被拒绝。** 调用它的公开方法以及 `ModHelper` 的纸张相关函数不受影响。[详情](ModdingGuide.zh-CN.md#一律拒绝的情况)
- **书本文件只能在模组文件夹内读写。** `PaperBookRegistry.Save`、`LoadFile` 和 `ReloadFromDisk` 会拒绝 `Mods/` 和你自己模组文件夹以外的路径，以及不是 `.json` 文件的路径，并改为记录一条错误。
- **其他模组的数据文件夹为只读。** `ReadModDataFileText` / `Bytes`、`ModDataFileExists` 和 `ListModDataFiles` 仍可使用任何模组的 id，但当 id 指向另一个已安装模组的数据文件夹时，`WriteModDataFileText` / `Bytes` 和 `DeleteModDataFile` 会抛出 `UnauthorizedAccessException`。你自己的 id 的其他写法（只要指向你自己的文件夹，例如 `CoolMod` 写成 `"coolmod"`），以及没有任何已安装模组使用的 id，仍可正常使用。如果一次写入在调用栈上找不到任何模组代码（例如 Harmony transpiler 插入到游戏方法里的代码，或动态生成的代码），则对所有已安装模组的文件夹都会被拒绝，包括你自己的：请从你自己的方法里调用这些函数。[详情](ModdingGuide.zh-CN.md#不声明能力也能读写文件)
- **已批准的模组会在此版本首次启动时重新扫描一次。**

**新增**

- **无需 `files` 能力即可使用资源包。** `ModHelper.LoadModAssetBundle(modId, relativePath)` 从你的模组文件夹加载资源包；只有接受路径的 `AssetBundle` 加载方法（`LoadFromFile`、`LoadFromFileAsync`、`RecompressAssetBundleAsync`）仍算作 `files`，`LoadFromMemory`、`LoadAsset` 等其余成员是免费的。只为资源包声明了 `files` 的模组可以去掉它。[详情](ModdingGuide.zh-CN.md#不声明能力也能读写文件)
- **`DifficultyRules.louDemandValue`**：Lou 在伪装来访之后索要的物资价值（信用点），休闲 500、普通 750、困难 1000、挑战 1500。用 `AddDifficulty` 注册的难度会从其 `basedOn` 复制这个值。已移除的常量 `StoreClientData.LOU_DEMAND_VALUE` 改为 `StoreClientData.GetLouDemandValue()`。她来收取时的炸弹阈值是该值的一半，即 `StoreClientData.GetLouDemandMinimum()`；常量 `LOU_DEMAND_MINIMUM` 已标记为 `[Obsolete]`，不再被读取。
- **其他小的新增。** `ModLoader.CallingModId()` 返回当前调用栈上最近的模组的 id，游戏自身的代码则返回 null（上面的数据文件夹规则就用它判断）。`ModWorkshop.TryGetStats(publishedFileId, out ItemStats)` 在 Steam 回应后给出创意工坊物品的首次上传日期和好评、差评数（`ItemStats.createdUtc`、`votesUp`、`votesDown`、`Ratings`）。`ModCapability.Risk` 和 `RiskOf(capability)` 给出启用对话框为每项能力着色所用的风险等级（native、dynamic-code、files、reflection-external 和 network 为 `Severe`，steam 和 process 为 `Medium`）。

## 2026 年 10 月 30 日（安全更新）

**建议处理**

- **启动程序永远不被允许。** `System.Diagnostics.Process` / `ProcessStartInfo` 无论清单怎么写都会导致启用被拒绝，游戏运行时也会拦截来自模组代码的 `Process.Start`（模组会被停止并停用）。`process` 能力现在只涵盖参数为字面 `http://` 或 `https://` 网址的 `Application.OpenURL`，玩家看到的说明是"在浏览器中打开网页链接"。[详情](ModdingGuide.zh-CN.md#一律拒绝的情况)
- **使用 Steam API 现在属于新的 `steam` 能力，而且有些 Steam 调用永远不被允许。** 成就、好友、游戏内覆盖界面、创意工坊查询等 Steamworks 调用必须声明为 `<Capability>steam</Capability>`。创建、更新、删除、订阅或下载创意工坊物品，Steam 云写入，身份验证票证，聊天消息和邀请，`SteamAPI` / `SteamClient`，以及对 Steam 的 `DllImport`，无论清单怎么写都会导致启用被拒绝；游戏运行时也会拦截这些调用，被发现这样做的模组会被停止并停用。发布方式不变，仍使用 steamcmd。[详情](ModdingGuide.zh-CN.md#一律拒绝的情况)
- **扫描的是整个模组文件夹，而不只是 DLL。** 任何名称下的可执行文件和脚本，以及看起来经过加密或压缩的未知格式文件，都会导致启用被拒绝；图片、声音、文本、字体和 PDB 没有问题。发布内容中请去掉 zip、安装程序和美术源文件。没有大小限制。[详情](ModdingGuide.zh-CN.md#能力声明与扫描器)
- **向 `Harmony.Unpatch` 传入你自己的 id。** `Unpatch(original, type)` 默认使用 id `"*"`（所有补丁所有者），现在会被拒绝；请写成 `harmony.Unpatch(original, type, harmony.Id)`。
- **已批准的模组会在此版本首次启动时重新扫描一次**，因此依赖上述调用的模组会停止加载，直到作者更新它。

## 2026 年 10 月（1.0 正式版）

**建议处理**

- **`manifest.xml` 需要 `<Assemblies>` 和 `<Capabilities>`。** 两者缺一的清单不会被列出。在 `<Assemblies>` 下列出每个要加载的 DLL（文件夹中的其他任何 DLL 都会导致启用被拒绝，与游戏或框架程序集同名的 DLL 同样会被拒绝），在 `<Capabilities>` 下声明你的代码在游戏 API 之外做了什么：`files`、`network`、`process`、`dynamic-code`、`native`、`reflection-external`。这个元素通常为空。玩家启用你的模组时，游戏会扫描你的 DLL：未声明的能力会导致启用被拒绝，已声明的能力会在玩家确认前展示给玩家。用控制台命令 `mod-scan <id>` 自查。[详情](ModdingGuide.zh-CN.md#能力声明与扫描器)
- **批准按电脑、按版本记录。** 玩家点击"启用"时会记录你文件的哈希。不新增能力的更新继续运行；新增能力的更新会等待玩家重新审核。在本地迭代模组时，请在"模组"菜单中打开**开发者模式**，这样你的每次重新编译都被信任。[详情](ModdingGuide.zh-CN.md#玩家看到什么)
- **F8 控制台和 F9 开发菜单需要 `dev.txt`。** 正式发布的游戏中两者默认关闭，直到游戏可执行文件旁存在一个名为 `dev.txt` 的空文件。在你的开发机上创建一次即可；模组本身无需任何改动。Marketing Panel 现在是开发者专用窗口，注册在 `DEBUG_CATEGORY_MARKETING` 下的按钮会落入 Special。[详情](ModdingGuide.zh-CN.md#开发工具)
- **每个模组都需要一个含 `IMod` 类的 DLL。** 只有资源的文件夹（没有 DLL，或没有实现 `IMod` 的 DLL）不再出现在"模组"菜单中，控制台会改为记录 `[你的模组名] Error: ...`。只含资源的模组请附带一个最简单的 `IMod` 类。[详情](ModdingGuide.zh-CN.md#模组资源)
- **不要再为修改掉落而修补 `TableMaster` / `TableGroupMaster`。** 它们的静态字典已被移除；掷取（roll）现在都经过 `LootRegistry`，它为此提供了受支持的 API。[详情](ModdingGuide.zh-CN.md#掉落表)

**新增**

- **玩家能看到你的模组名。** 它是你所添加物品提示框的最后一行；对于你添加的顾客，对话记录器会在其第一句台词之前显示"来自你的模组名："（两者都是玩家选项，默认开启）。从你的 DLL 注册的物品、在 `OnGenerateCustomer*` 钩子中加入的顾客会被自动识别；以其他方式加入的顾客用 `ModHelper.SetClientSource(client, modId)` 标记，工厂函数不是你的代码的物品用 `ModHelper.SetSource` 标记。[详情](ModdingGuide.zh-CN.md#通过物品目录钩子添加物品)
- **你自己的鉴定物品。** `ModHelper.AddAppraisalItem(modId, id, itemId, unlockRank, createRandom, getCorrectValue, isType, guideItemId, displayName)` 添加一种鉴定物品类型，玩家的鉴定师委员会等级解锁后，鉴定顾客就会带来它（每个等级可有多个；相同 id 会替换原版类型）。估价以你的 `getCorrectValue` 评级。`RemoveAppraisalItems(modId)` 移除它们，`GetAppraiserRank()` 读取等级。[详情](ModdingGuide.zh-CN.md#鉴定物品)
- **无需 `files` 能力的文件访问。** `ModHelper.ReadModFileText / ReadModFileBytes / ModFileExists / GetModFolder` 读取你的模组文件夹；`GetModDataFolder`、`ReadModDataFileText / Bytes`、`WriteModDataFileText / Bytes`、`DeleteModDataFile`、`ListModDataFiles` 读写存档位置下每个模组专属的文件夹。只接受相对路径。用它们代替 `System.IO`，就无需声明任何能力。[详情](ModdingGuide.zh-CN.md#不声明能力也能读写文件)
- **控制台命令** `mod-scan <id 或文件夹>`（扫描器在你的 DLL 中发现了什么，以及该版本的 fingerprint 哈希）、`mod-trust [id]`（这台电脑上的批准记录）和 `mod-trust-list`（远程名单状态）。[详情](ModdingGuide.zh-CN.md#发布前自查)
- **难度成为数据。** 现在有四个难度（cozy、normal、hard、challenge），`ModHelper.AddDifficulty(modId, id, order, title, subtitle, configure, basedOn, notes, iconKey)` 可添加你自己的难度：一组游戏直接读取的 `DifficultyRules` 数值，在选择界面按顺序列出，并根据与普通难度不同的规则生成说明。`ModifyDifficulty(id, modify)` 调整任意难度，`RemoveDifficulties(modId)` 移除你的难度，`GetDifficultyId()` / `GetDifficultyRules()` / `IsDifficultyAtLeast(id)` 读取当前难度，一局开始或载入时触发 `ModHook.OnDifficultyApplied(id)`。`PlayerStore.IsHardMode()` 现在表示困难或更高。[详情](ModdingGuide.zh-CN.md#难度)
- **你自己的起始天赋。** `ModHelper.AddStartingPerk(modId, id, cost, type, name, description, iconKey, incompatiblePerks, extraPerkSlots, mindEditable)` 把一个天赋与原版天赋一起列在新游戏的天赋界面上；选择随本局存档保存，你的模组通过 `IsStartingPerkActive(id)` / `GetStartingPerkIds()` 读取后自行施加效果。`RemoveStartingPerks(modId)` 可再移除。[详情](ModdingGuide.zh-CN.md#起始天赋)
- **你自己的起始方案。** `ModHelper.AddStartingScenario(modId, id, title, description, startWith, onStart, iconKey, tag, tagTone, skipIntro, comingSoon)` 把一个专精加进新游戏界面的图标栏；`onStart` 在新的一局开始时放置初始物品。`RemoveStartingScenarios(modId)` 可再移除，`GetStartingScenarioId()` / `IsStartingScenario(id)` 可得知本局以哪个方案开始，每局新游戏都会触发 `ModHook.OnNewGameStarted(id)`。[详情](ModdingGuide.zh-CN.md#起始方案)
- **你自己的人脉升级。** `ModHelper.AddNetworkUpgrade(modId, id, cost, subtitle, title, description, onUnlock, tab, iconKey, prerequisites, cooldownDays, ...)` 把一个升级放进重做后的"Wild 的人脉"窗口：副标题决定卡片，标签页是任意字符串（留空表示"基础"标签页，`SetNetworkTabLabel` 为它命名），同一卡片内的前置条件会画出链条连接线，图标用你自己的精灵图。状态随本局存档按 ID 保存。`RemoveNetworkUpgrades(modId)` 可再移除，`IsNetworkUpgradeUnlocked(id)` 和 `GetNetworkUpgrade(id)` 读取状态，`OpenWildNetwork()` 打开窗口，每次购买都会触发 `ModHook.OnNetworkUpgradeUnlocked(id)`。[详情](ModdingGuide.zh-CN.md#人脉升级)
- **掉落表编辑。** 把你的物品加进游戏的掉落表、修改或移除已有掉落、注册新的表和表组：`ModHelper.AddLootEntry / SetLootWeight / RemoveLootEntry / RegisterLootTable` 以及对应的 `Group` 版本，可在 `OnEnable` 中调用。权重是相对值，原版表的总和为 1000，因此权重 `10` 约为 1%。[详情](ModdingGuide.zh-CN.md#掉落表)
- **JSON 掉落文件。** 同样的编辑可以以数据形式提供：模组文件夹中的 `LootTables/*.json`，无需 C#。[详情](ModdingGuide.zh-CN.md#用-json-文件编辑掉落表)
- **`ModHook.OnLootTablesLoaded`**（掉落表就绪，所有编辑已应用）和 **`ModHook.OnLootRolled(LootRollContext)`**（覆盖任意一次掷取的结果）。[详情](ModdingGuide.zh-CN.md#响应掷取)
- **控制台命令** `loot-list [id]` 和 `loot-roll <id> [count]`，用于查看实际概率、哪个模组改了什么，以及试掷一张表。[详情](ModdingGuide.zh-CN.md#在控制台中查看掉落表)
- **模组数据存储。** 用 `ModHelper.SetModData / GetModData`（以及 `Int`、`Float`、`Bool` 变体、`HasModData`、`RemoveModData`、`GetModDataKeys`、`ClearModData`）保存任何不属于某个物品的数据。按模组 ID 隔离命名空间，随本局游戏一起保存，载入时恢复。[详情](ModdingGuide.zh-CN.md#保存模组数据)
- **自定义 UI。** 用 `CustomUIManager` 的链式构建器从代码创建你自己的窗口（标签、按钮、开关、滑块、输入框、下拉框、进度条、图片、标签页、滚动列表），可放在任意游戏画布上或一个跨场景持久的覆盖层上。模组精灵图通过 `"modId:spriteName"` 键使用。自定义 UI 从"暂不支持"列表移入已支持列表。[详情](ModdingGuide.zh-CN.md#自定义-ui)
- **自定义 UI 与机器窗口的新增内容。** 构建器新增 `AddHeader`、`AddWarning`、`AddSeparator`、`AddCloseButton`、`AddIconButton`、`BeginPanel`、`BeginScrollFlexible`，以及第三种外观 `UseMachineryStyle()` / `CustomUIManager.Style.Machinery`：机器内容窗口的 Machinery 风格。机器窗口新增 `MachineryRangeSlider`、`MachineryText.WithInfoLink`，以及 `CreateMachineryWindow(canMove, displayOrder, panels)`，可在不影响存档的情况下以另一种顺序绘制已发布窗口的面板。[详情](ModdingGuide.zh-CN.md#自定义-ui)
- **你自己的 F9 调试按钮。** `ModHelper.AddDebugFunction(modId, category, name, action, tall)` 在 F9 开发菜单的 Store、Command、Spawn 或 Special 列下添加一个按钮；`RemoveDebugFunctions(modId)` 再把它们移除。可在 `OnEnable` 中调用。[详情](ModdingGuide.zh-CN.md#添加你自己的调试按钮)
- **模组配置。** `ModHelper.GetConfig(modId).Define(...)` 为你的模组提供有类型、会保存的设置（bool、int、带可选范围的 float、带可选选项的 string、枚举），以及"模组"菜单中齿轮按钮后面自动生成的配置面板，带"应用"和"恢复默认"。值按模组保存在 `ModConfigs/<modId>.json` 中，`ConfigEntry.OnChanged` 和 `ModHook.OnModConfigApplied` 报告变化。[详情](ModdingGuide.zh-CN.md#模组配置)
- **Steam 创意工坊（仅正式版）。** 已订阅的物品像 `Mods/` 文件夹一样加载，在"模组"菜单中带 Steam 图标显示，玩家激活之前保持未激活；菜单中可以取消订阅并打开物品页面。与已订阅物品 `<ID>` 相同的本地文件夹会覆盖创意工坊副本。发布通过 steamcmd 完成，不在游戏内。[详情](ModdingGuide.zh-CN.md#steam-创意工坊)
- **新的"模组"菜单。** 两个列表都可滚动，并可按名称或 ID 搜索；当前置模组缺失或未激活、或游戏版本不匹配时，行上会显示警告；详情面板会列出你的 `<Prerequisites>`（勾或叉）、按当前游戏版本给 `<GameVersions>` 着色，并显示你的预览图：创意工坊物品使用创意工坊预览图，其他情况使用模组文件夹中的 `preview.png`（没有图片时不显示横幅）。"自动排序"会把已激活的模组排在其前置模组之后。
- **把你的设置放进游戏的"选项"窗口。** `ModHelper.AddGameOptionSection / AddGameOptionToggle / AddGameOptionSlider / AddGameOptionDropdown / AddGameOptionKeyBind` 添加条目（你自己的分区或内置分区），游戏用自己的控件绘制、通过你的 getter 填充，并在"应用"时通过你的 setter 写回；`RemoveGameOption / RemoveGameOptions` 再把它们移除。可在 `OnEnable` 中调用。[详情](ModdingGuide.zh-CN.md#游戏选项)
- **加载错误会被报告。** 当你的 DLL 加载失败，或者 `Init`、`OnEnable` 或某个 Harmony 补丁抛出异常时，控制台会记录 `[你的模组名] Error: <异常>`，后面紧跟完整的堆栈跟踪；模组菜单会在你的模组旁显示警告图标，该模组仍留在已启用列表中，方便停用。对于 `Mods/` 文件夹中的模组，F8 控制台还会在启动时自动打开。`LoadedMod.LoadError` 保存一行简短的原因。[详情](ModdingGuide.zh-CN.md#故障排查)

## 2026 年 7 月

**建议处理**

- **不要再用自己的 `AudioSource` 播放声音。** 模组声音现在会以 `<modId>:<key>` 为标识注册到游戏的音频系统。请改用 `ModHelper.PlaySound / PlaySound2 / PlaySound3(modId, key)`，这样玩家的音量和暂停设置才会生效。直接读取 `mod.Sounds` 仍然可行，但会绕过音量设置。[详情](ModdingGuide.zh-CN.md#声音)

**行为变化**

- **钩子处理函数抛出的异常不再影响游戏或其他模组。** 每个订阅者都在自己的 try/catch 中运行；错误会以 `[ModHook] ... from '<your mod>' threw: ...` 的形式记录到 F8 控制台，其余一切照常继续。通过在处理函数中抛出异常来中止游戏代码的做法不再有效（这从来就不受支持；请使用返回 `false` 的 Harmony Prefix）。记录下来的异常仍然意味着你的模组有问题。

**新增**

- **基于 CSV 的本地化。** 在模组文件夹中以 `Localization/<localeCode>.csv` 文件提供翻译，并用 `ModHelper.GetLocalized(modId, key, args...)` 读取。先解析当前语言，再回退到英语，最后回退到键本身。[详情](ModdingGuide.zh-CN.md#本地化)
- **自定义物品音效。** 物品的声音字段（`soundUse`、`soundDragStart`、`soundContainerOpen` 等）现在接受模组声音标识：`item.soundUse = ModHelper.GetSoundIdentifier("my_mod_id", "gulp");`
- **`ModHook.OnModAssetsLoaded(LoadedMod)`**：每个已启用的模组在其全部贴图、物品精灵图和声音载入内存后触发一次。它会为每个模组触发，请检查 `mod.Manifest.ID` 是不是你的。[详情](ModdingGuide.zh-CN.md#如何知道资源已就绪)

**政策**

- **反编译：可以看，不可以复制。** 为了研究游戏、寻找补丁目标而反编译游戏是官方默许的；再分发游戏代码或资源则不行。[完整政策](CodeOfConduct.zh-CN.md#尊重其他创作者)
