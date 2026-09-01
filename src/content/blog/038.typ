
#let date = datetime(
  year: 2022,
  month: 11,
  day: 4,
)
#metadata((
  title: "windows cmd切换盘符",
  subtitle: [cmd],
  author: "dashuai009",
  description: "在windwos里，cmd命令行中，直接输入D:回车，就可以切换盘符。",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

在windwos里，cmd命令行中，直接输入D:回车，就可以切换盘符。

之前在win10里死活cd不进D盘，powershell应该没有这种问题。win11没试过。

注意别忘了D后边的冒号。
