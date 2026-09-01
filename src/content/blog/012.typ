#let date = datetime(
  year: 2024,
  month: 7,
  day: 20,
)
#metadata((
  "title": "使用yalantinglibs中的反射库格式化自定义struct/enum",
  "author": "dashuai009",
  description: "",
  pubDate: date.display(),
  subtitle: [modules,模块],
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


#date.display();

#outline()


yalantinglibs是一个c++20的库集合。
std::formatter是c++20的新特性，用来格式化内容。

这里尝试使用ylt里的反射库实现自定义struct/enum的格式化输出


== std::format的基本用法
=== 基本用法
头文件`#include <format>`

一眼看起来和python rust的格式化语法很类似。实际用起来，受限制很多。比如std::format的控制字符串需要编译期检查，没法运行时生成，也没有python的`print(f"a = {a}")`（这叫啥？），参数只能放到后面`std::println("a = {}", a)`。

~~总之，比没有好~~。

```cpp
#include <format>
#include <string>


int main(){
    int a = 42;
    std::string b{"Hello World!"};
    float c = 10.24;
    std::cout << std::format("a = {}, b = {}, c = {:.4f}\n", a, b, c);
    return 0;
}
```

输出内容
```text
a = 42, b = Hello World!, c = 10.2400

```

=== 扩展用法

自定义的struct/enum都没有默认支持，需要自定义`std::formatter<T>`来实现。

具体来说，需要特化`std::formatter<T>`，并实现他的两个函数
- `parse()` 实现如何解析类型的格式字符串说明符
- `format()` 为自定义类型的对象/值执行实际格式化


```
#include <iostream>
#include <format>
#include <string>

struct Person {
    std::string name;
    int age;
};

// 定义Person的formatter
template<>
struct std::formatter<Person> {
    static constexpr auto parse(std::format_parse_context& ctx) {
        return ctx.begin();
    }

    auto format(const Person& p, std::format_context& ctx) const {
        return std::format_to(ctx.out(), "Person(name: {}, age: {})", p.name, p.age);
    }
};

int main() {
    Person p{"Alice", 30};
    std::string s = std::format("{}", p);
    std::cout << s << std::endl;

    return 0;
}

```

输出

```
Person(name: Alice, age: 30)

```

=== 其他用法

太多了，不给自己挖坑了。推荐看这个#link("https://github.com/xiaoweiChen/CXX20-The-Complete-Guide")[c++20 compelte guide]

- `std::vformat() 和 vformat_to()`
- 格式字符串的语法
- 标准格式说明符：`fill align sign # 0 width .prec L type`
- 全局化，语言环境
- 错误处理
- 自定义格式
- 自定义格式的解析格式字符串

== yalantinglibs的reflection

官方示例#link("https://github.com/alibaba/yalantinglibs/blob/main/src/reflection/tests/test_reflection.cpp")[test_reflection]

文章#link("http://www.purecpp.cn/detail?id=2435")[C++20 非常好用的编译期反射库，划重点【没有宏，没有侵入式】]


=== 几个api

1. `constexpr auto sz = ylt::reflection::members_count<S>();`获取S的成员个数。编译期计算。
2. `template <typename T, typename Visit> inline constexpr void for_each(Visit func)`遍历`struct T`的每一个成员。

  Visit func可以是
  - `[](auto& field) {}`
  - `[](auto &field, auto name, auto index) {}`
  - `[](auto& field, auto name) {}`
3. `constexpr auto type_name = ylt::reflection::type_string<S>();`获取S的类型字符串

有这几个就可以写出struct的formatter了。

=== int[]的formatter

直接放代码吧

> 我遇到的struct都是C的API，所以没有太复杂的类型。

```cpp
template<int T>
struct std::formatter<int[T]> {
    constexpr auto parse(std::format_parse_context &ctx) {
        return ctx.begin();
    }

    template<typename FormatContext>
    auto format(const int p[T], FormatContext &ctx) const {
        ctx.out() = std::format_to(ctx.out(), "int[{}]{{", T);
        for (int i = 0; i < T; ++i) {
            if (i == T - 1) {
                ctx.out() = std::format_to(ctx.out(), "{}", p[i]);
            } else {
                ctx.out() = std::format_to(ctx.out(), "{}, ", p[i]);
            }
        }
        ctx.out() = std::format_to(ctx.out(), "}}");
        return ctx.out();
    }

};
```

可以将int[]数组格式化掉。


=== struct的format函数

这里把formatter的parse函数单独实现为一个模板函数。

```cpp
template<typename S, typename FormatContext>
auto my_struct_format(const S &p, FormatContext &ctx) {
    constexpr auto struct_name = ylt::reflection::type_string<S>();
    ctx.out() = std::format_to(ctx.out(), "{}{{ ", struct_name);
    constexpr auto sz = ylt::reflection::members_count<S>();
    ylt::reflection::for_each(p, [&ctx](auto &field, auto name, auto index) {
        if (index < sz - 1) {
            ctx.out() = std::format_to(ctx.out(), "{}: {}, ", name, field);
        } else {
            ctx.out() = std::format_to(ctx.out(), "{}: {} }}", name, field);
        }
    });
    return ctx.out();
}
```

