This appendix documents how subproblem complexity is estimated for runtime allocation. The estimates are computed from input data tables before the @MILP model is built, counting expected variables based on entity attributes and horizon settings. @tab:variable-estimation-full shows which attributes trigger discrete or continuous variables:

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: (left, left, left),
    table.header([*Entity Type*], [*Discrete Variables*], [*Continuous Variables*]),
    [Production], [+1 if discrete/minimum lot size active \ +1 if fixed cost active], [+1 per active period],
    [Transport], [+1 if discrete/minimum lot size active \ +1 if fixed cost active], [+1 per active period],
    [Customer Transport], [+1 if discrete/minimum lot size active \ +1 if fixed cost active], [+1 per active period],
    [External Procurement], [+1 if fixed cost active], [+1 per active period],
    [Location Product], [None], [+1 stock variable per plannable period],
    [Customer Product], [None], [+2 per demand period],
    [Resources], [None], [None (constraints only)],
  ),
  caption: [Variable estimation rules by entity type],
) <tab:variable-estimation-full>

When multiple features require a binary indicator, they share the same variable and may not need a continuous variable.