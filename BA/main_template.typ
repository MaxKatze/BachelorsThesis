// LTeX: enabled=false
#import "template.typ": caption_with_source, project
#set math.equation(numbering: "1.")
#show: project.with(
  // 'de' for german or 'en' for english.
  // Pull Requests for other languages are welcome! :)
  lang: "en",

  // 'dhbw' or 'ihk'
  program: "dhbw",

  // Shows a line for a signature, if set to `false`,
  is_digital: true,

  // Display the confidentiality clause
  confidentiality_clause: true,

  // Your degree program
  examination: "Bachelor of Science (B. Sc.)",

  // Your field of study
  study_field: "Computer Science",

  ///
  /// Cover Sheet
  ///
  // Full title of your project
  title_long: "Decomposition of Supply Networks into Subnetworks for Reducing Computational Complexity in Mixed-Integer Optimization Problems",
  // Shortened title, which is displayed in the header on every page
  title_short: "Writing in Typst",
  // The type of your project
  thesis_type: "Projektarbeit 1 (T3_2000)",
  // Other information about you and your project
  authors: (
    (
      firstname: "John",
      lastname: "Doe",
      identification_number: "0000000",
      course: "TINF21B2", // optional
    ), // make sure to keep this comma after the first author if there is only one author!
    // (
    //   firstname: "Erika",
    //   lastname: "Musterfrau",
    //   identification_number: "1234567",
    //   course: "TINF23B1"
    // )
  ),
  signature_place: "Karlsruhe",
  submission_date: "31. März 2023",
  processing_period: "01.01.2023 - 31.03.2023",
  // Commenting out the line below removes the department from the title page
  department: "ABAP Kernel",
  supervisor_company: "Christian Klein",
  supervisor_university: "Prof. Dr. Heinrich Braun",

  // Disable the abstract by changing to `abstract: ()`
  // To load the abstract from a file use include("abstract.typ") instead of [...]`
  // If you only want one language, leave the comma at the end -> `("de", "Deutsch", []),` its necessary for syntax of the template
  abstract: (
    ("de", "Deutsch", include "abstracts/abstract_german.typ"),
    (
      "en",
      "English",
      [This is a short abstract to show the formatting and general style of the template

        It is possible to have multiple abstracts in different languages
      ],
    ),
  ),

  // appendices: usage: ("Title", [content] || include("appendix.typ"))
  // change to `appendices: none` to remove appendix
  appendices: (
    // ("Appendix Titel 1", include("appendix.typ")), // appendix from file
    (
      "Titel 1",
      [
        == This is some more source code
        #lorem(10)
      ],
    ), // appendix inline
    (
      "Titel 2",
      [
        == Even more!
        #lorem(50)
      ],
    ),
  ),

  // Path/s to references - either .yaml or .bib files
  // * for `.yaml` files see: [hayagriva](https://github.com/typst/hayagriva)
  library_paths: "example.yaml",

  // Specify acronyms here.
  // The key is used to reference the acronym.
  // The short form is used every time and the long form is used
  // additionally the first time you reference the acronym.
  acronyms: (
    (key: "NN", short: "NN", long: "Neural Network"),
    (key: "SG", short: "SG", long: "Singular"),
  ),
)

// LTeX: enabled=true
// You can now start writing :)

= Introduction

Typst is a versatile and powerful tool for creating well-structured and beautifully formatted documents, from technical reports to academic papers. This guide provides a detailed overview of using Typst, highlighting its key features, including basic formatting, embedding code blocks and utilizing specialized functions for enhanced document design.

= Algorithms
In this section various algorithms are introduced to split the graph into subnetworks. Those algorithms will later be implemented and evaluated.
The underlying problem can be formulated as in @underlying_problem.
$ Pi = {V_1, V_2, dots, V_n}, V_i inter V_j = emptyset, union.big_i V_i = V $ <underlying_problem>
== Horizontal Cutting
The first approach is to perform a layering algorithm on the graph with the outcome that, for any node $A$, $L(A)$ gives us the number of ancestors of $A$.
$ V_l = {v in V | L(v) = l} $

== Clustering
Clustering Algorithms => $Pi = {V_1, V_2, dots, V_n}$

== Vertical Cutting


= Basic Formatting

#let typst-preview(output, typst-code) = table(
  columns: 2,
  fill: (_, row) => if row == 0 { blue } else { white },
  align: (_, row) => if row == 0 { center } else { horizon + left },
  text(fill: white, weight: "bold", "Typst Code"),
  text(fill: white, weight: "bold", "Output"),

  align(horizon, box(width: 100%, typst-code)),
  box(width: 100%)[
    #set heading(numbering: "i.", outlined: false, offset: 1)
    #output
  ],
)

- *Headings and Subheadings:* Create headings by typing = followed by your heading text. Increase the number of `=` signs for subheadings, indicating their level within the document structure.

- *Emphasizing Text:* Use `_underscores_` to _italicize words or phrases_, adding emphasis where needed.

- *Lists:* Generate ordered lists with `+` and unordered lists with `-`. Indent lists for sub-items, creating a hierarchical structure.

#typst-preview[
  = Main Heading
  _This_ is a *level 1* heading.

  == Subheading
  + This is an ordered list.
  + It can contain multiple items.
][```typ
= Main Heading
_This_ is a *level 1* heading.

== Subheading
+ This is an ordered list.
+ It can contain multiple items.
```]

