#import "@preview/polylux:0.3.1": *
#import "@preview/diagraph:0.2.1": render as render-graph
#import "slides_template.typ": *
#import "slides_utils.typ": side-by-side
#import "drawings.typ": *

#show link: set text(blue)
#set text(font: "Inria Sans")
#show heading: set text(font: "Vollkorn")
#show raw: set text(font: "JuliaMono")

#show: clean-theme.with(
  logo: image("images/logo.png"),
  short-title: [DRL & Graphs],
  footer: [Travis Hammond - Rijksuniversiteit Groningen],
)

#let textsize = 20pt
#let topspace = 30pt

#set text(size: textsize)

// Helper function to show figures in 11pt text-size
#let ogfigure(fig) = [
  #set text(size: 10pt) 
  #box(width: 100%, height: 90%)[
    #align(horizon)[
      #figure(fig)
    ]
  ]
]

#title-slide(
  title: [Combining Graph-Based Planning and Deep Reinforcement Learning],
  subtitle: "Masters Thesis",
  authors: "Travis Hammond",
  date: "September 2024",
)

#slide(title: "Outline")[
    // Why not include an outline?
    #polylux-outline(padding: 1em, enum-args: (tight: false))
]

// Rust!
// Demo!



// Questions:
// does this still suffer from worse asymptotic performance?
// - yes, its behavior / policy is influenced by the model and
//   the model can be bad --> leads to bad data
// known weakpoints:
// - chicken / egg problem in exploration BUT: potential here
// - no learned distance measure BUT: proof of concept exists





/// SECTION
#new-section-slide("Introduction")


#slide(title: "The Building Blocks: Deep Reinforcement Learning")[
  #side-by-side[
    #v(topspace)

    Learn a #emph("global solution") over all states
    - i.e. a value or action-value function
    Operates on atomic (low-level) actions

    #v(50pt)

    Fails at long-horizon planning
    - i.e. many actions into the future

    Can we fix that?
  ][
    #ogfigure(agent-environment-loop)
  ]
]
#slide(title: "The Building Blocks: Deep Reinforcement Learning")[
  #side-by-side[
    #v(topspace)

    Incoming data stream to train the deep neural network violates the #strong("i.i.d") assumption:
    
    - Distribution determined by current policy

    #v(30pt)

    Replay Buffers are commonly used to partially restore this assumption and to improve sample efficiency.
  ][
    #ogfigure(online-vs-offline-learning)
  ]
]


#slide(title: "The Building Blocks: Hierarchical RL")[
  #side-by-side[
    #v(topspace)
    Abstract over time, i.e. sequences of actions
    #v(-10pt)
    #image("images/hierarchical-rl-diagram-MBRL-survey.png")
    @MBRL-Survey
  ][
    #ogfigure(agent-environment-loop)
  ]
]
#slide(title: "The Building Blocks: Hierarchical RL")[
  #side-by-side[
    #v(topspace)
    An elegant solution: parameterize the goal!
    - Goal-Conditioned RL (aka UVFA)

    #v(30pt)

    Some challenges:
    - Even more general -> harder to train
      - Even shorter horizon!

    - How to generate subgoals?
      - Suitable level of abstraction

    // - Algorithm architecture
    // TODO: GoExplore, HAC, Feudal
  ][
    #ogfigure(agent-environment-loop-goal-conditioned)
  ]
]


#slide(title: "The Building Blocks: Model-Based RL")[
  #side-by-side[
    #v(topspace)
    Idea is to learn a model of the environment

    With #emph("reversible access")
    - Can simulate taking actions
    - Can repeatedly plan forward from any state

    #v(30pt)

    Benefits
    - Better sample efficiency
    - Better at long-horizon tasks
    - Interpretable Model
  ][
    #ogfigure(agent-model-environment-loop)
  ]
]
#slide(title: "The Building Blocks: Model-Based RL")[
  #side-by-side[
    #v(topspace)
    Idea is to learn a model of the environment

    With #emph("reversible access")
    - Can simulate taking actions
    - Can repeatedly plan forward from any state

    #v(30pt)

    Benefits only IF the model is good, otherwise:
    - Model sampling becomes the burden
    - Worse performance

    Bad model --> Bad influence
  ][
    #ogfigure(agent-model-environment-loop)
  ]
]


