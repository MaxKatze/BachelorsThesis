= Theoretical Foundations <theoretical-foundations>

This chapter establishes the theoretical foundations underlying the decomposition approach developed in this thesis. Beginning with @MILP, this chapter introduces its formal definition, discusses computational complexity, and motivates the need for decomposition approaches. The chapter then examines how SAP @IBP Supply Planning models supply chains as directed graphs and transforms them into mathematical optimization problems.

== Mixed-Integer Programming

@MILP is a fundamental optimization paradigm that extends @LP by requiring some variables to take integer values.
A Mixed-Integer Program is an optimization problem of the following form @wolsey2020:

$ min quad & c^T x \
  "subject to" quad & A x <= b \
  & x_i in ZZ quad forall i in I \
  & x_i in RR quad forall i in.not I \
  & x >= 0 $<eq:MILP-standard>

where $c in RR^n$ is the objective coefficient vector, $A in RR^(m times n)$ is the constraint matrix, $b in RR^m$ is the right-hand side vector and $I subset.eq {1, ..., n}$ is the index set of variables constrained to integer values.

Several important special cases arise from this general formulation:

- *Pure Integer Program*: When $I = {1, ..., n}$, all variables must be integer-valued.
- *Binary Program*: When $x_i in {0, 1}$ for all $i in I$, variables are restricted to binary values.
- *Linear Program*: When $I = emptyset$, no integrality constraints exist, yielding a standard LP.

The computational complexity of solving a @MILP places it in the class of NP-hard problems @garey1979. The fundamental difficulty arises from the integrality constraints. While the feasible region of a linear program is a convex polyhedron @schrijver1998, requiring even one variable to take integer values transforms the feasible region into a discrete, non-convex set, making the optimization problem NP-hard in general @garey1979.

The source of this hardness lies in the combinatorial explosion of possible integer assignments. If each integer variable is restricted to a finite domain $D_i$, the search space contains $product_i |D_i|$ possible assignments before accounting for the linear constraints.

This exponential complexity has direct implications for solution algorithms. Unlike @LP, where the interior point method finds optimal solutions in polynomial time, no known algorithm solves general @MILP:pl in polynomial time @schrijver1998.

Every @MILP has an associated LP relaxation. The LP relaxation is obtained by replacing the variables with integer domains with continuous domains, allowing all integer-constrained variables to take fractional values @wolsey2020:

$ z_"LP" = min{c^T x : A x <= b, x in RR^n, x >= 0} $<eq:lp-relaxation>

This relaxation possesses several important properties. For minimization problems, the LP relaxation provides a lower bound on the optimal @MILP objective value: $z_"LP" <= z_"MILP"$. This relationship holds because the feasible region of the LP relaxation contains all integer-feasible solutions @wolsey2020. The quality of the relaxation is measured by the integrality gap:

$ "gap" = (z_"MILP" - z_"LP") / (|z_"MILP"|) $<eq:integrality-gap>

A small integrality gap indicates that the LP relaxation closely approximates the @MILP, making it a "tight" relaxation. While solving general @MILP:pl is NP-hard, linear programs can be solved in polynomial time @schrijver1998, making LP relaxation relevant for bounding and approximation purposes.

The exponential worst-case complexity motivates the use of decomposition approaches. The general idea is to exploit the structure of a large optimization problem by dividing it into smaller subproblems, thereby reducing the complexity of the search space. Consider a @MILP with $n$ binary variables, the number of possible assignments can grow exponentially as $2^n$. If the problem can be decomposed into $k$ smaller subproblems of size $n/k$, the corresponding search space is reduced to approximately $k dot 2^(n/k)$, illustrating the potential computational benefits of decomposition.

This scaling behavior makes decomposition particularly attractive for large-scale optimization. However, decomposition approaches introduce additional challenges. When subproblems are coupled through shared variables or constraints, solving them independently may no longer preserve global optimality. While exact decomposition methods can maintain optimality guarantees, they often require additional coordination and iterative procedures @barbarosoglu1999 @lidestam2011. In practice, large-scale @MILP:pl are frequently not solved to proven optimality due to computational limits, but rather until a satisfactory solution is obtained within a given time budget. Therefore, approximate decomposition approaches may trade optimality guarantees for computational efficiency, aiming to obtain high-quality solutions within reasonable time limits @bixby2012.

Modern @MILP solvers use branch-and-bound algorithms to systematically explore the solution space @wolsey2020. The algorithm works by recursively partitioning the problem. At each node in the search tree, the LP relaxation is solved to obtain a lower bound. If the relaxation's solution satisfies all integrality constraints, an integer-feasible solution has been found. Otherwise, the algorithm selects a fractional variable and creates two child nodes by adding constraints that fix the variable to either its floor or ceiling value. Branches can be pruned when their LP relaxation bound exceeds the best known integer solution, eliminating large portions of the search space without explicit enumeration. The efficiency of branch-and-bound thus depends heavily on how quickly each LP relaxation can be solved, as thousands or millions of LP solves may be required during a single @MILP optimization.

