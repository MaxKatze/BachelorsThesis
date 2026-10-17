= Decomposition Framework Design <design>

This chapter presents the design of a decomposition framework that partitions supply chain networks into smaller subnetworks, solves them sequentially with coordinated information exchange and combines their solutions into a feasible global solution. To achieve the approach of partitioning and solving subnetworks, the framework consists of several key components:

- A *graph-based representation* of supply chain networks that captures material flow and enables structural analysis
- A *decomposition strategy* for partitioning the network along the natural supply chain stages
- *Link nodes and virtual constraints* for connecting subnetworks at their boundaries
- *Constraint handling mechanisms* for shared resources that span multiple subnetworks
- A *two-phase solving approach* consisting of a bottom-up demand propagation phase and a top-down supply allocation phase
- *Aggregation heuristics* for propagating costs, lead time and capacity information across subnetwork boundaries
- A *solution combination process* that merges partial solutions into a feasible global solution
== Graph-based Problem Modeling <graph-modelling>

The starting point of the framework is a supply chain defined by master data tables, which can be directly transformed into a @MILP formulation and solved monolithically, i.e., as a single unified problem, using the standard optimization service. To enable decomposition, a directed graph $G = (V, E)$ is constructed as a structural abstraction from these tables, as described in @supply-chains-as-graphs. This graph-based representation captures the flow of materials through the network, defined by the master data tables described in @supply-chains-as-graphs. Unlike simple tree structures, supply chain graphs are multi-source, multi-sink and can contain cycles. Cycles in practical scenarios arise through closed-loop supply chains involving recycling, rework processes or side-outputs @guide2003. The presence of cycles has important implications for the decomposition approach discussed in subsequent sections.

Each node $v in V$ represents an operational entity in the supply chain and carries a type attribute corresponding to the node categories introduced in @supply-chains-as-graphs. 
Edges $e in E$ represent material flow relationships and resource dependencies.

== Decomposition <decomposition>

The decomposition partitions the supply chain graph $G = (V, E)$ into $k$ disjoint subgraphs ${G_0, G_1, ..., G_(k-1)}$ based on the position of nodes within the supply chain. The goal is to create subproblems that can be solved sequentially, while each subnetwork represents an actual stage in a supply chain, e.g. Procurement, Production or Distribution. @fig:decomposition-overview shows the target state of this decomposition process. The figure shows the several concepts that are now formally defined throughout this section.

#figure(
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1em,
    [
      #image("../figures/whole.png", width: 100%)
      #align(center)[(a) Original supply chain graph]
    ],
    stack(
      dir: ttb,
      spacing: 0.5em,
      [
        #image("../figures/subnet0.png", width: 100%)
        #align(center, text(size: 0.9em)[(b) Subnetwork 0: Procurement])
      ],
      [
        #image("../figures/subnet1.png", width: 100%)
        #align(center, text(size: 0.9em)[(c) Subnetwork 1: Production])
      ],
      [
        #image("../figures/subnet2.png", width: 100%)
        #align(center, text(size: 0.9em)[(d) Subnetwork 2: Distribution])
      ],
    )
  ),
  caption: [
    Decomposition of a supply chain graph into three subnetworks with link nodes and virtual procurements. Source: Internal SupplyChainViewer.
  ]
) <fig:decomposition-overview>

#heading(outlined: false, level: 3)[Cycles]

The stage assignment and partitioning relies on the relative position of nodes and well-defined up- and downstream relationships. Cyclic dependencies invalidate this assumption, making the assignment ambiguous. Furthermore, partitioning a cycle across multiple subnetworks introduces circular dependencies between them, preventing the subnetworks from being ordered for sequential optimization. Consequently, cycles must remain entirely within a single subnetwork and may not be split during partitioning.

To achieve this, the decomposition operates on the condensation $G_C = (V_C, E_C)$ of the network rather than on $G$ directly. The condensation is constructed by first identifying all @SCC:pl, then contracting each @SCC into a single meta-node. An edge exists between two meta-nodes in $G_C$ if and only if an edge exists between their corresponding components in $G$. Since all cycles are absorbed into the contracted nodes, the condensation is always a @DAG, enabling topological traversal. The stage classification therefore assigns stages to meta-nodes (SCCs) rather than individual nodes and all nodes within an @SCC inherit the same stage from their containing meta-node.

#heading(outlined: false, level: 3)[Classification]

