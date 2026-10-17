#import "../finding.typ": finding

= Evaluation <evaluation>

This chapter presents the experimental evaluation of the proposed decomposition approach. The evaluation systematically compares solutions obtained through decomposition against monolithic solving across the 13 benchmark scenarios introduced in @benchmark-scenarios, using the metrics defined in @metrics. Empirical observations and correlations identified during the evaluation are labeled as _Findings_ and numbered sequentially. Each _Finding_ is then analyzed and possible reasons for it are discussed in @discussion. Each scenario is associated with a runtime budget that reflects the time limit used by the customer in production. @tab:runtime-budgets shows the runtime budgets for all benchmark scenarios. The monolithic run and the decomposed run both receive the same runtime budget. If one approach solves the scenario to its proven optimality, the budget is reduced to the used time.

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: (center, right, right),
    table.header(
      [*Scenario*], [*Runtime Budget (s)*], [*Runtime Budget (h)*],
    ),
    [S1], [31000], [8.6],
    [S2], [21600], [6.0],
    [S3], [1800], [0.5],
    [S4], [1600], [0.4],
    [S5], [10800], [3.0],
    [S6], [14800], [4.1],
    [S7], [20000], [5.5],
    [S8], [18000], [5.0],
    [S9], [5], [$<0.01$],
    [S10], [114], [$<0.1$],
    [S11], [18800], [5.2],
    [S12], [45000], [12.5],
    [S13],[1800],[0.5]
  ),
  caption: [Runtime budgets for benchmark scenarios],
) <tab:runtime-budgets>

@tab:baseline-results presents the objective function values and optimality gaps for both approaches. The *Mono. Gap* and *Decomp. Gap* columns show how far each solution deviates from the monolithic bound. The *Avg. Subproblem Gap* column shows the average of how far each subproblem deviates from its own bound. The *Relative Diff.* is calculated as $((text("Decomposition") - text("Monolithic")) / text("Monolithic"))$, showing the percentage difference between the two approaches, where lower objective values are better and thus negative percentages indicate better decomposition solutions. The temporal resolution of the runtime limit permits an accuracy of only two significant figures, because the solver cannot terminate instantly when reaching the runtime limit. Therefore, objective function values in @tab:baseline-results are rounded to two significant figures. Runs that did not provide a valid solution are reported with _inf_.

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    inset: 6pt,
    align: (left, right, right, right, right, right, right),
    table.header(
      [*Scenario*], [*Monolithic*], [*Mono. Gap*], [*Decomposition*], [*Decomp. Gap*], [*Avg. Subproblem Gap*], [*Relative Diff.*],
    ),
    [S1], [3.5e12], [0.00], [3.6e12], [0.01], [0.00], [0.01],
    [S2], [1.1e12], [0.00], [1.2e12], [0.01], [0.00], [0.01],
    [S3], [4.2e14], [0.28], [3.0e14], [0.01], [0.00], [-0.29],
    [S4], [inf], [inf], [2.0e9], [unknown], [0.00], [inf(Mono)],
    [S5], [1.9e17], [0.36], [2.0e17], [0.40], [0.13], [0.05],
    [S6], [6.3e16], [0.00], [inf], [inf], [inf], [inf(Deco)], 
    [S7], [7.5e12], [0.68], [2.7e12], [0.10], [0.35], [-0.64],
    [S8], [1.1e13], [0.85], [inf], [inf], [inf], [inf(Deco)], 
    [S9], [1.5e12], [0.33], [1.1e12], [0.07], [0.00], [-0.26],
    [S10], [2.2e12], [0.55], [1.1e12], [0.07], [0.00], [-0.52],
    [S11], [5.1e13], [0.94], [2.6e13], [0.88], [0.19], [-0.49], 
    [S12], [2.2e13], [0.93], [1.8e12], [0.12], [0.01], [-0.92],
    [S13], [8.9e11], [0.00], [1.6e12], [0.78], [0.00], [0.78]
  ),
  caption: [Objective function values and optimality gaps for monolithic and decomposition approaches],
) <tab:baseline-results>

