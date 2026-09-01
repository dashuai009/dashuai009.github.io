#let date = datetime(
  year: 2022,
  month: 11,
  day: 28,
)
#metadata((
  title: "UE4模块系统",
  subtitle: [UnrealEngine],
  author: "dashuai009",
  description: "详细介绍ue中的模块系统",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

参考资料

#link("https://www.youtube.com/watch?v=DqqQ_wiWYOw")[UE4 Modules - YouTube]

#link("https://docs.unrealengine.com/4.27/zh-CN/ProductionPipelines/BuildTools/UnrealBuildTool/")[虚幻编译工具 | 虚幻引擎文档 (unrealengine.com)]

== 简介
<简介>
众所周知，c++17及之前中没有modules概念。模块化的代码的优势有#strong[代码分割];、#strong[代码重用];和#strong[加快编译速度];等。

ue中每个模块都被编译为一个dll，据传ue源代码中有一千多个模块\~
ue使用c\#编译构建源代码，而不是vs的sln文件。sln仅仅是为了vs方便。所以，如果新建的模块写进C\#构建文件后，ubt就可以编译构建，即使sln中不显示新建的ue模块。每次更改.build.cs或者更改了文件夹结构，为了生成sln文件，双击项目目录下的GenerateProject.bat。

== 创建一个模块
<创建一个模块>
每个模块位于一个同名文件夹下，一般来说包含一个Public文件夹、Private文件夹和一个C\#构建类。我们创建一个Foo模块，比如说位于Foo文件夹下：

```
Foo
|--Private
|--Public
|--Foo.build.cs
```

Public包含可供其他模块引用的头文件（导出类），Private包含cpp源文件及私有头文件。
每个.buidl.cs中的模块类需要继承自ModuleRules。Foo.build.cs的最基本的实现如下：

```csharp
using UnrealBuildTool;

public class Foo : ModuleRules
{
  public FooBar(ReadOnlyTargetRules Target) : base(Target)
  {
     PrivateDependencyModuleNames.AddRange(new string[] {"Core"});
  }
}
```

== build.cs 中的ModuleRules详解
<build.cs-中的modulerules详解>
=== 依赖dependency
<依赖dependency>
`PrivateDependencyModuleNames (List<String>)`
#strong[私有依赖];”：我们的私有代码依赖这些模块，但我们的公共代码不依赖这些模块。

`PublicDependencyModuleNames (List<String>)`
#strong[公共依赖];（不需要路径）（自动执行私有/公共包含）。这些是我们的公共源文件所需要的模块。

- 添加到依赖中的模块：添加引用模块的public目录到includePath，链接对应的dll（相应的导出函数、类等被引入）。
- private依赖不会传递导出的符号：A private/public depends on B，B private depends in C，则A不能看到C的头文件，也不会导入C导出的符号。如果A private/public depends on B，B public depends in C，则A能看到C的头文件，但不会导入C导出的符号。也就是说，B可以public的C的头文件，但始终不能转发链接符号。
- 如果只是private中的cpp/h依赖了外部模块，建议添加到private dependence中，可以加快编译速度。
- Forward declare when you can so you don’t need to mark something as a public dependency.

=== 其他othter
<其他othter>
#link("https://docs.unrealengine.com/4.27/zh-CN/ProductionPipelines/BuildTools/UnrealBuildTool/ModuleFiles/")[模块 | 虚幻引擎文档 (unrealengine.com)]

== 实现一个模块
<实现一个模块>
现在我们有了一个Foo.build.cs，我们需要用cpp实现它。

=== module.h
<module.h>
一般来说，我们要在`[YourModuleName]Module.h`中声明如下代码（以Foo模块为例）：

```cpp
#include "Modules/ModuleInterface.h"

class FFooModule : public IModuleInterface
{
public:
    /**
     * Called right after the plugin DLL has been loaded and the plugin object has been created
     */
    virtual void StartupModule();

    /**
     * Called before the plugin is unloaded, right before the plugin object is destroyed.
     */
    virtual void ShutdownModule();

    void DoFoo();
}
```

`FFooModule`必须继承自`IModuleInterface`（位于`Modules/ModuleInterface.h`）中

=== module.cpp
<module.cpp>
在`private/FooModule.cpp`中实现以下代码：

```cpp
#include "FooModule.h"
#include "Modules/ModuleManager.h"

IMPLEMENT_MODULE( FFooModule, Foo );

Foo::StartupModule(){
    //do sth right after the dll has been loaded and the static object has been created
    //可以在module中定义一个单例，并在这里初始化
}

Foo::ShutdownModule(){
    // 单例在这析构
}

Foor::DoFoo(){
     //自定义函数
}
```

- `IMPLEMENT_MODULE( F[YourModule]Module, Foo)`
  宏，一个参数是类名（推荐命名方式`F[YourModule]Module`，第二个是模块名
- #strong[IMPLEMENT\_GAME\_MODULE]
- #strong[IMPLEMENT\_PRIMARY\_GAME\_MODULE]
- "Modules/ModuleManager.h" 和 "Modules/ModuleInterface.h"
  位于Core模块中，这是我们最少依赖的模块。

=== 模块的使用方式
<模块的使用方式>
`FModuleManager::Get().LoadModuleChecked<FFooModule>(TEXT("Foo")).DoFoo();`

== PCH(precompiled headers)预编译头文件
<pchprecompiled-headers预编译头文件>
#strong[不推荐使用PCH，初学者可以直接跳过这一节。]
仅适用于代码库比较庞大的情况。

#link("https://learn.microsoft.com/zh-cn/cpp/build/creating-precompiled-header-files?view=msvc-170")[预编译的头文件 | Microsoft Learn]

