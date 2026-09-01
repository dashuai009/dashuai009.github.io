#let date = datetime(
  year: 2024,
  month: 1,
  day: 1,
)
#metadata((
  "title": "modules 模块",
  "author": "dashuai009",
  description: "这是一种将C++更加现代的代码组织方式。 模块是一组源代码文件，独立于导入它们的翻译单元进行编译。",
  pubDate: date.display(),
  subtitle: [modules,模块],
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


这是一种将C++更加现代的代码组织方式。 模块是一组源代码文件，独立于导入它们的翻译单元进行编译。

= 模块试图解决的问题

- 头文件
  - module几乎解决了头文件编译的难题，比如头文件的重复替换 （复杂项目中，如果一个底层头文件被修改，上层引用的头文件都会被重新编译）。 使用module之后，这种问题会得到极大的改善。
- 封装：对外接口的暴露
  - 在模块中声明的宏、预处理器指令和未导出的名称在模块外部不可见。 它们对导入模块的翻译单元的编译没有影响。 您可以按任意顺序导入模块，而无需考虑宏重定义。导入翻译单元中的声明不参与导入模块中的重载解析或名称查找。
- 编译速度
  - 模块编译一次后，结果将存储在描述所有导出的类型、函数和模板的二进制文件中。 编译器处理该文件的速度比头文件快得多。 而且，编译器可以在项目中导入模块的每个位置重用它。

= 实现细节

todo

= 常见库支持状态

#link("https://arewemodulesyet.org/")["arewemodulesyet"]

Nope!

= 编译器支持状态

todo

= 基本示例

假设我们现在有如下cpp

```cpp
int square(int i); // 声明一个函数
class Square {
private:
  int value;

public:
  explicit Square(int i) : value{square(i)} {}
  int getValue() const { return value; }
};
template <typename T> Square toSquare(const T &x) { return Square{x}; }
int square(int i) { // 实现平方函数
  return i * i;
}
```

只需要两步就可以转成一个模块单元： 1. 在第一行添加`export module Square;`，这相当于导出一个名为Square的模块。 2. 把想要导出的函数前面加上export关键字。

```cpp
/** modules/mod0/square.ixx **/
export module Square; // declare module  Square
int square(int i);
export class Square {
private:
  int value;

public:
  explicit Square(int i) : value{square(i)} {}
  int getValue() const { return value; }
};
export template <typename T> Square toSquare(const T &x) { return Square{x}; }
int square(int i) { return i * i; }
```

在主文件中，就可以愉快地`import Square`啦~。

```cpp
/*== mod0/main.cpp ==*/
import std;
import Square; // import module `Square`
int main() {
  Square x = toSquare(42);
  std::cout << x.getValue() << '\n';
}
```

= 我就喜欢写头文件？模块实现单元（module implementation unit）和模块声明单元（module interface unit）

像上边这个例子，属于实现和声明放在一起了，可以写的很pythonic。 模块由若干个模块单元（module units）组成。而且模块可以进行分区（partition），或分为子模块。模块单元是包含模块声明的翻译单元（源文件）。类似.h和.cpp，模块分为**接口单元**和**实现单元**。

有几种类型的模块单元：

- 模块接口单元（module interface unit）包含关键词`export module`，用于导出模块名称和分区（partition）。和.h文件类似。
- 模块实现单元（implementation unit）是不导出模块名称、分区名称。顾名思义，它用于实现模块。和cpp文件类似。
- 主模块接口单元（primary module interface unit）是导出模块名称的模块接口单元。 模块中必须有一个且只能有一个主模块接口单元。上边这个例子里还没有模块分区，直接`export module Square`，算是主模块单元。
- 模块分区接口单元（partition interface unit）是导出模块分区名称的模块接口单元。
- 模块分区实现单元（partition implementation unit）是模块实现单元，其模块声明中具有模块分区名称，但没有export关键字。

