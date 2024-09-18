#let date = datetime(
  year: 2023,
  month: 5,
  day: 20,
)
#metadata((
  "title": "list命令",
  "author": "dashuai009",
  description: "",
  pubDate: date.display(),
  subtitle: [linux,list命令],
))<frontmatter>

#import "../../__template/style.typ": conf
#show: conf

= 实验任务

编程实现程序myList.c，列表普通磁盘文件，包括文件名和文件大小。要求能够处理以下几个选项


#table(
  columns: (auto, auto),
  table.header("参数", "含义"),
  `-r`, [递归方式列出子目录],
  `-a`, [列出文件名第一个字符为圆点的普通文件],
  `-l <bytes>`, [限定文件大小的最小值（字节）],
  `-h <bytes>`, [限定文件大小的最大值（字节）],
  `-m <integer>`, [限定文件的最近修改时间必须在n天内],
  `--`, [显式地终止命令选项分析],
)


= fstat、stat和lstat的区别：

三个函数原型如下

```cpp
int fstat(int filedes, struct stat *buf);

int stat(const char *path, struct stat *buf);

int lstat(const char *path, struct stat *buf);
```

- fstat系统调用接受的是 一个“文件描述符”，而另外两个则直接接受“文件全路径”。文件描述符是需要我们用open系统调用后才能得到的，而文件全路经直接写就可以了。
- stat和lstat的区别：当文件是一个符号链接时，lstat返回的是该符号链接本身的信息；而stat返回的是该链接指向的文件的信息。

= 实现步骤

== 选用lstat

*能够处理“死链接”*，对于符号链接文件，如果链接目标文件不存在，在使用stat函数的情况下，会访问链接的目标文件，导致输出"No such file or directory"。实际上，链接文件link依旧存在，文件大小不为0。而使用fstat不会有这种情况。fstat不会访问目标文件。

== 处理参数

设置以下标志位

#table(
  columns: (auto, auto),
  table.header("参数", "含义"),
  `int flag_recurse = 0;`, [是否递归遍历子目录，默认为0],
  `int flag_show_hidden = 0;`, [是否显示隐藏文件（文件名以.开头）],
  `int min_size = 0;`, [文件大小的最小值],
  `int max_size = -1;`, [文件大小的最大值，-1表示不受限制],
  `int last_n_days = -1;`, [只显示最近n天的文件],
)


== 全局变量
#table(
  columns: (auto, auto),
  table.header("参数", "含义"),
  `char *target[256];`, [输入的目录集合，最多处理256个输入目录],
  `int cntTarget;`, [输入目录的个数],
  `char current_dir[] = ".";`, [当前目录为'.'，当无输入目录时，默认为当前目录],
)

== 所需函数，具体代码在文末

```cpp
/**

- 满足flag的条件下，输出错误信息并退出整个程序，错误信息存储在可变参数列表...中
- 否则继续正常执行
*/
void handle_error(int flag, int num, ...)

/**
 * 考虑-a参数（是否显示隐藏文件），判断dir是否需要输出
 */
int checkDot(const char *dir)


/**

- 判断文件大小是否符合要求
*/
int checkSize(int fileSize)

/**
 * 判断文件日期是否符合要求
 */
int checkDate(struct timespec ti)

/**

- 输出dir目录，dep是目录深度，这里暂时没有用到
- 输出结果放在一行里
- 输出效果是彩色的。
*/
void myPrint(const char *dir, int dep)

```

```cpp
/**
 * 输入是一个目录，
 * 如果设置了-r标志，需要递归遍历
 * 否则只需要输出当前目录
 * 这里使用了lstat，而不是stat，可以处理死链接的情况
 */
void myList(const char *dir, int dep)
```

```cpp
/**

- 初始化传入的参数
*/
void init(int argc, char **argv)
```

主函数

