#outline()


= InteractiveToolsFramework介绍



本文参考以下几篇文档，过时内容被调整了，只保留ue5.3的实现。

#link("http://www.gradientspace.com/tutorials/2022/6/1/the-interactive-tools-framework-in-ue5")[The Interactive Tools Framework in UE5]

#link("http://www.gradientspace.com/tutorials/2021/01/19/the-interactive-tools-framework-in-ue426")[The Interactive Tools Framework in UE4.26 (at Runtime!)]

#link("http://www.gradientspace.com/tutorials/2022/5/27/modeling-mode-extension-plugins-in-ue5")[Modeling Mode Extension Plugins in UE5]


InteractiveToolsFramework（ITF，交互式工具框架）本质是解决“如何在UE中构建3D编辑工具”（“How to Build 3D Tools using Unreal Engine”）。该框架从UE4.26开始提供。
该框架支持在运行模式（游戏中）、编辑器等条件下使用。


这里有一个UE5的游戏示例项目#link("https ://github.com/gradientspace/UE5RuntimeToolsFrameworkDemo")[UE5RuntimeToolsFrameworkDemo]。


== 背景

首先，我将解释*交互式工具框架(ITF) *作为概念的一些背景。它来自哪里，它试图解决什么问题。

接下来我将解释 UE4 交互工具框架的主要部分。我们将从*Tools、ToolBuilders 和 ToolManager*开始，然后讨论工具生命周期、接受/取消模型和基础工具。输入处理将包含在*输入行为系统（The Input Behavior System）*、通过工具属性集存储的工具设置（Tool Property Sets）和工具操作（Tool Actions）中。

接下来我将解释*Gizmos*系统，用于实现视口内 3D 小部件，重点关注上面的剪辑/图像中显示的*标准 UTransformGizmo*。

在 ITF 的最高级别，我们有Tools Context 和 ToolContext API ，我将详细介绍 ITF 客户端需要实现的 4 个不同的 API - IToolsContextQueriesAPI、IToolsContextTransactionsAPI、IToolsContextRenderAPI 和 IToolsContextAssetAPI。然后我们将介绍一些特定于网格编辑工具的细节，特别是Actor/Component Selections 、 FPrimitiveComponentTargets和FComponentTargetFactory 。


// 到目前为止，一切都与 UE4.26 附带的 ITF 模块有关。为了在运行时使用 ITF，我们将创建自己的运行时工具框架后端，其中包括可选网格“场景对象”的基本 3D 场景、相当标准的 3D 应用程序变换 Gizmo 系统以及 ToolsContext API 的实现上面提到的与这个运行时场景系统兼容。本节基本上解释了我们必须添加到 ITF 才能在运行时使用它的额外位，因此您需要阅读前面的部分才能真正理解它。


// 接下来，我将介绍一些特定于演示的材料，包括使演示正常工作所需的ToolsFrameworkDemo 项目设置、 RuntimeGeometryUtils 更新，特别是 USimpleDynamicMeshComponent 的碰撞支持，然后是有关在运行时使用建模模式工具的一些说明，因为这通常需要一些粘合代码才能使现有的网格编辑工具在游戏环境中发挥作用。

== Interactive Tools Framework - The Why

原作者很早之前就在实践3D编辑相关的工程。后来加入EpicGames，编写了ITF这个框架。

第一个例子，普通APP，比如微信、知乎之类的，点击去，不是直接展示单个聊天、单个问答，而是先浏览一个列表，再浏览单个聊天。浏览之后，推出到列表，再点击进入别的界面。

第二个例子，PowerPoint、Word之类，我想插入图片，ppt、word不会限制我在什么时候才能添加图片，这类内容编辑程序的流程概念相对模糊，或者说自由度相对较高。而3D内容编辑（也就是DCC）更甚，用到的工具多，相互交叉影响多。

== UInteractiveTool