`export`关键字仅在接口文件中使用。实现文件可以`import`另一个模块，但不能`export`任何名称。 实现文件可以具有任何扩展名（这一点编译器还有些特殊处理，好像标准里没有规定）。

= 模块和namespace

不像其它语言，模块不会自动添加一个namespace。 就像第一个例子，import Square之后，Square里导出的所有东西都被直接暴露。 有两种方法可以处理一下，让代码更加规范：

定义一个和模块同名的namespace，

1. 导出命名空间中需要的接口，则命名空间也会被隐式导出，但是命名空间中，没有被导出的接口则不会暴露

```cpp
export module Square; // declare module ”Square”
namespace Square {
    int square(int i);// not exported
    export class Square {
        // bala bala ...
    };
    export template<typename T>
    Square toSquare(const T& x) {
        // ...
    }
    int square(int i) { // not exported
        // ...
    }
}
```

1. 显式导出整个命名空间，则命名空间中的所有声明都会被导出。

```cpp
export module Square; // declare module ”Square”
int square(int i);
export namespace Square {
    class Square {
        // ...
    };
    template<typename T>
    Square toSquare(const T& x) {
        // ...
    }
}
int square(int i) { // not exported
    // ...
}
```

这样，在主文件中都可以达到以下效果：

```cpp
import Square;// 这个是模块名，需要和export匹配
int main(){
    Square::Square x = Square::toSquare(42);
    // ::前Square是命名空间的名字，::Square是类名，这块搞清楚，之后写模块就简单了
    std::cout << x.getValue() << '\n';
}
```

= 多文件

== 模块接口单元与模块实现单元

模块接口单元用于导出模块名、模块接口。按照模块分区（partition），分为主模块接口单元和分区模块接口单元。直观上，如果整个模块叫做mod1，则含有export module mod1;的文件就是主接口单元；其他文件不能导出mod1这个名字。如果其他文件导出了mod1的子模块export module mod1:submod;则该文件是分区接口单元。

先来说没有分区的模块接口单元：

```cpp
export module Mod1;  // module declaration

import std;

struct Order {
    int count;
    std::string name;
    double price;

    Order(int c, const std::string& n, double p)
            : count{c}, name{n}, price{p} {
    }
};

export class Customer {
private:
    std::string name;
    std::vector<Order> orders;
public:
    Customer(const std::string& n)
            : name{n} {
    }
    void buy(const std::string& ordername, double price) {
        orders.push_back(Order{1, ordername, price});
    }
    void buy(int num, const std::string& ordername, double price) {
        orders.push_back(Order{num, ordername, price});
    }
    double sumPrice() const;
    double averagePrice() const;
    void print() const;
};
```

第一行，定义并导出模块的名字：

```cpp
export module Mod1;  // module declaration
```

第二行，导入标准模块std：

```cpp
import std;
```

之后就是常见的类型声明部分，声明一个订单结构体 struct Order，和一个顾客类。相比于普通头文件，唯一多的就是 class Customer前前面的export关键字，表示导出这个类。

```cpp
struct Order {
    // ...
}

export class Customer {
    // ....
}
```

简单来说，首先声明并导出一个模块，导入需要的模块，声明需要类型，导出必要的类型。

接下来，需要实现这些类型（或者函数），类似cpp文件，这里我们分成两个实现单元：

实现单元第一行，标明所属模块，`module Mod1;`表示该单元属于Mod1模块。接着，这个单元实现`void Customer::print() const{}`函数。具体用到了format函数，这也是c++20的新功能。

```cpp
module Mod1;         // implementation unit of module Mod1
import std;

void Customer::print() const
{
    // print name:
    std::cout << name << ":\n";
    // print order entries:
    for (const auto& od : orders) {
        std::cout << std::format("{:3} {:14} {:6.2f} {:6.2f}\n",
                                 od.count, od.name, od.price, od.count * od.price);
    }
    // print sum:
    std::cout << std::format("{:25} ------\n", ' ');
    std::cout << std::format("{:25} {:6.2f}\n", "    Sum:", sumPrice());
}
```

