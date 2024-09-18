
#let date = datetime(
  year: 2023,
  month: 6,
  day: 17,
)
#metadata((
  title: "windows只用键盘如何打开蓝牙，连接蓝牙鼠标？",
  subtitle: [windows],
  author: "dashuai009",
  description: "",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


== 事故描述
今天手残了，用蓝牙鼠标把蓝牙关掉了，鼠标直接切断了。电脑上只有有线键盘还连着。

== 恢复
我用的windows11，win+i打开设置，用tab和上下键挪到打开蓝牙的地方，用#strong[空格键]打开蓝牙。
之前用enter死活打不开，还是上网搜出来，应该用空格键。