#slide(title: "The Building Blocks: Graph-Based Planning")[
  #side-by-side[
    #v(topspace)
    Meanwhile, we all remember Dijkstra?
    - Long-horizon planning --> No problem!

    #v(40pt)

    Nice properties:
    - Stable performance: $O(|E| + |V|log|V|)$
    - Guarantees (completeness & optimality)
  ][
    #ogfigure(example-graph)
  ]
]
#slide(title: "The Building Blocks: Graph-Based Planning")[
  #side-by-side[
    #v(topspace)
    Meanwhile, we all remember Dijkstra?
    - Long-horizon planning --> No problem!

    #v(40pt)

    But...
    - Requires handcrafted graph-representation
      - Set of nodes
      - Set of weights / edges
    - How to actually move between nodes?
  ][
    #ogfigure(example-graph)
  ]
]


#slide(title: "The Idea: Combine Graph-Based Planning and DRL")[
  #side-by-side[
    #box(width: 100%, height: 90%)[
      #set text(size: 10pt)
      #align(horizon)[
        #v(70pt)
        #figure(agent-environment-loop-goal-conditioned)
        #v(60pt)
        #set text(size: 19pt)
        Low-level Controller: Reaches short-horizon subgoals via goal-conditioned RL.
      ]
    ]
  ][
    #box(width: 100%, height: 90%)[
      #set text(size: 10pt)
      #align(horizon)[
        #figure(example-graph)
        #v(20pt)
        #set text(size: 19pt)
        High-level Controller: Solves long-horizon tasks via sequencess of short-horizon subgoals.
      ]
    ]
  ]
]









/// SECTION
#new-section-slide("Methods")


#slide(title: "Actor-Critic Architecture (DDPG)")[
  #side-by-side[
    #v(topspace)
    Components:
    - Replay Buffer
    - Actor(State) --> Action
    - Critic(State, Action) --> Reward

    #v(20pt)

    Benefits:
    - Loosly coupled --> allows multiple actors
    - Can handle continuous environments
    - Training stability
  ][
    #ogfigure(actor-critic-architecture)
  ]
]


#slide(title: "Big Idea: The Critic is the Distance Measure")[
  #side-by-side[
    #ogfigure(actor-critic-architecture)
    // explain why the critic is a good proxy for the distance
  ][
    #ogfigure(example-graph)
  ]
]
#slide(title: "Big Idea: The Actor is the Controller")[
  #side-by-side[
    #ogfigure(actor-critic-architecture)
    // explain how the actor takes the role of the controller
    // and how that piece is missing for graph-algorithms
  ][
    #ogfigure(example-graph)
  ]
]
#slide(title: "Big Idea: The Buffer contains the Nodes")[
  #side-by-side[
    #ogfigure(actor-critic-architecture)
    // explain how the actor takes the role of the controller
    // and how that piece is missing for graph-algorithms
  ][
    #ogfigure(example-graph)
  ]
]


#slide(title: "Challenge: Graph Sparsification")[
  #side-by-side[
    #box(width: 100%, height: 90%)[
      #image("images/SoRB-illustration.png")
      #v(-30pt)
      #image("images/SGM-illustration.png")
      @SoRB@SGM
    ]
  ][
    #ogfigure(example-graph)
  ]
]
#slide(title: "Challenge: Graph Sparsification")[
  #side-by-side[
    #v(topspace)
    - Online sparsification algorithm $O(|V|^2)$ @SGM
    - For any asymmetric distance function
    - Proof of error bound in shortest-paths
    
    #v(15pt)
    #[
      #set text(size: 16pt) 
      Two states are redundant if they are interchangeable as both starting states and goal states.
    ]

    $ C_("out") (s_1, s_2) = max_omega abs( d(s_1, omega) - d(s_2, omega) ) lt.eq tau $
    $ C_("in") (s_1, s_2) = max_omega abs( d(omega, s_1) - d(omega, s_2) ) lt.eq tau $
  ][
    #box(width: 100%, height: 90%)[
      #scale(ogfigure(SGM-node-merging), x: 180%, y: 180%)
      @SGM
    ]
  ]
]
#slide(title: "Challenge: Graph Sparsification")[
  #let resize = 100%
  #box(width: 100%, height: 90%)[
    #v(35pt)
    A full Replay Buffer sparsified with $tau in {0.32, 0.40, 0.48}$
    #set text(size: 10pt) 
    #scale(
      figure(
        grid(
          columns: (auto, auto, auto, auto),
          rows: 1,
          image("images/SGM/full-buffer.png"),
          image("images/SGM/full-buffer-only-graph-tau32.png"),
          image("images/SGM/full-buffer-only-graph-tau40.png"),
          image("images/SGM/full-buffer-only-graph-tau48.png"),
        ),
      ),
      x: resize,
      y: resize,
    )
  ]

]