Across the 10 scenarios for which both approaches produced feasible solutions, the average relative difference was −23%, corresponding to an average relative objective value improvement of 23% for decomposition. Of these 10 directly comparable scenarios, 6 showed improvement under decomposition while 4 showed worse results. Additionally, one scenario produced a feasible solution only under decomposition, and two scenarios produced feasible solutions only under monolithic solving.

The first notable correlation is that scenarios S1, S9 and S10 report an Avg. Subproblem Gap of $0.00$ but fail to find the optimal monolithic solution, shown by the Decomp. Gap being greater than $0.00$. To verify whether this gap represented a genuinely suboptimal decomposed solution, the corresponding monolithic models S9 and S10 were solved with extended runtime in another experiment run. The monolithic solver subsequently found integer-feasible solutions matching the respective bounds implied by the decomposition gaps. This confirms that the bounds were attainable and that the decomposed solutions were not globally optimal, despite all subproblems having been solved to optimality. This leads to @finding-local-optimal:

#finding[Solving all subproblems to optimality does not guarantee that the decomposition finds the global optimum.] <finding-local-optimal>

Decomposition performs substantially better on scenarios where the monolithic solution reports a large optimality gap due to problem size. Examples include scenarios S11 (0.94 Mono. Gap and -0.49 improvement) and S12 (0.93 Mono. Gap and -0.92 improvement). This leads to @finding-big-scenarios:

#finding[Decomposition provides a good improvement on big scenarios that are solved far from optimality by the monolithic run.] <finding-big-scenarios>

A notable case is scenario S4, where the monolithic formulation failed to find any feasible solution within the allocated runtime budget, while decomposition successfully produced a solution with an objective value of $2.0"e"9$. Since the monolithic run provides neither a solution nor a bound, the quality of the decomposition solution cannot be directly assessed through gap comparison. However, two indicators suggest the solution is reasonably good: first, all subproblems were solved to optimality and second, the customer demand fulfillment rate reports 95%. These characteristics, combined with the observation that decomposition at least provides a usable solution where monolithic solving provides none, demonstrate a practical advantage of the decomposition approach for scenarios that exceed the monolithic solver's capabilities within given time constraints. This leads to @finding-mono-infeasible:

#finding[Decomposition can provide feasible solutions for scenarios where monolithic solving fails entirely within the given time budget.] <finding-mono-infeasible>

Contrary to @finding-big-scenarios, scenarios S9 and S10 are small scenarios that report notable improvements despite consisting of few variables and constraints. Both scenarios share the same master data, but the discrete planning horizon of S10 is four times larger than S9, resulting in more discrete variables and a harder problem. This explains why the improvement of S10 exceeds that of S9, showing that the benefit of decomposition can increase with scenario size when the underlying network structure remains the same. This strongly reinforces @finding-big-scenarios. The general reason for the improvement by decomposition on these two scenarios despite their small size becomes apparent when examining the virtual demand delivery results. Using S9 as a representative example for both scenarios, the virtual demand delivery rate across all decomposed runs reaches 98.5%, which explains why decomposition almost finds the optimal solution with a gap of only 0.07. Additionally, the subproblems show an evenly distributed problem severity, with problem sizes reported in @11KB_text_milp_subproblems.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: 6pt,
    align: (left, right, right, right),
    table.header(
      [*Subnetwork*], [*Variables*], [*Discrete Variables*], [*Constraints*],
    ),
    [bottom_up_0], [17962], [2876], [8262],
    [bottom_up_1], [13108], [1630], [6699],
    [bottom_up_2], [14821], [1872], [6232],
    [top_down_1], [18802], [1636], [6330],
    [top_down_2], [14306], [1156], [7488],
  ),
  caption: [Subproblem sizes for scenario S9],
) <11KB_text_milp_subproblems>

