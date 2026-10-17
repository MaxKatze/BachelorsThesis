= Conclusion <conclusion>

This thesis developed and evaluated a stage-based decomposition approach for supply chain network optimization. The approach partitions large @MILP problems along supply chain stages procurement, production and distribution and solves them through a two-phase bottom-up/top-down procedure that coordinates subproblem solutions via virtual demands at stage boundaries.


*RQ1: How can supply chain networks be decomposed into subnetworks while preserving solution feasibility?*

An approach was proposed that decomposes supply chain networks by partitioning nodes according to their stage classification within the supply chain hierarchy. Link nodes at stage boundaries serve as coordination points where virtual demand variables enable information exchange between subnetworks. The bottom-up phase determines material requirements propagating upstream, while the top-down phase commits to actual deliveries based on upstream capacity. The correction mechanism ensures that, when all required subproblems are solved successfully, the final combined solution satisfies the original constraints. The handling for inter-subnetwork constraints supports constraints spanning multiple subnetworks. Several heuristics for information aggregation improve the solution quality. However, the evaluation revealed that this two-phase coordination could lead to suboptimal inter-stage flow commitments when bottom-up decisions are made without complete visibility into upstream capacity constraints.

*RQ2: How does decomposition affect solution quality and computational performance compared to monolithic solving?*

The evaluation demonstrates that decomposition provides substantial improvements for large scenarios where monolithic solving struggles to find good solutions within reasonable time budgets. On scenarios with monolithic optimality gaps exceeding 0.90, decomposition achieved improvements of up to 92%. Conversely, for scenarios that can be solved optimally by monolithic approaches, decomposition may produce worse results due to the inherent information asymmetry at stage boundaries. Stage-aligned supply chains with balanced complexity across stages benefit most from decomposition, while production-dominated scenarios where discrete variables concentrate in one stage show diminished benefits.

*RQ3: Can decomposition enable solving previously intractable problems?*

Yes. The evaluation identified scenarios where monolithic solving failed to find any feasible solution within the allocated time budget, while decomposition successfully produced usable results. Decomposition decouples constraints that prevent the monolithic solver from making progress, offering a practical fallback strategy when increasing the runtime budget is impractical.


This work contributes a practical decomposition approach tailored to the hierarchical structure of supply chain networks. Unlike classical methods such as Dantzig-Wolfe or Benders decomposition that require iterative coordination between master and subproblems, stage decomposition trades this iterative exchange for computational simplicity and speed. The approach aligns with the broader research direction of exploiting problem structure for scalable optimization @wolsey2020, while addressing the specific characteristics of multi-echelon supply chain planning. The evaluation on real-world customer scenarios from SAP @IBP demonstrated that the approach provides practical value for enterprise-scale supply chain optimization.


Several limitations constrain the generalizability of the findings. The evaluation covered a limited set of benchmark scenarios and certain constraint types could not be decomposed. Future work could address the information asymmetry at stage boundaries and the observed degeneracy in top-down subproblems through the discussed approaches.

The central finding of this thesis is that stage decomposition can be beneficial, but performs best under specific structural conditions. The evaluation shows that decomposition improves results more often than it degrades them, yet when supply chain complexity is unbalanced or the network structure misaligns with decomposition boundaries, the approach can perform worse than the monolithic baseline it aims to replace. Further improvements are needed and practitioners should view the decomposition approach not as a universal solution, but as a tool whose applicability depends on the structural characteristics of their specific supply chain. The evaluation provides concrete criteria for this assessment, allowing an informed decision on whether decomposition will likely be beneficial.