Each node $v in V_C$ is assigned a supply chain stage $s(v) in {1, 2, 3, 4, 5}$ based on its relative position inside the network. The five stages reflect the typical phases of material flow in supply chains: procurement from suppliers, pre-processing, production/transformation, post-processing of finished goods and distribution to customers. This classification provides the finest meaningful granularity and coarser decompositions can be achieved by grouping stages together, as described in the following section. @tab:stages summarizes the five stages and their criteria and @fig:example_stages shows an example classification of nodes.

#figure(
  table(
    columns: (auto, auto, auto),
    inset: 6pt,
    align: (center, left, left),
    table.header(
      [*Stage*], [*Name*], [*Criterion*],
    ),
    [1], [Sourced], [Is procurement or input from procurement],
    [2], [Pre-Production], [Upstream of all production, no direct procurement],
    [3], [Intermediate], [Contains production or lies between production stages],
    [4], [Finished], [Downstream of all production, no customer connection],
    [5], [Distribution], [Is customer node or output to customer node],
  ),
  caption: [Supply chain stage classification],
) <tab:stages>


#figure(
  image("../figures/exampe_stage_assignment.png", height: 70%),
  caption: [Example stage classification of nodes. Source: Internal SupplyChainViewer.]
) <fig:example_stages>

The formal definition of the stage sets uses the position of nodes relative to production. Let $tau: V_C -> {"Proc", "Prod", "Cust"}$ denote the node type function. For singleton meta-nodes, i.e., SCCs containing a single original node, $tau$ maps to the type of that node. For multi-node SCCs, an SCC may contain nodes of different types. In this case, $tau$ maps to the dominant type according to the priority order Proc $>$ Prod $>$ Cust. Let $P = {v in V_C : tau(v) = "Prod"}$ be the set of production meta-nodes. Using reachability analysis on $G_C$, where $v arrow.r^* p$ denotes that $v$ can reach $p$ via a directed path, define:

- $U_P = {v in V_C : exists p in P, v arrow.r^* p}$: nodes that are upstream of production (i.e., nodes from which at least one production node is reachable along the directed path)
- $D_P = {v in V_C : exists p in P, p arrow.r^* v}$: nodes that are downstream of production (i.e., nodes that are reachable from at least one production node along the directed path)

Note that every node can reach itself, meaning $p arrow.r^* p$ holds for any node $p$. Consequently, all production nodes belong to both $U_P$ and $D_P$.

Nodes in $U_P without D_P$ are upstream of at least one production node but downstream of none (stages 1-2), nodes in $D_P without U_P$ are downstream of at least one production node but upstream of none (stages 4-5) and nodes in $U_P inter D_P$ lie between production stages (stage 3). Within these groups, the presence of direct procurement or customer edges determines the final stage assignment:

$ S_1 &= {v in U_P without D_P : tau(v) = "Proc" or exists (u, v) in E_C, tau(u) = "Proc"} \
S_2 &= {v in U_P without D_P : tau(v) != "Proc" and not exists (u, v) in E_C, tau(u) = "Proc"} \
S_3 &= U_P inter D_P \
S_4 &= {v in D_P without U_P : tau(v) != "Cust" and not exists (v, w) in E_C, tau(w) = "Cust"} \
S_5 &= {v in D_P without U_P : tau(v) = "Cust" or exists (v, w) in E_C, tau(w) = "Cust"} $

Let $R = V_C without (U_P union D_P)$ be the set of nodes without any production in their connected component. Let $R_1 = {v in R : tau(v) = "Proc" or exists (u, v) in E_C, tau(u) = "Proc"}$ be the subset that are procurement nodes or have direct procurement input and $R_5 = {v in R : tau(v) = "Cust" or exists (v, w) in E_C, tau(w) = "Cust"}$ the subset that are customer nodes or have direct customer output. Then:

$ S_1 &:= S_1 union R_1 \
S_5 &:= S_5 union (R_5 without R_1) \
S_4 &:= S_4 union (R without R_1 without R_5) $


Following these definitions every node is assigned correctly to its stage in the supply chain as described in @tab:stages. These sets $S_1$ to $S_5$ are pairwise disjoint and partition $V_C$, which is proven in @proof-stage-disjointness. This property is essential for correctness, since it guarantees that each node is assigned to exactly one stage, preventing variables and constraints from being duplicated or lost during creation of the subgraphs and then subproblems from the stages. Resource nodes are excluded from the stage assignment and partitioning process beforehand, as their capacities may be shared across multiple subnetworks and require coordinated handling across partition boundaries. Their treatment is detailed in @inter-subnet-constraint-handling.