The high virtual demand delivery rate of 98.5% and the evenly distributed problem sizes across subnetworks may stem from the same root cause. The supply chain network shows a clear hierarchical organization that naturally aligns with the chosen decomposition into procurement, production and distribution stages. This manifests in the network topology through a uniform depth from procurement to customer and a clean separation of delivery decisions. Different possibilities exist to produce or transport a product, but those decisions remain within one subnetwork and both alternatives lead to the same link nodes, enabling all subnetworks to make optimal decisions with little optimality lost. When such a stage-aligned network is partitioned along its natural stage boundaries, the resulting subproblems inherit balanced complexity. The network topology visualization in @well-structured-sc illustrates this structure further, showing the clear separation between supply chain stages. Characteristics that would oppose this stage-aligned pattern include cycles, customer products at different depths of the graph, especially at production or procurement level, sibling nodes that are both production and customer nodes within the same subnetwork, varying numbers of production steps per product and operations spanning nodes at different stages of the supply chain.

#figure(
  image("../figures/well-structured-sc.png"),
  caption: [Network visualization showing regular structure and clear stage separation],
) <well-structured-sc>

This analysis about scenarios S9 and S10 is formulated as @finding-well-structured:

#finding[A "stage-aligned" supply chain leads to high virtual demand fulfillment rates, evenly distributed problem severity and therefore good decomposition results.] <finding-well-structured>


Scenario S6 reports no feasible decomposition solution, while the monolithic run converged to optimality. The decomposition aborted because the top-down production subnetwork found no solution within its allocated time limit of 12,500 seconds. Notably, the same subnetwork solved to optimality in only 109 seconds during the bottom-up phase. The only differences between the two formulations are the removal of virtual procurement variables and the injection of fixed supply quantities from the upstream subnetwork into the inventory balance constraints. To investigate this discrepancy, @tab:s6-model-comparison compares the model statistics of both formulations. Despite the top-down model having fewer variables and constraints, it fails to find any solution while the bottom-up run reaches optimality.

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: (left, right, right),
    table.header(
      [*Metric*], [*Bottom-up*], [*Top-down*],
    ),
    [Variables], [149,699], [119,859],
    [Discrete Variables], [7,048], [6,803],
    [Constraints], [74,699], [70,502],
    [Solve Time (s)], [109], [12,548],
    [Solution], [Optimal], [None],
  ),
  caption: [Model comparison of S6 production subnetwork (bottom-up vs. top-down)],
) <tab:s6-model-comparison>


This observation is highly unintuitive: the solve time is 115 times higher on essentially the same problem with slightly fewer variables, yet the solver found no solution. To understand this discrepancy, @tab:s6-solver-behavior compares the internal solver behavior between both runs.

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: (left, right, right),
    table.header(
      [*Metric*], [*Bottom-up*], [*Top-down*],
    ),
    [Root LP Time (s)], [1.44], [440.69],
    [Crossover Time (s)], [—], [271.24],
    [First B&B Node (s)], [43], [2,110],
    [Total B&B Nodes], [114,706], [15],
    [Final Result], [Near-optimal (0.01% gap)], [No solution],
  ),
  caption: [Solver behavior comparison for S6 production subnetwork],
) <tab:s6-solver-behavior>

The bottom-up run solves the root LP relaxation quickly and explores over 100,000 branch-and-bound nodes. In contrast, the top-down run spends significant time on the root LP relaxation alone, requiring an additional Crossover phase of 271 seconds. The first branch-and-bound node takes 50 times longer than in the bottom-up run and within the remaining time budget, the solver explores only 15 nodes without finding any integer-feasible solution.

