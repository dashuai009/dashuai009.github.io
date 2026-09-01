#let date = datetime(
  year: 2022,
  month: 9,
  day: 1,
)
#metadata((
  title: "欧拉函数与中国剩余定理",
  subtitle: [math,数论,中国剩余定理],
  author: "dashuai009",
  description: "欧拉函数与中国剩余定理",
  pubDate: date.display(),
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

== $phi.alt$函数公式
<phi函数公式>
- 如果p是素数，且$k gt.eq 1$，则 $ phi.alt (p^k) = p^k - p^(k - 1) $
- 如果$g c d (m , n) = 1$，则$phi.alt (m n) = phi.alt (m) phi.alt (n)$

== 证明
<证明>
瞪眼法可得证。

== 中国剩余定理
<中国剩余定理>
设$a_1 , a_2 , dots.h , a_k$是任意整数，且$n_1 , n_2 , dots.h , n_k$两两互素，则同余方程组
$
  {(
    x equiv a_1 (#h(0em) mod med n_1)\
    x equiv a_2 (#h(0em) mod med n_2)\
    dots.h\
    x equiv a_k (#h(0em) mod med n_k)
  )
$
有解。令$N = product_(i = 1)^k n_i$，则同余方程组的解在模N下，唯一。

唯一为：

$ x = (sum_(i = 1)^k a_i N / n_i m_i) #h(0em) mod med N $

其中$m_i$为$N / n_i$在模$n_i$下的逆元