#heading(outlined: false, level: 3)[Subgraph Construction]

A stage grouping $cal(S) = {S_1, S_2, ..., S_k}$ partitions the five stages into $k$ groups, where each group becomes one subnetwork. To partition the supply chain into the natural stages of procurement, production and distribution, the grouping $cal(S) = {{1, 2}, {3}, {4, 5}}$ is used in this thesis, which creates three subnetworks corresponding to these stages.

Given the stage function $s: V -> {1, ..., 5}$, mapping a node to its stage and the grouping $cal(S)$, the node assignment function $sigma: V -> {1, ..., k}$ maps each node to its subnetwork:

$ sigma(v) = i quad "where" quad s(v) in S_i $

The subgraph of the subnetwork $i$, $G_i = (V_i, E_i)$ contains:
$ V_i = {v in V : sigma(v) = i} $
$ E_i = {(u, v) in E : u in V_i and v in V_i} $

Every edge $(u, v) in E$ falls into exactly one of two categories: either both endpoints belong to the same subnetwork ($sigma(u) = sigma(v)$), in which case the edge is included in $E_i$, or the endpoints belong to different subnetworks ($sigma(u) != sigma(v)$), making it a cut edge. Cut edges require special handling through cut harmonization, but no edge is lost in the decomposition.

#heading(outlined: false, level: 3)[Cut Harmonization]

Cut edges $(u, v) in E$ where $sigma(u) != sigma(v)$ represent material flow between subnetworks. These edges cannot simply be removed, because they are the coupling between the subnetworks. To enable the exchange of materials across partition boundaries, the framework introduces "link nodes". Link nodes are designated location-product nodes that serve as the interface between adjacent subnetworks.

By the structure of supply chain graphs (see @supply-chains-as-graphs), every edge in the material flow connects a source-of-supply node (Production, Transport, Procurement) to a location-product node, or vice versa. Customer nodes form a special case, but a customer transport node and a customer product node are always assigned to the same stage, so they cannot appear on cut edges. Consequently, every cut edge has at least one location-product node as an endpoint. These location-product nodes on cut edges form the set of link nodes $cal(L)$:

$ cal(L) = {ell in V : ell "is a location-product node" and exists (u, v) in E, sigma(u) != sigma(v), ell in {u, v}} $

Each link node $ell in cal(L)$ is replicated in both adjacent subnetworks. Consider an edge from production node $p in G_i$ to link node $ell in G_j$. The node $ell$ is added to $G_i$ and an edge from $p$ to $ell$ is added in $G_i$. The link node $ell$ now serves as the interface coupling between the subnetworks.

For each link node $ell in cal(L)$ in the downstream subnetwork $G_j$, a virtual external procurement node $v_ell^"virt"$ is created and connected to $ell$. This virtual node represents the supply that will flow from the upstream subnetwork to the downstream subnetwork. An example of this setup can be seen in @fig:decomposition-overview. Therefore, when solving the downstream subnetwork individually this virtual procurement node $v_ell^"virt"$ gets treated as a supply point and the amount of the requested supply of the downstream subnetwork can be propagated to the upstream subnetwork (see @two-phase-solve).

#heading(outlined: false, level: 3)[Constraint Deduplication and Feasibility]

The replication of link nodes introduces the challenge that the same location-product now appears in two subnetworks, which would lead to duplicated constraints and variables and therefore capacities if not handled correctly. In the original monolithic formulation, each location-product has exactly one inventory balance constraint and one inventory variable. After replication, just generating constraints for both copies would double-count inventory capacity, initial stock and storage costs.

To preserve feasibility, the framework must assign all inventory-related constraints exclusively to one copy of each link node $ell in cal(L)$. While either copy could serve this role, the framework assigns them to the upstream copy in subnetwork $G_i$ by convention. The downstream copy (in subnetwork $G_j$) is marked as "non-storable", eliminating its inventory constraints and storage variables. The downstream copy thus functions as a pure flow-through point. This design ensures that the combined solution across subnetworks will maintain feasibility with respect to the original formulation.

== Two-Phase Solve Approach <two-phase-solve>

The coordination of subproblems across the decomposed network requires a systematic approach that respects the dependencies between subnetworks while ensuring solution feasibility. In contrast to iterative decomposition methods that require multiple passes to achieve convergence, this newly proposed approach consists of exactly two traversals: a bottom-up phase that propagates demand information from distribution toward procurement, followed by a top-down phase that allocates actual supplies from procurement toward distribution.

