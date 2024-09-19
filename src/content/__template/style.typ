#let conf(doc) = {
  let quote(body) = {
    rect(fill: luma(240), stroke: (left: 0.25em))[
      #body
    ]
  }

  show raw.line: it => {
    text(fill: gray)[#it.number]
    h(1em)
    it.body
  }

  set text(font: ( "Noto Sans SC", "Source Han Sans"), lang: "zh", region: "cn")
  set par(leading: 1em)
  set page(width: 35em, height: auto, margin: 0.5em)
  doc
}