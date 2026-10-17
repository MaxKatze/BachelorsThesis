
= Future Work <potential-improvements>

This chapter discusses potential directions for future research building on the presented decomposition framework. The following section outlines improvements to address identified limitations and extensions that could broaden the applicability of the approach.

#heading(level: 2, outlined: false)[Improvement of Information Asymmetry] <improvement-of-assymmetry>


Two possible improvements to the design could mitigate the information asymmetry limitation identified in @finding-local-optimal and @finding-structural-limitation.

#heading(level: 3, outlined: false)[Resource Capacity Aggregation]

This approach propagates approximate resource capacity information from upstream subnetworks down to the link nodes before the bottom-up run. For each combination of resource $r$ and link node $l$, the approach computes a coefficient $c_(r,l,T)$ representing the maximum amount of resource $r$ consumed per unit of link node product delivered up to period $T$. These coefficients then form aggregated constraints on the link nodes that approximate the upstream resource limitations. For each period $T$, the constraint would ensure that the cumulative resource consumption implied by the virtual demand requests does not exceed the cumulative resource capacity up to period $T$:

$ sum_(t=0)^T "Capa"_r(t) >= sum_(t=0)^T sum_(l in L_r) c_(r,l)(t) dot "VP"_(l)(t) $

where $L_r$ denotes all link nodes that have resource $r$ in their upstream subnetwork and $"VP"_(l)(t)$ is the virtual demand quantity requested at link node $l$ in period $t$. By incorporating these aggregated resource constraints into the bottom-up formulation, the subnetwork gains visibility into upstream capacity limitations before committing to specific virtual demand quantities, potentially increasing the virtual demand fulfillment rate.

#heading(level: 3, outlined: false)[Iterative Extension]

Iterative refinement can further improve decomposition solutions by progressively shrinking the problem and re-solving. After the first bottom-up and top-down pass, much of the network is already planned, parts of the supply chain are committed and usually only few customer demands are unfulfilled. The key insight is that the settled portions of the supply network can be removed from the problem entirely, leaving a much smaller network to re-solve.
Two categories of elements are removed after each iteration:
1. Fulfilled customer demands: When a customer demand is completely satisfied, its entire upstream supply path can be removed, provided those operations do not serve other unfulfilled demands. These decisions are final and need no further optimization.
2. Capacity-limited paths: When a virtual demand is only partially fulfilled, the procurement path hit a capacity constraint. The segments upstream and downstream of this bottleneck, up to the next branching point, can be removed, since they cannot fulfill additional demands, or they would have already. 
The quantities produced along the segments are fixed and subtracted from resource or storage capacities.
The result is a substantially reduced problem. Re-solving this smaller network allows the decomposition to explore alternative procurement routes that were bypassed in the first pass. Since the fixed quantities represent feasible partial solutions, feasibility is preserved when combining iterations. This process can be repeated until virtual demand fulfillment reaches 100% or no further improvement occurs.
Because the first pass already satisfies most demands, subsequent iterations operate on progressively smaller problems and should solve quickly.

#heading(level: 2, outlined: false)[Improvement of Top-Down Problem Degeneracy] <improvement-degeneracy>

Possible improvements could mitigate the degeneracy of the top-down problems identified in @finding-topdown-bottleneck.

Using Dual Simplex for the root relaxation and for the relaxations on branch-and-bound nodes could improve performance by avoiding the expensive Crossover phase. 

A massive speedup of top-down runs could be achieved by using Dual Simplex with a warm start from the bottom-up solution. For portions of the problem where virtual demands were satisfiable, the top-down solution will closely match the already known bottom-up result. The top-down run then only needs to resolve the portions where virtual demands could not be fulfilled, because there, the bottom-up solution is infeasible.

An alternative application of the decomposition approach emerges from the finding that decomposition can find good solutions faster than monolithic solving, but fails to converge to optimality. Rather than using decomposition as a standalone solving strategy, it could serve as a rapid heuristic to generate high-quality starting solutions for subsequent optimization. The decomposed solution could provide a warm start for monolithic solving or serve as an initial incumbent for other metaheuristic approaches @wolsey2020. This hybrid strategy would combine the speed advantage of decomposition with the optimality guarantees of monolithic methods.


