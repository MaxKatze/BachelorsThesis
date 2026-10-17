= Implementation <implementation>

This chapter describes the technical implementation of the decomposition framework and its architecture.

== System Architecture <system-architecture>

The system is realized as an external orchestration layer written in Python that operates independently of the SAP IBP Supply Planning optimization engine while leveraging its solver infrastructure through a service interface. The framework coordinates multiple solver invocations without modifying the underlying optimization engine. This architectural decision stems from the requirement to preserve the correctness and modularity of the production solver while enabling experimental decomposition strategies. Embedding decomposition logic directly into the optimization engine would require extensive modifications to a complex codebase and would complicate the process for the @POC of this thesis.

@fig:system-architecture loosely illustrates the overall system architecture, showing the interaction of local modules and the remote optimization service.

#figure(
  image("../figures/high-level-overview.png", width: 100%),
  caption: [System architecture of the decomposition framework showing the orchestration layer and solver service interaction]
) <fig:system-architecture>

#heading(outlined: false, level: 3)[Module Overview]

The framework is organized into the following packages:

- *domain*: Contains domain models, data mappings and configuration for supply chain entities. Defines node type enumerations, node and edge resolution from database tables and heuristic configuration parameters.

- *algorithms*: Implements the core graph algorithms. The `transformer` module handles bidirectional conversion between database tables and graph representation (@graph-modelling). The `decomposition` subpackage contains `static_decomposer` for stage classification and graph partitioning (@decomposition) and `subnetwork_harmonizer` for cut edge handling and meta-graph construction. The `solver` subpackage implements `static_solver` for the two-phase solving approach and `executor` for invoking the Optimization Service (@two-phase-solve), `solution_harmonizer` for combining subnetwork solutions (@solution-combination) and `constraint_propagation` for cross-boundary constraint handling. The `initial_heuristics` subpackage provides `aggregation_propagation` for computing link node parameters (@link-node-heuristics).

- *persistence*: Handles file I/O. Includes `file_parser` and `file_writer` for database serialization.

- *orchestration*: Coordinates the overall workflow through the `orchestrator` module, which sequences the transformation, decomposition, solving and solution combination phases as described in @two-phase-solve.

#heading(outlined: false, level: 3)[ServiceTool Integration]

The framework communicates with the SAP @IBP optimization service through a command-line interface tool called ServiceTool. This tool acts as a bridge between the local Python environment and the cloud-based optimization infrastructure. ServiceTool performs OAuth2 authentication against the service cluster, then uploads the input file along with the solver configuration. After the optimization completes on the remote infrastructure, ServiceTool downloads the solution archive containing the result tables. The framework invokes ServiceTool as a subprocess from Python using the `subprocess.Popen` interface with streaming output capture.

#heading(outlined: false, level: 3)[Error Handling and Recovery]

The executor module implements retry logic with exponential backoff for transient failures such as network timeouts or temporary service unavailability. Permanent failures, such as solver time limit reached or infeasible problems, are detected through exit code analysis in the solver output and raise dedicated exceptions that terminate the current solve attempt without retry.

The framework architecture supports recovery functionality through checkpointing of intermediate results. Each subnetwork solution is persisted to disk immediately after completion, which enables recovery from failure after every fully finished optimization run. The system can detect which subnetwork was the last one completely solved and continue from there.

== Data Handling and Technologies <data-handling>

The framework operates on data stored as files on the local filesystem. This file-based approach enables inspection of intermediate subnetwork solutions and provides natural checkpoints for the solving process.

Python was selected as the implementation language for several reasons @python2024. The ecosystem provides libraries for graph algorithms and large data operations. The language's flexibility supports rapid prototyping and fast development of decomposition approaches. Furthermore, Python's subprocess management enables integration with the ServiceTool command-line interface.

The framework employs the following primary libraries:

- *NetworkX* @networkx2024: Used for graph representation and algorithms. The supply chain network is modeled as a directed graph using NetworkX's `DiGraph` representation. The library contains several graph algorithms like traversals or condensation which the framework uses throughout.

- *Polars* @polars2024: Used for tabular data manipulation. Polars provides high-performance DataFrame operations for filtering and concatenating the master data tables and solver result tables. The library is used throughout SAP Supply Planning scripts and has direct integration with the table data format.

- *NumPy* @numpy2020: Used for numerical computations on graph node and edge attributes, particularly for the aggregation heuristics.

