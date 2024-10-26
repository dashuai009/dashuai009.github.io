
#let date = datetime(
  year: 2022,
  month: 10,
  day: 2,
)
#metadata((
  title: "梅森素数与完全数",
  subtitle: [数论],
  author: "dashuai009",
  description: "什么是梅森素数，欧几里得完全数公式，$delta$函数的定义，欧拉完全数定理",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

== 引入梅森素数
<引入梅森素数>
#quote[
  对于整数$a gt.eq 2 , n gt.eq 2$， 若$a^n - 1$ 是素数，则$a = 2 , n$
  为素数。
]

注意反之不一定成立。

注意到，几何级数求和公式
$ a^n - 1 = (a - 1) (a^(n - 1) + a^(n - 2) + dots.h + a + 1) $

若a\>2，则$a - 1 > 1 , a - 1 \| (a^n - 1)$，与$a^n - 1$是素数冲突。

若n为合数，假设$n = m k$，由上式，

$
  a^n - 1 & = (a^m)^k - 1\
  & = ((a^m) - 1) ((a^m)^(k - 1) + dots.h + a^m + 1)
$

所以$a^m - 1 > 1 , a^m - 1 \| (a^n - 1)$，冲突。

得证。

#quote[
  对于整数$a gt.eq 2 , n gt.eq 2$， 若$a^n + 1$ 是素数，则$n$ 为2的幂次。
]

证明类似，用到$a^n+1$的公式。

== 梅森素数

我们将形容如$a^p - 1$的素数称为梅森素数。

- 有无穷多个梅森素数吗？现在仍不知道

== 什么是完全数

#quote[
  真因数之和等于他本身。
]

比如6=1+2+3，28=1+2+4+7+14

== 欧几里得完全数公式

#quote[
  如果$2^p - 1$是素数 ， 则$2^(p - 1) (2^p - 1)$是完全数
]

== $sigma$函数

=== 定义
$ sigma (n) = n 的 所 有 因 数 之 和 （ 包 括 1 和 n ） $

=== 性质
<性质>
- 如果p是素数，$k gt.eq 1$，则

$ sigma (p^k) = sum_(i = 0)^n p^i = frac(p^(k + 1) - 1, p - 1) $

- 如果$gcd (m , n) = 1$，则$sigma (m n) = sigma (n) sigma (m)$

=== 证明

瞪眼法

== 欧拉完全数定理
<欧拉完全数定理>
如果n是偶完全数，则n形如$n = 2^(p - 1) (2^p - 1)$，其中
$2^p - 1$是梅森素数。

=== 证明
<证明>
将偶数中的2都分解出来，则$n = 2^k m$，其中$k gt.eq 1$且m是奇数。则
$
  sigma (n) = & sigma (2^k m)\
  = & sigma (2^k) sigma (m)\
  = & (2^(k + 1) - 1) sigma (m)
$

又n为完全数，则$sigma (n) = 2 n = 2^(k + 1) m$。所以，

$ 2^(k + 1) m = (2^(k + 1) - 1) sigma (m) $

即$2^(k + 1) \| (2^(k + 1) - 1) sigma (m)$，
即$2^(k + 1) \| sigma (m)$。
也就是说存在整倍数c，使得$sigma (m) = 2^(k + 1) c$。

#set math.equation(numbering: "(1)")
即 $
2^{k+1}m=(2^{k+1}-1)\\sigma(m)=(2^{k+1}-1)2^{k+1}c
 $

即

$ m = (2^(k + 1) - 1) c med 且 med sigma (m) = 2^(k + 1) c $

下面，我们来证明c=1.反证法，先假设c\>1。

则m至少有三个不同的因数$1 , c , m$。
$ sigma (m) gt.eq 1 + c + m = 1 + c + (2^(k + 1) - 1) c = 1 + 2^(k + 1) c $

又由(1)得， $ 2^(k + 1) c gt.eq 1 + 2^(k + 1) c $
显然，这是荒谬的。故假设不成立，c因该等于1 。 这样，我们得知
$ m = (2^(k + 1) - 1) ， 且 sigma (m) = 2^(k + 1) = 1 + m $

后半部分说明m为质数（因数只有1，m）。 所以，如果n为偶完全数，则
$ n = 2^k (2^(k + 1) - 1) ， 其 中 2^(k + 1) - 1 是 素 数 。 $
。再由梅森素数的定义，原定理得证。

== 奇完全数

存在吗？现在不知。


== 定理

设 $p$ 和 $q$ 是奇素数。若 $p$ 整除 $M_q$ ，则 $p e.not 1 (mod p)$ 且 $p eq.not plus.minus 1 (mod 8)$。

=== 证明


== Pollard's p - 1 algorithm