与上边这个类似，这是另一个实现单元：标明属于Mod1模块，实现了两个函数`double Customer::sumPrice() const {}` 和另一个函数`double Customer::averagePrice() const {}`

```cpp
module Mod1;         // implementation unit of module Mod1

double Customer::sumPrice() const {
    double sum = 0.0;
    for (const Order &od: orders) {
        sum += od.count * od.price;
    }
    return sum;
}

double Customer::averagePrice() const {
    if (orders.empty()) {
        return 0.0;
    }
    return sumPrice() / orders.size();
}
```

实现单元和cpp文件类似。以上三个文件完整定义并实现了Mod1模块。

具体使用模块如下：

```cpp
import std;
import Mod1;

int main() {
    Customer c1{"Kim"};
    // Order b1(1, "buy", 590.0); // error Order并没有被导出。

    c1.buy("table", 59.90);
    c1.buy(4, "chair", 9.20);

    c1.print();
    std::cout << "  Average: " << c1.averagePrice() << '\n';
}
```

输出结果为

```jsx

```

> 上边这种定义与实现分离的方式，cmake支持好像还不太好，没编译过去
>

== 模块内部（internal）单元，模块分区

有接口和实现单元还不够，c++20的module特性还支持模块划分，每个模块还可以被划分为子模块。类似python中`import a.b.c;`

分区接口的开头如下：

```cpp
export module Example:part1;
```

分区实现单元的开头如下：

```cpp
module Example:part1;
```

若要访问另一个分区中的声明，分区必须导入它，但它只能使用分区名称，而不是模块名称：

```cpp
module Example:part2;
import :part1;// 额外注意：这里不能带模块名，Example:part1不行。
```

主接口单元必须导入并重新导出模块的所有接口分区文件，如下所示：

```cpp
export module Example;
// export import :part1; // 如果part1不被export，则part1的所有内容对外不可见（包括export的接口）
export import :part2;// 所有part2导出的接口，都会被导出到Example中。
```

主接口单元可以导入分区实现文件，但无法导出它们。 不允许这些文件导出任何名称。 这一限制使模块能够在模块内部保留实现详细信息。

> 具体的例子看modules/mod2
>

= 子模块submodule

标准里面没有子模块的规定，但是模块名支持`.` ，他在模块名中没有特殊含义，但是可以从逻辑上划分模块之间的关系。

```cpp
export module a;
// export import a.c; 没有被export，如果只import a是看不到a.c的。
export import a.b.c;
```

= 模块和include

**While in theory modules could replace all traditional header files with all their flaws, in practice this will never happen**.

=== global module fragment

现在，我们可以确定，有export module xxx的就是模块接口单元，没有export关键字，但是有module xxx都是模块实现单元。

c++为了和旧代码兼容(~~为了留住用户~~)，特地兼容了普通的头文件。用到了 全局模块片段(global module fragment)

```cpp
module; // start module unit with global module fragment
#include <string>
#include <vector>
export module Mod1; // module declaration

// bula bula bula
```

前面三行就是全局模块片段，不看前三行，和前面说过的模块单元是一样的。但是

- include进来的 指令 （`#define` and `#include`）可以正常使用和被看到。
- 不会导出任何东西（包括macros, declarations, definitions）

== importable header

可被导入的头文件。

比如

```cpp
import <vector>;
import "myheader.h";
```

> include头文件和import模块之间的主要区别在于：头文件中的任何预处理器定义在语句之后的导入程序中都可见。
>

= 其他
- 模块的使用可以提高代码的可读性和可维护性，解决了头文件编译的难题，同时也提高了编译速度。
- 模块分为接口单元和实现单元，可以通过定义同名的命名空间来更加规范地使用模块。
- 全局模块片段和可导入的头文件也是模块的一部分，可以提高代码的兼容性和可读性。