After partitioning the supply chain graph into subgraphs as described in @decomposition, each subnetwork must be converted into a standalone scenario file that the solver can process independently. The framework achieves this through a table filtering mechanism that extracts the data rows relevant to each subnetwork from the entire monolithic file. Each table in the data schema defines retain-if rules that specify which graph node types a row in the table references. The `columns` mapping specifies which table columns must match the corresponding node attributes for a row to be retained. @lst:retain-if shows an example of such a rule for the production source item table, which stores the bill of materials for production rules. This table references both the production node through location and source and the component's location-product node. Multiple retain-if items in the list are AND-concatenated, meaning a row is only retained if it matches nodes from all specified types in the subgraph.

#figure(
```python
RetainIfList(
    items=[
        RetainIf(
            node_type=NodeType.PRODUCTION,
            columns={"LOCID": "LOCID", "SOURCEID": "SOURCEID"}
        ),
        RetainIf(
            node_type=NodeType.LOCATION_PRODUCT,
            columns={"COMPONENTPRDID": "PRDID", "LOCID": "LOCID"}
        ),
    ],
    mode=RetainIfMode.AND
)
```,
  caption: [Retain-if configuration for the production source item table]
) <lst:retain-if>

When generating the scenario file for subnetwork $i$, the framework collects all node identifiers and attributes present in subgraph $G_i$, then filters each table to retain only rows whose key columns reference nodes within that subgraph. The filtered tables are then serialized into a binary scenario file that represents a standalone optimization scenario.

This pipeline ensures that each subproblem receives exactly the data required to optimize its portion of the supply chain, with cut edges handled through the virtual procurement mechanism described in @decomposition.

The underlying optimization engine uses Gurobi as its @MILP solver. Gurobi is a commercial solver known for its performance on large-scale mixed-integer programs @gurobi2024. SAP Supply Planning uses Gurobi for most optimization runs due to its good performance. Therefore, the framework uses it here as well. The complete solver parameter configuration is documented in @appendix-gurobi.

The optimization problems are solved on the SAP Performance Optimization Cluster, a cloud-based infrastructure. Although the actual hardware can differ based on the assigned computational node, experiments showed that the differences between different runs are negligible compared to the runtimes. All experiments in this thesis, both monolithic and decomposed solves, were executed on this same infrastructure to ensure fair comparison.

== Solution Verification <solution-verification>

The decomposition framework produces solutions through a sequence of coordinated subproblem solves and combines them. The framework verifies the combined solution against the original monolithic formulation to confirm that the decomposed solution is feasible for the original problem and to obtain the true objective function value under the complete cost structure.

The verification procedure takes the original monolithic problem and adds the values from the decomposed solution as pseudo hard constraints. Specifically, the production quantities $"VO"$, transport quantities $"VT"$ and procurement quantities $"VP"$ from the decomposed solution are injected into the problem formulation.

Pseudo hard constraints add a penalty term to the objective function for any deviation from the target value. For each decision variable $"VX"_i$ with decomposed solution value $"VX"_i^*$, the solver adds:

$ M dot |"VX"_i - "VX"_i^*| $

to the objective function where $M$ is a large penalty coefficient, defined by $M = 10 dot C$ where $C$ is the highest cost in the model. This soft constraint approach allows the solver to deviate from the injected values if necessary to maintain feasibility, while strongly preferring the original solution values. In practice, the penalty is large enough that the solver converges to the adjusted values unless doing so would violate hard constraints, because the verification runs are solved to optimality. The verification uses pseudo hard constraints rather than hard constraints because the decomposition may produce solutions with minor numerical deviations. These deviations are tolerated by the soft constraint approach and then corrected by the verification. To differentiate between infeasible solutions and numerical issues, the decomposed solution is considered valid if no pseudo hard constraint is violated by more than $10^(-4)$.

The verification solve completes rapidly compared to the original optimization. With the primary decision variables fixed, the remaining problem reduces to computing the implied values of dependent variables and evaluating the objective function. The solver does not need to explore the combinatorial space of production and transport decisions, as these are predetermined by the injected constraints. In practice, no verification run exceeded a runtime of $1%$ of the original runtime. This efficiency enables verification to be performed after each decomposed solve to obtain the correct objective function value. The correct objective function value cannot be obtained directly from the decomposed solutions, because, during the two-phase solve, each subproblem optimizes a modified objective that includes virtual costs and penalties for link nodes. These virtual terms guide the decomposition but do not correspond to actual costs in the original formulation. The verification problem uses the original objective function without any virtual terms. The resulting objective value represents the true cost of the decomposed solution as it would be evaluated by the monolithic solver to allow comparison.
