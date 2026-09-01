
#let date = datetime(
  year: 2023,
  month: 8,
  day: 20,
)
#metadata((
  title: "使用python和qwen处理doc文件",
  subtitle: [qwen,win32com,python-docx,textextract],
  author: "dashuai009",
  description: "",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


今天帮同学处理了一些docx文件，主要是一些会议通知的文件，总共有一千多份doc、docx、pdf、wps等文件。

目标是提取这些会议通知中的时间、地点、名称、主办单位。

这些文本的格式相对统一，比如

```
通知
一、会议时间：
xxx年xx月xx日xx点
二、会议地点
xxxx
三、xxx

xxx

   【通知单位】
   年月日​
这种算是比较好的，还有啥

通知
一、请xxx于xxx月xx日到xxx参加xxx
xxx
xx​
```

两千份通知，横跨半年，至少四种文件格式（pdf、doc、docx、wps），大体格式至少十几种。

手写regex规则是不可能了，这辈子也不可能了。正好想到最近疯狂开源的大模型，文本直接喂给他们，可以帮我总结这些文本。

首先不考虑chatgpt，死贵死贵，2023年8月19日，`16K context $0.003 / 1K tokens`，两百万文本就要110人民币。其次，数据传到境外，明显不太安全，这里还是有些敏感数据的。

找了一圈，发现qwen和llama2还可以（早一个月遇到这个问题可能还没这好弄，感谢开源人士）。后边这个中文一般般，有#link("https://huggingface.co/LinkSoul/Chinese-Llama-2-7b")[LinkSoul微调的模型]，我用下来效果一般，我这个任务可能不太对付的问题。前边qwen是阿里开源的，看他们公布的对比测试，很能打，阿里出品，看起来靠谱。（注：我只是对于我的文件进行测试，不代表两个相对好坏）

这两个试用都很方便，hugginface真是大大滴好。qwen文档：#link("https://github.com/QwenLM/Qwen")[Qwen-7B/README_CN.md at main · QwenLM/Qwen-7B (github.com)]
第一次用huggingface，还以为要手动一个个下载`pytorch_model-0001-0008.bin`文件，原来代码里都处理好这些琐事了。直接跑，自动下载。
qwen还依赖flash-attention，官方推荐`git clone -b v1.0.8` ，就别用flash-attention2了，安装会遇到编译问题。
== 文件处理
找了半天没找到合适的库去读doc文件

- textract #link("https://textract.readthedocs.io/en/stable/")[textract 1.6.1 documentation] 这个说是啥都能读，安装好之后会遇到后边这个报错，调用antiword命令处理时有问题。
- 其他好多库都不太支持doc，只支持docx
- 批量转#link("https://www.bilibili.com/read/cv3416134/")[【真技术】批量将doc转为docx的方法 - 哔哩哔哩 (bilibili.com)] 有vba和ps的代码
- python的win32com库可以实现上一种方法，具体如后边代码
- python-docx可以修改和读取docx

```
Traceback (most recent call last):
  File "C:\Users\15258\.conda\envs\llm\Lib\site-packages\textract\parsers\utils.py", line 87, in run
    pipe = subprocess.Popen(
           ^^^^^^^^^^^^^^^^^
  File "C:\Users\15258\.conda\envs\llm\Lib\subprocess.py", line 1026, in __init__
    self._execute_child(args, executable, preexec_fn, close_fds,
  File "C:\Users\15258\.conda\envs\llm\Lib\subprocess.py", line 1538, in _execute_child
    hp, ht, pid, tid = _winapi.CreateProcess(executable, args,
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
FileNotFoundError: [WinError 2] The system cannot find the file specified
```
处理pdf、doc都可以同word打开，然后重新saveas，pdf用word打开时会有个提示，按理来说可以在python加个-y的参数，自动选yes，没找到资料，跑脚本的时候手动点的yes，还好也就二三十个。有些pdf有加密，不让其他程序读取内容，这些处理不了，只能人工。