Investigation of S8, the other scenario where decomposition failed, reveals the same pattern. The top-down subnetwork found no solution within 7,900 seconds, while the bottom-up run of the same subnetwork reached near-optimality within 3,200 seconds. This behavior generalizes across many scenarios. @tab:topdown-hardness shows that top-down subproblems consistently require more time and achieve worse gaps than their bottom-up counterparts.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: 6pt,
    align: (left, right, right, right),
    table.header(
      [*Metric*], [*S2*], [*S11*], [*S12*]
    ),
    [Bottom-up Time (s)], [1,900], [7,524], [9,000],
    [Top-down Time (s)], [9,100], [11,240], [9,000],
    [Bottom-up Gap], [0.00], [0.08], [0.00],
    [Top-down Gap], [0.00], [0.88], [0.08],
  ),
  caption: [Top-down vs. bottom-up performance across scenarios],
) <tab:topdown-hardness>


To identify the root cause of this performance difference, the LP relaxation of S8's top-down production subnetwork was analyzed in isolation. @tab:s8-lp-phases shows the progression through solver phases.

#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: 6pt,
    align: (center, left, right, left),
    table.header(
      [*\#*], [*Phase*], [*Time (s)*], [*Observation*],
    ),
    [1], [Barrier], [27], [Converged normally (64 iterations)],
    [2], [Crossover], [969], [Aborted due to numerical instability],
    [3], [Dual Simplex], [5,400], [Objective function value constant ($approx 1.59"e"12$), infeasibility oscillations ($10^7$–$10^(18)$), Markowitz Tolerance warnings],
    [—], [*Total*], [*6,400*], [Bottom-up LP Comparison: 7 seconds],
  ),
  caption: [LP relaxation solver phases for S8 top-down production subnetwork],
) <tab:s8-lp-phases>

The Barrier method converges quickly to an interior-point solution, but the subsequent Crossover phase, which converts this solution into a basic feasible solution, fails due to numerical instability. The solver then falls back to dual simplex, where it spends 5,400 seconds with effectively no progress on the objective function while infeasibility residuals oscillate across 11 orders of magnitude.

These observations are classical symptoms of problem degeneracy @wolsey2020 @bertsimas1997 @andersen1996:
- Rapid Barrier convergence to an interior-point solution
- Long Crossover phase turning the interior-point solution into a basic solution
- Infeasibility oscillations spanning $10^7$ to $10^(18)$
- Markowitz tolerance warnings @markowitz1957
- Minimal objective improvement during simplex iterations

None of these symptoms appeared in the bottom-up run. To verify the diagnosis of problem degeneracy, an additional experiment run of the LP relaxation of S8's top-down production subnetwork forced the solver to use dual simplex directly, bypassing Barrier and Crossover entirely. The LP then solved in 772 seconds, which is still elevated compared to the bottom-up run, because dual simplex is also affected by the underlying degeneracy, but faster than the run using Barrier and Crossover. This supports the diagnosis that the top-down transformation introduces or substantially increases degeneracy in the formulation. When the LP relaxation exhibits this degenerate behavior, the relaxations at branch-and-bound nodes are likely to exhibit it as well, thereby slowing down the entire solving process.

To summarize, the following finding is reported, with reasons identified and improvements discussed in @discussion:

#finding[Top-down subproblems exhibit severe degeneracy, causing them to require substantially more time than their bottom-up counterparts and becoming a runtime bottleneck that degrades overall decomposition performance.] <finding-topdown-bottleneck>

Following the general analysis and identification of the root cause for infeasible scenarios, the next step examines why scenarios, that did not show improvement, performed poorly. Scenarios that report a relative difference of $"Relative Diff." gt 0.00$ include S1, S2, S5 and S13.

A common pattern emerges across all scenarios that perform worse under decomposition: an uneven distribution of problem complexity across subnetworks, with the production subnetwork (subnetwork 1) consistently being the hardest. @tab:complexity-distribution shows the estimated complexity distribution across subnetworks. 
#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: 6pt,
    align: (left, right, right, right),
    table.header(
      [*Scenario*], [*Subnetwork 0 (%)*], [*Subnetwork 1 (%)*], [*Subnetwork 2 (%)*],
    ),
    [S1], [10], [80], [10],
    [S2], [0 (empty)], [90], [10],
    [S5], [10], [80], [10],
    [S13], [0 (empty)], [86], [14],
  ),
  caption: [Complexity distribution across subnetworks for scenarios with worse decomposition results],
) <tab:complexity-distribution> 

