#let date = datetime(
  year: 2022,
  month: 9,
  day: 9,
)
#metadata((
  "title": "linux缺页中断次数统计",
  "author": "dashuai009",
  description: "",
  pubDate: date.display(),
  subtitle: [linux,缺页中断],
))<frontmatter>

#import "../../__template/style.typ": conf
#show: conf


#date.display();
#outline()


= 描述

修改内核源代码，使得内核自启动以后，统计发生缺页的次数。

编写程序，输出内核启动时间，和内核统计到的缺页中断次数。


= 实验环境

`openeuler20.03LTS  qemu x86_64`

= 统计次数

== 声明计数变量

在内核文件arch/x86/mm/fault.c中定义了`do_page_fault()`函数，这是操作系统处理缺页中断的入口。

只需要在这里添加一个计数变量`unsigned long pfcount`，并在每次执行`do_page_fault()`时，使计数变量加一。

![声明计数变量pfcount](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/6/2021-05-07%2009-19-22%20%E7%9A%84%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE.png)

== 声明为全局变量

在内核文件include/linux/mm.h中，将`pfcount`声明为全局变量。

![pfcount](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/6/2021-05-07%2009-20-56%20%E7%9A%84%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE.png)

== 导出到内核变量全局符号表中

在内核文件kernel/kallsyms.c中，最后一行添加`EXPORT_SYMBOL_GPL(pfcount)`

![EXPORT_SYMBOL_GPL](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/6/2021-05-07%2009-21-44%20%E7%9A%84%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE.png)


EXPORT_SYMBOL_GPL 导出的符号只能被GPL协议的模块读取。
= 重新编译内核

`make & make modules_install & make install`

这一步真是一言难尽～～之前三步的修改会导致*整个内核几乎重新编译一遍。*（修改的内容太底层，不是模块方式加载进去）

= 编写模块输出统计变量

编写如下pf.c文件

这里将当前日期和缺页次数，输出到了/proc/pfcount。这里用到了/proc文件系统。之后可以直接通过`cat /proc/pfcount`直接查看当前的信息。

```c
#include <linux/fs.h>
#include <linux/mm.h>
#include <linux/proc_fs.h>
#include <linux/rtc.h>
#include <linux/time.h>
#include <linux/module.h>
#define BUFSIZE 512
MODULE_LICENSE("GPL");

struct timeval tv;
struct rtc_time tm;

static struct proc_dir_entry *pf;

static ssize_t read_pfcount(struct file *f, char __user *ubuf, size_t count,
                            loff_t *ppos) {

        char buf[BUFSIZE];
        int len=0;
    int year, mon, day, hour, min, sec;
        //printk( KERN_DEBUG "read handler\n");
        if(*ppos > 0 || count < BUFSIZE)
                return 0;

    do_gettimeofday(&tv);
    rtc_time_to_tm(tv.tv_sec, &tm);
    year = tm.tm_year + 1900;
    mon = tm.tm_mon + 1;
    day = tm.tm_mday;
    hour = tm.tm_hour + 8;
    min = tm.tm_min;
    sec = tm.tm_sec;
    len=sprintf(buf,"Current time: %d-%02d-%02d %02d:%02d:%02d pfcount = %ld\n", year,
           mon, day, hour, min, sec, pfcount);

        if(copy_to_user(ubuf,buf,len))
                return -EFAULT;
        *ppos = len;
    return len;
}
static ssize_t write_pfcount(struct file *f, const char __user *buf, size_t len,
                             loff_t *off) {
    printk(KERN_DEBUG "test\n");
    return -1;
}
static const struct file_operations myProc = {
    .owner = THIS_MODULE,
    .write = write_pfcount,
    .read = read_pfcount,
};

static int __init myproc_init(void) {
    printk("Start pf modules...\n");

    pf = proc_create("pfcount", 0660, NULL, &myProc);
    if (pf == NULL)
        return -ENOMEM;
    return 0;
}

static void __exit myproc_exit(void) {
    printk("Exit pf module...\n");
    proc_remove(pf);
}

module_init(myproc_init);
module_exit(myproc_exit);
```

= 加载并执行模块

执行结果

![执行结果](https://blog-picture-1305172231.cos.ap-beijing.myqcloud.com/6/2021-05-07%2009-32-18%20%E7%9A%84%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE.png)

可以看到系统在09:22:17~09:31:13的536秒中，缺页中断发生了2826616-1693154=1133462次。

= 本次实验的缺点

== volatile

有地方这样写声明全局变量
`extern unsigned long volatile pfcount;`

[volatile 的作用](https://www.runoob.com/w3cnote/c-volatile-keyword.html)

我这里没有加volatile关键字，不知道有没有影响。~~（编译一次太费劲了）~~