== 提示QWEN去提取信息
简单，直接加用
```
f"找出以下通知的会议名称、会议时间、会议地点和主办单位，结果用逗号隔开\n{text}"
```
text是docx文本。

也就三个步骤：

- 把pdf、doc转成docx
- 读取docx
- 文本加提示词喂给qwen
代码
```python
import os
from win32com import client as wc #导入模块
import textract


word = wc.Dispatch("Word.Application") # 打开word应用程序


base_dir = './docs'

def find_all_file(base, extension):
    for root, ds, fs in os.walk(base):
        for f in fs:
            fullname = os.path.join(root, f)
            if f.endswith(extension):
                yield os.path.abspath(fullname)


for file in find_all_file(base_dir, ".pdf"):
    print(file)
    _file = file.replace("pdf", "docx")
    print(_file)
    if not os.path.exists(_file):
        doc = word.Documents.Open(file) #打开word文件
        doc.SaveAs(_file, 12)#另存为后缀为".docx"的文件，其中参数12指docx文件
        doc.Close() #关闭原来word文件

for file in find_all_file(base_dir, ".doc"):
    print(file)
    _file = file.replace("doc", "docx")
    print(_file)
    if not os.path.exists(_file):
        doc = word.Documents.Open(file) #打开word文件
        doc.SaveAs(_file, 12)#另存为后缀为".docx"的文件，其中参数12指docx文件
        doc.Close() #关闭原来word文件

word.Quit()

import os
from docx import Document
from transformers import AutoModelForCausalLM, AutoTokenizer
from transformers.generation import GenerationConfig

# 请注意：分词器默认行为已更改为默认关闭特殊token攻击防护。
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen-7B-Chat", trust_remote_code=True)

# 打开bf16精度，A100、H100、RTX3060、RTX3070等显卡建议启用以节省显存
# model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen-7B-Chat", device_map="auto", trust_remote_code=True, bf16=True).eval()
# 打开fp16精度，V100、P100、T4等显卡建议启用以节省显存
# model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen-7B-Chat", device_map="auto", trust_remote_code=True, fp16=True).eval()
# 使用CPU进行推理，需要约32GB内存
# model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen-7B-Chat", device_map="cpu", trust_remote_code=True).eval()
# 默认使用自动模式，根据设备自动选择精度
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen-7B-Chat", device_map="auto", trust_remote_code=True).eval()

# 可指定不同的生成长度、top_p等相关超参
model.generation_config = GenerationConfig.from_pretrained("Qwen/Qwen-7B-Chat", trust_remote_code=True)


base_dir = './docs' # 通知文件的文件夹
out_file = open("./doc_out2.txt", "w") #结果输出文件
def find_all_file(base): #和上边代码重复了
    for root, ds, fs in os.walk(base):
        for f in fs:
            fullname = os.path.join(root, f)
            if f.endswith('.docx'):
                yield fullname

cnt = 0
for i in find_all_file(base_dir):
    document = Document(i) #读取docx
    text = ""
    for p in document.paragraphs:
        text += p.text #拼接文本
    text_format = f"找出以下通知的会议名称、会议时间、会议地点和主办单位，结果用逗号隔开\n{text}"
    # 问模型
    response, _ = model.chat(tokenizer, text_format, history = None)
    cnt += 1
    print(cnt, i)
    out_file.write("\n" + "==" * 10 + "\n")
    out_file.write(f"file_name = {i}\n") # 输出结果
    out_file.write(response)

```

== 总结
有了large language model，这种任务一下子简单很多。

结果上，对于比较规整的文件，提取结果非常好。不太规整的文件，人力不好做，大模型也整不明白。

以我的经验，gpt4能把这个任务做的很好，qwen这些开源的7b模型，还是不如人意，比如

- 输出了多余的提示信息，”您好”、”结果如下“等等
- 分不清楚主办单位和被通知人，源文件确实复杂
- 吃内存，4090 24G显存，也就处理4k左右的中文文本，多了爆显存
