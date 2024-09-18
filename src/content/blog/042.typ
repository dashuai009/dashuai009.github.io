
#let date = datetime(
  year: 2023,
  month: 5,
  day: 18,
)
#metadata((
  title: "c++23的std::print简单示例",
  subtitle: [c++23],
  author: "dashuai009",
  description: "",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


== 介绍
cpp23中加入了一个标准库std::print，类似python中的print。据说不是基于std::cout，性能应该有保障。

== 支持的编译器
目前只有msvc支持了这一标准库。在2023/05/17发布的vs2022 17.7.0 preview1中，加入了#link("https://github.com/microsoft/STL/pull/3337")[相关代码]。

== 示例

```cpp
import std;

int main() {
    std::vector test{ 10, 2, 3 };
    std::ranges::sort(test);
    for (auto const& [index, value] : std::ranges::enumerate_view(test)) {
        std::println("index = {}, val = {}", index, value);
    }
    return 0;
}
```

输出
```
index = 0, val = 2

index = 1, val = 3

index = 2, val = 10
```

== 看起来不错
看起来有点pythonic