The bottom-up phase solves each subnetwork assuming unlimited supply at its virtual procurement cut points, to determine the demand requirements that should be satisfied by the upstream subnetwork. Subsequently, the top-down phase resolves each subnetwork with the actual supply capacities determined by its upstream subnetworks, yielding a feasible allocation solution throughout the network. This two-pass approach eliminates the convergence uncertainty of iterative approaches while ensuring that, provided all subproblems obtain feasible solutions, the combined solution satisfies the original constraints.

#heading(outlined: false, level: 3)[Meta Graph Construction] <meta-graph>

While handling cut-edges, a meta graph $M = (cal(V)_M, cal(E)_M)$ is constructed, that captures the dependencies between the $k$ subnetworks:

$ cal(V)_M = {0, 1, ..., k-1} $
$ cal(E)_M = {(i, j, ell) : exists (u, v) in E "with" sigma(u) = i, sigma(v) = j, ell in cal(L) inter {u, v}} $

The meta graph is a multi-graph allowing multiple edges between the same pair of subnetworks, one per distinct link node.
The meta graph defines the solving order for both phases. The reverse of a topological ordering of $M$ yields a sequence in which each subnetwork appears only after all of its successors, establishing the correct execution order for the solve of the corresponding subproblems in the bottom-up phase. Conversely, the top-down phase requires all upstream supplies to be determined before a subnetwork can be solved. The topological order therefore provides the correct execution sequence for this case. @fig:meta-graph shows an example meta graph which would result in $(2,1,0)$ for the bottom-up solve and $(0,1,2)$ for the top-down solve.

#figure(
  image("../figures/meta_graph.png", width: 50%),
  caption: [
    Example meta graph $M$ for three subnetworks
  ]
) <fig:meta-graph>

#heading(outlined: false, level: 3)[Demand Propagation (Bottom-Up Phase)]

The bottom-up phase determines how much material each subnetwork requires from its upstream neighbors. Subnetworks are solved in reverse topological order, starting from distribution (closest to customers) and proceeding toward procurement. Each subnetwork $G_j$ is solved as an independent scenario with virtual procurement nodes representing the possible, currently infinite supply from upstream subnetworks. This means the modified constraint for link node $ell$ in the subnetwork $G_j$ becomes:

$ "VS"_(ell) (t) = "VS"_(ell) (t-1) + "VP"_(ell)(t) + dots, $

with decision variable $"VP"_(ell)(t)$ that represents the procurement from the upper subnetwork, allowing the solver to acquire material at this location, that is propagated to the supplying subnetwork in the following way.
Let $"VP"_v^"virt" (t)$ denote the planned procurement quantity at virtual node $v$ by subnetwork $G_j$. This quantity represents the demand that subnetwork $G_j$ requests from its upstream neighbor. After solving $G_j$, the demand is propagated to the upstream subnetwork $G_i$ by creating a location demand at the corresponding boundary location-product node $ell$:

$ "DQ"_(ell)(t) = "VP"_(v_ell^"virt")(t) $

where $"DQ"_(ell)(t)$ is the demand at location-product $ell$ in period $t$ in subnetwork $G_i$ and $"VP"_(v_ell^"virt")(t)$ is the external procurement quantity from the virtual procurement node connected to $ell$ in $G_j$. This demand is added to the upstream subnetwork as a demand target with constraint $"VP"_(ell)(t) <= "DQ"_(ell)(t)$. Then, the solve of subproblem $G_i$ determines the optimal delivered quantity $"VL"_(ell)(t)$, which appears both in the inventory balance as an outflow and in the objective function with a penalty term $"CD"_ell dot ("DQ"_(ell)(t) - "VL"_(ell)(t))$ for any unfulfilled portion. The non-delivery penalty $"CD"_ell$ is derived from an aggregated non-delivery cost, described in @non-delivery-cost-aggregation.

Since the virtual procurement nodes have unlimited capacity during the bottom-up phase, the solver determines ideal demand requirements without supply constraints, propagating demands backward through the supply chain from customer demands to procurements. This may result in demands that exceed what upstream subnetworks can actually provide. When an upstream subnetwork cannot fully satisfy a downstream demand, the downstream subnetwork's solution becomes temporarily infeasible. The top-down phase corrects this by re-solving each subnetwork with the actual supplies delivered by its upstream neighbors, ensuring that, provided all subproblems obtain feasible solutions, the combined solution satisfies the original cross-subnetwork constraints.



#heading(outlined: false, level: 3)[Supply Propagation (Top-Down Phase)]

