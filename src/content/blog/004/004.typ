#let date = datetime(
  year: 2022,
  month: 5,
  day: 1,
)
#metadata((
  "title": "ToDo",
  "author": "dashuai009",
  description: "",
  pubDate: date.display(),
  subtitle: [kotlin,Android],
))<frontmatter>

#import "../../__template/style.typ": conf
#show: conf


#date.display();


= 相关技术

== kotlin

在Google I/O 2017中，Google 宣布 Kotlin 成为 Android官方开发语言。官方文档中，java和kotlin是并列出现的。作为一种新型语言，相比与java， 它有以下优势：

1. 简洁：大大减少样板代码的数量（没有new关键字，没有分号等）。

2. 安全: 避免空指针异常等整个类的错误。

3. 互操作性: 充分利用 JVM、Android 和浏览器的现有库。

4. 工具友好: 可用任何 Java IDE 或者使用命令行构建。

== room可持久库

Room 在 SQLite 上提供了一个抽象层，以便在充分利用 SQLite的强大功能的同时，能够流畅地访问数据库。更重要的，**Google官方强烈建议我们使用Room（而不是SQLite）**。

Room 包含 3 个主要组件：

1. 数据库：包含数据库持有者，并作为应用已保留的持久关系型数据的底层连接的主要接入点。

  使用 `@Database` 注释的类应满足以下条件：

  - 是扩展 RoomDatabase 的抽象类。

  - 在注释中添加与数据库关联的实体列表。

  - 包含具有 0 个参数且返回使用`@Dao` 注释的类的抽象方法。

  在运行时，您可以通过调用 `Room.databaseBuilder()` 或`Room.inMemoryDatabaseBuilder()` 获取 `Database` 的实例。

2. Entity：表示数据库中的表。

3. DAO：包含用于访问数据库的方法。

应用使用 Room 数据库来获取与该数据库关联的数据访问对象(DAO)。然后，应用使用每个 DAO从数据库中获取实体，然后再将对这些实体的所有更改保存回数据库中。最后，应用使用实体来获取和设置与数据库中的表列相对应的值。

Room 不同组件之间的关系如图 1 所示：

![Room 架构图](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/4/room_architecture.png)

== Android架构

在大多数情况下，桌面应用将桌面或程序启动器当做单个入口点，然后作为单个整体流程运行。Android应用则不然，它们的结构要复杂得多。典型的 Android应用包含多个应用组件，包括Activity、Fragment、Service、内容提供程序和广播接收器。

移动设备的资源也很有限，因此操作系统可能会随时终止某些应用进程，以便为新的进程腾出空间。

鉴于这种环境条件，应用组件可以不按顺序地单独启动，并且操作系统或用户可以随时销毁它们。由于这些事件不受您的控制，因此**我们不应在应用组件中存储任何应用数据或状态**，并且应 用组件不应相互依赖。

== 常见的架构原则

=== 分离关注点

要遵循的最重要的原则是**分离关注点**。 一种常见的错误是在一个 Activity或 Fragment 中编写所有代码。这些基于界面的类应仅包含处理界面和操作系统交互的逻辑。应使这些类尽可能保 持精简，这样可以避免许多与生命周期相关的问题。

请注意，我们并非拥有 Activity 和 Fragment 的实现； 它们只是表示 Android操作系统与应用之间关系的粘合类。操作系统可能会根据用户互动或因内存不足等系统条件随时销毁它们。为了提供令人满意的用户体验和更易于管理的应用维护体验，最好尽量减少对它们的依赖。

=== 通过模型驱动界面

另一个重要原则是您应该通过模型驱动界面（最好是持久性模型）。模型是负责处理应用数据的组件。它们独立于应用中的View 对象和应用组件，因此不受应用的生命周期以及相关的关注点的影响。

持久性是理想之选，原因如下：

- 如果 Android 操作系统销毁应用以释放资源，用户不会丢失数据。

- 当网络连接不稳定或不可用时，应用会继续工作。

应用所基于的模型类应明确定义数据管理职责，这样将使应用更可测试且更一致。

== ToDo的应用结构

Google官方推荐如下架构，在我的ToDo应用中也实现了如下架构，非常amazing。

![ToDo架构图](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/4/final-architecture.png)

= 系统功能要求

== 用户需求

普通用户需要一个待办记录软件，希望我们实现如下功能：

- 记录并展示待办事项。

- 可编辑每个事项。

- 可以对事项进行排序。

== 需求分析

通过对用户需求的调查，我们可以得出如下具体的需求。

- 将每个事项抽象为包括**id(编号)、content(待办内容)、priority(优先级)、date(截止日期)、Done(是否完成)**。

- 将所有事项依次展示，形成一个列表。

- 添加一个事项。

  我们可以实现一个添加按钮，用户点击之后，可以添加一个事项，并实时展示相应内容。

- 编辑事项。

  当用户点击列表中的某个事项，可以对该事项进行编辑。

- 排序。

  设定两种排序方式，一种按照`id`字段进行排序，另一种按照`priority,date`两个字段进行排序。

= 系统设计与实现

总共设计了`MainActivity`和`NoteActivity`两个Acticity组件，`db`和`ui`两个模块。

== MainActicity

这是整个程序的主入口。

主要有如下几个函数和接口

- `onCreate`

  这是MainActivity的生命周期中的开始部分。绑定视图等内容就是在这里定义和实现。