#slide(title: "Building Block Overview")[
  #side-by-side[
    #box(width: 100%, height: 90%)[
      #set text(size: 10pt) 
      #figure(agent-environment-loop-goal-conditioned)
      #figure(agent-model-environment-loop)
    ]
  ][
    #box(width: 100%, height: 90%)[
      #v(20pt)
      #set text(size: 10pt) 
      #scale(figure(SGM-node-merging), x: 150%, y: 150%)
      #figure(actor-critic-architecture)
    ]
  ][
    #ogfigure(example-graph)
  ]
]
#slide(title: "HGB-DDPG (Hierachical-Graph-Based DDPG)")[
  #side-by-side[
    #v(topspace)

    Graph representation:
    - Nodes from the Buffer
    - Edge-weights from the Critic
      - actually we provide the true distances :(
    - Sparsified via SGM + MAXDIST
    
    Cleanup:
    - Edges that failed to traverse are removed
    - Reconstruct graph at fixed intervals
  ][
    #v(-10pt)
    #ogfigure(hierarchical-graph-based-ddpg)
  ]
]








/// SECTION
#new-section-slide("Experiment Setup")



#slide(title: "PointEnv Environment")[
  #side-by-side[
    #ogfigure(image("images/PointEnvs/Hooks-far.png"))
  ][
    #let resize = 75%
    #box(width: 100%, height: 90%)[
      #set text(size: 10pt) 
      #v(-35pt)
      #scale(
        figure(
          grid(
            columns: (auto, auto, auto),
            rows: 3,
            image("images/PointEnvs/Empty-close.png"),
            image("images/PointEnvs/OneLine-close.png"),
            image("images/PointEnvs/Hooks-close.png"),
        
            image("images/PointEnvs/Empty-mid.png"),
            image("images/PointEnvs/OneLine-mid.png"),
            image("images/PointEnvs/Hooks-mid.png"),
        
            image("images/PointEnvs/Empty-far.png"),
            image("images/PointEnvs/OneLine-far.png"),
            image("images/PointEnvs/Hooks-far.png"),
          ),
        ),
        x: resize,
        y: resize,
      )
    ]
  ]
]


#slide(title: "H-DDPG vs HGB-DDPG")[
  #side-by-side[
    #v(-40pt)
    #ogfigure(actor-critic-architecture-hierarchical)
    #v(-40pt)
    The DDPG setting is Goal-Conditioned, but the goal is simple the end-goal.
  ][
    #v(-10pt)
    #ogfigure(hierarchical-graph-based-ddpg)
  ]
]


#slide(title: "Challenges")[
  #side-by-side[
    #v(topspace)
    #strong("In-Distribution Challenges")
    
    Train the agent on one of the 9 environment settings, and measure test-time performance on the same environment.
  ][
    #v(topspace)
    #strong("Out-of-Distribution Challenges")
    
    Pretrain the agent on the easiest of the 9 environment settings, and measure test-time performance on a harder environment.
  ]
]


#slide(title: "Caveats")[
  #side-by-side[
    #v(topspace)
    We side-step the learned distance measure:
    - Assumed access to true distance function

    We assume ability to start with a buffer of good quality training data
    - uniformly-distributed
    - decent amount of rewarded transitions
  ][
  ]
]









/// SECTION
#new-section-slide("Results")


