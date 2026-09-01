#let date = datetime(
  year: 2022,
  month: 8,
  day: 28,
)
#metadata((
  title: "费马小定理",
  subtitle: [math,数论],
  author: "dashuai009",
  description: "费马小定理及其证明",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


== 费马小定理
<费马小定理>
设p为素数，a是任意整数，且$a equiv.not 0 (m o d med p)$，则
$ a^(p - 1) equiv 1 (m o d med p) . $

== 证明
<证明>
先来说明一个引理
=== 引理

设p是素数，a是任何整数，且$a equiv.not 0 (m o d med p)$，则数列
$ a , 2 a , 3 a , dots.h , (p - 1) a med med (m o d med p) $ 于数列
$ 1 , 2 , 3 , dots.h , (p - 1) med med (m o d med p) $

相同（忽略次序）。

=== 引理证明
<引理证明>
数列$a , 2 a , 3 a , dots.h , (p - 1) a$，含有$p - 1$ 个数字。

任取两个数$j a$和$k a$，假设它们同余： $ j a equiv k a (m o d med p) $

则$p \| (j - k) a$，又因为$a equiv.not 0 (m o d med p)$，所以$p \| (j - k)$。

而$1 lt.eq j , k lt.eq p - 1$，则
$0 lt.eq lr(|j - k|) lt.eq q - 2$，仅有$j = k$时，$p \| 0$。

所以，$a , 2 a , 3 a , dots.h , (p - 1) a$模p不同余。

p-1个数模p不同余，这p-1个余数一定就是$1 , 2 , dots.h , p - 1$。得证。

== 证明费马小定理
<证明费马小定理>
引理中的两个数列连乘得：

$ a dot.op (2 a) dots.h dot.op (p - 1) a equiv 1 dot.op 2 dots.h dot.op (p - 1) (m o d p) $

即

$ a^(p - 1) (p - 1) ! equiv (p - 1) ! (m o d med p) $

又有$(p - 1) !$与$p$互素，两边消掉得

$a^(p - 1) equiv 1 (m o d med p)$

得证。

== 利用费马小定理简单判断一个数是不是质数

a可以随便取，比如取2，只要计算出$2^(m - 1) #h(0em) mod med m eq.not 1$，那就说明m不是质数。
比如

当$m = 10^6 + 7$时，$2^(m - 1) #h(0em) mod med m = 399097$，所以$1 e 6 + 7$不是质数。

注意，若 $2^(m-1) mod m eq 1 $，#strong[m不一定是质数]