```cpp
int main(int argc, char **argv) {
    init(argc, argv);
    for (int i = 0; i < cntTarget; ++i) {
        printf("\033[93mSearching  %s\n", target[i]);
        struct stat st;
        int ret = lstat(target[i], &st);
        handle_error(ret == -1, 2, target[i], strerror(errno));
        if (S_ISDIR(st.st_mode)) {//保证遍历的是目录
            myList(target[i]);
        } else {
            myPrint(target[i]);
        }
    }
    return 0;
}
```

= 编译命令

`gcc myList.c -o list`

= 运行示例

== `./list`

列出默认路径`./`的文件和文件夹

// <img src="list命令/2021-05-07 17-11-34 的屏幕截图.png" style="zoom:67%;" alt="./list" />

== `./list -r`

递归遍历当前目录

// <img src="list命令/2021-05-07 17-11-23 的屏幕截图.png" style="zoom:50%;" alt="./list -r"/>

== `./list ./test/test1 ./test/test2 -a`

显示test/test1和test/test2目录下的所有文件，包括隐藏文件

// <img src="list命令/2021-05-02 21-21-43 的屏幕截图.png" style="zoom:50%;" alt="./list ./test/test1 ./test/test2 -a"/>

== `./list .. -l 1000000 -h 3000000`

列出父级目录中大于1000000字节，小于3000000字节的文件。通过名利`ls -al .. -S`可以将父级目录中的文件从大到小排列，得出结果，简单比对即可。

// <img src="list命令/2021-05-02 21-27-58 的屏幕截图.png" style="zoom:50%;" alt="./list .. -l 1000000 -h 3000000"/>

== `./list -r -m 15 ..`

递归便利父级目录，列出15天内修改的文件。通过`find .. -ctime -15`验证，可以的出一样的结果。

// <img src="list命令/2021-05-07 17-12-27 的屏幕截图.png" style="zoom:50%;" alt="./list -r -m 15 .."/>

== `./list ./test/test1 ./test2 -- .. ../..`

使用--截断之后的参数分析，之列出前两个参数中的文件。

// <img src="list命令/2021-05-02 21-34-37 的屏幕截图.png" style="zoom:50%;" alt="./list ./test/test1 ./test2 -- .. ../.."/>

= 代码

链接如下

