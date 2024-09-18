#let date = datetime(
  year: 2022,
  month: 3,
  day: 14,
)
#metadata((
  title: "生成函数",
  subtitle: [生成函数,math],
  author: "dashuai009",
  description: "生成函数",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

== 普通生成函数
<普通生成函数>
$ F (x) = sum_n a_n a^n (n gt.eq 0) $

=== 等比数列
<等比数列>
数列$< 1 , p , p^2 , p^3 , . . . , p^n , . . . >$的生产成函数$F (x) = sum_(n gt.eq 0) p^n x^n$的封闭式为$F (x) = frac(1, 1 - p x)$

=== $a = < 1 , 2 , 3 , 4 . . . >$
<a1234...>
生成函数 $ F (x) & = sum_(n gt.eq 0) (n + 1) x^n\
 & = sum_(n gt.eq 1) n x^(n - 1)\
 & = sum_(n gt.eq 0) (x^n) prime\
 & = (frac(1, 1 - x)) prime\
 & = 1 / (1 - x)^2 $

=== $binom(m, n)$,($n gt.eq 0 , m$是常数)
<m-choose-nngeq-0m是常数>
$ F (x) = sum_(n gt.eq 0) binom(m, n) x^n = (1 + x)^m $

=== $binom(m + n, n)$
<mn-choose-n>
$ F (x) = sum_(n gt.eq 0) binom(m + n, n) x^n = 1 / (1 - x)^(m + 1) $

=== 斐波那其数列 $a_0 = 0 , a_1 = 1 , a_n = a_(n - 1) + a_(n - 2) (n > 1)$
<斐波那其数列-a_00a_11a_na_n-1a_n-2n1>
$
  F (x) & = x F (x) + x^2 F (x) - a_0 x + a_1 x + a_0\
  & = frac(x, 1 - x - x^2)
$

通过求解 $ frac(A, 1 - a x) + frac(B, 1 - b x) = frac(x, 1 - x - x^2) $

得

$ frac(x, 1 - x - x^2) = sum_(n gt.eq 0) x^n 1 / sqrt(5) ((frac(1 + sqrt(5), 2))^n - (frac(1 - sqrt(5), 2))^n) $

== 指数生产成函数(exponential generating function，EGF)
<指数生产成函数exponential-generating-functionegf>
$ hat(F) (x) = sum_(n gt.eq 0) a_n frac(x^n, n !) $ \#\#\# 运算

$
  hat(F) (x) hat(G) (x) & = sum_(i gt.eq 0) a_i frac(x^i, i !) sum_(j gt.eq 0) b_j frac(x^j, j !)\
  & = sum_(n gt.eq 0) x^n sum_(i = 1)^n a_i b_(n - i) frac(1, i ! (n - i) !)\
  & = sum_(n gt.eq 0) frac(x^n, n !) sum_(i = 0)^n binom(n, i) a_i b_(n - i)
$

因此 $hat(F) (x) hat(G) (x)$ 是序列
$< sum_(i = 0)^n binom(n, i) a_i b_(n - i) >$ 的指数生成函数。

=== $< 1 , 1 , 1 , 1 , . . . >$
<section>
$ sum_(n gt.eq 1) frac(x^n, n !) = e^x $

=== $< 1 , p , p^2 , . . . >$
<pp2...>
$ sum_(n gt.eq 1) frac(p^n x^n, n !) = e^(p x) $

=== $a_n = n !$
<a_nn>
$ hat(P) (x) = sum_(n gt.eq 0) frac(n ! x^n, n !) = sum_(n gt.eq 0) x^n = frac(1, 1 - x) $

=== 圆排列
<圆排列>
$ hat(Q) (x) = sum_(n gt.eq 1) frac((n - 1) ! x^n, n !) = sum_(n gt.eq 1) x^n / n = - ln (1 - x) = ln (frac(1, 1 - x)) $

=== 圆排列与排列的关系
<圆排列与排列的关系>
=== 生成树计数
<生成树计数>
如果 $n$ 个点 #strong[带标号] 生成树的 EGF 是 $hat(F) (x)$ ，那么 $n$
个点 #strong[带标号] 生成森林的 EGF 就是$e x p hat(F) (x)$
——直观理解为，将 $n$
个点分成若干个集合，每个集合构成一个生成树的方案数之积。

=== 图
<图>
如果 $n$ 个点带标号无向连通图的 EGF 是 $hat(F) (x)$，那么 $n$
个点带标号无向图的 EGF 就是 $e x p hat(F) (x)$，后者可以很容易计算得到
$e x p hat(F) (x) = sum_(n gt.eq 0) 2^(binom(n, 2)) frac(x^n, n !)$。因此要计算前者，只需要一次多项式 $ln$ 即可。

