*Premise.* Let $G_C = (V_C, E_C)$ be the condensation of the supply chain graph. By construction, $G_C$ is a @DAG.

*Definitions.* Let $P = {v in V_C : tau(v) = "Prod"}$ be the production nodes. Define $U_P = {v in V_C : exists p in P, v arrow.r^* p}$ (nodes with production downstream) and $D_P = {v in V_C : exists p in P, p arrow.r^* v}$ (nodes with production upstream), where $arrow.r^*$ denotes reachability.

*Lemma 1.* The sets $U_P without D_P$, $U_P inter D_P$, $D_P without U_P$ and $V_C without (U_P union D_P)$ partition $V_C$.

_Proof._ For any universe $U$ and sets $A, B subset.eq U$, the four sets $A without B$, $A inter B$, $B without A$ and $U without (A union B)$ are pairwise disjoint and their union equals $U$ by definition. $square$

*Theorem.* The stage sets $S_1, S_2, S_3, S_4, S_5$ partition $V_C$.

_Proof._ Let $R = V_C without (U_P union D_P)$, $R_1 = {v in R : tau(v) = "Proc" or exists (u, v) in E_C, tau(u) = "Proc"}$ and $R_5 = {v in R : tau(v) = "Cust" or exists (v, w) in E_C, tau(w) = "Cust"}$. It is shown (i) pairwise disjointness and (ii) completeness.

*(i) Disjointness.* By Lemma 1, the four base regions $U_P without D_P$, $U_P inter D_P$, $D_P without U_P$ and $R$ partition $V_C$. Each node belongs to exactly one base region and is assigned to a stage set based only on its region. Since regions are disjoint, it suffices to show disjointness within each region.

Within $U_P without D_P$: $S_1$ contains nodes that are procurement nodes or have procurement input, $S_2$ contains nodes that are neither procurement nodes nor have procurement input. These conditions are complementary, so $S_1 inter S_2 = emptyset$.

Within $U_P inter D_P$: All nodes go to $S_3$.

Within $D_P without U_P$: $S_5$ contains nodes that are customer nodes or have customer output, $S_4$ contains nodes that are neither customer nodes nor have customer output. These conditions are complementary, so $S_4 inter S_5 = emptyset$.

Within $R$: Nodes in $R_1$ go to $S_1$. Nodes in $R_5 without R_1$ go to $S_5$. Nodes in $R without R_1 without R_5$ go to $S_4$. These three sets partition $R$ by construction.

*(ii) Completeness.* By Lemma 1, every $v in V_C$ belongs to exactly one base region:
- $U_P without D_P$: Covered by $S_1 union S_2$ (procurement node/input or not).
- $U_P inter D_P$: Equals $S_3$ by definition.
- $D_P without U_P$: Covered by $S_4 union S_5$ (customer node/output or not).
- $R$: Covered by $R_1 subset S_1$, $(R_5 without R_1) subset S_5$ and $(R without R_1 without R_5) subset S_4$.

Thus $S_1 union S_2 union S_3 union S_4 union S_5 = V_C$. $square$

*Corollary.* The stage classification assigns each node to exactly one stage, ensuring no duplication or omission of nodes and therefore later variables and constraints during decomposition.