The top-down phase then allocates actual supplies based on the supply decisions of upstream subnetworks. Subnetworks are solved in topological order, starting from procurement and proceeding toward distribution. The first subnetwork retains its bottom-up solution unchanged, as it has no upstream dependencies which could need correction.

For each subsequent subnetwork $G_j$, the virtual procurement nodes are replaced with fixed supply quantities derived from the upstream solutions. $"VL"_(ell)^(G_i) (t)$ denotes the quantity actually delivered to location-product $ell$ in period $t$ in the upstream subnetwork $G_i$. The top-down phase injects this quantity as a constant term into the inventory balance constraint (@eq:inventory-balance). The modified constraint for link node $ell$ in the downstream Subnetwork $G_j$ becomes:

$ "VS"_(ell) (t) = "VS"_(ell) (t-1) + "VL"_(ell)^(G_i) (t) + dots $

where $"VL"_(ell) (t)$ is now a fixed constant rather than a decision variable. This fixed supply term represents the actual material availability from the upstream subnetwork. The virtual external procurement rule for the boundary node is removed. The top-down solve may produce a different, worse solution compared to the bottom-up phase, since the actual supply may be less than the requested demand.

== Link Node Heuristics <link-node-heuristics>

The subnetworks have no information about cost-structure or non-delivery penalties of neighboring subnetworks. While the stated design already produces valid solutions for any problem, the solutions can be improved by providing more information to the different subproblems. Therefore, the virtual procurement nodes introduced at cut edges are parameterized without access to actual upstream subproblem solutions. Each virtual procurement gets assigned four parameters:

#figure(
  table(
    columns: 2,
    align: (left, left),
    [*Parameter*],  [*Purpose*],
    [Virtual marginal cost], [Approximate cheaper upstream procurements], 
    [Leadtime aggregation], [Prevent requesting before supply is possible],
    [Maximum flow capacity], [Identify dead ends that will never deliver ],
    [Virtual non-delivery penalty], [Prioritize fulfillment of higher-priority demands],
  ),
  caption: [Virtual procurement parameters]
) <tab:heuristics-list>
Computing exact values would necessitate solving the upstream subproblems first, defeating the purpose of decoupled optimization. The framework therefore employs conservative heuristic estimates that keep the solution space of the combined subnetwork solution the same, but restrict the solution spaces of the subproblems in the bottom-up phase, to get better virtual demand estimates. This means that the proposed heuristics can only improve the overall decomposition solution. The parameters in @tab:heuristics-list are assigned to the virtual procurement nodes created for each link node and will then be transformed into constraints during the @MILP formulation. The following sections describe each heuristic and how the computed values enter the subproblem formulation.

The aggregation heuristics must respect the structural semantics of different node types. Let $"pred"(v) = {u in V : (u, v) in E}$ denote the set of immediate predecessors of node $v$ and let $"succ"(v) = {w in V : (v, w) in E}$ denote the set of immediate successors. Two distinct behaviors are distinguished based on the logical relationship between a node and its predecessors:

- *OR-nodes*: Location-product and customer-product nodes represent points where material can arrive from multiple alternative sources. One source would be enough to fulfill demand.

- *AND-nodes*: Production nodes require inputs from all predecessors simultaneously, consuming components according to the @BOM coefficients $"PR"_(o,s,p)$ defined by the production model, where negative values indicate consumed materials and positive values indicate produced materials.

All other node types have exactly one predecessor by definition.


#heading(outlined: false, level: 3)[Production Cost Aggregation]<production-cost-aggregation>

The virtual procurement nodes require cost parameters representing the expense of obtaining materials from upstream subnetworks. Without these parameters, the downstream optimization would treat upstream supply as cost-free, leading to over-procurement. Production cost aggregation computes an estimated procurement cost for each boundary product based on the accumulated costs along the upstream supply paths.

Let $c_v$ denote the marginal cost of node $v$, representing the direct operational cost per unit on the operation (e.g. transport cost, production cost, procurement cost). The aggregation proceeds in topological order from sources to sinks. The aggregated cost $c_v^"agg"$ is computed as:

$ c_v^"agg" = cases(
  c_v & "if" "pred"(v) = emptyset,
  c_v + min_(u in "pred"(v)) c_u^"agg" & "if" v "is an OR-node",
  c_v + sum_(u in "pred"(v)) |"PR"_((u,v))| dot c_u^"agg" & "if" v "is an AND-node"
) $