[ubuntu paste bin](https://pastebin.ubuntu.com/p/9GB324Rrr6/)

```cpp
#include <dirent.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>

int flag_recurse = 0;
int flag_show_hidden = 0;
int min_size = 0;
int max_size = -1;
int last_n_days = -1;
char *target[256];
int cntTarget;
char current_dir[] = ".";
/**

- 满足flag的条件下，输出错误信息并退出整个程序，
- 否则继续正常执行
*/
void handle_error(int flag, int num, ...) {
    if (flag) {
        va_list ap;        // (1) 定义参数列表
        va_start(ap, num); // (2) 初始化参数列表
        printf("\033[91m%sError:");
        for (int i = 0; i < num; ++i) {
            printf("%s ", va_arg(ap, char *));
        }
        printf("\n");
        va_end(ap);
        exit(0);
    }
}

/**

- 考虑-a参数（是否显示隐藏文件），判断dir是否需要输出
*/
int checkDot(const char *dir) {
    if (flag_show_hidden) {
        return 1;
    }
    const char *ptr = strrchr(dir, '/');
    if (ptr == NULL) {
        return dir[0] != '.';
    } else {
        return ptr[1] != '.';
    }
}

/**

- 判断文件大小是否符合要求
*/
int checkSize(int fileSize) {
    return min_size <= fileSize && (max_size == -1 || fileSize <= max_size);
}

/**

- 判断文件日期是否符合要求
*/
int checkDate(struct timespec ti) {
    int lastChange = ti.tv_sec;
    struct timeval t;
    gettimeofday(&t, NULL);
    int currentTime = t.tv_sec;
    return last_n_days == -1 ||
           (currentTime - lastChange) <= 24 * 60 * 60 * last_n_days;
}

/**

- 输出dir目录，
- 输出结果放在一行里，
- 输出效果是彩色的。
*/
void myPrint(const char *dir) { // output in one line
    struct stat st;
    int ret = lstat(dir, &st);
    handle_error(ret == -1, 2, dir, strerror(errno));

    int dotPosition = -1;
    if (checkDot(dir) && checkSize(st.st_size) && checkDate(st.st_ctim)) {
        switch (st.st_mode & S_IFMT) {
        case S_IFBLK:
            printf("\033[32m%15d %s\n", st.st_size, dir); // block device
            break;
        case S_IFCHR:
            printf("\033[33m%15d %s\n", st.st_size, dir); // character device
            break;
        case S_IFDIR:
            printf("\033[95m%15d %s\n", st.st_size, dir); // directory
            break;
        case S_IFIFO:
            printf("\033[32m%15d %s\n", st.st_size, dir); // FIFO/pipe
            break;
        case S_IFLNK:
            printf("\033[32m%15d %s\n", st.st_size, dir); // symlink
            break;
        case S_IFREG:
            printf("\033[96m%15d %s\n", st.st_size, dir); // regular file
            break;
        case S_IFSOCK:
            printf("\033[32m%15d %s\n", st.st_size, dir); // socket
            break;
        default:
            printf("\033[32munknown?\n");
            break;
        }
    }
}

/**

- 输入是一个目录，
- 如果设置了-r标志，需要递归遍历
- 否则只需要输出当前目录
- 这里使用了lstat，而不是stat，可以处理死链接的情况
*/
void myList(const char *dir) {
    DIR *fd = opendir(dir);
    struct dirent *entry;
    while (entry = readdir(fd)) {
        char entry_dir[256];
        sprintf(entry_dir, "%s/%s\0", dir, entry->d_name);

        myPrint(entry_dir);

        struct stat st;
        int ret = lstat(entry_dir, &st);
        handle_error(ret == -1, 2, entry_dir, strerror(errno));
        if (S_ISDIR(st.st_mode)) {
            // printf("%s\n", entry->d_name);
            if (strcmp(entry->d_name, ".") != 0 &&
                strcmp(entry->d_name, "..") != 0 && flag_recurse) {
                myList(entry_dir);
            }
        }
    }
    closedir(fd);
}

/**

- 初始化传入的参数
*/
void init(int argc, char **argv) {
    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--") == 0) {
            break;
        } else if (strcmp(argv[i], "-r") == 0) {
            flag_recurse = 1;
        } else if (strcmp(argv[i], "-a") == 0) {
            flag_show_hidden = 1;
        } else if (strcmp(argv[i], "-l") == 0) {
            sscanf(argv[i + 1], "%d", &min_size);
            handle_error(min_size < 0, 1,
                         "The minimum value cannot be less than 0!");
            ++i;
        } else if (strcmp(argv[i], "-h") == 0) {
            sscanf(argv[i + 1], "%d", &max_size);
            handle_error(max_size < 0, 1,
                         "The maximum value cannot be less than 0!");
            ++i;
        } else if (strcmp(argv[i], "-m") == 0) {
            sscanf(argv[i + 1], "%d", &last_n_days);
            handle_error(last_n_days < 0, 1,
                         "The time value cannot be less than 0!");
            ++i;
        } else {
            target[cntTarget++] = argv[i];
        }
    }
    if (cntTarget == 0) {
        target[cntTarget++] = current_dir;
    }
}
int main(int argc, char **argv) {
    init(argc, argv);
    for (int i = 0; i < cntTarget; ++i) {
        printf("\033[93mSearching  %s\n", target[i]);
        struct stat st;
        int ret = lstat(target[i], &st);
        handle_error(ret == -1, 2, target[i], strerror(errno));
        if (S_ISDIR(st.st_mode)) {
            myList(target[i]);
        } else {
            myPrint(target[i]);
        }
    }
    return 0;
}

```