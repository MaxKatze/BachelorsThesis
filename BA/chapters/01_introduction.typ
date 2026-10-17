= Introduction

== Motivation and Problem

Modern supply chain networks have grown increasingly complex, spanning multiple continents and involving thousands of suppliers, production facilities, warehouses and customer demands @chopra2021. Planning these networks requires determining optimal production quantities, transportation quantities and inventory levels across the entire network and planning horizon. These decisions are typically formulated as @MILP problems, which simultaneously optimize continuous variables and discrete variables @wolsey2020.

However, the computational complexity of @MILP problems poses significant challenges for enterprise-scale supply chains. @MILP is NP-hard in general @garey1979, meaning that solving time can grow exponentially with problem size. Real-world scenarios can involve optimization problems with millions of decision variables. Solving such large-scale problems using traditional monolithic approaches often leads to excessive computation times or exceeds available memory. This scalability bottleneck represents a critical limitation for supply chain planning systems such as SAP @IBP @sap_ibp2024. The challenge lies in finding methods that can handle the scale of modern supply networks while maintaining solution quality and improving computational speed.

== Approach

A promising approach to address this challenge is decomposition. The core idea is to partition a large problem into smaller subproblems whose solutions combine into a global solution @dantzig1960. Graph-based decomposition strategies are particularly well-suited for supply chain networks, as these networks naturally exhibit hierarchical structures that lend themselves to partitioning along stage boundaries. The material flow in most supply chains follows three fundamental phases: sourcing raw materials and components from suppliers (Procurement), transforming inputs into finished goods (Production) and delivering products to customers (Distribution). These phases represent natural boundaries for decomposition  because material flows sequentially from one phase to the next, creating clear interfaces between them. This thesis therefore proposes reducing computational complexity by decomposing supply chains along these stages, partitioning the underlying @MILP accordingly, solving each subproblem separately and combining the partial solutions into a feasible global solution.

== Goal and Research Questions

The goal of this thesis is to develop and evaluate a stage-based decomposition strategy for supply chain network optimization problems. This involves designing a partitioning scheme that respects the network's hierarchical structure, developing a coordination mechanism that propagates information between dependent subproblems and ensuring that the combined result remains globally feasible.

This thesis addresses the following research questions:

+ *RQ1: How can supply chain networks be decomposed into subnetworks while preserving solution feasibility?* \
  This question investigates graph-based decomposition strategies that partition the network while maintaining the structural and logical dependencies necessary for a valid combined solution.

+ *RQ2: How does decomposition affect solution quality and computational performance compared to monolithic solving?* \
  This question examines whether decomposition can provide advantages in solution quality under the same conditions as the monolithic approach.

+ *RQ3: Can decomposition enable solving previously intractable problems?* \
  This question evaluates whether the proposed approach can successfully solve large-scale scenarios that would otherwise exceed the computational resource limits of runtime or memory.