For OR-nodes, the minimum reflects the optimizer's ability to choose the cheapest supplier. For AND-nodes, the sum scaled by @BOM coefficients captures the total input cost. The aggregated cost constitutes an underestimate of the true procurement cost, as the minimum operator assumes the cheapest path is always available. Capacity constraints may force later selection of more expensive alternatives in practice, but for the purpose of guiding the optimization toward cheaper decisions, this approximation is sufficient. The computed $c_v^"agg"$ is assigned as the procurement cost parameter of the virtual procurement node, entering the objective function as a per-unit cost term.

#heading(outlined: false, level: 3)[Lead Time Aggregation]<lead-time-aggregation>

Lead time $l_v$ represents the number of periods required from the initiation of an operation at node $v$ until the resulting material becomes available. When a subnetwork boundary is introduced, the downstream subnetwork loses visibility into upstream timing needs. The virtual procurement node must therefore carry an aggregate lead time reflecting the minimum time required for material to traverse the upstream network up to the point of the link node.

The aggregation proceeds in topological order. The aggregated lead time $l_v^"agg"$ is computed as:

$ l_v^"agg" = cases(
  l_v & "if" "pred"(v) = emptyset,
  min_(u in "pred"(v)) l_u^"agg" + l_v & "if" v "is an OR-node",
  max_(u in "pred"(v)) l_u^"agg" + l_v & "if" v "is an AND-node"
) $

For OR-nodes, the minimum selects the fastest alternative procurement path. For AND-nodes, the maximum identifies the critical path, since all inputs must be present before production can commence.

The computed $l_v^"agg"$ at boundary nodes is assigned to virtual procurement nodes as their validity period. This aggregation provides an optimistic underestimate, since capacity constraints may still limit the flow in valid periods because of missing input materials.

#heading(outlined: false, level: 3)[Max Flow Aggregation]<max-flow-aggregation>

The max flow aggregation identifies "dead end" link nodes where no material can feasibly flow across the subnetwork boundary. Such dead ends arise when upstream production paths are structurally infeasible, for example due to disabled productions or missing input materials. Without identifying these dead ends, the downstream optimization would create virtual procurement nodes for link nodes that can never receive supply from the upstream subnetwork, leading to unfulfillable demand requests during the bottom-up phase and therefore worse solutions.

The aggregation proceeds in topological order from source nodes toward boundary nodes. Let $f_v^"agg"$ denote the aggregated max flow at node $v$ and let $f_v^"own"$ denote the node's own capacity constraint (e.g. Maximum Transport, Maximum Production, Resource Capacity). The aggregated max flow is computed as:

$ f_v^"agg" = cases(
  f_v^"own" & "if" "pred"(v) = emptyset,
  sum_(u in "pred"(v)) f_u^"agg" & "if" v "is an OR-node",
  min_(u in "pred"(v)) f_u^"agg" / (|"PR"_((u,v))|) & "if" v "is an AND-node"
) $

For OR-nodes, the sum reflects that any combination of sources can contribute to total flow. For AND-nodes, the minimum identifies the bottleneck input, scaled by the @BOM coefficient to convert input capacity to output capacity. The final aggregated value incorporates any local resource constraints: $f_v^"agg" = min(f_v^"agg", f_v^"own")$.

When a link node $ell$ has $f_ell^"agg" = 0$ across all planning periods, it represents a structural dead end where no feasible flow can occur. In this case, the corresponding virtual procurement node is entirely removed from the downstream subnetwork. This creates better demand estimates to the upper subnetworks, because it stops the downstream subnetwork from attempting to request supply through paths that can never deliver.

#heading(outlined: false, level: 3)[Non-Delivery Cost Aggregation]<non-delivery-cost-aggregation>

Non-delivery cost represents the penalty incurred when customer demand cannot be fulfilled. Virtual procurement nodes in upstream subnetworks have no visibility into the downstream demand structure they serve. Without propagating penalty information upstream, virtual link nodes cannot distinguish between demands of varying importance. The non-delivery cost aggregation propagates penalty costs backward from demand nodes to their upstream suppliers.

Unlike the other heuristics, this aggregation operates in reverse topological order, from sink nodes toward source nodes. Let $"CD"_v$ denote the non-delivery penalty at a demand node $v$. The aggregated non-delivery cost $"CD"_v^"agg"$ is computed as:

$ "CD"_v^"agg" = cases(
  "CD"_v & "if" "succ"(v) = emptyset,
  "CD"_v + frac(1, |"succ"(v)|) sum_(w in "succ"(v)) "CD"_w^"agg" / (|"PR"_(v,w)|) & "otherwise"
) $