- 扩展了`NoteListAdapter.NoteListener`

  对于ListView中的每条目，实现三个接口。`onContentClick(curNote: Note)`,\
  `onCheckBoxClick(curNote: Note)`,`onDeleteBtnClick(curNote: Note)`

- refresh

  用于更新RecylerView的模块，是否排序等。

- `private lateinit var mSharedPreferences: SharedPreferences`

  用户保存用户配置：是否排序。

- onOptionsItemSelected

  右上角给出用户是否排序的选项。

- onActivityResult

  接收 NoteActivity的返回结果，根据id段是否为0分别进行插入和删除操作。

== NoteActivity

该组件提供给用户编辑条目的界面。当用户新建条目或编辑条目时都会跳转至该界面。

- `var editText: EditText`用于编辑和显示事项的内容。

- `var dateText: TextView;var timeText: TextView`显示选择的日期和时间。

- `var addBtn: Button`提交按钮。

- `var prioritySpinner: Spinner`选择优先级，0,1,2

- 直接通过xml定义timePicker和datePicker。

== db

这里实现了数据库，使用到了*room可持久库*，有如下四个部分。

=== dao

定义了NoteDao类，这里实现了数据库的sql语句。

=== entity

有两个类。

1. Note

  这是数据库条目的具体定义，并扩展了`Parcelable`，利用kotlin的序列化，可以非常方便的在Activity之间传递`note`类。

2. DateToLongConverters

  android内的SQLite无法直接保存Date类型，定一个转换器，将Date自动转化为Long类型，自动将Long转化回Date类型。

=== NoteRepository

存储库可管理查询，且允许您使用多个后端。在最常见的示例中，存储库可实现对以下任务做出决定时所需的逻辑：是否从网络中提取数据；是否使用缓存在本地数据库中的结果。

![存储库](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/4/cdfae5b9b10da57f.png)

=== Room数据库：TodoDateBase

什么是 Room 数据库？

- Room 是 SQLite 数据库之上的一个数据库层。

- Room 负责您平常使用 SQLiteOpenHelper 所处理的单调乏味的任务。

- Room 使用 DAO 向其数据库发出查询请求。

- 为避免界面性能不佳，默认情况下，Room
  不允许在主线程上发出查询请求。当 Room 查询返回 Flow时，这些查询会在后台线程上自动异步运行。

- Room 提供 SQLite 语句的编译时检查。

== ui

这里定义了几个关于界面的组件。

=== NoteListAdapter

ListView的适配器。绑定了试图的操作，根据`分离关注点`的原则，我定义了几个接口，这些接口将在MainActivity中实现（这样比较方便而已，最好是定义在一个单独的类中）。

=== NoteViewModel

ViewModel 的作用是向界面提供数据，不受配置变化的影响。ViewModel充当存储库和界面之间的通信中心。您还可以使用 ViewModel 在 fragment之间共享数据。ViewModel 是 Lifecycle 库的 一部分。

![ViewModel](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/4/72848dfccfe5777b.png)

ViewModel以一种可以感知生命周期的方式保存应用的界面数据，不受配置变化的影响。它会将应用的界面数据与Activity 和 Fragment 类区分开，让您更好地遵循单一责任原则：activity 和fragment 负责将数据绘制到屏幕上，ViewModel则负责保存并处理界面所需的所有数据。

LiveData 是一种可观察的数据存储器，每当数据发生变化时，都会收到通知。与Flow 不同，LiveData 具有生命周期感知能力，即遵循其他应用组件（如activity 或 fragment）的生命周期。LiveData会根据负责监听变化的组件的生命周期自动停止或恢复观察。因此，LiveData适用于界面使用或显示的可变数据。

ViewModel 会将存储库中的数据从 Flow 转换为 LiveData，并将字词列表作为LiveData传递给界面。这样可以确保每次数据库中的数据发生变化时，界面都会自动更新。

在 Kotlin 中，所有协程都在 CoroutineScope中运行。范围用于控制协程在整个作业过程中的生命周期。如果取消某一范围内的作业，该范围内启动的所有协程也将取消。

AndroidX lifecycle-viewmodel-ktx 库将 viewModelScope 添加为 ViewModel类的扩展函数，使您能够使用范围。

=== 两个Fragment

分别是DatePicker和DatePicker。

= 软件可能的扩展

== 存储库

在这里我们定义并实现了NoteResposity。在当前这个应用中，数据库的来源只有本地的数据库。这个存储库可以实现网络数据的拉取，而不需要更改其他代码。

== 功能更新

可以将事项添加到日历，并添加闹钟。但作为一个普通应用，而不是系统内置应用，访问日历有隐私问题。暂不考虑。

分类。可以将不同的事项分为不同的类。同类产品中有这种功能，实际体验中，用户需求度不高。

== 应用迭代

代码和apk发布在如下github仓库。

[github](https://github.com/dashuai009/ToDo)

如果有更新会提交的这里。

= 总结体会

1. 课程体会。本门课程与实际生活关联很大，不仅有用户体验方面的，还有技术实现上。

2. 技术总结。

- kotlin。
  非常的简洁，也避免的null错误等。
- room可持久库。
  避免使用 SQLiteOpenHelper 所处理的单调乏味的任务。
- android设计原则。
  虽然在这次编程中实现的不是很好，但可以明显的看出遵循原则之后，代码比较优美。'