先来介绍UInteractiveTool。每个Tool表示一个基本的工具，如果想要实现一个小工具，继承他，实现它列出的一些基本API。
它用来管理工具的状态、处理鼠标键盘等设备的输入。


```cpp
class UInteractiveTool{

public:
    /// 工具流程相关API
    virtual void Setup();
    virtual void Shutdown(EToolShutdownType ShutdownType);
    virtual void Tick(float DeltaTime) final;
protected:
    virtual void OnTick(float DeltaTime){};
public:
    virtual bool HasCancel() const;
    virtual bool HasAccept() const;
    virtual bool CanAccept() const;


    /// 渲染绘制相关
    virtual void Render(IToolsContextRenderAPI* RenderAPI);
    virtual void DrawHUD( FCanvas* Canvas, IToolsContextRenderAPI* RenderAPI );

    virtual UInteractiveToolManager* GetToolManager() const;

    /// Input Behaviors support
    virtual void AddInputBehavior(UInputBehavior* Behavior, void* Source = nullptr);
    virtual void RemoveInputBehaviorsBySource(void* Source);
    virtual const UInputBehaviorSet* GetInputBehaviors() const;


    /// property support
    virtual TArray<UObject*> GetToolProperties(bool bEnabledOnly = true) const;
    OnInteractiveToolPropertySetsModified OnPropertySetsModified;
    OnInteractiveToolPropertyInternallyModified OnPropertyModifiedDirectlyByTool;
    virtual void OnPropertyModified(UObject* PropertySet, FProperty* Property);

    /// Actions
    virtual FInteractiveToolActionSet* GetActionSet();
    virtual void ExecuteAction(int32 ActionID);
protected:
    virtual void RegisterActions(FInteractiveToolActionSet& ActionSet);

}
```


管理工具的生命周期的API还是比较简洁的：
+ `::Setup()`中初始化工具
+ 在::Shutdown()中执行任何完成和清理操作，这也是您执行“Apply”操作之类的操作的地方。 
+ `Tick()`被标记为final函数，派生的Tool应该重载OnTick函数，Tick()函数有去处理一些固定的关键功能，所以不允许派生类重写。
+ HasAccepted()返回 当前状态下工具能否被accepted，HasCancel()同理


UInteractiveTool的实例需要从`UInteractiveToolManager`请求。而Manager中会存储每个工具的字符串标识和对应的`UInteractiveToolBuilder`。UInteractiveToolBuilder 是一个非常简单的工厂模式基类，必须为每种工具类型实现：

```cpp
class UInteractiveToolBuilder : public UObject
{
	GENERATED_BODY()

public:
	virtual bool CanBuildTool(const FToolBuilderState& SceneState) const;
	virtual UInteractiveTool* BuildTool(const FToolBuilderState& SceneState) const;
	virtual void PostBuildTool(UInteractiveTool* Tool, const FToolBuilderState& SceneState) const;
	virtual void PostSetupTool(UInteractiveTool* Tool, const FToolBuilderState& SceneState) const;
};

```

UInteractiveToolManager的主要 API 总结如下。通常，您不需要实现自己的 ToolManager，基本实现功能齐全，并且应该执行使用工具所需的所有操作。但如果需要，您可以自由地扩展子类中的各种功能。


下面的函数大致按照您调用它们的顺序列出。 RegisterToolType()将字符串标识符与 ToolBuilder 实现相关联。然后，应用程序使用SelectActiveToolType()设置活动生成器，然后使用ActivateTool()创建新的 UInteractiveTool 实例。有 getter 来访问活动工具，但在实践中很少调用来频繁执行此操作。应用程序必须在每一帧调用Render()和Tick()函数，然后应用程序调用激活的工具的关联函数。最后DeactiveTool()用于终止激活的工具。


