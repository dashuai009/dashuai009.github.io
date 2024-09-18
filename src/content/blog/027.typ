#let date = datetime(
  year: 2022,
  month: 6,
  day: 9,
)
#metadata((
  title: "rust减少编译警告",
  subtitle: [rust],
  author: "dashuai009",
  description: "项目前期开发中，可以通过RUSTFLAGS减少rust编译时给出的警告。后期去掉这些选项即可。",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


== rust编译信息
<rust编译信息>
#link("https://doc.rust-lang.org/reference/attributes/diagnostics.html")[diagnostics attributes]

#link("https://doc.rust-lang.org/rustc/lints/levels.html")[lints levels]

rust分为四种lint信息：
- #strong[allow( C )] overrides the check for C so that violations will go unreported,
- #strong[warn( C )] warns about violations of C but continues compilation.
- #strong[deny( C )] signals an error after encountering a violation of C,
- #strong[forbid( C )] is the same as deny( C ), but also forbids changing the lint level afterwards

默认情况下rust编译会给出#strong[大量警告信息];，比如变量命名不规范、未使用的变量等等。比较烦人，有很多种方法可以减少这些信息。

== 查看所有lint
<查看所有lint>
`rustc -W help`

== 通过lint check属性减少编译警告
<通过lint-check属性减少编译警告>
（lint check attribute 这不知道咋翻译了

将前边提到的C替换成`rustc -W help`看到的东西。比如给函数添加`#[allow(missing_docs)]`可以允许不写相关文档。

== 设置RUSTFLAGS
<设置rustflags>
执行rustc之前可以在export一些环境变量。

`export RUSTFLAGS="$RUSTFLAGS -A unused"; rustc balbalbaba`

在intellij系列的IDE中，可给运行/调试配置中自动添加这些环境变量。
不过，配置里#strong[不需要添加引号”];，他会自动加上。

#figure(
  image("027/clion.png"),
  caption: [
    示意图
  ],
)

上边这个脚本配置相当于这条命令：
`export RUSTFLAGS="$RUSTFLAGS -A dead_code -A unused -A non_snake_case -A non_upper_case_globals -A non_camel_case_types"; wasm-pack build`

这里我用到了以下几个

- -A dead\_code
- -A unused 允许未使用（变量、函数等，一个lint group）
- -A non\_snake\_case 允许这三种不推荐的命名方式
- -A non\_upper\_case\_globals
- -A non\_camel\_case\_types

全给他allow。#strike[美滋滋，编译结果清净了]