#let config(doc) = {
    set page(paper: "a4")
    set text(lang: "cs")

    set heading(numbering: "1.")
    show heading.where(level: 2): set heading(numbering: none)
    show heading.where(level: 3): set heading(numbering: none)
    show heading: it => { v(1em) + it + v(.5em) }

    show raw.where(block: true): it => block(
        fill: luma(95%),
        width: 100%,
        inset: 8pt,
        radius: 2pt,
        it
    )
    show raw.where(block: false): it => box(
        fill: luma(95%),
        inset: (x: 3pt, y: 0pt),
        outset: (y: 3pt),
        radius: 2pt,
        it
    )

    doc
}
