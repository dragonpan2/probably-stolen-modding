# Probably Stolen：模组 API 变更

English version: [APIChanges.md](APIChanges.md)

按游戏更新记录模组 API 的变化，最新的在最上面。每次更新内部按重要性排序：需要你立即处理的在前，新增能力在后。完整文档见 [ModdingGuide.zh-CN.md](ModdingGuide.zh-CN.md)。

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