This observation directly relates to @finding-well-structured, but represents its inverse. While stage-aligned supply chains with balanced subproblem complexity lead to good decomposition results, supply chains with a dominant production stage lead to poor results. This characteristic peaks in so-called "production scenarios". Such scenarios include S13, where the Procurement stage is very small or non-existent because the scenario was modeled with infinite inputs for all productions. This modeling choice reflects situations where the company has virtually unlimited access to raw materials and primarily needs to determine production quantities. These scenarios can be identified by their low number of Supplier or Procurement nodes, as shown in @tab:scenarios where S13 reports only 6 Procurements. This uneven complexity arises not only from the sheer number of nodes in the production stage, but also from the concentration of discrete lot sizes in production operations. For instance, S5 contains approximately three times as many discrete production variables as discrete transport variables, because transportation decisions are often modeled as continuous while production lot-sizing decisions require discretization. When decomposition faces such an unbalanced problem structure with one dominant subproblem, the decomposition approach cannot leverage its advantage effectively.

#finding[Decomposition performs poorly when the production subnetwork dominates problem complexity due to a concentration of discrete decision variables.] <finding-production-dominance>

The most critical structural limitation of the approach becomes apparent when analyzing the specific results of scenarios where decomposition produced worse overall results than monolithic solving. This observation identifies the root cause of @finding-local-optimal, which showed that decomposition cannot find the global optimum even when all subproblems are solved to optimality. @tab:demand-fulfillment shows that decomposition performed worse because of lower customer demand fulfillment. 

#figure(
  table(
    columns: (auto, auto, auto, auto),
    inset: 6pt,
    align: (left, right, right, right),
    table.header(
      [*Scenario*], [*Customer Demand Mono. (%)*], [*Customer Demand Decomp. (%)*], [*Virtual Demand Fulfillment (%)*],
    ),
    [S1], [88], [87], [90],
    [S2], [92], [91], [95],
    [S5], [39], [37], [52],
    [S13], [96], [82], [84],
  ),
  caption: [Demand fulfillment rates for scenarios with worse decomposition results],
) <tab:demand-fulfillment>


Examining customer demands that were fulfilled in the monolithic run but not during decomposition reveals a consistent pattern. These demands trace back to unfulfilled virtual demands due to suboptimal request placement. Either the bottom-up phase requested material in periods where upstream capacity was already exhausted while earlier periods still had availability, or requests were routed through link nodes whose upstream paths faced bottlenecks while alternative link nodes could have delivered.

This represents a fundamental structural limitation of the two-phase decomposition. The bottom-up phase commits to specific inter-stage flows without knowledge of whether those flows can actually be fulfilled by upstream stages and the optimal procurement paths may require requesting from additional link nodes. Since the single up-and-down pass cannot revisit these decisions after the correction phase fails to deliver, material that could have been procured through alternative routes remains unutilized. This behavior is most pronounced in scenarios that provide multiple paths from different procurements or productions to the same output customer product, meaning the decision of which path to choose must be made in the lowest subnetwork without access to information about capacity limitations in higher subnetworks. Since resource capacity limits represent the most frequent capacity limitations and therefore the most frequent reason for unfulfilled virtual demands, this behavior intensifies when single resources are shared across many operations, resulting in a high number of resource consumers per single resource. Scenario S5 exemplifies this pattern with only 175 production resources but 106,394 production resource consumers.



The following finding is reported, with two possible improvements proposed in @potential-improvements:

#finding[Decomposition can yield worse solutions than monolithic solving, especially on scenarios with shared resources or multiple production or transport alternatives.] <finding-structural-limitation>