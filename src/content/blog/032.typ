#let date = datetime(
  year: 2022,
  month: 8,
  day: 29,
)
#metadata((
  title: "欧拉公式",
  subtitle: [math,数论],
  author: "dashuai009",
  description: "欧拉公式及其证明",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf


== 欧拉函数
<欧拉函数>
在1\~m中与m互素的整数的个数，记作$phi.alt (m)$

$ phi.alt (m) = {a \| 1 lt.eq a lt.eq m , gcd (a , m) = 1} $

显然，$phi.alt (1) = 0 , phi.alt (p) = p - 1$

== 欧拉公式

若$gcd (a , m) = 1$，则 $ a^(phi.alt (m)) equiv 1 (mod med m) . $

== 证明
<证明>
先来说明一个引理

=== 引理 令数列
$1 lt.eq b_1 < b_2 < dots.h < b_(phi.alt (m)) < m$是1\~m中与m互素的$phi.alt (m)$个整数。

若$g c d (a , m) = 1$，则数列$ b_1 a , b_2 a , b_3 a , dots.h , b_(phi.alt (m)) a med med (mod med m) , $于数列 $ 1 , 2 , 3 , dots.h , b_(phi.alt (m)) med med (mod med m) , $
相同（忽略次序）。

=== 引理证明
<引理证明>
证明过程与费马小定理证明过程类似。

注意到$g c d (b_i , m) = g c d (a , m) = 1$，则$g c d (b_i a , m) = 1$.

从而数列(1)与同余于数列(2)每一个数。这两个数列都含有$phi.alt (m)$个数字。

从数列(1)中任取两个数$b_j a$和$b_k a$，假设它们同余：
$ b_j a equiv b_k a (mod med p) $

则$p \| (j - k) a$，又因为$a equiv.not 0 (mod med m)$，所以$m \| (b_j - b_k)$。

而$1 lt.eq b_j , b_k lt.eq m - 1$，则
$0 lt.eq lr(|b_j - b_k|) lt.eq m - 2$，仅有$b_j = b_k$时，$p \| 0$。

所以，$b_1 a , b_2 a , b_3 a , dots.h , b_(phi.alt (m)) a$模m不同余。

$phi.alt (m)$个数模m不同余，这$phi.alt (m)$个余数一定就是数列(2)。得证。

== 证明欧拉公式
<证明欧拉公式>
引理中的两个数列连乘得：

$ b_1 a dot.op (b_2 a) dots.h dot.op b_(phi.alt (m)) a equiv b_1 dot.op b_2 dots.h dot.op b_(phi.alt (m)) (mod m) $

即

$ a^(phi.alt (m)) B equiv B (mod med m) $

又有$B$与$m$互素，两边消掉得

$a^(phi.alt (m)) equiv 1 (mod med m)$

得证。

== 卡歇米尔数

如果对于每个满足$gcd (a , m) = 1$的整数a，同余式$a^(m - 1) equiv 1 (#h(0em) mod med m)$成立，则称#strong[合数m为卡歇米尔数];。

例如$m = 561 = 3 \* 11 \* 17$是卡歇米尔数。
