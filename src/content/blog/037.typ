#let date = datetime(
  year: 2022,
  month: 10,
  day: 25,
)
#metadata((
  title: "cmake对c++20 module的支持",
  subtitle: [c++20,modules,cmake],
  author: "dashuai009",
  description: "在cmake中，通过target_source增加了对c++20 module特性的支持。到了3.25版本，这一命令得到大幅改进。看起来是对c++20 module做了应有的支持（编译器不支持的语法，cmake也没办法）。",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

== 相关链接
<相关链接>
#link("https://zhuanlan.zhihu.com/p/350136757")[知乎 孙孟越]
介绍比较详细了，还介绍了 C++ 之父介绍了 modules 的发展进程.

#link("https://github.com/royjacobson/modules-report")[github modules-reportmodules-report]

#link("https://cmake.org/cmake/help/latest/command/target_sources.html")[cmake target\_sources]

#link("https://www.youtube.com/watch?v=hkefPcWySzI")[target\_sources CMake 2022 C++ Modules and More - Bill Hoffman - CppNow 2022]
22年7月就分享了如何支持module,一直到10月份才出来。

== target\_sources
<target_sources>
简单示例，上边youtube中的。

#figure(
  image("037/cmake.png"),
  caption: [
    cmake target\_source
  ],
)

== demo
<demo>
#link("https://www.kitware.com/import-cmake-c20-modules/")[import CMake; C++20 Modules (kitware.com)]

上边是cmake官方给出的例子，比较简单。

我在vs2022 preview 17.6、cmake3.26下测试，模块分区（module internal
partition）还不被支持。 目前来说（2023.4）c++20的构建系统还不是很完善。