=== 错排数:长度为 $n$ 的一个错排是满足 $p_i eq.not i$ 的排列。
<错排数长度为-n-的一个错排是满足-p_ine-i-的排列>
=== 不动点：
<不动点>
有多少个映射
$f : 1 , 2 , dots.h.c , n arrow.r 1 , 2 , dots.h.c , n$，使得

$
  underbrace(f circle.stroked.tiny f circle.stroked.tiny dots.h.c circle.stroked.tiny f, k) = underbrace(f circle.stroked.tiny f circle.stroked.tiny dots.h.c circle.stroked.tiny f, k - 1)
$

$n k lt.eq 2 times 10^6 , 1 lt.eq k lt.eq 3$。

考虑 $i$ 向 $f (i)$ 连边。相当于我们从任意一个 $i$ 走 $k$ 步和走 $k - 1$
步到达的是同一个点。也就是说基环树的环是自环且深度不超过
$k$（根结点深度为
$1$）。把这个基环树当成有根树是一样的。因此我们的问题转化为：$n$
个点带标号，深度不超过 $k$ 的有根树森林的计数。

考虑 $n$ 个点带标号深度不超过 $k$ 的有根树，假设它的生成函数是
$hat(F_k) (x) = sum_(n gt.eq 0) f_(n , k) frac(x^n, n !)$。

考虑递推求 $hat(F_k) (x)$。深度不超过 $k$ 的有根树，实际上就是深度不超过
$k - 1$ 的若干棵有根树，把它们的根结点全部连到一个结点上去。因此

$ hat(F_k) (x) = x exp hat(F)_(k - 1) (x) $

那么答案的指数生成函数就是 $exp hat(F)_k (x)$。求它的第 $n$ 项即可。

=== Lust
<lust>
给你一个 $n$ 个数的序列 $a_1 , a_2 , dots.h.c , a_n$，和一个初值为 $0$
的变量 $s$，要求你重复以下操作 $k$ 次：

- 在 $1 , 2 , dots.h.c , n$ 中等概率随机选择一个 $x$。
- 令 $s$ 加上 $product_(i eq.not x) a_i$。
- 令 $a_x$ 减一。

求 $k$ 次操作后 $s$ 的期望。

$1 lt.eq n lt.eq 5000 , 1 lt.eq k lt.eq 10^9 , 0 lt.eq a_i lt.eq 10^9$。
假设 $k$ 次操作后 $a_i$ 减少了 $b_i$，那么实际上

$ s = product_(i = 1)^n a_i - product_(i = 1)^n (a_i - b_i) $

因此实际上我们的问题转化为，求 $k$ 次操作后
$product_(i = 1)^n (a_i - b_i)$ 的期望。

不妨考虑计算每种方案的的 $product_(i = 1)^n (a_i - b_i)$ 的和，最后除以
$n^k$。

而 $k$ 次操作序列中，要使得 $i$ 出现了 $b_i$ 次的方案数是

$ frac(k !, b_1 ! b_2 ! dots.h.c b_n !) $

这与指数生成函数乘法的系数类似。

设 $a_j$ 的指数生成函数是

$ F_j (x) = sum_(i gt.eq 0) (a_j - i) frac(x^i, i !) $

那么答案就是

$ [x^k] product_(j = 1)^n F_j (x) $

为了快速计算答案，我们需要将 $F_j (x)$ 转化为封闭形式：

$
  F_j (
    x
  ) & = sum_(i gt.eq 0) a_j frac(x^i, i !) - sum_(i gt.eq 1) frac(x^i, (i - 1) !) med & = a_j e^x - x e^x med & = (
    a_j - x
  ) e^x
$

因此我们得到

$ product_(j = 1)^n F_j (x) = e^(n x) product_(j = 1)^n (a_j - x) $

其中 $product_(j = 1)^n (a_j - x)$ 是一个 $n$
次多项式，可以暴力计算出来。假设它的展开式是
$sum_(i = 0)^n c_i x^i$，那么

$
  product_(j = 1)^n F_j (x) & = (sum_(i gt.eq 0) frac(n^i x^i, i !)) (sum_(i = 0)^n c_i x^i) med \
  & = sum_(i gt.eq 0) sum_(j = 0)^i c_j x^j frac(n^(i - j) x^(i - j), (i - j) !) med \
  & = sum_(i gt.eq 0) frac(x^i, i !) sum_(j = 0)^i n^(i - j) i^(underline(j)) c_j
$

计算这个多项式的 $x^k$ 项系数即可。