#heading(level: 2, outlined: false)[Improvement of Inter-Subnetwork Constraint Handling]

Two possible alternative approaches could improve the simple resource inter-subnetwork constraint handling presented in @inter-subnet-constraint-handling.

#heading(level: 3, outlined: false)[First-Come, First-Served]

The @FCFS strategy allocates resource capacity dynamically based on actual usage during the top-down phase. In the bottom-up phase, all subnetworks receive access to the full original capacity. In the top-down phase, the first subnetwork retains its bottom-up solution unchanged, effectively using full capacity, and its actual consumption is recorded. Each subsequent subnetwork then receives only the remaining capacity:

$ "RC"_r^((i))(t) = "RC"_r(t) - sum_(j "solved before" i) sum_(o in O_j) "RR"_(o,r) dot "VO"_o^((j))(t) $

This approach aligns capacity allocation with material flow direction. However, upstream subnetworks may consume all available capacity, leaving downstream subnetworks with insufficient capacity to fulfill demands.

#heading(level: 3, outlined: false)[Preallocation]

The Preallocation strategy provides an informed capacity allocation by first solving the LP relaxation of the entire monolithic problem. The resulting fractional solution provides guidance on how capacity would be utilized under optimal continuous conditions and how it should be distributed for the @MILP.
After solving the LP-relaxation, the capacity is distributed across subnetworks proportionally based on the LP-derived usage. For a shared resource $r$ with capacity $"RC"_r(t)$, let $N_r$ be the set of subnetwork indices containing operations that consume $r$. The total LP usage by operations in subnetwork $i$ is $U_i^"LP"(t) = sum_(o in O_i) "RR"_(o,r) dot "VO"_o^"LP"(t)$. The capacity allocated to each subnetwork $i in N_r$ is:

$ "RC"_r^((i))(t) = "RC"_r(t) dot frac(U_i^"LP"(t), sum_(j in N_r) U_j^"LP"(t)) $ <eq:lp-split>

@eq:lp-split distributes the entire original capacity $"RC"_r (t)$ across all subnetworks that have operations consuming the resource, using the LP solution only to determine the allocation ratios. That means that even if the LP solution does not use the whole available capacity, each subnetwork receives its proportional share of the full capacity. Since all proportional shares sum to $1$, this ensures that unused capacity in the LP solution remains available for the integer subproblems, even if it was not used in the LP solution.

This approach offers several advantages over the alternatives. Unlike equal split, the allocation reflects actual optimization priorities rather than treating all subnetworks uniformly. Unlike @FCFS, all subnetworks receive their allocation simultaneously based on global information, avoiding the sequential bias where solve order determines capacity access. The primary limitation is that the LP relaxation might not be trivial to solve for large scenarios and it takes up additional runtime before the actual solving can begin.

#heading(level: 2, outlined: false)[Improvement of Runtime Allocation]

The current runtime allocation mechanism uses a complexity score based on variable counts to distribute the total time budget across subnetworks. However, this heuristic may not accurately predict actual solver runtime, which depends on many factors beyond variable counts alone. When the complexity estimate underallocates time to a critical subproblem, that subproblem may terminate prematurely without finding a solution, making the entire decomposition infeasible. This approach could be improved in a number of ways.

Instead of estimating complexity before model construction, the allocation could be performed by first building all subnetwork models in the beginning. The virtual demand variables cannot be included in this initial assessment since they are only known after the bottom-up solve, but they are easier to estimate compared to the base model size. The base models could be kept in memory and the virtual demands and supplies added just before each subnetwork is solved. This would enable more accurate complexity assessment based on the actual model structure rather than heuristic estimates.

The current approach terminates subproblems when their allocated time budget expires, even if no solution has been found. A more robust strategy would be to continue solving a subproblem beyond its allocated budget if it has not yet found a feasible solution, potentially reallocating the entire remaining global budget to that critical subproblem. This is justified because when any subproblem fails to find a solution, the entire decomposition run cannot produce a valid solution due to the dependencies between subnetworks. Therefore, investing all available time to obtain at least one feasible solution for the blocking subproblem increases the chance of obtaining any solution at all, rather than strictly adhering to budget allocations and guaranteeing failure.