#slide(title: "In-Distribution Challenges")[
  #side-by-side[
    #v(topspace)
    - H-DDPG baseline (orange)
    - HGB-DDPG algorithm (blue)
    - PointEnvs "close".

    #v(30pt)
    We see the expected disadvantage of model-based methods: 

    - Asymptotic performance is worse
    - Overhead of subgoals too high
    - Not suitable for short horizon tasks
  ][
    #box(width: 100%, height: 90%)[
      #let resize = 85%
      #set text(size: 10pt) 
      #v(-75pt)
      #scale(
        figure(
          grid(
            columns: (15em, auto),
            rows: (15em, 15em, 15em),
            image("images/PointEnvs/Empty-close.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-empty-close.png"),
            image("images/PointEnvs/OneLine-close.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-oneline-close.png"),
            image("images/PointEnvs/Hooks-close.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-hooks-close.png"),
          ),  
        ),
        x: resize,
        y: resize,
      )
    ]
  ]
]
#slide(title: "In-Distribution Challenges")[
  #side-by-side[
    #v(topspace)
    - H-DDPG baseline (orange)
    - HGB-DDPG algorithm (blue)
    - PointEnvs "mid".

    #v(30pt)
    We see the expected disadvantage of model-based methods: 

    - Asymptotic performance is worse
    - Overhead of subgoals too high
    - Not suitable for short horizon tasks
  ][
    #box(width: 100%, height: 90%)[
      #let resize = 85%
      #set text(size: 10pt) 
      #v(-75pt)
      #scale(
        figure(
          grid(
            columns: (15em, auto),
            rows: (15em, 15em, 15em),
            image("images/PointEnvs/Empty-mid.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-empty-mid.png"),
            image("images/PointEnvs/OneLine-mid.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-oneline-mid.png"),
            image("images/PointEnvs/Hooks-mid.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-hooks-mid.png"),
          ),
        ),
        x: resize,
        y: resize,
      )
    ]
  ]
]
#slide(title: "In-Distribution Challenges")[
  #side-by-side[
    #v(topspace)
    - H-DDPG baseline (orange)
    - HGB-DDPG algorithm (blue)
    - PointEnvs "far".

    #v(30pt)
    We see the expected disadvantage of model-based methods: 

    - Asymptotic performance is worse
    - Overhead of subgoals too high
    - Not suitable for short horizon tasks
  ][
    #box(width: 100%, height: 90%)[
      #let resize = 85%
      #set text(size: 10pt) 
      #v(-75pt)
      #scale(
        figure(
          grid(
            columns: (15em, auto),
            rows: (15em, 15em, 15em),
            image("images/PointEnvs/Empty-far.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-empty-far.png"),
            image("images/PointEnvs/OneLine-far.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-oneline-far.png"),
            image("images/PointEnvs/Hooks-far.png"),
            image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-hooks-far.png"),
          ),
        ),
        x: resize,
        y: resize,
      )
    ]
  ]
]


#slide(title: "Out-of-Distribution Challenges")[
  #side-by-side[
    #v(topspace)
    - H-DDPG baseline (orange)
    - HGB-DDPG algorithm (blue)
    - Pretrained on PointEnv-Empty-close.

    #v(30pt)
    We see the advantages of model-based methods: 

    // - Asymptotic performance is worse
    // - Overhead of subgoals too high
    // - Not suitable for short horizon tasks
  ][
    #box(width: 100%, height: 90%)[
      #let resize = 85%
      #set text(size: 10pt) 
      // #v(-15pt)
      #scale(
        figure(
          grid(
            columns: (15em, auto),
            rows: (15em, 15em),
            image("images/PointEnvs/OneLine-mid.png"),
            image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-oneline-mid.png"),
            image("images/PointEnvs/OneLine-far.png"),
            image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-oneline-far.png"),
          ),
        ),
        x: resize,
        y: resize,
      )
    ]
  ]
]
#slide(title: "Out-of-Distribution Challenges")[
  #side-by-side[
    #v(topspace)
    - H-DDPG baseline (orange)
    - HGB-DDPG algorithm (blue)
    - Pretrained on PointEnv-Empty-close.

    #v(30pt)
    We see the advantages of model-based methods: 

    // - Asymptotic performance is worse
    // - Overhead of subgoals too high
    // - Not suitable for short horizon tasks
  ][
    #box(width: 100%, height: 90%)[
      #let resize = 85%
      #set text(size: 10pt) 
      // #v(-15pt)
      #scale(
        figure(
          grid(
            columns: (15em, auto),
            rows: (15em, 15em),
            image("images/PointEnvs/Hooks-mid.png"),
            image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-hooks-mid.png"),
            image("images/PointEnvs/Hooks-far.png"),
            image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-hooks-far.png"),
          ),
        ),
        x: resize,
        y: resize,
      )
    ]
  ]
]



