
#let date = datetime(
  year: 2023,
  month: 3,
  day: 3,
)
#metadata((
  title: "[USACO Feb. Gold] Problem1. EQUAL SUM SUBARRAYS",
  subtitle: [usaco],
  author: "dashuai009",
  description: "",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


== 题目链接
<题目链接>
#link("http://www.usaco.org/index.php?page=viewproblem2&cpid=1305")[USACO]

== 题目描述
<题目描述>
有一个长度为$N$的数组$a$，a的$frac(N (N + 1), 2)$的连续子序列的和各不相同。对于每一个$i$，输出“最少需修改（增大或减少）$a_i$，使得$a$的两个连续子序列的和相等”。

== 题目解析
<题目解析>
首先求出$frac(N (N + 1), 2)$个子数组的和$s_i$，进行排序。每个和对应一个子数组。
对于每一个$s_i$，对应于原数组的区间$[l_i , s_i]$，如果通过最少修改$s_i$，让$s_i$等于另一个$s_j$，则$s_j$只能是$s_(i - 1)$或$s_(i + 1)$。维护结果数组$r e s_i$，初始化为最大值，对于每个$s_i$，用$min { lr(|s_i - s_(i - 1)|) , lr(|s_i - s_(i + 1)|) }$去更新$[l_i , r_i]$。最后输出结果即可。
