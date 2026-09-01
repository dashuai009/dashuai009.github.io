
#let date = datetime(
  year: 2023,
  month: 6,
  day: 17,
)
#metadata((
  title: "使用c++扩展python",
  subtitle: [cpython,c++],
  author: "dashuai009",
  description: "",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


= 简介
c++可以编写python的扩展库。

1. Extending Python with C or C++ — Python 3.11.4 documentation

= 开发环境

linux 下需要安装python3-dev

= CMAKE编写
这里给出test.cpp编写的python模块和测试用 的test.py

编译与执行
```
mkdir build

cmake -S . -B ./build

cmake --build ./build

python3 test.py
```

```cmake
cmake_minimum_required(VERSION 3.12) # 3.12才可以find_package(python)
project(test_cp)

find_package (Python REQUIRED Interpreter Development)

set(test_cpp_demo_name "test_cpp") # 定义一个库的名字，同时作为py模块的名字
add_definitions(-DPY_MODULE_NAME_STR="${test_cpp_demo_name}")
add_definitions(-DPY_MODULE_NAME=PyInit_${test_cpp_demo_name})


add_library(${test_cpp_demo_name} SHARED test.cpp)
set_target_properties(
        ${test_cpp_demo_name}
        PROPERTIES
        PREFIX "" # 输出前缀没有了
        OUTPUT_NAME ${test_cpp_demo_name}.cpython-310-x86_64-linux-gnu # 注意后边的python版本、平台版本、编译器组织
)
target_include_directories(${test_cpp_demo_name} PRIVATE
        ${Python_INCLUDE_DIRS})

target_link_directories(${test_cpp_demo_name} PRIVATE
        ${Python_LIBRARY_DIRS})

target_link_libraries(${test_cpp_demo_name} PRIVATE
        ${Python_LIBRARIES})
```

= TEST.CPP
具体可以参考上边给出的链接

```cpp
#include "Python.h"

//  起一个命名空间
namespace test_cpp {
constexpr int N = 1000;
int f[N];
bool flag = false;
int Fib_impl(int n) {
    if (flag && 0 <= n && n < N) {
        return f[n];
    }
    f[1] = 1;
    for (int i = 2; i < N; ++i) {
        f[i] = f[i - 1] + f[i - 2];
    }
    flag = true;
    return f[n];
}
} // namespace test_cpp

// 给python导出接口
static PyObject *Fib(PyObject * /* unused module reference */, PyObject *o) {
    int n = PyLong_AsLong(o);
    int fn = test_cpp::Fib_impl(n);
    return Py_BuildValue("i", fn);
}

//定义python模块中有哪些函数
static struct PyMethodDef test_cpp_methods[] = {
    {"fast_fib", Fib, METH_O, "fast fib"},
    // Terminate the array with an object containing nulls.
    {nullptr, nullptr, 0, nullptr}};

// 定义模块
static struct PyModuleDef test_cpp_module = {
    PyModuleDef_HEAD_INIT,
    PY_MODULE_NAME_STR, /* name of module */ // python里可以import 这个名字
    nullptr, /* module documentation, may be NULL */
    -1,      /* size of per-interpreter state of the module,
                or -1 if the module keeps state in global variables. */
    test_cpp_methods
    };
//定义模块的初始化函数，import之后会自动执行


// .so的名字要和这个函数的名字、和PyModuleDef里的name对齐
PyMODINIT_FUNC PY_MODULE_NAME(void) {
    PyObject *m;
    m = PyModule_Create(&test_cpp_module);
    if (m == NULL)
        return NULL;
    return m;
}
```

= PYTHON使用

```python
import sys
# sys.path.append("./build/lib.linux-x86_64-3.10")
sys.path.append("./build")
import test_cpp

a = test_cpp.fast_fib(10);
print(a)
```