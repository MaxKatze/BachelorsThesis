= Methodology <methodology>

This chapter describes the research methodology employed in this thesis and the evaluation design used to assess the proposed decomposition approach. The methodology follows the @DSR paradigm, which is well-suited for developing and evaluating artifacts that address practical problems in information systems.

== Research Approach <research-approach>

This thesis follows the @DSR methodology, a research paradigm focused on creating and evaluating artifacts to solve identified organizational problems @hevner2004. DSR is particularly appropriate for this work because the primary goal is to develop a practical solution that addresses the computational challenges of large-scale supply chain optimization.

The artifact developed in this thesis is a decomposition framework for supply chain networks modeled as @MILP problems. This framework partitions complex supply networks into smaller subnetworks that can be solved independently, with the goal of reducing computational complexity while maintaining solution feasibility.

The DSR process in this thesis follows four main phases:

+ *Problem Identification and Motivation:* The limitations of monolithic @MILP solving for enterprise-scale supply chains are identified and analyzed. This reasoning shows the practical relevance and necessity of a decomposition approach.

+ *Objectives Definition:* Clear objectives are defined based on the research questions: preserving solution feasibility (RQ1), comparing solution quality and computational performance against monolithic solving (RQ2) and enabling previously unsolvable problems to be solved (RQ3).

+ *Design and Development:* The decomposition framework is designed and implemented, including graph-based modeling, the decomposition strategy and the two-phase solving approach.

+ *Evaluation:* The artifact is evaluated against defined metrics using real-world benchmark scenarios, comparing performance against a monolithic baseline.

== Evaluation Design <evaluation-design>

The evaluation compares the proposed decomposition approach against the monolithic baseline used in SAP @IBP. In the baseline, the entire supply network is formulated and solved as a single @MILP. For each scenario, both approaches solve the same optimization problem under identical conditions, with the same time limit, the same solver and the same parameter settings. This controlled setup isolates the effect of decomposition, allowing direct attribution of performance differences to the approach itself.

#heading(outlined: false, level: 3)[Metrics]<metrics>

The evaluation uses two primary metrics that represent the fundamental trade-off in optimization @wolsey2020.

*Runtime* measures the solver time required to solve the optimization problem, excluding preprocessing and decomposition overhead. This focus on pure solver time is deliberate, since the primary research interest lies in understanding how decomposition affects the complexity of the underlying optimization problems themselves. By measuring only the time spent in the @MILP solver, the evaluation captures the impact of partitioning large problems into smaller subproblems. Additionally, the current implementation introduces overhead due to architectural design decisions that would not be present in a production integration within SAP @IBP (see @implementation), where decomposition logic could be tightly integrated with the existing optimization pipeline. Comparing total runtimes would confuse this implementation-specific overhead with the actual optimization benefits, obscuring the true potential of the decomposition approach. Moreover, the decomposition overhead is expected to be negligible for real customer scenarios with substantial solve times, since all employed algorithms are graph algorithms that scale as $O(V + E)$ and can be implemented very efficiently.

*Solution Quality* is measured by the objective function value of the resulting solution. In supply chain optimization, the objective function minimizes the total costs. Lower objective values indicate better solutions.

To ensure fair comparison between the decomposition approach and the monolithic baseline, both runs receive the same runtime budget, which corresponds to the operational time limit configured by the customer company for that scenario. The evaluation then compares the solution quality achieved within this budget. If one approach solves the problem to proven optimality before the time limit, the runtime budget for the other approach is reduced to match this shorter time, ensuring a fair comparison at the point of optimality. If a run fails to find any feasible solution within the given time, its solution quality is reported as infeasible. In such cases, any feasible solution found by the other approach represents a clear improvement, regardless of its objective value.

#heading(outlined: false, level: 3)[Benchmark Scenarios]<benchmark-scenarios>

The evaluation uses 13 real customer scenarios from SAP @IBP, deliberately selected to represent diverse network structures and complexity characteristics. These scenarios are anonymized production data that show the variety of supply chain configurations in practice. The selection aims to identify which network characteristics make decomposition beneficial and which scenarios may not benefit from the approach. The scenario statistics are shown in @tab:scenarios. @tab:scenario-characteristics assigns each scenario a characteristic label describing its primary structural feature. While not comprehensive, these labels highlight distinguishing properties that allow pattern recognition and enable systematic analysis of which network characteristics benefit from decomposition.