Modern LP solvers employ two main algorithmic approaches: simplex methods and interior-point (Barrier) methods @bertsimas1997. The feasible region of an LP forms a convex polyhedron and the optimal solution always lies at a vertex of this polyhedron. Simplex methods traverse the vertices of the feasible polyhedron along its edges, maintaining a basic feasible solution at each step and converging directly to an optimal vertex. The Barrier method instead traverses the interior of the feasible region, converging to a point near the optimal vertex but not exactly at it. Since branch-and-bound requires a vertex solution as a starting point for subsequent child nodes, Barrier solutions must be converted through a Crossover phase that moves the interior-point solution to the nearby optimal vertex @andersen1996. Modern solvers like Gurobi often run simplex and Barrier concurrently, using whichever finishes first. However, if the LP formulation exhibits numerical difficulties such as degeneracy, the Crossover phase can become extremely slow or fail entirely, causing severe performance degradation in the overall @MILP solve.

== SAP Supply Chain Planning <sap-supply-chain-planning>

SAP @IBP Supply Planning provides an enterprise platform for supply chain optimization that transforms real-world supply networks into mathematical models @sap_ibp2024. This section introduces the conceptual foundations of how SAP Supply Planning represents supply chains and formulates optimization problems, establishing the context for the decomposition approaches developed in this thesis.

#heading(depth: 3, outlined: false, "Supply Chains as Graphs") <supply-chains-as-graphs>

Modern supply chains consist of connected products, operations and customers that can be naturally represented as directed graphs @chopra2021. SAP @IBP Supply Planning leverages this graph-theoretic perspective to model supply networks, where vertices represent operational entities and edges capture material flows and dependencies.

The foundation of Supply Planning is a relational data model organized into several categories of input tables @sap_ibp2024. Example categories are given by:#footnote[The tables vary based on interface, version and release, but can generally be categorized by those examples.]

- *Location-Product Tables* define which products exist at which locations in the supply network, establishing the basic inventory points.

- *Customer-Product Tables* represent a product at a customer, modeling possible demand points where customer orders may occur.

- *Production Tables* define manufacturing operations through production rules that encode @BOM relationships, specifying which input materials and in what quantities are required to produce each output product.

- *Transport Tables* describe logistics lanes between locations, capturing lead times, capacities and transportation costs for moving materials through the network.

- *Customer-Transport Tables* define delivery lanes from locations to customers, specifying how finished products reach demand points.

- *Procurement Tables* model external supply sources, defining available quantities, costs and constraints for purchasing materials from suppliers.

- *Resource Tables* capture capacity constraints for production equipment, storage facilities and transportation vehicles that limit operational throughput.

Each table contains time-indexed key figures that specify period-by-period values for quantities, costs and capacity limits across the planning horizon.

From these relational tables, a directed graph $G = (V, E)$ can be constructed to capture the supply chain topology. This graph abstraction makes explicit the relationships between entities that are implicit in the relational tables, enabling structured partitioning for decomposition approaches. By dividing the graph into subgraphs, it can be directly determined which portions of the input data belong to each subproblem. The vertex set $V$ comprises the node types that represent the distinct operational entities defined by the tables above.

The edge set $E$ captures the material flow and dependencies of resources on operations. @fig:supply-chain-graph illustrates an example of such a supply chain graph with material flow from top to bottom.

#pagebreak()
#page(flipped: true)[
  #figure(
    image("../figures/supply_chain_graph.png", width: 100%),
    caption: [Example of a supply chain graph with different node types. Source: Internal SupplyChainViewer.]
  ) <fig:supply-chain-graph>
]

For the purposes of this thesis, the standard optimization pipeline in SAP @IBP is modeled as:

$ "Input Tables" arrow.r "Object-oriented Model" arrow.r "MILP Model" arrow.r "Solver" arrow.r "Solution" $

The relational input tables are used to build the object-oriented model which is then transformed into a @MILP formulation. The @MILP is then submitted to an external solver such as Gurobi or SCIP/SoPlex @gurobi2024 @scip2024. Finally, the solver's solution is interpreted back into operational decisions, such as how much to produce, what to transport, and when to procure materials.

Separately, the supply chain graph $G = (V, E)$ serves as an auxiliary abstraction built from the same input tables. This graph representation provides structural insight useful for analysis and, as explored in this thesis, for decomposition strategies. When any form of structural decomposition in this thesis is applied, the graph is constructed from the input tables, partitioned into subgraphs and these subgraphs guide how to filter or modify the original input data to create subproblems (see @data-handling). Each subproblem's modified input data is then transformed into a @MILP and solved.