```cpp
UCLASS()
class UInteractiveToolManager : public UObject, public IToolContextTransactionProvider
{
    void RegisterToolType(const FString& Identifier, UInteractiveToolBuilder* Builder);
    bool SelectActiveToolType(const FString& Identifier);
    bool ActivateTool();

    void Tick(float DeltaTime);
    void Render(IToolsContextRenderAPI* RenderAPI);

    void DeactivateTool(EToolShutdownType ShutdownType);
};
```

=== 工具的生命周期 
在比较粗的层次上，工具的生命周期如下

+ ToolBuilder 已向 ToolManager 注册
+ 一段时间后，用户表示他们希望启动工具（例如通过按钮）
+ UI工具面板请求工具激活
+ ToolManager 检查 ToolBuilder.CanBuildTool() = true，如果是，则调用 BuildTool() 创建新实例
+ ToolManager 调用 Tool Setup()
+ 在 Tool 停用之前，每帧都会对其进行 Tick() 和 Render() 处理
+ 用户表明他们希望退出工具（例如通过按钮、热键等）
+ ToolManager 使用适当的关闭类型调用 Tool Shutdown()
+ 一段时间后，Tool 实例被垃圾收集

注意最后一步。每个工具是 UObject，因此不能依赖 C++ 析构函数进行清理。您应该在 Shutdown() 实现中进行任何清理，例如销毁临时参与者。
=== EToolShutdownType and the Accept/Cancel Model

第一种 Accepted/Cancel

第二种 Compeleted 直接退出

=== Base Tools
ITF包含了一些高频出现的工具，代码在BaseTools/目录下。

1. USingleClickTool 鼠标单击工具

```cpp
class INTERACTIVETOOLSFRAMEWORK_API USingleClickTool : public UInteractiveTool
{
    FInputRayHit IsHitByClick(const FInputDeviceRay& ClickPos);
    void OnClicked(const FInputDeviceRay& ClickPos);
};
```

`USingleClickTool`处理鼠标单击输入，如果`IsHitByClick()`函数返回有效的点击，则调用`OnClicked()`函数。您提供这两者的实现。请注意，此处的`FInputDeviceRay`结构包括 2D 鼠标位置和 3D 光线。

2. UClickDragTool

```cpp
class INTERACTIVETOOLSFRAMEWORK_API UClickDragTool : public UInteractiveTool
{
    FInputRayHit CanBeginClickDragSequence(const FInputDeviceRay& PressPos);
    void OnClickPress(const FInputDeviceRay& PressPos);
    void OnClickDrag(const FInputDeviceRay& DragPos);
    void OnClickRelease(const FInputDeviceRay& ReleasePos);
    void OnTerminateDragSequence();
};
```

`UClickDragTool`处理鼠标连续拖拽的情况，而不仅是单击。如果`CanBeginClickDragSequence()`返回 true（通常您会在此处进行命中测试，类似于 `USingleClickTool`），则将调用 `OnClickPress()` / `OnClickDrag()` / `OnClickRelease()`，类似于标准 OnMouseDown/Move/Up 事件模式。但请注意，您必须在OnTerminateDragSequence()中处理序列在没有 Release 的情况下中止的情况。


3. USingleSelectionTool 这个有点奇怪，没在basetool目录里，5.4倒是放进去。

```cpp
class USingleSelectionTool : public UInteractiveTool, public IInteractiveToolCameraFocusAPI{
{
GENERATED_BODY()
public:
	virtual void SetTarget(UToolTarget* TargetIn);
	virtual UToolTarget* GetTarget();
	virtual bool AreAllTargetsValid() const
	{
		return Target ? Target->IsValid() : false;
	}


public:
	virtual bool CanAccept() const override
	{
		return AreAllTargetsValid();
	}

protected:
	UPROPERTY()
	TObjectPtr<UToolTarget> Target;

public:
	// IInteractiveToolCameraFocusAPI implementation
	INTERACTIVETOOLSFRAMEWORK_API virtual bool SupportsWorldSpaceFocusBox() override;
	INTERACTIVETOOLSFRAMEWORK_API virtual FBox GetWorldSpaceFocusBox() override;
	INTERACTIVETOOLSFRAMEWORK_API virtual bool SupportsWorldSpaceFocusPoint() override;
	INTERACTIVETOOLSFRAMEWORK_API virtual bool GetWorldSpaceFocusPoint(const FRay& WorldRay, FVector& PointOut) override;

};

```

