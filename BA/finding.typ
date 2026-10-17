// Finding callout box function with auto-numbering and referencing
#let finding-counter = counter("finding")

#let finding(content) = figure(
  kind: "finding",
  supplement: [_Finding_],
  {
    finding-counter.step()
    block(
      fill: luma(245),
      stroke: (left: 3pt + black),
      inset: 10pt,
      radius: 2pt,
      width: 100%,
      context [*Finding #finding-counter.display():* #content]
    )
  }
)