This pipeline architecture enables SAP @IBP to leverage external @MILP solvers while maintaining a domain-specific interface for supply chain planners @sap_ibp2024.



#heading(depth: 3, outlined: false, "Mathematical Model Formulation") <mathematical-model-formulation>

SAP @IBP formulates the supply chain planning problem as a @MILP containing variables, constraints and costs @sandner1998 @shapiro2006.

The @MILP formulation introduces decision variables that correspond to operational quantities across all time periods in the planning horizon @sandner1998. Let $T = {1, 2, ..., n}$ be the discrete time periods over which decisions are made, called planning periods. Examples of the primary decision variables are:

- $"VO"_(o,s) (t)$ -- the number of production lots of model $o$ started at location $s$ in period $t$
- $"VT"_(e,p) (t)$ -- the quantity of material $p$ transported on edge $e$ in period $t$
- $"VS"_(s,p) (t)$ -- the inventory level of material $p$ at location $s$ at the end of period $t$
- $"VL"_(d) (t)$ -- the quantity delivered for demand $d$ in period $t$

Various business requirements can introduce integer or binary variables into the formulation. For example, when lot sizes are active, production can only occur in discrete multiples of the lot size $L_o$, requiring $"VO"_(o,s) (t) in ZZ$. The output of the operation is then given by $L_o dot "VO"_(o,s) (t)$. Such integrality requirements make the problem a @MILP rather than a pure @LP.

The objective function minimizes total supply chain costs, balancing operational costs against delivery penalties @wolsey2020:

$ min sum_(t in T) [ &sum_(s in S) sum_(o in O_s) "CO"_(o,s) dot L_o dot "VO"_(o,s)(t) + sum_(s in S) sum_(p in "PS"_s) "CS"_(s,p) dot "VS"_(s,p)(t) \
+ &sum_(e in E) sum_(p in "PE"_e) "CT"_(e,p) dot "VT"_(e,p)(t) \
+ &sum_(d in D) "CD"_d dot ("DQ"_(d)(t) - "VL"_(d)(t)) ] $ <eq:objective>

where $"CO"_(o,s)$ denotes production costs per unit of production model $o$ at location $s$; $"CS"_(s,p)$ represents inventory holding costs; $"CT"_(e,p)$ captures transportation costs per unit on edge $e$ and $"CD"_d$ is the penalty for each unit of unfulfilled demand $d$.

The non-delivery penalty term ensures that the model prefers fulfilling demand when feasible, with the penalty magnitude reflecting the business cost of missed deliveries.

The @MILP formulation enforces physical and operational constraints that link the decision variables. The following presents the constraints most relevant for understanding the decomposition approach developed in this thesis:

*Location-Product Constraints.* For each location-product node, the inventory balance ensures that stock changes reflect all inflows and outflows:

$ "VS"_(s,p) (t) = "VS"_(s,p) (t-1) + sum_(o in O_s) "PR"_(o,s,p) dot "VO"_(o,s) (t) \
+ sum_(e in E_s) "VT"_(e,p) (t) - sum_(e in E^s) "VT"_(e,p) (t) - "VL"_(d) (t) $ <eq:inventory-balance>

where $"PR"_(o,s,p)$ is the @BOM coefficient representing the quantity of material $p$ produced (positive) or consumed (negative) by production model $o$ at location $s$. Location-product nodes contribute inventory holding costs $"CS"_(s,p) dot "VS"_(s,p) (t)$ to the objective.

*Resource Constraints.* Resource nodes impose shared capacity limits across multiple operations. Three types of resources exist: production resources constrain production operations, transport resources constrain transport operations and storage resources constrain inventory levels at locations. All three follow the same constraint structure. The resource consumption is computed directly in the capacity constraint by summing used quantities multiplied by resource requirement coefficients. For production resources:

$ sum_(o in O_(s_r)) "RR"_(o,r) dot "VO"_(o,s) (t) <= "RC"_r (t) $ <eq:resource-capacity>

where $"RR"_(o,r)$ is the resource requirement for production model $o$ on resource $r$ and $"RC"_r (t)$ is the capacity of resource $r$. Transport and storage resources follow analogously, with their respective variables $"VT"$ and $"VS"$ replacing $"VO"$. This constraint couples multiple operational decisions through shared capacity. Resource nodes do not directly contribute to the objective but constrain feasible solutions.

*Non-Negativity.* All quantity variables must be non-negative:

$ "VO"_(o,s) (t), "VT"_(e,p) (t), "VS"_(s,p) (t), "VL"_(d) (t) >= 0 $

The complete mathematical formulation is not presented here, as it is beyond the scope of this thesis and would not contribute to the discussion of the proposed decomposition approach anyway.
