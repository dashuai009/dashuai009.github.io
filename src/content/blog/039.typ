
#let date = datetime(
  year: 2022,
  month: 11,
  day: 12,
)
#metadata((
  title: "cmake解决visual studio 运行时库链接错误",
  subtitle: [visual stduio],
  author: "dashuai009",
  description: "在visual studio中，连接其他库时会遇到runtime library连接错误，cmake可以设置该参数",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

== 错误信息
<错误信息>

Error LNK2038 mismatch detected for 'RuntimeLibrary': value
'MT\_StaticRelease' doesn’t match value 'MD\_DynamicRelease' in file.obj

在vs中，链接其他库时会遇到这种错误，这是运行时库的版本没有和已有项目对齐。

== RuntimeLibrary是什么
<runtimelibrary是什么>

CRT：C Runtime Library
，C语言运行时库，系统自动为程序加载该库，以便访问C标准函数。同样，C++也有类似的东西。

该库有动态和静态两个版本，现在windows推荐使用动态库。之前还分单线程和线程两种，现在只推荐多线程库。同时，根据是否能调试，总共分为四种库：#strong[多线程静态库，多线程动态库，多线程静态库debug版，多线程动态库debug版];。在vs中通过编译选项控制。

作用：
- 提供C标准库(如memcpy、printf、malloc等)、C++标准库（STL）的支持。

- 应用程序添加启动函数，启动函数的主要功能为将要进行的程序初始化，对全局变量进行赋初值，加载用户程序的入口函数。

== 在sln中设置runtimelibrary
<在sln中设置runtimelibrary>
项目-\> properties -\> c/c++ -\> code generation -\>
改为Multi-threaded(/MT)

#quote[
  我这边的主项目没法修改，默认是/MT。只能把第三方的库编译时选则#strong[静态多线程 运行时库];。这样就能接入主项目。
]

== 在cmake中设置runtimelibrary
<在cmake中设置runtimelibrary>
cmake中提供了一个变量#link("https://cmake.org/cmake/help/latest/variable/CMAKE_MSVC_RUNTIME_LIBRARY.html")[CMAKE\_MSVC\_RUNTIME\_LIBRARY];可以设置该值。该值有四种值可选

- MultiThreaded ，-MT选项
- MultiThreadedDLL，-MD选项
- MultiThreadedDebug ，-MTd选项
- MultiThreadedDebugDLL，-MDd选项

如果设置不正确，会报错（即使是在其他平台下）。 设置方法如下：

`set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")`

（ 图不放了，很好找

这样在debug/release里使用不同的配置，，在我的问题中，写死`set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")`。

== note！！！！！！！！
<note>
上边的都可以不看，这个必须注意

#quote[
  Note: This variable has effect only when policy CMP0091 is set to NEW prior to the first project() or enable\_language() command that enables a language using a compiler targeting the MSVC ABI.
]

该值必须在第一个project()或enable\_language()#strong[之前]
设置规则`CMP0091`。

也就是说，想要设置该规则，必须在顶级项目（子项目中不行，为了统一所有项目的该值）之前启用该规则。

```
cmake_mininum_required(VERSION 3.15.0)
if(POLICY CMP0091) # 检测是否可用，也就是cmake的版本是否大于等于3.15
 cmake_policy(SET CMP0091 NEW)
endif()
project(balabala)

if (CMAKE_SYSTEM_NAME  matches "Windows")
 set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")
endif()
```