= Advanced Elements

== Figures
Inserting figures and code blocks into your Typst document enhances its informational depth. When specifying a `caption` for a figure, the template will automatically generate a list of figures, making it easy to navigate your document.

/ Note: When using "ieee" Sorting for bibliography, the sources for figures will be evaluated before the text. To prevent "false sorting", you can use `#caption_with_source("Text", [@source])` instead. This will display the caption in outlines without source and will the source evaluate at the time the figure is displayed

=== Image Figures
#typst-preview(figure(image("assets/SAP-Logo.svg"), caption: "SAP Logo"))[```typ
#figure(
  image("assets/SAP-Logo.svg"),
  caption: "SAP Logo"
)
```]

=== Code Snippets:

#import "utils.typ": codefigure, codefigurefile

This template uses #link("https://typst.app/universe/package/codly")[Codly] for code snippets. Look at their documentation on how to further customize and control your code blocks.

Besides that the template provides two functions to create code snippet figures that get listed in a source code listing: `codefigure` and `codefigurefile`.

// Pagebreak for better formatting
#pagebreak()

Use `codefigure` to display a code figure from the provided code.

#typst-preview(
  codefigure(caption: "My Code")[```rust
  fn main() {
    println!("Hello World!");
  }
  ```],
  raw(read("assets/example-code.typ"), block: true, lang: "typ"),
)

/ Note: You can also provide custom syntax (`.sublime-syntax`) files for code highlighting. The template already includes a syntax file for CDS, so you can use the `cds` language in your code blocks.

Use `codefigurefile` to create a code snippet figure from the content of a file. Note that the provided file is searched relative to `./`.

#typst-preview(
  codefigurefile("assets/example-code.typ", caption: "My Code from a file"),
  ```typst
   #codefigurefile(
     "assets/example-code.typ",
     caption: "My Code from a file"
   )
  ```,
)

== Math
The math syntax is a loose interpretation of LaTeX, allowing you to create complex mathematical equations with ease.
See #link("https://typst.app/docs/reference/math/", "the Typst documentation") for a detailed overview of the math syntax.

#typst-preview[
  $
    sum_(k=0)^n k & = 1 + ... + n \
                  & = (n(n+1)) / 2 \
  $
][```typ
$ sum_(k=0)^n k
    &= 1 + ... + n \
    &= (n(n+1)) / 2 $
```]

== Block Quotes

#typst-preview[
  #quote(attribution: [Frankling D. Roosevelt @fdr_inaugural_address])[
    The only thing we have to fear is fear itself.
  ]
][```typ
#quote(attribution: [Frankling D. Roosevelt @fdr_inaugural_address])[
  The only thing we have to fear is fear itself.
]
```]

== Notes

#import "@preview/drafting:0.2.2": *

This template uses #link("https://typst.app/universe/package/drafting/")[Drafting] for notes.
Using `margin-note` you can add notes to #margin-note("Anywhere in your document!") the margin of your document.

#inline-note[You can also add inline notes to your document with `inline-note`]

Check out their documentation for more advanced use casese.

You might have noticed the notes listing on the first page of this document.
This listing reminds you of the notes still present in your document. Once you remove all notes, the listing will disapear.

= References and Citations

== Local Elements
You can reference local elements like figures, code blocks and sections using the `ref()` function. You can also use the synax sugar `<ref>` to define and `@<ref>` to reference references.

#typst-preview[
  = Important Section <section-1>
  Some important text

  = Other Section
  More important text, just like @section-1
][```typ
= Section 1 <section-1>
Some important text

= Section 2
More important text, just like @section-1
```]

== Code Blocks
If you use the provided `codefigure` function, you can specify a reference name via the `reference` parameter. This allows you to reference the code block later in the document.

#typst-preview(
  [#codefigure(caption: "Code w/ Ref", reference: "my-rust-code")[```rust
    fn main() {
      panic!("Hilfe!");
    }
    ```]

    Look at my code in @my-rust-code!],
  raw(read("assets/example-code-2.typ"), block: true, lang: "typ"),
)

== Bibliography
Typst supports references to external sources, such as books, articles and websites. You can include a `.yaml` or `.bib` file with your references and use the `cite()` function to reference them in your document. Again, you can use the same syntax sugar `@<ref>` to cite.

#typst-preview[
  #quote[
    Just Because You're Allowed To Use Magic Now Does Not Mean You Have To Whip Your Wands Out For Everything! @harry
    _\~ Molly Weasley_
  ]
][```typ
#quote[
  Just Because [...] Whip Your Wands Out For Everything! @harry
  _\~ Molly Weasley_
]
```]

== Acronyms
Specify acronyms in the project configuration to use them throughout your document. You can use the `@acr` function to reference acronyms and the `@acr:pl` function to reference their plural form.

#typst-preview[
  #quote[
    I don't understand @NN or @NN:pl and never will understand.
  ]
][```typ
  #quote[
    I don't understand @NN or @NN:pl and never will.
    _\~ Me_
  ]
  ```
]

On the first usage, the full form of the acronym is displayed and on subsequent usages, only the acronym is shown.

= Conclusion
Happy writing with Typst! If you have any questions, open an issue :)
