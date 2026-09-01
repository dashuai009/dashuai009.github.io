#let date = datetime(
  year: 2022,
  month: 9,
  day: 6,
)

#metadata((
  title: "使用g++编译cpp20的module文件",
  subtitle: [c++20],
  author: "dashuai009",
  description: "本文简单给出了两个文件，使用了c++20 的module特性，并说明了如何使用g++进行编译。",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

== 简介
<简介>
简单记录一下初次尝试c++20中module特性的过程。包括一个main.cpp和子模块
test\_include.cxx。编译器为gnu的g++12.2。编译环境是wsl2-arch，glibc\>=2.36（g++12.2要求的）。

== demo结构
<demo结构>
两个文件，main.cpp 和 子模块 test\_include.cxx。直接上代码：

#quote[
  main.cpp
]

```cpp
import TestInclude;//引入TestInclude模块

int main(){
    TestInclude::push(1);// 这个TestInclude是命名空间的名字，不是模块名！！！
    TestInclude::push(3);
    TestInclude::push(2);
    TestInclude::print();
    // std::cout << "error\n"; //美滋滋地把std::cout 隐藏起来， 如果用include这个cout会自动引入
    return 0;
}
```

#quote[
  test\_include.cxx
]

```cpp
//本模块定义一个私有的全局vector，对外导出两个接口，push和print
module;//这一行不能少！
#include<vector>
#include<iostream>

export module TestInclude; //声明一下模块名字

std::vector<int32_t> staticVec;//

export namespace TestInclude{//导出接口外边套一层namespace
    void push(int32_t x){
        staticVec.push_back(x);
    }

    void print(){
        for (auto x:staticVec){
            std::cout << x << ' ';
        }
        std::cout << '\n';
    }
}
```

== 编译运行
<编译运行>
编译命令 `g++ test_include.cxx main.cpp -o o -std=c++20 -fmodules-ts`

执行`./o` 可以如期输出`1 3 2`

== 总结
<总结>
- 编译命令需要添加`-std=c++20`和`-fmodules-rs`。现在g++编译错误提示还可以，#strike[`-fmodule-ts`我现在还不知道为什么]
- main.cpp是找不到std::cout的，这种module的特性应该大有可为！！封装c库？
- test\_include.cxx
  中手动控制了#strong[模块名];和一个#strong[默认导出的命名空间];同为`TestInclude`，算是强行伪装了rust中文件名即模块名的特点。利用一个默认导出的命名空间可以规范模块导出的接口，这个意义更为重要，估计会出现在很多编码规范中！（或者限制在某一个命名空间中导出，效果类似，个人更倾向上边这种，export个数少）
- g++还可以使用`g++ -c -xc++ test_include.cxx -fmodules-ts`单独编译某个模块。会生成`gcm.cache/TestInclude.gcm`和
  `test_include.o`的缓存文件，据说可以加快编译速度。emmm期待编译工具链的支持。