#figure(
  text(size: 13pt)[#grid(
    columns: 1,
    row-gutter: 1em,
    // First half of scenarios
    table(
      columns: (auto, auto, auto, auto, auto, auto, auto),
      inset: 4pt,
      align: (left, right, right, right, right, right, right),
      table.header(
        [*Attribute*], [*S1*], [*S2*], [*S3*], [*S4*], [*S5*], [*S6*],
      ),
      table.cell(colspan: 7, fill: luma(230), [*Graph Attributes:*]),
      [Total nodes], [38,536], [976], [21,097], [1,047,357], [1,042,863], [234,061],
      [Loc-Prods], [18,145], [203], [7,609], [185,608], [275,932], [26,862],
      [Productions], [10,088], [119], [1,433], [55,004], [21,472], [1,666],
      [Transports], [6,701], [262], [7,879], [796,557], [525,009], [132,360],
      [Customer-Prods], [2,717], [149], [4,112], [9,621], [219,890], [72,656],
      [Procurements], [402], [236], [4], [567], [165], [474],
      [Resources], [483], [7], [60], [0], [395], [43],
      table.cell(colspan: 7, fill: luma(230), [*Monolithic Model:*]),
      [Variables], [5,276,857], [66,361], [146,810], [212,315,069], [9,580,634], [2,046,469],
      [Discrete Vars], [102,480], [6,644], [43,349], [4,299,160], [1,058,220], [13,027],
      [Constraints], [2,694,876], [33,117], [60,429], [54,179,932], [3,299,673], [654,314],
    ),
    // Second half of scenarios
    table(
      columns: (auto, auto, auto, auto, auto, auto, auto, auto),
      inset: 4pt,
      align: (left, right, right, right, right, right, right, right),
      table.header(
        [*Attribute*], [*S7*], [*S8*], [*S9*], [*S10*], [*S11*], [*S12*], [*S13*]
      ),
      table.cell(colspan: 8, fill: luma(230), [*Graph Attributes:*]),
      [Total nodes], [481,061], [234,039], [365], [365], [116,432], [233,169], [2,215],
      [Loc-Prods], [70,212], [26,862], [140], [140], [54,981], [26,861], [245],
      [Productions], [40,667], [1,666], [39], [39], [13,868], [1,666], [89],
      [Transports], [199,813], [132,357], [121], [121], [36,606], [131,489], [237],
      [Customer-Prods], [166,006], [72,656], [28], [28], [5,797], [72,656], [1,626],
      [Procurements], [2,327], [455], [20], [20], [5,051], [454], [6],
      [Resources], [2,036], [43], [17], [17], [129], [43], [12],
      table.cell(colspan: 8, fill: luma(230), [*Monolithic Model:*]),
      [Variables], [6,109,827], [6,597,019], [38,396], [47,859], [1,276,677], [7,016,374], [100,972],
      [Discrete Vars], [181,711], [59,224], [6,372], [25,268], [578,864], [142,924], [5,297],
      [Constraints], [3,057,346], [2,107,145], [17,450], [17,450], [438,907], [2,476,997], [36,492],
    ),
  )],
  caption: [Benchmark scenario characteristics],
) <tab:scenarios>

#figure(
  table(
    columns: (auto, 1fr),
    inset: 6pt,
    align: (center, left),
    table.header(
      [*Scenario*], [*Characteristic*],
    ),
    [S1], [Medium-sized, Production-dominated],
    [S2], [Medium-sized, balanced structure, few resources],
    [S3], [Few procurements, production scenario],
    [S4], [No resources, very large],
    [S5], [High resource sharing, low procurement to consumer ratio],
    [S6], [Large production compared to procurement and distribution],
    [S7], [Large-scale, high resource count],
    [S8], [Few productions compared to transports],
    [S9], [Small, stage-aligned, balanced complexity],
    [S10], [Small, stage-aligned, same as S9 with extended horizon],
    [S11], [Very large, procurement to consumer ratio of 1],
    [S12], [Very large],
    [S13], [Production scenario, minimal procurement],
  ),
  caption: [Scenario structural characteristics],
) <tab:scenario-characteristics>
