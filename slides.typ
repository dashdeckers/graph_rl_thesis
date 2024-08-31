#import "@preview/polylux:0.3.1": *
#import "slides_template.typ": *
#import "drawings.typ": *

#show link: set text(blue)
#set text(font: "Inria Sans")
#show heading: set text(font: "Vollkorn")
#show raw: set text(font: "JuliaMono")

#show: clean-theme.with(
    logo: image("images/logo.png"),
    short-title: [DRL & Graphs],
    footer: [Travis Hammond - Rijksuniversiteit Groningen],
)

#let textsize = 20pt
#set text(size: textsize)

// Helper function to show figures in 11pt text-size
#let ogfigure(fig) = [
  #set text(size: 11pt) // Set text-size to 11pt in scope
  #figure(fig)
]


#title-slide(
    title: [Combining Graph-Based Planning and Deep Reinforcement Learning],
    subtitle: "Masters Thesis",
    authors: "Travis Hammond",
    date: "September 2024",
)


/// SECTION
#new-section-slide("Introduction")


#slide(title: "About this presentation")[
    #ogfigure(agent-environment-loop)

    Let's explore what we have here.
]


/// SECTION
#new-section-slide("Methods")


#slide(title: "A title")[
    #ogfigure(on-policy-vs-off-policy-algorithms)
]


/// SECTION
#new-section-slide("Results")


/// SECTION
#new-section-slide("Conclusion")


#slide(title: "That's it!")[
  Consider giving my repository #link("https://github.com/dashdeckers/graph_rl")[a GitHub star #text(font: "OpenMoji")[#emoji.star]] or open an issue if you run into bugs or have feature requests.
]

































// #new-section-slide("Dynamic content")


// #slide(title: [A dynamic slide with `pause`s])[
//     Sometimes we don't want to display everything at once.
//     #pause

//     That's what the `#pause` function is there for!
//     #pause

//     It makes everything after it appear at the next subslide.

//     #text(.6em)[(Also note that the slide number does not change while we are here.)]
// ]

// #slide(title: "Fine-grained control")[
//     When `#pause` does not suffice, you can use more advanced commands to show
//     or hide content.

//     These are some of your options:
//     - `#uncover`
//     - `#only`
//     - `#alternatives`
//     - `#one-by-one`
//     - `#line-by-line`

//     Let's explore them in more detail!
// ]

// #let example(body) = block(
//     width: 100%,
//     inset: .5em,
//     fill: aqua.lighten(80%),
//     radius: .5em,
//     text(size: .8em, body)
// )

// #slide(title: [`#uncover`: Reserving space])[
//     With `#uncover`, content still occupies space, even when it is not displayed.

//     For example, #uncover(2)[these words] are only visible on the second "subslide".

//     In `()` behind `#uncover`, you specify _when_ to show the content, and in
//     `[]` you then say _what_ to show:
//     #example[
//         ```typ
//         #uncover(3)[Only visible on the third "subslide"]
//         ```
//         #uncover(3)[Only visible on the third "subslide"]
//     ]
// ]

// #slide(title: "Complex display rules")[
//     So far, we only used single subslide indices to define when to show something.

//     We can also use arrays of numbers...
//     #example[
//         ```typ
//         #uncover((1, 3, 4))[Visible on subslides 1, 3, and 4]
//         ```
//         #uncover((1, 3, 4))[Visible on subslides 1, 3, and 4]
//     ]

//     ...or a dictionary with `beginning` and/or `until` keys:
//     #example[
//         ```typ
//         #uncover((beginning: 2, until: 4))[Visible on subslides 2, 3, and 4]
//         ```
//         #uncover((beginning: 2, until: 4))[Visible on subslides 2, 3, and 4]
//     ]
// ]

// #slide(title: "Convenient rules as strings")[
//     As as short hand option, you can also specify rules as strings in a special
//     syntax.

//     Comma separated, you can use rules of the form
//     #table(
//         columns: (auto, auto),
//         column-gutter: 1em,
//         stroke: none,
//         align: (x, y) => (right, left).at(x),
//         [`1-3`], [from subslide 1 to 3 (inclusive)],
//         [`-4`], [all the time until subslide 4 (inclusive)],
//         [`2-`], [from subslide 2 onwards],
//         [`3`], [only on subslide 3],
//     )
//     #example[
//         ```typ
//         #uncover("-2, 4-6, 8-")[Visible on subslides 1, 2, 4, 5, 6, and from 8 onwards]
//         ```
//         #uncover("-2, 4-6, 8-")[Visible on subslides 1, 2, 4, 5, 6, and from 8 onwards]
//     ]
// ]

// #slide(title: [`#only`: Reserving no space])[
//     Everything that works with `#uncover` also works with `#only`.

//     However, content is completely gone when it is not displayed.

//     For example, #only(2)[#text(red)[see how]] the rest of this sentence moves.

//     Again, you can use complex string rules, if you want.
//     #example[
//         ```typ
//         #only("2-4, 6")[Visible on subslides 2, 3, 4, and 6]
//         ```
//         #only("2-4, 6")[Visible on subslides 2, 3, 4, and 6]
//     ]
// ]

// #slide(title: [`#alternatives`: Substituting content])[
//     You might be tempted to try
//     #example[
//         ```typ
//         #only(1)[Ann] #only(2)[Bob] #only(3)[Christopher] likes #only(1)[chocolate] #only(2)[strawberry] #only(3)[vanilla] ice cream.
//         ```
//         #only(1)[Ann] #only(2)[Bob] #only(3)[Christopher]
//         likes
//         #only(1)[chocolate] #only(2)[strawberry] #only(3)[vanilla]
//         ice cream.
//     ]