首先获取struct的名字，获取结构体成员个数。

再利用`ylt::reflection::for_each`遍历每个成员和每个值。特判是否是最后一个成员，处理`,`。

=== enum的format函数

enum没有出现在官方例子里，~~我这瞎搞了半天，看样子是对的~~。


直接贴一下关键API`get_enum_arr`的实现吧

```cpp
// Enumerate the numbers in a integer sequence to see if they are legal enum
// value
template <typename E, std::int64_t... Is>
constexpr inline auto get_enum_arr(
    const std::integer_sequence<std::int64_t, Is...> &) {
  constexpr std::size_t N = sizeof...(Is);
  std::array<std::string_view, N> enum_names = {};
  std::array<E, N> enum_values = {};
  std::size_t num = 0;
  (([&]() {
     constexpr auto res = try_get_enum_name<E, static_cast<E>(Is)>();
     if constexpr (res.first) {
       //  the Is is a valid enum value
       enum_names[num] = res.second;
       enum_values[num] = static_cast<E>(Is);
       ++num;
     }
   })(),
   ...);
  return std::make_tuple(num, enum_values, enum_names);
}
```

三个返回值：
- num: enum的成员个数
- enum_values：每个成员的值，是一个数组，大小是可变模板参数Is的多少。
- enum_names: 每个成员的名称，是一个数组，大小同上。

这个函数要求传入定长的integer sequence，一般情况enum的枚举个数不一定一样。我这里直接传个20，假设我要格式化的enum的枚举个数都不超过20。看上边这个代码，20这个参数用来申请内存空间的，多了无所谓，预留默认空值。

这样，enum的格式化函数如下。

```cpp
template<typename S, typename FormatContext>
auto my_enum_format(const S &p, FormatContext &ctx) {
    constexpr auto index_enum_str = ylt::reflection::get_enum_arr<S>(std::make_integer_sequence<int64_t, 20>{});
    constexpr auto enum_name = ylt::reflection::type_string<S>();
    for (int i = 0; i < 20; ++i) {
        if (std::get<1>(index_enum_str)[i] == p) {
            ctx.out() = std::format_to(
                    ctx.out(),
                    "{}::{}(value = {})",
                    // 这个p别忘了强制转为p，不然无限递归了
                    enum_name, std::get<2>(index_enum_str)[i], (int) p
            );
            break;
        }
    }
    return ctx.out();
}
```


=== 测试

```cpp
struct S1 {
    int a;
    float b;
    int c[6];
    float d[3];
};

enum E1 {
    XX = 10,
    YY,
    MAX
};

int main() {
    S1 s{.a = 42, .b = 10.24, .c = {0, 1, 4, 9, 16, 25}, .d = {1.1, 2.2, 3.3}};
    std::cout << std::format("s = {}\n", s);
    E1 y = E1::MAX;
    std::cout << std::format("y = {}", y);
    return 0;
}
```

输出结果如下
```
s = S1{ a: 42, b: 10.24, c: int[6]{0, 1, 4, 9, 16, 25}, d: float[3]{1.1, 2.2, 3.3} }
y = E1::MAX(value = 12)
```

== 所有代码

```cmake
cmake_minimum_required(VERSION 3.15)
project(test_formatter)

set(CMAKE_CXX_STANDARD 20)


include(FetchContent)

FetchContent_Declare(
        yalantinglibs
        GIT_REPOSITORY https://github.com/alibaba/yalantinglibs.git
        GIT_TAG "0.3.5" # optional ( default master / main )
        GIT_SHALLOW 1 # optional ( --depth=1 )
)

FetchContent_MakeAvailable(yalantinglibs)


add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE yalantinglibs::yalantinglibs)
target_compile_features(${PROJECT_NAME} PRIVATE cxx_std_20)
```

#link("https://pastebin.ubuntu.com/p/kr2T7hDpbs/")[main.cpp pastebin]


== 后

小坑小点还是挺多的。比如std::formatter的特化没法放到某个namespace里。即
```cpp
namespace test_space{
    struct S{};
    templace<>
    struct std::formatter<S>{
        // ...
    };
}
```
会编译失败。

虽然达到我想要的结果了，但是有几个点感觉不是清晰。

1. int[T]的格式化，能再写成个模板好了，可以迭代的容器的格式化。不知道view行不行。
2. enum的格式化，感觉应该有个api获取enum的格式，在编译期计算，这样传给get_enum_arr就不会多余或者不够了。应该是我没找到相关内容。
3. 每个struct都要写一个宏。`MY_STRUCT_FORMAT(S1);` `MY_ENUM_FORMAT(E1);`这样。

唉，不是不能用。