=== 私有的预编译头文件。
<私有的预编译头文件>
为自己的模块创建的自定义 PCH。使用 PrivatePCHHeaderFile 属性在 Build.cs
文件中定义它。 按照惯例，它应该命名为`[your-module-name]PrivatePCH.h`

```csharp
using UnrealBuildTool;

public class Foo : ModuleRules
{
  public FooBar(ReadOnlyTargetRules Target) : base(Target)
  {
    PrivatePCHHeaderFile = "FooPrivatePCH.h";//每个模块最多一个pch
    PrivateDependencyModuleNames.AddRange(new string[] {"Core"});
  }
}
```

Unreal Build Tool 会自动为模块中的所有编译文件注入它。

=== 共享的预编译头文件。
<共享的预编译头文件>
共享 PCH
是指一个模块定义了#strong[给其他依赖模块使用的];预编译头文件。模块本身不能使用它。基础虚幻引擎模块中比较常见（UnrealEd, Engine, Slate, CoreUObject, and Core）。只有引擎模块（engine
module可以创建shared PCH）。

您无法选择使用哪一个，虚幻引擎会根据优先级分数从您的模块依赖项之一中为您选择。该优先级分数按模块排序，取决于它依赖的具有共享PCH的其他模块的数量。这是一个有点奇怪的解释，但上面的模块列表已经按优先级排序。例如，如果您的模块依赖于所有五个模块，Unreal将在编译时选择 UnrealEd 的共享 PCH 用于您的模块。

=== 那么什么时候使用哪种预编译头类型呢？
<那么什么时候使用哪种预编译头类型呢>
你实际上有三个选择。

您可以创建自己的私有预编译头文件。

这对于代码库非常大的模块很有用，大型游戏中的主要游戏模块通常就是这种情况。

您必须决定在 PCH 中放入什么以及如何自己平衡它。

您可以使用共享引擎 PCH，这对于所有其他较小的模块来说都是一个不错的选择。

最后，不推荐使用任何 PCH。

这不是很实用，我不知道你为什么要这样做，除非你正在做一些极端的编译调试。

但是你有选择。

因此，让我们看看您在哪里配置这些 PCH 构建设置。

=== 在模块的 Build.cs 文件中设置。
<在模块的-build.cs-文件中设置>
有两个相关的设置来配置它

采用 PCHUsageMode 枚举的 PCHUsage 属性

当您想使用私有 PCH 时，还可以选择 PrivatePCHHeaderFile 属性

这只是标题的字符串路径。

那么，设置PCHUsageMode，我们应该使用哪个设置呢？

嗯，它比 Enum 看起来要简单一些，因为

这三个是遗留的，您应该始终选择 UseExplicitOrSharedPCHs。

该选项默认使用共享 PCH，如果您已通过 PrivatePCHHeaderFile
属性设置，则使用私有 PCH。

从 4.24.2 开始，它实际上已经是默认设置

因此，如果您使用的是在该版本或更高版本上创建的项目，那么您甚至不必设置它。

此设置将来可能会逐步淘汰。

== Include What You Use，通常缩写为 IWYU
<include-what-you-use通常缩写为-iwyu>
遵循四个原则

+ 所有头文件包含其所需的依赖性。
  #strong[CoreMinimal];头文件包含了UE核心编程环境的常见类型（包括FString、FName、TArray等）。这样，在头文件中首先include该文件，就可以引入这些东西。
+ Foo.cpp文件首先包含其匹配的Foo.h文件。
  否则ubt将发出警告（如要禁用，可在模块的\*.build.cs文件中将
  `bEnforceIWYU` 设为 `false`）。
+ PCH文件已不再是显式包含。
+ 不再包含单块头文件（monolithic header，比如Engine.h、UnrealEd.h）。

=== 启用IWYU
<启用iwyu>
在version\<=4.23中，IWYU默认不启用，在 .Build.cs 文件中将 PCHMode
属性设置为 UseExplicitOrSharedPCHs 来打开 IWYU。

在version\>=4.24.2中，默认启用。具体来说，默认启用是通过#strong[DefaultBuildSettings
\= BuildSettingsVersion.V2];设置的。该选项做了三件事
- PCHUsage gets set to PCHUsageMode.UseExplicitOrSharedPCHs;
- #strong[bLegacyPublicIncludePaths] 被设为false，虚幻构建工具会从公共包含路径中省略子文件夹，以减少编译器命令行长度并缩短编译时间。现在必须让每个包含路径都正确。之前你可以只包含Actor.h，现在你必须包含GameFramework/Actor.h。#link("https://docs.unrealengine.com/4.27/zh-CN/ProductionPipelines/BuildTools/UnrealBuildTool/IWYU/IncludeTool/")[包含工具 | 虚幻引擎文档 (unrealengine.com)]
- #strong[ShadowVariableWarningLevel gets set to WarningLevel.Error;]

=== 模块日志
<模块日志>
=== 声明模块日志的类别：
<声明模块日志的类别>
```cpp
DECLARE_LOG_CATEGORY_EXTERN(CategoryName, DefaultVerbosity, CompileTimeVerbosity);
```

- Commonly (Log\[ModuleName\], Display, All), see Logging/LogVerbosity.h
  for more.
- Declares a category class that extends FLogCategory.
- Most practical to put it in its own header file.

=== 定义模块日志的类别（方便过滤）
- DEFINE\_LOG\_CATEGORY(CategoryName);
- Instantiates an instance of that log category class, which registers
  itself with the log suppression system in the constructor.
- Put it in the same place where you called IMPLEMENT\_MODULE.
=== 使用模块日志
- UE\_LOG(Log\[ModuleName\] Display, TEXT("A wild log appeared!"));
