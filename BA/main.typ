// LTeX: enabled=false
#import "template.typ": caption_with_source, project
#set math.equation(numbering: "1.")
#show: project.with(
  // 'de' for german or 'en' for english.
  // Pull Requests for other languages are welcome! :)
  lang: "en",

  // 'dhbw' or 'ihk'
  program: "dhbw",

  // Shows a line for a signature, if set to `false`,
  is_digital: false,

  // Display the confidentiality clause
  confidentiality_clause: false,

  // Your degree program
  examination: "Bachelor of Science (B. Sc.)",

  // Your field of study
  study_field: "Computer Science",

  ///
  /// Cover Sheet
  ///
  // Full title of your project
  title_long: "Decomposition of Supply Networks into Subnetworks for Reducing Computational Complexity in Mixed-Integer Optimization Problems",
  // Shortened title, which is displayed in the header on every page
  title_short: "Decomposition of Supply Networks",
  // The type of your project
  thesis_type: "Bachelor's Thesis",
  // Other information about you and your project
  authors: (
    (
      firstname: "Max",
      lastname: "Katzenberger",
      identification_number: "4008573",
      course: "TINF23B2", // optional
    ), // make sure to keep this comma after the first author if there is only one author!
  ),
  signature_place: "Karlsruhe",
  submission_date: "August 31, 2026",
  processing_period: "June 8, 2026 – August 31, 2026",
  // Commenting out the line below removes the department from the title page
  department: "SCM Optimizer",
  supervisor_company: "Christoph Eckert",
  supervisor_university: "Prof. Dr. Heinrich Braun",

  // Disable the abstract by changing to `abstract: ()`
  // To load the abstract from a file use include("abstract.typ") instead of [...]`
  // If you only want one language, leave the comma at the end -> `("de", "Deutsch", []),` its necessary for syntax of the template
  abstract: (
    ("en", "English", include "abstracts/abstract_english.typ"),
    ("de", "Deutsch", include "abstracts/abstract_german.typ"),
  ),

  // appendices: usage: ("Title", [content] || include("appendix.typ"))
  // change to `appendices: none` to remove appendix
  appendices: (
    ("Proof: Disjointness of Stage Sets", include "appendices/proof_stage_disjointness.typ", <proof-stage-disjointness>),
    ("Variable-Count Estimation", include "appendices/complexity_estimation.typ", <appendix-complexity>),
    ("Solver Configuration", include "appendices/gurobi_configuration.typ", <appendix-gurobi>),
  ),

  // Path/s to references - either .yaml or .bib files
  // * for `.yaml` files see: [hayagriva](https://github.com/typst/hayagriva)
  library_paths: "bibliography.yaml",

  // Specify acronyms here.
  // The key is used to reference the acronym.
  // The short form is used every time and the long form is used
  // additionally the first time you reference the acronym.
  acronyms: (
    (key: "MILP", short: "MILP", long: "Mixed-Integer Linear Programming"),
    (key: "LP", short: "LP", long: "Linear Programming"),
    (key: "SCM", short: "SCM", long: "Supply Chain Management"),
    (key: "BOM", short: "BOM", long: "Bill of Materials"),
    (key: "DAG", short: "DAG", long: "Directed Acyclic Graph"),
    (key: "SCC", short: "SCC", long: "Strongly Connected Component"),
    (key: "IBP", short: "IBP", long: "Integrated Business Planning"),
    (key: "NP", short: "NP", long: "Nondeterministic Polynomial Time"),
    (key: "FCFS", short: "FCFS", long: "First-Come, First-Served"),
    (key: "BFS", short: "BFS", long: "Breadth-First Search"),
    (key: "POC", short: "PoC", long: "Proof-of-Concept"),
    (key: "DSR", short: "DSR", long: "Design Science Research"),
  ),
)