The inverse @BOM scaling accounts for material conversion ratios, since, when multiple units of a component produce one unit of output, failing to deliver one component unit affects, on average, only a fraction of the final product. The average over successors distributes the downstream penalty proportionally when a node feeds multiple paths.

This heuristic is inherently imprecise since it remains unknown which specific customer demand will ultimately be fulfilled by delivering a particular intermediate product. Furthermore, failing to deliver one component of a production process prevents the entire output from being produced, not merely the fraction implied by the @BOM coefficient. Nevertheless, the aggregated penalty provides the solver with directional guidance to prioritize fulfilling demands with higher downstream criticality. The computed $"CD"_v^"agg"$ is assigned as the non-delivery penalty $"CD"_ell$ of the virtual demand created at the link node, entering the objective function as a penalty term for unfulfilled virtual demand.

== Inter-Subnetwork Constraint Handling <inter-subnet-constraint-handling>

The graph partitioning described in the previous sections creates subnetworks that can be solved independently, but certain constraints in the original formulation cannot be assigned to a single subproblem. As introduced in @mathematical-model-formulation, resource nodes impose shared capacity limits across multiple operations through constraints of the form $sum_(o in O_(s_r)) "RR"_(o,r) dot "VO"_(o,s) (t) <= "RC"_r (t)$, where $O_(s_r)$ is the set of production models using the resource's capacity. When operations from different subnetworks share the same resource, this constraint spans multiple subproblems and cannot be enforced locally. Without coordination, each subnetwork would assume access to the full resource capacity, leading to collective over-allocation that violates the original constraint. This section presents an approach for allocating shared resource capacity across subnetworks.

The equal split strategy provides a straightforward mechanism for distributing shared resource capacity across subnetworks. The capacity is divided equally among all sharing subnetworks, regardless of their actual requirements. This approach requires only structural information about which subnetworks reference each resource, without knowledge of consumption patterns or optimization outcomes.

Let $r$ denote a shared resource with capacity $"RC"_r (t)$ in period $t$ and let $N_r = {i_1, i_2, ..., i_m}$ be the set of subnetwork indices that contain operations consuming $r$. The capacity allocated to each subnetwork $i in N_r$ is:

$ "RC"_r^((i)) (t) = frac("RC"_r (t), |N_r|) $

The equal split approach offers simplicity and guaranteed feasibility since each subnetwork receives a fraction of the original capacity and these fractions sum to one, the combined usage across all subnetworks cannot exceed the original constraint. However, this strategy can result in inefficient utilization when subnetworks have heterogeneous demands. For the sake of simplicity this approach is used throughout the experiments. It is expected that the solution quality can be improved by using more sophisticated approaches, like @FCFS or Preallocation. Possible designs are discussed in @potential-improvements, but the implementation and evaluation remain future work.

== Solution Combination <solution-combination>

After the top-down phase completes, each subnetwork has produced a local solution. These solutions must be combined into a single solution for the original monolithic problem. The combination process addresses two categories of variables:
- unique variables that exist in exactly one subnetwork,
- link node variables at cut edges.

#heading(outlined: false, level: 3)[Unique Variables]

The majority of decision variables in the original formulation appear in exactly one subnetwork. Decision variables for nodes that are not link nodes are directly adopted from their respective subnetwork solution. These variables require no special handling since their constraints are entirely contained within a single subnetwork.

#heading(outlined: false, level: 3)[Link Node Variables]

As described in @decomposition, link nodes $ell in cal(L)$ are replicated across adjacent subnetworks during cut harmonization. The upstream copy in subnetwork $G_i$ retains all inventory-related constraints and variables, while the downstream copy in $G_j$ functions as a flow-through point with no inventory constraints.

During the two-phase solve, virtual demands and virtual procurements are introduced at link nodes to coordinate the subnetworks. In the combined solution, these virtual elements are removed. The upstream copy's solution provides all inventory and constraint-related values for the link node. The delivered quantity $"VL"_(ell) (t)$ from the upstream subnetwork becomes the actual inventory outflow to the downstream subnetwork, satisfying the original material inflow constraint without requiring an explicit demand variable in the combined solution:

$ "VS"_(s,p)^"combined" (t) = "VS"_(s,p)^((i)) (t) quad "for" ell in cal(L) $

This ensures that the combined solution satisfies the original inventory balance constraints, because the decomposition assigns all inventory constraints exclusively to the upstream copy. The downstream copy has no inventory variable and constraint that would conflict.

