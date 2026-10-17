The following Gurobi parameters were configured for all optimization runs in this evaluation. Parameters not listed use Gurobi's default values.

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: (left, right, left),
    table.header(
      [*Parameter*], [*Value*], [*Description*],
    ),
    [NodeLimit], [1e+100], [Maximum number of branch-and-bound nodes (effectively unlimited)],
    [FeasibilityTol], [1e-08], [Primal feasibility tolerance],
    [IntFeasTol], [1e-08], [Integer feasibility tolerance],
    [OptimalityTol], [1e-06], [Dual feasibility tolerance],
    [MIPGap], [1e-06], [Relative MIP optimality gap],
    [NumericFocus], [2], [Higher numeric precision focus],
    [IntegralityFocus], [1], [Prioritize integrality of solutions],
  ),
  caption: [Non-default Gurobi solver parameters],
) <tab:gurobi-params>