// ============================================================================
// THESIS STRUCTURE OVERVIEW
// ============================================================================
//
// = Introduction
// == Motivation and Problem
// == Goal and Research Questions
//
// = Theoretical Foundations
// == Mixed Integer Programming
// === Complexity and NP-Hardness                    // Why are MILPs hard, how hard are they, why does Decomposition therefore makes sense (nonlinear time complexity), what is LP Relaxation 
// === Solving Mixed Integer Linear Problems         // How do Solvers solve that, Branch and Bound etc. (just very briefly)
// == SAP Supply Chain Planning
// 
// === Supply Chains as Graphs   // Simple, How does SAP IBP SCM work (check  /Users/i587903/Documents/Arbeit/Praxisphase 5/Repos/engines/ops/snp for the implementation of the sop snp), How Input Tables (no Names, just how it works), Specified Demands, Transport, Productions, ExternalProcurements... (you can also check /Users/i587903/Documents/Arbeit/Praxisphase 5/own_development/graph-setup on how we build a simple graph from the tables), this should be no detailed example, just how SAP IBP works, that we have those input tables, then create a graph and a context from it and then an MILP, which gets sent to extern solvers (Gurobi/Scip/...) and then that solution is interpreted to answer how much to produce .. (the whole mathematical formulation shouldnt be here, it comes in the next chapter)
// === Mathematical Model Formulation // How do we solve the Supply Chain? Make a Milp out of it, example Objective function terms ... (check imlpementation, just the simplest, Demands, Producitons, Stock Level, Procurement, ... (no resources, quote usw)) and their Constraints, Varaibles, Objvalue impact, whole formulation is in appendix (make placeholder for it) just so that reader gets a simple connection between relational Model/graph/RealWorld which you can imagine and the mathematical model
// == Existing Decomposition Methods //which decompositions methods are like the basic theoretical foundations and how do they maintain feasability, (not related work and applications, but just the early general background), Decomposition could be Graph like or MILP like, in the best case something about both and a connection between them. The Generalization is important.
//
// = Related Work //Related Papers that do similar approaches and how they worked, example: in the end research Gap and why we do it.
// = Methodology
// == Research Approach                              // Design Science Research, Goal, Requirements
// == Evaluation Design
// === Metrics                                       // Runtime, Solution Quality (Gap, Objective Value), Memory, Feasibility, Dimensions: Runtime, Complexity, Solution Quality, Memory, Resource and AggregConstraints Splitting Mode, Heuristics (0-4 on/off), iterations(?)
// === Baseline                                      // Monolithic solve without decomposition
// === Benchmark Scenarios                           // Description of test scenarios, size, complexity, source
//
// = Model Design                                    // Main Chapter for how to solve the Problem
// == Problem Analysis                               // Requirements, Challenges for Decomposition, Quality Criteria
// == Concept
// === Graph-based Problem Modelling
// === Decomposition Strategies
// === Two-Phase Solve Approach (Bottom-Up/Top-Down) // Meta Graph etc.
// === Virtual Link Nodes (virtual Procurement/Demand)
// == Link Node Heuristics                           // AND/OR-Nodes, BOM-Scaling
// === Production Cost Aggregation
// === Lead Time Aggregation
// === Max Flow Aggregation
// === Non-Delivery Cost Aggregation
// == Inter Subnet Constraint Handling
// === Explanation (Aggregated Constraints, Resource Capacity Supply)
// === Equal Split                                   // Resplit after didn't use
// === First-Come First-Serve                        // First-come bottom-up vs First-come top-down
// === LP-Relaxation                                 // For splitting
// == Verification
// === Solution Combination
// === Solution Verification                         // Maybe Formal Proof that this leads guaranteed to a valid solution
//
// = Implementation
// == Technologies                                   // Local Setup (Python), Graph Handling, Data Processing (networkx, Polars, Numpy, rm_pybind), MIP Solver (SAP IBP => Gurobi)
// == Architecture
// === Process Pipeline                              // Local Decomposition, Http Solver, ...
// === System Architecture                           // Local Repo: Different Layers, Modules, Data Driven Design, Design-Patterns, CLI-Interface
// == Data Handling                                  // Graph-Representation, Node Types, Edge-Semantics (BOM, Resource-Consumption, Material Flow), Database Tables, Read-in/Write-out, Retain-if, Time Series Attributes: Numpy Operations, Period Indexing, vectorized operations etc.
// == Graph Construction                             // Database-to-Graph: Node/Edge Queries, Complexity
// == Decomposition
// === Cycles, Condensation, etc.
// === Stage Decomposition                           // Stage Assignment (BFS), Stage Grouping, Node Distribution
// === Layer Decomposition                           // Layering via longest-path, Boundary-Layer Computation (Middle, Avg, Balanced, MIP-Balanced), Distribution
// === Cut Harmonization                             // Virtual Procurements, Link Nodes, Meta-Graph
// == Two-Phase Solving
// === Bottom-up                                     // (Request Phase:) Reverse Topological Order, Virtual Demand Injection, Resource Capacity Tracking, Runtime Budget Allocation, Link Node Output Collection (Request Amounts)
// === Top-Down                                      // (Correction/Supply Phase:) Forward Topological Order, Actual Virtual Supply Injection, Solution Refinement (to actual possible)
// == Inter Subnet Constraint Handling
// === Explanation (Aggregated Constraints, Resource Capacity Supply)
// === Equal Split                                   // Resplit after didn't use
// === First-Come First-Serve                        // First-come bottom-up vs First-come top-down
// === LP-Relaxation                                 // For splitting
// == Verification
// === Solution Combination
// === Solution Verification
//
// = Evaluation                                      // Dimensions: Runtime, Complexity, Solution Quality, Memory, Number of Subnetworks, Decomposition mode (none, layer, stage), Decomposition-Mode configurations (middle, avg, balanced, [1,2,3][4,5], ...), Resource and AggregConstraints Splitting Mode, Heuristics (0-4 on/off), Whole Scenario Size/Complexity
//
// Welche Szenarien eignen sich gut
// Welche Szenarien eignen sich nicht gut (Verbesserungsmöglichkeiten)
// 
// = Discussion                                      // Interpretation, Limitations (Overhead, Cycles, Approximations, Shared Capacities), Comparison with Related Work, Threats to Validity
//
// = Conclusion                                      // Summary, Research Questions answered, Practical Impact, Future Work
//
// ============================================================================

// Chapter includes
#include "chapters/01_introduction.typ"
#include "chapters/02_theoretical_foundations.typ"
#include "chapters/03_related_work.typ"
#include "chapters/04_methodology.typ"
#include "chapters/05_design.typ"
#include "chapters/06_implementation.typ"
#include "chapters/07_evaluation.typ"
#include "chapters/08_discussion.typ"
#include "chapters/09_future_work.typ"
#include "chapters/10_conclusion.typ"