#slide()[
  #side-by-side[
    #box(width: 100%, height: 90%)[
      #strong("Results on In-Distribution Challenges")
      #show table.cell.where(x: 2, y: 1): strong
      #show table.cell.where(x: 4, y: 2): strong
      #show table.cell.where(x: 4, y: 3): strong
      #show table.cell.where(x: 4, y: 4): strong
      #show table.cell.where(x: 4, y: 5): strong
      #show table.cell.where(x: 4, y: 6): strong
      #show table.cell.where(x: 4, y: 7): strong
      #show table.cell.where(x: 4, y: 8): strong
      #show table.cell.where(x: 2, y: 9): strong
      #show table.cell.where(x: 4, y: 9): strong
      #figure(
        table(
          columns: 6,
          stroke: (x: none),
          row-gutter: (2.2pt, auto),
          ..csv("data/data_successes.csv").flatten(),
        ),
      )
    ]
  ][
    #box(width: 100%, height: 90%)[
      #strong("Results on Out-of-Distribution Challenges")
      #show table.cell.where(x: 2, y: 1): strong
      #show table.cell.where(x: 4, y: 1): strong
      #show table.cell.where(x: 2, y: 2): strong
      #show table.cell.where(x: 4, y: 2): strong
      #show table.cell.where(x: 4, y: 3): strong
      #show table.cell.where(x: 2, y: 4): strong
      #show table.cell.where(x: 4, y: 4): strong
      #show table.cell.where(x: 4, y: 5): strong
      #show table.cell.where(x: 4, y: 6): strong
      #show table.cell.where(x: 4, y: 7): strong
      #show table.cell.where(x: 4, y: 8): strong
      #show table.cell.where(x: 4, y: 9): strong
      #figure(
        table(
          columns: 6,
          stroke: (x: none),
          row-gutter: (2.2pt, auto),
          ..csv("data/data_successes_out-of-dist.csv").flatten(),
        ),
      )
    ]
  ]
]


#slide(title: "Model Interpretability")[
  #side-by-side[
    #box(width: 100%, height: 90%)[
      #let resize = 85%
      #set text(size: 10pt) 
      #v(-30pt)
      #scale(
        figure(
          grid(
            columns: 2,
            rows: 2,
            image("images/PointEnvs/Hooks-far.png"),
            image("images/PointEnv-Graph/PointEnv-Hooks-far--plan.png"),
            image("images/PointEnv-Graph/PointEnv-Hooks-far--buffer.png"),
            image("images/PointEnv-Graph/PointEnv-Hooks-far--graph-plan.png"),
          ),
        ),
        x: resize,
        y: resize,
      )
    ]
  ][
    #box(width: 100%, height: 90%)[
      #let resize = 85%
      #set text(size: 10pt) 
      #v(-30pt)
      #scale(
        figure(
          grid(
            columns: 2,
            rows: 2,
            image("images/PointEnvs/Hooks-far.png"),
            image("images/PointEnv-Graph/PointEnv-Hooks-far--50e-plan.png"),
            image("images/PointEnv-Graph/PointEnv-Hooks-far--50e-buffer.png"),
            image("images/PointEnv-Graph/PointEnv-Hooks-far--50e-graph-plan.png"),
          ),
        ),
        x: resize,
        y: resize,
      )
    ]
  ]
]









/// SECTION
#new-section-slide("Conclusion")


#slide(title: "Successes")[
  #v(topspace)
  Performance improvement for long-horizon tasks.

  The model is interpretable, even editable.

  Learning can transfer to new environments (no retraining).
]


#slide(title: "Caveats: Learned Distances")[
  #side-by-side[
    #v(topspace)
    Learned distances are side-stepped by providing the true underlying (euclidean) distance function.

    Proof of concept already shown by @SoRB@SGM, but implementation exceeded the scope of a MSc thesis.

    Computationally expensive
  ][
    #v(topspace)
  ]
]
#slide(title: "Future Research: Exploration")[
  #side-by-side[
    #v(topspace)
    Potential for exploration improvements, e.g:
    - Aiming for "frontiers" in the graph
    - Keeping statistics on novel nodes found

    A solution here would replace our need for pre-filling the replay buffer with uniformly distributed data
  ][
    #ogfigure(image("images/SGM/bad-buffer.png"))
  ]
]
// #slide(title: "Future Research: 3-Phase Training")[
//   #v(topspace)
//   Phase 1 (Pretraining):
//   - Attempt to reach previously visited nodes (Do not actively explore)
//   - Improve success rate until converging

//   Phase 2: (Exploration)
//   - Attempt to reach frontiers of the graph (Randomly explore from there)
//   - Keep per-node statistics & visit high-potential nodes
//   - Continue until the number of new novel nodes converges to zero

//   Phase 3 (Exploitation)
//   - Reach goals & cleanup graph
// ]







/// SECTION
#new-section-slide("Questions")


#slide(title: "Bibliography")[
    #bibliography(title: none, "refs.bib")
]

// #slide(title: "That's it!")[
//   Consider giving my repository #link("https://github.com/dashdeckers/graph_rl")[a GitHub star #text(font: "OpenMoji")[#emoji.star]] or open an issue if you run into bugs or have feature requests.
// ]