//     But it is hard to see what piece of text actually changes because everything
//     moves around.
//     Better:
//     #example[
//         ```typ
//         #alternatives[Ann][Bob][Christopher] likes #alternatives[chocolate][strawberry][vanilla] ice cream.
//         ```
//         #alternatives[Ann][Bob][Christopher] likes #alternatives[chocolate][strawberry][vanilla] ice cream.
//     ]
// ]

// #slide(title: [`#one-by-one`: An alternative for `#pause`])[
//     `#alternatives` is to `#only` what `#one-by-one` is to `#uncover`.

//     `#one-by-one` behaves similar to using `#pause` but you can additionally
//     state when uncovering should start.
//     #example[
//         ```typ
//         #one-by-one(start: 2)[one ][by ][one]
//         ```
//         #one-by-one(start: 2)[one ][by ][one]
//     ]

//     `start` can also be omitted, then it starts with the first subside:
//     #example[
//         ```typ
//         #one-by-one[one ][by ][one]
//         ```
//         #one-by-one[one ][by ][one]
//     ]
// ]

// #slide(title: [`#line-by-line`: syntactic sugar for `#one-by-one`])[
//     Sometimes it is convenient to write the different contents to uncover one
//     at a time in subsequent lines.

//     This comes in especially handy for bullet lists, enumerations, and term lists.
//     #example[
//         #grid(
//             columns: (1fr, 1fr),
//             gutter: 1em,
//             ```typ
//             #line-by-line(start: 2)[
//                 - first
//                 - second
//                 - third
//             ]
//             ```,
//             line-by-line(start: 2)[
//                 - first
//                 - second
//                 - third
//             ]
//         )
//     ]

//     `start` is again optional and defaults to `1`.
// ]

// #slide(title: [`#list-one-by-one` and Co: when `#line-by-line` doesn't suffice])[
//     While `#line-by-line` is very convenient syntax-wise, it fails to produce
//     more sophisticated bullet lists, enumerations or term lists.
//     For example, non-tight lists are out of reach.

//     For that reason, there are `#list-one-by-one`, `#enum-one-by-one`, and 
//     `#terms-one-by-one`, respectively.
//     #example[
//         #grid(
//             columns: (1fr, 1fr),
//             gutter: 1em,
//             ```typ
//             #enum-one-by-one(start: 2, tight: false, numbering: "i)")[first][second][third]
//             ```,
//             enum-one-by-one(start: 2, tight: false, numbering: "i)")[first][second][third]
//         )
//     ]

//     Note that, for technical reasons, the bullet points, numbers, or terms are
//     never covered.

//     `start` is again optional and defaults to `1`.
// ]


// /*
// #slide(title: "Different ways of covering content")[
//     When content is covered, it is completely invisible by default.

//     However, you can also just display it in light gray by using the
//     `mode` argument with the value `"transparent"`:
//     #let pc = 1
//     #{ pc += 1 } #show: pause(pc, mode: "transparent")

//     Covered content is then displayed differently.
//     #{ pc += 1 } #show: pause(pc, mode: "transparent")

//     Every `uncover`-based function has an optional `mode` argument:
//     - `#show: pause(...)`
//     - `#uncover(...)[...]`
//     - `#one-by-one(...)[...][...]`
//     - `#line-by-line(...)[...][...]`
// ]
// */

// #new-section-slide("Themes")


// #slide(title: "How a slide looks...")[
//     ... is defined by the _theme_ of the presentation.

//     This demo uses the `clean` theme.

//     Because of it, the title slide and the decoration on each slide (with
//     section name, short title, slide number etc.) look the way they do.

//     Themes can also provide variants, for example ...
// ]

// #focus-slide[
//     ... this one!

//     It's very minimalist and helps the audience focus on an important point.
// ]

// #slide(title: "Your own theme?")[
//     If you want to create your own design for slides, you can define custom
//     themes!

//     #link("https://polylux.dev/book/themes/your-own.html")[The book]
//     explains how to do so.
// ]

// #new-section-slide("Utilities")

// #slide(title: [The `utils` module])[
//     Polylux ships a `utils` module with solutions for common tasks in slide
//     building.
// ]

// #slide(title: [Fit to height])[
//     You can scale content such that it has a certain height using
//     `#fit-to-height(height, content)`:

//     #fit-to-height(2.5cm)[Height is `2.5cm`]
// ]

// #slide(title: "Fill remaining space")[
//     This function also allows you to fill the remaining space by using fractions
//     as heights, i.e. `fit-to-height(1fr)[...]`:

//     #fit-to-height(1fr)[Wow!]
// ]

// #slide(title: "Side by side content")[
//     Often you want to put different content next to each other.
//     We have the function `#side-by-side` for that:

//     #side-by-side(lorem(10), lorem(20), lorem(15))
// ]

// #slide(title: "Outline")[
//     Why not include an outline?
//     #polylux-outline(padding: 1em, enum-args: (tight: false))
// ]

// #new-section-slide("Typst features")

// #slide(title: "Use Typst!")[
//     Typst gives us so many cool things #footnote[For example footnotes!].
//     Use them!
// ]

// #slide(title: "Bibliography")[
//     Let us cite something so we can have a bibliography: @DDPG
//     #bibliography(title: none, "refs.bib")
// ]

