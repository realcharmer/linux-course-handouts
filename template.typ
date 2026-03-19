#import "@preview/toffee-tufte:0.1.1": *

#let doc_template(
  title: "",
  authors: "",
  date: none,
  abstract: [],
  bibfile: none,
  body,
) = {
  // 1. Setup heading spacing logic
  let heading_counter = counter("custom_heading_spacing")
  
  show heading.where(level: 1): it => {
    heading_counter.step()
    // Add space before H1, except for the very first one
    context {
      if heading_counter.get().first() > 1 { v(1em) }
    }
    it
  }

  show heading.where(level: 2): it => { 
    v(0.8em)
    it
  }

  // 2. Configure Global Document Styles
  set page(paper: "a4")
  set text(lang: "cs", font: "Libertinus Serif", size: 10pt)
  set heading(numbering: none)

  // 3. Apply the base Toffee-Tufte template
  show: template.with(
    title: title,
    authors: authors,
    date: date,
    abstract: abstract,
  )

  // 4. Render Body
  body

  // 5. Automatic Bibliography Handling
  if bibfile != none {
    pagebreak()
    wideblock(
      bibliography(
        bibfile,
        full: true,
        style: "iso-690-author-date",
      )
    )
  }
}