The resource capacity splitting strategies ensure that each subnetwork respects its allocated capacity share. Since the allocated shares sum to at maximum the original capacity, the combined resource consumption cannot exceed the original resource constraint $"RC"_r (t)$.

The combination step is straightforward because the top-down phase has already resolved all cross-boundary dependencies since each subnetwork was solved with the actual supplies provided by its upstream neighbors, ensuring that the combined solution is feasible with respect to the original formulation.


== Runtime Allocation

When solving large-scale supply network instances, a total runtime budget is specified to limit computational cost. In the monolithic case, this budget is allocated to a single @MILP solver invocation. Under decomposition, the total budget must be distributed across multiple subproblem solves. When dividing into $k$ subnetworks the bottom-up phase needs $k$ @MILP solve runs and the top-down phase needs $k-1$ @MILP solve runs, because the uppermost subnetwork retains its solution unchanged. This leads to $2k-1$ solve operations in total. A time distribution strategy needs to address that problems with fewer variables will find better solutions faster and might be solved to optimality before the allocated time expires. Bigger problems on the other hand might need more time to find even one possible solution, which is crucial to continue the whole solve, since when one problem does not find a solution, the whole run cannot be continued.

A complexity-weighted allocation strategy is therefore introduced, that distributes runtime proportionally to estimated subproblem difficulty. Since the exact model statistics are only available once the mathematical model is built, estimates depending on the graph nodes and their master data are used. Let $n_i^"cont"$ denote the estimated number of continuous variables and $n_i^"disc"$ the estimated number of discrete variables in subnetwork $i$. From these estimates, a heuristic complexity score $C_i$ is computed using an internal formula employed by existing SAP decomposition modules. The exact calculation of $C_i$ is not specified in this thesis, as the underlying heuristic is an internally developed measure that has not been formally validated as a general measure of computational complexity. The formula weights discrete variables more heavily than continuous ones, reflecting the exponential impact of integrality constraints on branch-and-bound search complexity. The estimations for counting discrete and continuous variables per node type are detailed in @appendix-complexity.

The complexity scores are computed once before solving begins and normalized to obtain time shares $s_i = C_i / (sum_(j=0)^(k-1) C_j)$ for each subnetwork. However, the actual runtime allocation is performed dynamically during the solving process based on remaining subproblems and previously consumed time.

Let $T_"rem"$ denote the remaining runtime budget and $S_"rem"$ the sum of time shares for all unsolved subnetworks. When subnetwork $i$ is about to be solved, its allocated runtime is:

$ t_i = T_"rem" dot frac(s_i, S_"rem") $

After solving subnetwork $i$, let $t_i^"used"$ denote its actual solver runtime. The remaining budget is updated as $T_"rem" := T_"rem" - t_i^"used"$ and subnetwork $i$'s time share is removed from the remaining share pool: $S_"rem" := S_"rem" - s_i$. This dynamic reallocation ensures that any time saved by a subnetwork that solves faster than expected is redistributed proportionally among the remaining unsolved subnetworks according to their complexity shares.

To prevent excessively small allocations to low-complexity subnetworks, a minimum share threshold $s_"min" = 0.1$ (10%) is enforced, ensuring each subnetwork receives at least 10% of the total budget regardless of its complexity. If a subnetwork's complexity-based share $s_i$ falls below $s_"min"$, it is raised to $s_"min"$. The required additional share is taken proportionally from subnetworks whose shares exceed $s_"min"$. Specifically, let $D = sum_(s_i < s_"min") (s_"min" - s_i)$ be the total deficit and $S = sum_(s_i >= s_"min") (s_i - s_"min")$ be the total surplus available. Each subnetwork $j$ with $s_j >= s_"min"$ has its share reduced by:

$ s_j := s_j - D dot frac(s_j - s_"min", S) $

This redistribution preserves the relative ordering of shares above the minimum while guaranteeing all subnetworks receive sufficient time. The normalized shares still sum to 1.0 and are used throughout both solving phases.

The complexity-weighted approach offers two advantages. First, it allows harder subproblems to utilize more computational time, potentially improving solution quality where it matters most. Second, it prevents easy subproblems from consuming time they do not need.

However, complexity-based allocation has limitations. The heuristic complexity score may not accurately predict actual solver runtime, which depends on many more factors than variable counts alone. Furthermore, if the complexity estimate underallocates time to a critical subproblem, that subproblem may terminate prematurely with a poor or no solution, degrading the quality of the overall decomposed solution or making it impossible to solve. Improvements and future possibilities are discussed in @potential-improvements.