该工具用来处理单个选中的物体。也就是场景里有一个被选中的物体，当前工具需要对这个工具做编辑操作，USingleSelectionTool有几个API（IInteractiveToolCameraFocusAPI）用来获取物体相关的信息。


3.1 UMeshSurfacePointTool

```cpp
class UMeshSurfacePointTool : public USingleSelectionTool, public IClickDragBehaviorTarget, public IHoverBehaviorTarget
{
	GENERATED_BODY()

public:
    bool HitTest(const FRay& Ray, FHitResult& OutHit);
    void OnBeginDrag(const FRay& Ray);
    void OnUpdateDrag(const FRay& Ray);
    void OnEndDrag(const FRay& Ray);

    void OnBeginHover(const FInputDeviceRay& DevicePos);
    bool OnUpdateHover(const FInputDeviceRay& DevicePos);
    void OnEndHover();
}
```


UMeshSurfacePointTool与 UClickDragTool 类似，它提供了单击-拖动-释放输入处理模式。下面的HitTest()函数的默认实现将使用标准 LineTrace（因此，如果足够的话，您不必覆盖此函数）。 UMeshSurfacePointTool 还支持悬停，并跟踪 Shift 和 Ctrl 修饰键的状态。对于简单的“表面绘制”类型工具来说，这是一个很好的起点，并且许多建模模式工具都派生自 UMeshSurfacePointTool。 (一个小说明：这个类也支持读取手写笔压力，但是在 UE4.26 中手写笔输入是 Editor-Only) ((额外注意：虽然它被命名为 UMeshSurfacePointTool，但它实际上并不需要 Mesh，只需要一个支持线迹））


3.1.1 UBaseBrushTool

还有yi个基础工具UBaseBrushTool ，它使用基于画笔的 3D 工具特有的各种功能（即表面绘画画笔、3D 雕刻工具等）扩展了 UMeshSurfacePointTool。这包括一组标准画笔属性、3D 画笔位置/大小/衰减指示器、“画笔标记”跟踪以及各种其他有用的位。如果您正在构建画笔式工具，您可能会发现这很有用。


=== FToolBuilderState 

UInteractiveToolBuilder API 函数都需要 FToolBuilderState 参数。该结构的主要提供了哪些物体被选中信息。 它指示工具将或应该执行的操作。该结构体的关键字段如下所示。 ToolManager 将构造一个 FToolBuilderState 并将其传递给 ToolBuilder，然后 ToolBuilder 将使用它来确定是否可以对选择进行操作。在 UE4.26 ITF 实现中，Actor 和 Components 都可以传递，但也只能传递Actor 和Components。请注意，如果某个组件出现在 SelectedComponents 中，那么它的 Actor 也会出现在 SelectedActors 中。包含这些 Actor 的 UWorld 也包括在内。

```cpp
/**
 * FToolBuilderState is a bucket of state information that a ToolBuilder might need
 * to construct a Tool. This information comes from a level above the Tools framework,
 * and depends on the context we are in (Editor vs Runtime, for example).
 */
struct FToolBuilderState
{
	/** The current UWorld */
	UWorld* World = nullptr;
	/** The current ToolManager */
	UInteractiveToolManager* ToolManager = nullptr;
	/** The current TargetManager */
	UToolTargetManager* TargetManager = nullptr;
	/** The current GizmoManager */
	UInteractiveGizmoManager* GizmoManager = nullptr;

	/** Current selected Actors. May be empty or nullptr. */
	TArray<AActor*> SelectedActors;
	/** Current selected Components. May be empty or nullptr. */
	TArray<UActorComponent*> SelectedComponents;

	UE_DEPRECATED(5.1, "This has moved to a context object. See IAssetEditorContextInterface")
	TWeakObjectPtr<UTypedElementSelectionSet> TypedElementSelectionSet;

	PRAGMA_DISABLE_DEPRECATION_WARNINGS
	FToolBuilderState() = default;
	FToolBuilderState(FToolBuilderState&&) = default;
	FToolBuilderState(const FToolBuilderState&) = default;
	FToolBuilderState& operator=(FToolBuilderState&&) = default;
	FToolBuilderState& operator=(const FToolBuilderState&) = default;
	PRAGMA_ENABLE_DEPRECATION_WARNINGS
};
```


在建模模式工具中，我们不直接操作组件，而是将它们包装在标准容器中，这样我们就可以对具有容器实现的“任何”网格组件进行 3D 雕刻。这很大程度上是我编写本教程的原因，因为我可以使用这些工具编辑其他类型的网格，例如运行时网格。但是在构建您自己的工具时，您可以忽略 FToolBuilderState。您的 ToolBuilder 可以使用任何其他方式来查询场景状态，并且您的工具不限于作用于 Actor 或组件。



=== On ToolBuilders

ITF 用户经常提出的一个问题是 UInteractiveToolBuilder 是否有必要。在最简单、最常见的情况下，您的 ToolBuilder 将是简单的样板代码（不幸的是，由于它是 UObject，因此该样板无法直接转换为 C++ 模板）。当人们开始重新利用现有的 UInteractiveTool 实现来解决不同的问题时，ToolBuilder 的实用性就出现了。

例如，在 UE 编辑器中，我们有一个用于编辑网格多边形组（实际上是多边形）的工具，称为 PolyEdit。我们还有一个非常相似的用于编辑网格三角形的工具，称为 TriEdit。在底层，它们是相同的 UInteractiveTool 类。在 TriEdit 模式下，Setup() 函数配置工具的各个方面以适合三角形。为了在 UI 中公开这两种模式，我们使用两个单独的 ToolBuilder，它们在创建的 Tool 实例分配后、Setup() 运行之前设置“bIsTriangleMode”标志。


我当然不会说这是一个优雅的解决方案。但是，这是权宜之计。根据我的经验，随着您的工具集不断发展以处理新情况，这种情况会一直出现。通常，可以通过一些自定义初始化、一些附加选项/属性等来填充现有工具来解决新问题。在理想的世界中，人们可以重构工具，通过子类化或组合来实现这一点，但我们很少生活在理想的世界中。因此，破解工具以完成第二项工作所需的一些难看的代码可以放置在自定义 ToolBuilder 中，并在其中（相对）封装。

用于向 ToolManager 注册 ToolBuilder 的基于字符串的系统可以允许您的 UI 级别（即按钮处理程序等）启动 Tools，而无需实际了解 Tool 类类型。这通常可以在构建 UI 时更清晰地分离关注点。例如，在我将在下面描述的 ToolsFrameworkDemo 中，工具是由 UMG Blueprint Widget 启动的，它们只是将字符串常量传递给 BP 函数 - 它们根本不了解工具系统。然而，在生成工具之前设置“活动”构建器的需要在某种程度上是一种退化，并且这些操作将来可能会被合并。


== The Input Behavior System

上面提到过“交互式工具处理鼠标键盘等设备输入”。但 UInteractiveTool API 没有任何鼠标输入处理函数。这是因为输入处理（大部分）与工具分离。输入由UInputBehavior对象捕获和解释，该对象需要被注册到UInputRouter里，UInputRouter “拥有”输入设备并将输入事件路由到适当的行为。

为什么要分离？大部分鼠标处理逻辑都是样板代码，用户只要鼠标点了、拽了、按键按了一下这些事件即可。而且，鼠标处理逻辑非常复杂，mouseup、mouserelease都不能直接指示一个鼠标点击事件（这里的”鼠标点击”是人们常说的点击，不是一个非常精确的描述，，比如点-拖拽-抬，拖拽时间小到多少程度才算“点击”？），这些麻烦的事情，全部交给behavior系统来做。

因此，出于这个原因，ITF 将这些小型输入事件处理状态机转移到 UInputBehavior 实现中，以便可以在许多工具之间共享。事实上，一些简单的行为（例如USingleClickInputBehavior 、 UClickDragBehavior和UHoverBehavior ）可以处理鼠标驱动交互的大多数情况。然后，行为通过工具或 Gizmo 等可以实现的简单接口将其提取的事件转发到目标对象。例如 USingleClickInputBehavior 可以作用于任何实现IClickBehaviorTarget的东西，它只有两个函数 - IsHitByClick() 和 OnClicked()。请注意，因为 InputBehavior 不知道它正在作用什么（“按钮”可以是 2D 矩形或任意 3D 形状），所以 Target 接口必须提供命中测试功能。

InputBehavior 系统的另一个方面是工具不直接与 UInputRouter 对话。他们只提供他们希望激活的 UInputBehavior 列表。支持此功能的 UInteractiveTool API 的新增内容如下所示。通常，在工具的 ::Setup() 实现中，会创建和配置一个或多个输入行为，并将其传递给 AddInputBehavior。然后，ITF 在必要时调用 GetInputBehaviors，以向 UInputRouter 注册这些行为。注意：目前，输入行为集无法在工具期间动态更改，但是您可以根据您希望的任何标准配置行为以忽略事件。


```cpp
class UInteractiveTool : public UObject, public IInputBehaviorSource
{
    // ...previous functions...

    void AddInputBehavior(UInputBehavior* Behavior);
    const UInputBehaviorSet* GetInputBehaviors();
};
```

UInputRouter与 UInteractiveToolManager 类似，默认实现足以满足大多数用途。 InputRouter 的唯一工作是跟踪所有活动的输入行为并调节输入设备的捕获。捕获是工具中输入处理的核心。当 MouseDown 事件进入 InputRouter 时，它会检查所有已注册的行为，询问它们是否要开始捕获鼠标事件流。例如，如果您按下某个按钮，该按钮的注册 USingleClickInputBehavior 将表明是的，它想要开始捕获。一次只允许一个行为捕获输入，并且多个行为（彼此不了解）可能想要捕获 - 例如，与当前视图重叠的 3D 对象。因此，每个行为都会返回一个 FInputCaptureRequest，指示“是”或“否”以及深度测试和优先级信息。然后，UInputRouter 查看所有捕获请求，并根据深度排序和优先级，选择一个行为并告诉它捕获将开始。然后，MouseMove 和 MouseRelease 事件仅传递给该行为，直到 Capture 终止（通常在 MouseRelease 上）。

实际上，在使用 ITF 时，您很少需要与 UInputRouter 进行交互。一旦建立了应用程序级鼠标事件和 InputRouter 之间的连接，您就不需要再次触摸它。该系统很大程度上解决了常见错误，例如由于捕获错误而导致鼠标处理“卡住”，因为 UInputRouter 最终控制鼠标捕获，而不是单个行为或工具。在附带的 ToolsFrameworkDemo 项目中，我已经实现了 UInputRouter 运行所需的一切。

基本的 UInputBehavior API 如下所示。 FInputDeviceState是一个大型结构，包含给定事件/时间的所有输入设备状态，包括常用修改键的状态、鼠标按钮状态、鼠标位置等。与许多输入事件的一个主要区别是，还包括与输入设备位置关联的 3D 世界空间射线。

```cpp
UCLASS()
class UInputBehavior : public UObject
{
    FInputCapturePriority GetPriority();
    EInputDevices GetSupportedDevices();

    FInputCaptureRequest WantsCapture(const FInputDeviceState& InputState);
    FInputCaptureUpdate BeginCapture(const FInputDeviceState& InputState);
    FInputCaptureUpdate UpdateCapture(const FInputDeviceState& InputState);
    void ForceEndCapture(const FInputCaptureData& CaptureData);

    // ... hover support...
}
```

为了简化事情，我在上面的 API 中省略了一些额外的参数。特别是如果您实现自己的行为，您会发现几乎到处都有一个 EInputCaptureSide 枚举传递，主要作为默认的 EInputCaptureSide::Any。这是供将来使用的，以支持行为可能特定于任意一只手的 VR 控制器的情况。


然而，对于大多数应用程序，您可能会发现您实际上不需要实现自己的行为。如上所述的一组标准行为包含在 InteractiveToolFramework 模块的 /BaseBehaviors/ 文件夹中。大多数标准行为都派生自基类UAnyButtonInputBehavior ，这使得它们可以使用任何鼠标按钮，包括由 TFunction （可以是键盘键）定义的“自定义”按钮！类似地，标准BehaviorTarget实现都派生自IModifierToggleBehaviorTarget ，它允许在Behavior上配置任意修饰键并将其转发到Target，而无需子类化或修改Behaviour代码。


=== Direct Usage of UInputBehaviors


=== Non-Mouse Input Devices

TODO
==== A Limitation - Capture Interruption
TODO

== Tool Property Sets

UInteractiveTool 还有一组我没有介绍的 API 函数，用于管理一组附加的UInteractiveToolPropertySet对象。这是一个完全可选的系统，在某种程度上是为 UE 编辑器中的使用而定制的。对于运行时使用来说，它的效率较低。本质上，UInteractiveToolPropertySet 用于存储您的工具设置和选项。它们是具有 UProperties 的 UObject，在编辑器中，可以将这些 UObject 添加到 Slate DetailsView 以自动在编辑器 UI 中公开这些属性。

下面总结了其他 UInteractiveTool API。一般在Tool::Setup()函数中，会创建各种UInteractiveToolPropertySet子类并传递给AddToolPropertySource()。 ITF 后端将使用 GetToolProperties() 函数初始化 DetailsView 面板，然后 Tool 可以使用 SetToolPropertySourceEnabled() 动态显示和隐藏属性集

```cpp
class UInteractiveTool : public UObject, public IInputBehaviorSource
{
    // ...previous functions...
public:
    TArray<UObject*> GetToolProperties();
protected:
    void AddToolPropertySource(UObject* PropertyObject);
    void AddToolPropertySource(UInteractiveToolPropertySet* PropertySet);
    bool SetToolPropertySourceEnabled(UInteractiveToolPropertySet* PropertySet, bool bEnabled);
};
```


在 UE 编辑器中，UProperties 可以使用元标记进行标记，以控制生成的 UI 小部件 - 例如滑块范围、有效整数值以及基于其他属性值启用/禁用小部件。建模模式中的大部分 UI 都是以这种方式工作的。


不幸的是，UProperty 元标记在运行时不可用，并且 UMG Widget 不支持 DetailsView 面板。结果，ToolPropertySet 系统变得不那么引人注目。但它仍然提供了一些有用的功能。其一，属性集支持使用属性集的 SaveProperties() 和 RestoreProperties() 函数跨工具调用保存和恢复其设置。您只需对 Tool Shutdown() 中设置的每个属性调用 SaveProperties()，并在 ::Setup() 中调用 RestoreProperties()。


第二个有用的功能是 WatchProperty() 函数，它允许响应 PropertySet 值的更改，而无需任何类型的更改通知。这对于 UObject 是必要的，因为 C++ 代码可以直接更改 UObject 上的 UProperty，并且这不会导致发送任何类型的更改通知。因此，可靠地检测此类更改的唯一方法是通过轮询。是的，投票。这并不理想，但请务必考虑到 (1) 工具必须具有用户可以处理的有限数量的属性，以及 (2) 一次只有一个工具处于活动状态。为了使您不必为 ::OnTick() 中的每个属性实现存储值比较，您可以使用以下模式添加观察者：

```
MyPropertySet->WatchProperty( MyPropertySet->bBooleanProp,  [this](bool bNewValue) { // handle change! } );
```

在 UE4.26 中，有一些必须解决的附加警告（即错误），请参阅下文了解更多详细信息。


== Tool Actions

Action主要是为了支持快捷键的功能，UInteractiveTool通过函数`GetActionSet()`返回了该工具用到的快捷键。

Action有一个整数ID，Tool的有一个接口接收这个ID，执行对应的Action。

每个Action是一个`TFunction<void()>`。

该抽象方式方便蓝图调用，。


== Gizmos 

Gizmos（小部件），就是编辑操作的控制器，比如W移动时的三维坐标轴，E旋转时的三个四分之一圆，用户通过操作这些控制器来做编辑。

Gizmos用来捕获用户的输入，但不是一个完整的tool，只是一小步的编辑操作。


在交互式工具框架中，Gizmos 被实现为UInteractiveGizmo的子类，它与 UInteractiveTool 非常相似：


```cpp
UCLASS(Transient, MinimalAPI)
class UInteractiveGizmo : public UObject, public IInputBehaviorSource
{
	GENERATED_BODY()

public:
	  UInteractiveGizmo(); 

    virtual void Setup(); 
    virtual void Shutdown(); 
    virtual void Render(IToolsContextRenderAPI* RenderAPI); 
    virtual void DrawHUD( FCanvas* Canvas, IToolsContextRenderAPI* RenderAPI );
    virtual void Tick(float DeltaTime);
    virtual UInteractiveGizmoManager* GetGizmoManager() const;

	//
	// Input Behaviors support
	// 
    virtual void AddInputBehavior(UInputBehavior* Behavior);
    virtual const UInputBehaviorSet* GetInputBehaviors() const;



protected:

	/** The current set of InputBehaviors provided by this Gizmo */
	UPROPERTY()
	TObjectPtr<UInputBehaviorSet> InputBehaviors;
};
```


类似地，Gizmo 实例由UInteractiveGizmoManager管理，使用通过字符串注册的UInteractiveGizmoBuilder工厂。 Gizmos 使用相同的 UInputBehavior 设置，并由 ITF 进行类似的渲染和Tick。

在这个高层次上，UInteractiveGizmo 只是一个骨架，要实现自定义 Gizmo，您必须自己做大量工作。与工具不同，由于视觉表示方面的原因，提供“基础”Gizmos 更具挑战性。特别是，标准输入行为将要求您能够针对您的 Gizmo 进行光线投射命中测试，因此您不能只在 Render() 函数中绘制任意几何体。也就是说，ITF 确实提供了一个非常灵活的标准 Translate-Rotate-Scale Gizmo 实现，可以重新利用它来解决许多问题。

=== 标准 UTransformGizmo

最基本的Gizmo就是标准的平移-旋转-缩放 (TRS) Gizmos。，它支持轴和平移（轴线和中央V形）、轴旋转（圆形）、统一缩放（中央框）、轴缩放（外轴支架）和平面比例（外 V 形）。这些子Gizmos可以分开组合。

#figure(
    image("./ToolsFrameworkDemo_Gizmo.png")
)


Gizmo可以嵌套分层，比如上边这个，轴平移子小控件（绘制为红/绿/蓝线段）是UAxisPositionGizmo的实例，旋转圆是UAxisAngleGizmo 。这几个子Gizmos组合成了UTransformGizmo。我们自定义的其他Gizmo也可以组合嵌套。该系统比较复杂。



