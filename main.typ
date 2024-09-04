#import "template.typ": ieee

// Diagrams
#import "drawings.typ": *

// Pseudocode
#import "@preview/lovelace:0.2.0": algorithm, pseudocode-list, setup-lovelace
#show: setup-lovelace

// Tables Styling
#show table.cell.where(y: 0): set text(weight: "bold")


#show: ieee.with(
  title: [Combining Graph-Based Planning and Deep Reinforcement Learning],
  abstract: [
Historically, planning and reinforcement learning have had similar goals but have lived in a dichotomy of research fields, having complimentary strengths and weaknesses but with no way of combining them in a fundamental way. Motivated by recent attempts to combine the fields of graph-based planning and deep reinforcement learning, we provide an overview of the methods involved and experimentally show how this approach provides a number of quantitative benefits in terms of performance on in-distribution- as well as on out-of-distribution- challenges and qualitative benefits in terms of model interpretability as well as the ability to manually edit this model, allowing to incorporate domain-knowledge into the trained model. To achieve this, we contribute to the Candle deep learning framework and thus to the overall reinforcement learning ecosystem of the Rust programming language.
  ],
  authors: (
    (
      name: "Travis Hammond",
      department: [Faculty of Science and Engineering],
      organization: [University of Groningen],
      location: [Leipzig, Germany],
      email: "t.hammond@student.rug.nl"
    ),
    (
      name: "Dr. Davide Grossi",
      department: [Faculty of Science and Engineering],
      organization: [University of Groningen],
      location: [Groningen, Netherlands],
      email: "d.grossi@rug.nl"
    ),
    (
      name: "Dr. Matthia Sabatelli",
      department: [Faculty of Science and Engineering],
      organization: [University of Groningen],
      location: [Groningen, Netherlands],
      email: "m.sabatelli@rug.nl"
    ),
  ),
  index-terms: (
    "reinforcement learning",
    "machine learning",
    "deep learning",
    "actor-critic",
    "planning",
    "graph theory",
    "rust language",
  ),
  bibliography-file: "refs.bib",
)

#let spaced_eq(eq, l) = [
  #v(15pt)
  #eq #label(l)
]


= Introduction


Reinforcement learning (RL), especially deep reinforcement learning (DRL), has demonstrated the ability to learn optimal policies from raw, high-dimensional input data such as images without requiring any domain knowledge @Atari@NatureATARI, but it has consistently shown its success to be limited to short-horizon tasks. The further away the goal is, quantified in terms of how many actions and timesteps are required to reach it, the harder it becomes to train RL algorithms to be successful in reaching this goal. This is evident in the performance of RL algorithms over time across the famous ATARI benchmark @Atari: the games that required long-distance planning took the longest time to be solved. Furthermore, as is generally the case with neural-networks, these algorithms return black-box policies which are difficult or even impossible to interpret which is a problem that becomes more important the more safety or business critical the deployment of that policy becomes @Interpretable-RL.

Classical graph-based planning on the other hand has converged to efficient, correct and provably optimal search algorithms that easily find solutions to long-horizon tasks as early as 1956 with algorithms such as Dijkstra's @Dijkstra and later A\* @A-Star. However, these algorithms require the environment to be defined in terms of a graph in which the possibly raw, high-dimensional state space of the real world is abstracted away into a set of nodes and the transition dynamics are abstracted away into a set of edges connecting these nodes. While this graph then lends itself nicely to the analysis and interpretation of resulting plans, it has to be hand-crafted with domain-specific knowledge and the quality of this graph has a deciding influence on the quality of the solution. Further, actually executing this plan still requires a controller with the ability to select low-level actions in the real world to transition between these abstract nodes towards the goal.

It seems as though these fields attempt to achieve the same goal and their solutions to the problem complement each other quite nicely in terms of their strengths and weaknesses. Having started from different assumptions, the fields of planning and reinforcement learning have developed their own methodologies and then found each other in a field that become known as model-based reinforcement learning @MBRL-Survey at least as early as 1990 @Early-MBRL. In this thesis we focus on one particular approach to combining the fields of deep reinforcement learning and graph-based planning by means of hierarchical, model-based RL in which a graph-based representation of the environment is built up over time from past experiences and a non-parametric high-level controller (i.e. a graph-search algorithm) creates plans consisting of short-horizon sub-goals which are delegated to a low-level controller (i.e. a reinforcement learning agent) @SoRB@SGM.

We first provide an introduction to the field of deep reinforcement learning in @section-RL, giving a primer on each of the concepts necessary to understand the final algorithms, as well as a quick introduction to graphs and the most relevant graph-based planning algorithms and their performance characteristics in @section-planning. In @section-prior-work we provide an overview of how different works so far have tackled this idea and an in-depth summary of the most important papers that have been published on this particular approach building up to #cite(<SoRB>, form: "normal") and #cite(<SGM>, form: "normal"). We then include an additional section on the role of the Rust programming language in our work in @section-rust, as we did spend a considerable amount of effort promoting the field of deep reinforcement learning in the ecosystem of this young but promising language, including an open-source contribution to a major machine-learning framework.

Finally, we provide an implementation of this graph-based reinforcement learning approach in Rust, based on the implementations by #cite(<SoRB>, form: "prose") and #cite(<SGM>, form: "prose"). We show that the graph-based approach provides a number of quantitative benefits in terms of performance on increasingly difficult (in terms of longer horizon) environment settings as well as the performance on more difficult settings after training on easier ones, showcasing the ability of zero-shot generalization to- and thus robustness in the face of- slightly different environments. We also show a number of qualitative benefits such as the interpretability of the policy due to the ability to inspect the graph and the current plan, noting that the graph can even be edited by hand if necessary, as well as the flexibility of the trained algorithm to reach any given goal due to the goal-conditioned nature. For this, we introduce our methods in @section-methods and show our results in @section-results. We finish with a discussion and a note on future work in particular on aspects we did not cover in this thesis due to time constraints in @section-discussion. 

The main research questions we wish to answer here are 1) can we combine the strengths of graph-based planning and deep reinforcement learning and 2) does this provide us with quantitative benefits in terms of model performance as well as 3) qualitative benefits in terms of model interpretability?


= Reinforcement Learning <section-RL>


Reinforcement learning can be loosely defined in terms of a few key components. We define the decision maker as the #emph("agent"), who selects #emph("action")s based on #emph("observation")s and #emph("reward")s provided by the #emph("environment"). The environment in turn, comprising everything outside of the agent (including, for example, its sensors), receives these actions and modifies its underlying state in some way, returning a new set of observations and rewards. It is the job of the agent to learn and adapt its behavior, or #emph("policy"), in such a way as to maximize the total reward over the full length of an episode (which can possibly continue forever). See @fig-agent-environment for a diagram visualizing this coupled, dynamic process @RL.

// reward timestep notation differences (most common: R_0 does not exist)
// https://ai.stackexchange.com/questions/43550/how-can-reward-at-time-step-t-can-be-a-function-of-a-state-at-time-step-t1

#figure(
  agent-environment-loop,
  caption: [The agent-environment loop. The dotted line indicates where the loop begins, bold lines indicate the initial flow of data. The first observation $O_t$ (maybe from a newly initialized environment) is passed to the agent which responds with an action $A_t$. The environment then responds with a new observation $O_(t+1)$ and reward $R_(t+1)$ which are passed to the agent, and the process is repeated. After the first timestep, the agent uses the reward $R_(t+1)$ to update its behavior ($R_0$ does not exist).],
  placement: auto,
)<fig-agent-environment>


== Markov Decision Process <section-MDPs>


We can more strictly define these concepts in terms of a Markov Decision Process (MDP) @MDP, a mathematical framework which helps formalize the notion of maximizing reward by sequential decision making in a dynamic environment that is influenced by the actions taken @RL.

In this idealized formalization of the MDP we will often talk about #emph("state")s ($S_t$), which represent the true underlying state of the environment. What the agent in fact receives are #emph("observation")s ($O_t$) which are not necessarily the same as the true underlying states for many possible reasons, e.g.:

- An embodied agent is in some true state in the real world, but its observations are distorted by imperfect sensors.
- A virtual agent receives an observation from a game showing an empty room, but the true state includes a key located off-screen.

In fact, an MDP is usually defined in terms of the true underlying state because many of its mathematical proofs relies on the state having the #emph("Markov Property"), which says that the state must include information about all aspects of the past agent–environment interaction that make a difference for the future @RL. This obviously does not reflect reality (see the two examples above) and there are certain ways to attempt to reconcile the reality of the partially observable world with the theoretical reliance on the Markov property but these are outside the scope of this thesis and from here on we will use the terms #emph("state") and #emph("observation") interchangeably, excused by the fact that in the environments we investigate the observations do in fact coincide with the true states.

We define the agent and environment interactions to take place at discrete time steps ($t=0, 1, 2, 3, ...$). At each time step $t$, the agent receives a state $S_t$ which is sampled from the state space $cal(S)$ on the basis of which it chooses an action $A_t$ from the actions space $cal(A)$. This action affects the environment in some way that changes the underlying state and the corresponding numerical reward signal to produce $S_(t+1)$ and $R_(t+1) in RR$, where the reward is a function of the state-action-next-state triple $R: cal(S) times cal(A) times cal(S) arrow RR$. These interactions produce a #emph("trajectory"):

#spaced_eq(
  $ S_0, A_0, R_1, S_1, A_t, R_2, S_2, A_2, R_3, ... $,
  "eq-trajectory",
)

\
which unrolls into a sequence of #emph("transitions"):

#spaced_eq(
  $
    S_0, A_0, R_1, &S_1                             && "Transition 1" \
                   &S_1, A_1, R_2, S_2 quad quad    && "Transition 2" \
  $,
  "eq-transitions",
)

\
In a #emph("finite") MDP that satisfies the Markov property, in which the sets of states, actions and rewards ($cal(S), cal(A), "and" RR$) each contain a finite number of elements, the dynamics of the environment can be fully described by a probability distribution that depends only on the previous state and action:

#spaced_eq(
  math.equation(block: true, numbering: none)[
  	$p(s',r|s,a) eq.def Pr{S_t=s', R_t=r | S_(t-1)=s, A_(t-1)=a},$	
  ],
  ""
)

\
for all $s',s in cal(S)$, $r in RR$, and $a in cal(A)$ @RL. This restriction on each state to include any and all information that affects the next state and reward is another way of formulating the Markov property.


== Episodic vs Continuous Tasks <section-episodic-continuous-tasks>


#emph("Episodic"), or sometimes called #emph("finite-horizon"), tasks are those that end in a final time step $T$, where $T$ is a finite, random variable, while #emph("continuous") tasks are those that don't end or at least not in any meaningful timelimit. This makes a difference when reasoning about the behavior of different algorithms because, as we will discuss in @section-returns-rewards, we often talk about the agent maximizing the total reward and in an infinite timeframe the total reward can itself easily become infinite. So to simplify the math, or to reason about these situations, we either consider finite horizon tasks or infinite horizon tasks with #emph("discounted") rewards @RL.


== Discrete vs Continuous Action Spaces <section-discrete-continuous-actions>


Tasks can also be differentiated in terms of the domain of the action space $cal(A)$, which could consist of a discrete, finite set of actions $A_t in {A_0, A_1, ... A_n}$ at each timestep, a continuous range $A_t in [A_min, A_max]$. As we can imagine, tasks with a continuous action space are typically more difficult to learn and require different kinds of algorithms. In this thesis we will consider the case of continuous action spaces.


== Returns & Rewards <section-returns-rewards>


We can formulate what we wish the agent to achieve by designing a suitable reward function. This reward function is unknown to the agent and therefore part of the environment @RL. The goal of the agent is to maximize the #emph("expected return") which, in the simplest case and for #emph("undiscounted") and #emph("episodic") environments, is simply the #emph("expected value") of the #emph("cumulative sum") of rewards from any given starting state:

#spaced_eq(
  $ G_T eq.def R_(t+1) + R_(t+2) + R_(t+3) + ... + R_(T) $,
  "eq-return-episodic"
)

\
where $G_T$ is the return at timestep $T$. Note that we omit the expectation operator for simplicity. An episode is a sequence of agent-environment interactions that ends when the environment transitions into a #emph("terminal state"), $S_T in cal(S)^+$, which is defined as a state which transitions only into itself and which provides no reward. Practically, when the environment reaches a terminal state (regardless of whether this means it was successful or not) it resets and a new episode begins, providing some initial observation $O_0$ and no reward, from which the agent may again attempt to maximize its return.

In the case of #emph("continuous") environments, we can define the expected return to be the cumulative sum of #emph("discounted") rewards:

#spaced_eq(
  $ G_T eq.def R_(t+1) + gamma R_(t+2) + gamma^2 R_(t+3) + ... = sum^infinity_(k=0) gamma^k R_(t+k+1) $,
  "eq-return-continuous"
)

\
where $gamma in [0, 1)$ is the #emph("discount rate") that determines how much future rewards are discounted, that is, how much less a future reward is worth at the present compared to an immediate reward of the same value. To be exact, a reward $R_k$ received $k$ time steps from the present is now only worth $R_k dot gamma^(k-1)$. For example, when $gamma = 0$ then only the immediate next reward $R_(t+1)$ is important to the agents goal, so it optimizes its policy greedily to pick actions $A_t$ only such that $R_(t+t)$ is maximized. On the other hand when $gamma$ approaches $1$, the agent becomes more aware of the value of potential future rewards which might lead to greater total rewards than the greedy perspective.

We can see how this term helps us define the notion of discounted future rewards, but this also helps us deal with any potential infinite rewards: as long as $0 lt.eq gamma < 1$, this term has a finite value. 

// Keeping in mind that $G_T=0$, the term @eq-return-continuous can also be written recursively as follows:

// #spaced_eq(
//   $ G_t eq.def R_(t+1) + gamma G_(t+1) $,
//   "eq-return-recursive"
// )

\
Because we defined the terminal state to be a special state that transitions only into itself and generates only rewards of zero, we can combine both the episodic as well as the continuous tasks into a single notation:

#spaced_eq(
  $ G_T eq.def sum^T_(k=t+1) gamma^(k-t-1) R_k, $,
  "eq-return-unified"
)

\
where either $T=infinity$ or $gamma = 1$, but not both. The case of both continuous and undiscounted tasks is out of the scope of this thesis. 


== Policies & Value Functions <section-policies-value-funcs>


#figure(
  algorithm-policy-environment-loop,
  caption: [The same agent-environment loop as in @fig-agent-environment, but here the agent is expanded to show that it consists of a policy $pi$ which defines the actions $A_t$ to take, given an observation $O_t$ and a learning algorithm which defines how the policy is updated as a consequence of the resulting observation $O_(t+1)$ and reward $R_(t+1)$.],
  placement: auto,
)<fig-algorithm-policy-environment>

To achieve the aim of maximizing the expected return, as we defined it in the previous section, the agent will need to adapt its behavior, or #emph("policy"), based on the feedback it receives. A reinforcement learning algorithm specifies how the policy is updated as a result of the experiences collected @RL. @fig-algorithm-policy-environment shows the distinction between the algorithm and the policy. A policy, denoted $pi$, is defined as a probability density function over the action space for every possible state. If the agent is following policy $pi$ at time $t$, then $pi(a|s)$ is the probability that $A_t = a$ if $S_t = s$ @RL.

Reinforcement learning algorithms distinguish themselves, among other aspects, from planning methods by learning a #emph("global") solution over all states, not just those states relevant to the solution @MBRL-Survey, and there are two common ways to formalize this: As a #emph("value function") $v_pi (s)$ which is defined over states or as an #emph("action-value function") $q_pi (s, a)$ which is defined over state-action pairs. For MDPs, these can be formally defined:

#spaced_eq(
  $
    v_pi (s) &eq.def EE_pi [G_t | S_t = s] \
             &eq.def EE_pi [ sum^infinity_(k=0) gamma^k R_(t+k+1) | S_t = s] \
  $,
  "eq-value-func"
)
#spaced_eq(
  $
    q_pi (s, a) &eq.def EE_pi [G_t | S_t = s, A_t = a] \
                &eq.def EE_pi [ sum^infinity_(k=0) gamma^k R_(t+k+1) | S_t = s, A_t = a] \
  $,
  "eq-q-func"
)

\
for all $s in cal(S)$.

We can see that for discrete action spaces, the (so-far) optimal policy can be derived e.g. from $q_(pi)(s, a)$ by taking the max over the set of possible actions from a given state while for continuous action spaces this is not straightforward and requires a different approach we will discuss in @section-methods.


// https://ai.stackexchange.com/questions/10474/what-is-the-relation-between-online-or-offline-learning-and-on-policy-or-off
== Online vs Offline <section-online-offline>


#figure(
  online-vs-offline-learning,
  caption: [Conceptual differences between purely online and purely offline learning algorithms in the context of reinforcement learning. Here, $x$ denoted a sampled timestep independent of the current timestep $t$. Purely online algorithms take actions and directly use the resulting observations and rewards from the environment resulting in a tight coupling. Purely offline algorithms learn a policy from a static dataset by sampling transitions. Replay buffer methods sit between the two by interacting with the environment but sampling transitions from a dynamic buffer.],
  placement: auto,
)<fig-online-vs-offline>


The concepts of #emph("offline") and #emph("online") algorithms in general, or those that fall somewhere in between, are not specific to reinforcement learning but they help characterize a certain aspect of the learning setting so that it helps to define these terms to fully understand the algorithm we are building towards. 

In the case of strictly #emph("online") learning algorithms, the algorithm updates and improves with data as it is made available and then immediately throws away that data. These algorithms have a poor sample efficiency (as of course they use every sample only once), but they tend to handle non-stationary tasks better because they can "forget" about older examples and adapt to newer ones @RL.

On the contrast, strictly #emph("offline") learning algorithms operate on the (static) dataset as a whole and would need to be retrained from scratch if any part of that dataset changes. This is an active area of research, as we can imagine the challenges that arise from the agent not being able to explore as it learns but also the benefits of being able to utilize the massive amounts of already collected, static datasets that we have and not have to rely on simulations to train real-world reinforcement learning agents @Offline-RL.

An algorithm somewhere between the two extremes can be constructed, for example, from an #emph("online") algorithm and a buffered dataset that stores the last $N$ datapoints. This leads to improved stability during the training process, especially for the case of neural networks as this helps the validity of the i.i.d assumption. It also increases the sample efficiency because datapoints are now reused multiple times. Many algorithms are chosen in-between these extremes by incorporating a so-called #emph("replay buffer") @NatureATARI, which is exactly a buffered dataset of collected transitions, or #emph("experiences"), of a fixed size where the oldest experiences are forgotten as new ones come in when the buffer is full. In the learning step, all datapoints currently in the buffer are sampled from, either uniformly or with some prioritization, and they can even be relabeled as is the case in Hindsight Experience Replay (HER) @HER. This technique in general is often called #emph("experience replay") and this replay buffer will play a central role in our final algorithm.


// https://ai.stackexchange.com/questions/10474/what-is-the-relation-between-online-or-offline-learning-and-on-policy-or-off
// https://stats.stackexchange.com/questions/184657/what-is-the-difference-between-off-policy-and-on-policy-learning
== On-policy vs Off-policy <section-on-policy-off-policy>


#figure(
  on-policy-vs-off-policy-algorithms,
  caption: [The difference between on-policy (left) and off-policy (right) algorithms.],
  placement: auto,
)<fig-on-policy-vs-off-policy>

In reinforcement learning, we can optionally differentiate between the policy being optimized and the policy that is being used to collect data. That is, the actions chosen by the agent in the environment don't have to be sampled from the same policy that is being updated in the learning step. 

In the simplest example, the agent might always choose a random action, completely disregarding any observations, but still learn, i.e. update an internal policy, from incoming experiences. We might be able to deploy this agent after training and obtain better rewards than if we would deploy the random policy.

To be more concrete, reinforcement learning algorithms differ in terms of whether they are #emph("on-policy") or #emph("off-policy") @RL. In the case of #emph("on-policy") algorithms, they are updating their so-called #emph("target policy"), usually denoted by $pi$, with data collected using that same policy. In the more general case of #emph("off-policy") algorithms, the data collection policy of the agent, also called the behavior policy and denoted by $b$, during the training process is different to the policy that is being optimized. In our simple example, the behavior policy $b$ is a simple uniform sampling process of the action space and the target policy $pi$ is being optimized.

Off-policy algorithms are a strict generalization of on-policy algorithms as any off-policy algorithm can trivially be made on-policy be setting $b = pi$. This can also be done to some variable degree as is the case with the $epsilon$-greedy policy which samples from the random policy $epsilon$% of the time and from the target policy otherwise. The use of a replay buffer typically makes an algorithm off-policy because the sampled transitions from which the policy is updated come from older timesteps during which the policy was possibly different, and offline reinforcement learning (@section-online-offline) is considered to be "fully" or "pure" off-policy @Offline-RL.


== Model-Based Reinforcement Learning <section-MBRL>


Model-based reinforcement learning is an umbrella term meaning to capture all algorithms that learn a model of the environment to which it has #emph("reversible") access @MBRL-Survey. The distinction between #emph("reversible") and #emph("irreversible") access to a model arises from the fact that a model-free reinforcement learning algorithm can, and usually does, implicitly learn a model of the environment (for example by learning the environment dynamics) but it is not able to repeatedly plan forward from the same state like humans might when pondering the different consequences of taking different actions (in the sense that we can mentally reverse back to the original state and take a different action). Instead, it must take an action and observe the consequences. Model-based reinforcement learning algorithms in contrast, have reversible access to the model of the environment and can use that access to repeatedly plan from any state as often as it wishes before actually taking an action.

#figure(
  agent-model-environment-loop,
  caption: [Showcasing an agent with reversible access to a world model. The agent can explicitly update the model based on transitions it takes within the environment, and it can sample (synthetic) transitions from the model by taking repeated "imaginary" actions from any state in the model before actually taking some action $A_t$ in the environment.],
  placement: auto,
)<fig-model-based-rl-diagram>

It is a good idea to remind ourselves that learning can now happen in locations in the algorithm: While learning the policy and while learning the model. This means that we can either learn the model or provide a known model, and we can either learn a policy or provide a rule-based algorithm (See @table-planning-learning-combinations). The combination of a known model and a rule-based algorithm is referred to as #emph("planning") and will be discussed in the next section. The combination of learning a model and providing a known policy is not strictly considered model-based reinforcement learning @MBRL-Survey since it does not learn a policy (i.e. a global solution), but the other two combinations are.

#figure(
  table(
    columns: (6em, 6em, auto),
    stroke: (x: none),
    row-gutter: (2.2pt, auto),

    table.header[Model Learned][Policy Learned][Example],
    [+], [+], [Dyna @RL],
    [-], [+], [AlphaZero @AlphaZero],
    [+], [-], [Embed2Control @Embed2Control],
    [-], [-], [A\* @A-Star]
  ),
  caption: [The possible combinations of learning with reversible access to a model. Note that only those methods where the (global) policy is learned are technically considered reinforcement learning. This table is gathered from content provided by #cite(<MBRL-Survey>, form: "prose").],
) <table-planning-learning-combinations>

Having reversible (or even irreversible) access to a previously unknown model can provide a number of benefits such as sample efficiency due to the ability to sample transitions from the model before taking actions (this is especially relevant in real-world situations such as robotics), explicit exploration strategies based on e.g. model uncertainty, and interpretability of the learned policy by being able to inspect the learned model. Model-based methods can also have better transfer performance to slightly different environments by being able to reuse the learned model @Transfer-RL.

But model-based RL also comes with a number of challenges, the biggest of which is model uncertainty making the sampled transitions inaccurate especially while the model is being learned. In practice, this leads to model-based methods where the model is learned usually having a lower asymptotic performance. Another important challenge is that model-based methods usually have a higher number of hyperparameters that need tuning such as when and how often and for how many steps to plan from the model, etc. Hyperparameter tuning is already a challenging aspect of RL in general.


== Hierarchical Reinforcement Learning <section-HRL>

#figure(
  image("images/hierarchical-rl-diagram-MBRL-survey.png"),
  caption: [Diagram of Hierarchical RL, copied from @MBRL-Survey, where a high-level agent $mu^("high")$ picks high-level actions (goals) $g_t$ for the low-level controller $mu^("low")$ to reach, and the low-level controller picks atomic actions $a_t$ to take which transitions the environment to the next state $s_(t+1)$.],
  placement: auto,
)<fig-hierarchical-rl-diagram>

// MBRL-Survey (pdfpage 8):
// "the line between model-based RL and replay buffers is thin"
// and hierarchical RL is considered a subset of model-based RL here

In the definition of reinforcement learning so far, especially considering the MDP as the building block upon which the algorithms are built, we typically consider low-level, atomic actions executed at a high-frequency @MBRL-Survey. This highly detailed view of the agent-environment interaction dynamic typically results in long-horizon tasks, where a large number of actions need to be taken until a reward is received and this is makes it hard to correctly assign credit and in consequence, learn the solution. The idea of temporal abstraction over the action space to mitigate this is known as hierarchical reinforcement learning (sometimes considered a subset of model-based RL), and typically distinguishes between low-level controllers that deal with actions on the atomic level but only need to reach short-horizon goals and high-level controllers that deal with actions on a higher level of abstraction and produce plans consisting of series of short-horizon sub-goals.

#figure(
  agent-environment-loop-goal-conditioned,
  caption: [The same agent-environment loop as in @fig-agent-environment, but the observation space is augmented by the current goal that should be reached $G_t$. This simple generalization over the goal space can provide a temporal abstraction and as a consequence, a hierarchical reinforcement learning agent.],
  placement: auto,
)<fig-goal-conditioned-rl-diagram>

One popular such attempt, and one we will focus on, are #emph("goal-conditioned value-functions"), also known as universal value function approximators @UVFA (dating back to Feudal RL @FeudalRL) which uses a goal space $cal(G)$ as the abstract action space. The implementation of this is quite straightforward. Consider that we can extend the classic reinforcement learning setting that we introduced in @section-MDPs to a more general goal-parameterized setting in which the agent is provided not just an observation and a reward signal, but also a goal which it must reach (@fig-goal-conditioned-rl-diagram). The reward signal is then also goal-parameterized, producing different values depending on the current goal. The standardized API for this task setting as proposed by @Gymnasium is for the environment to recieve an action and to return a 3-tuple of an #emph("achieved goal"), which is the current state of the agent, the #emph("desired goal"), which is the state the agent should aim for as it would produce the successful reward, and the #emph("observation"), which includes the information contained in achieved goal as well as providing additional information about the environment (e.g. walls etc).

This is formalized by extending our definitions of the value function or action-value function from @section-policies-value-funcs by a goal $g in cal(G)$ resulting $v_pi (s, g)$ or $q_pi (s, a, g)$. This is a strictly more general problem, making the agent more flexible by being able to reach different goals without the need for retraining but it also makes the problem more difficult to learn, especially on long-horizon goals. However, the agent now only needs to learn to reach short-horizon goals allowing a higher-level agent to generate suitable sub-goals. Note that this approach generalizes the temporal abstraction of the action space in some sense by how fine-grained the sub-goals are selected, and in the extreme case the next sub-goal is simply the goal. An important question here is how to discover the most relevant sub-goals, i.e. how to define the best level of abstraction. This idea of training goal-conditioned policies as a method of temporal abstraction for long-horizon tasks has been shown to be successful, for example in the case of GoExplore @GoExplore.





// TODO notation update:
// pi_target and pi_b instead of pi and b
// find a way to unify G for graph and G_t for some goal from goal space
// the solution for that needs to be conform with how S_t, A_t and R_t are handled






// https://ai.stackexchange.com/questions/10180/what-is-the-difference-between-search-and-planning
= Graph-Based Planning <section-planning>


Planning is the process of modeling a problem and then #emph("searching") for a plan using that model. Historically, the task of modeling the problem has been the task of human domain experts handcrafting models in e.g. an action language, propositional logic, a graph or an MDP. As opposed to reinforcement learning methods, planning methods focus on generating plans from a model that they have #emph("reversible") access to (see @section-MBRL) and they do not necessarily concern themselves with learning, i.e. in planning we mostly consider the model as known and algorithmically search for good solutions. 

Another distinction between planning and reinforcement learning methods, that arises from the difference in assumption of whether the model is known, is that planning methods are typically only concerned with a #emph("local") representation of the solution (i.e. the actions and states between the current state and the goal) and reinforcement learning methods attempt to learn a #emph("global") solution (i.e. a value function or action-value function over all states, as described in @section-policies-value-funcs) @MBRL-Survey. See @table-planning-learning-differences for an overview of the differences between model-based RL, model-free RL, and planning.

#figure(
  table(
    columns: 3,
    stroke: (x: none),
    row-gutter: (2.2pt, auto),

    table.header[][Model][Global Solution],
    [Planning], [+], [-],
    [Model-Based RL], [+], [+],
    [Model-Free RL], [-], [+],
  ),
  caption: [The distinction between planning and model-based or model-free reinforcement learning based on whether the method has #emph("reversible") access to a model (known or learned) and whether the method learns a #emph("local") or a #emph("global") solution. This table is reproduced from #cite(<MBRL-Survey>, form: "prose").],
) <table-planning-learning-differences>

By being able to assume reversible access to a high-quality model, very efficient and provably correct search algorithms have been devised to find optimal plans. In this thesis, we are particularly concerned with graph-based search.


== Graphs <section-graphs>


As we said in the introduction, in the end we want our agent to make use of a high-level (i.e. more temporally abstract in the hierarchical sense as discussed in @section-HRL instead of at the lowest level of atomic actions) graph data structure as a model of the environment that it builds up as it explores and interacts with the world. This graph should have edges which are associated with a certain cost of traversal, as we can imagine that some edges can take longer to traverse than others. It should also be directed, as it might be easy to traverse an edge in one direction and impossible to traverse it in the opposite direction, for example. Let us first define this data structure and then consider some search algorithms that operate on it.

We specifically consider a weighted, directed graph, which is defined by a triple of disjoint sets $G=(V, E, w)$, such that $V$ is the set of #emph("vertices"), also called nodes, $E$ is the set of #emph("edges") which are each an ordered 2-element subset of $V$ defining which two vertices are #emph("joined") by the edge (e.g. $x, y in V$ joined by $x y in E$), and $w$ is the #emph("weighting function") which defines the #emph("weight") of an edge (e.g. $w(x y) = 0.5$), which we interpret as the cost of traversing that edge. Because we specifically consider #emph("directed") graphs in this thesis, the ordering of the vertices joined by edges matters, i.e. $x y in E eq.not y x in E$. An edge can join a vertex with itself $x x in E$, this is called a #emph("loop"), but we do not consider parallel edges (multiple edges connecting the same vertices in the same direction). This definition has the consequence that the manner in which the graph is drawn is irrelevant, only the information about which vertices exist and how they are joined by edges is important @GraphTheory. 

#figure(
  box(example-graph),
  caption: [An example graph with 5 nodes.],
  placement: auto,
)<fig-graph-example1>

// negative edge weights?

Two vertices that are joined by an edge are #emph("neighbours"). A vertex with no neighbors is #emph("isolated"). The number of neighbors of a vertex is also called the #emph("degree") of that vertex, and this allows us to consider the #emph("minimum degree") of a graph as well as the #emph("maximum degree") or the #emph("average degree") as the minimum, maximum or average number of neighbors of all of the vertices in $V$. See @fig-graph-example1 for an example of a directed graph.

//   - average degree == 2 * (|E| / |V|)

A path is an ordered list of distinct and sequentially joined vertices, #emph("linking") the first and the last vertices. The number of edges in this path, or equivalently one less than the number of vertices in this path, is called the #emph("length") of the path. The sum of the weights of the edges in the path is called the #emph("distance")- or the #emph("cost") of traversing between- the first and the last vertices. A #emph("cycle") is a cyclical path, that contains an additional edge from the last to the first vertex.

// SGM sparsification does "contraction" with redundant nodes


// https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm
// https://en.wikipedia.org/wiki/A%2a_search_algorithm
// https://stackoverflow.com/questions/4212431/dijkstra-vs-floyd-warshall-finding-optimal-route-on-all-node-pairs
// https://stackoverflow.com/questions/7165356/fastest-implementation-for-all-pairs-shortest-paths-problem
// https://www.quora.com/How-do-I-decide-between-the-Dijkstras-and-Floyd-Warshall-algorithm
== Dijkstra's Algorithm


Dijkstra's algorithm @Dijkstra is a single-source shortest path algorithm, meaning it returns the shortest paths from a single source vertex $v in V$ to all vertices $u in V$. The time complexity of Dijkstra's algorithm depends mainly on the data structure used to represent the set $Q$ (see @algo-dijkstra), in particular it depends on the complexities of the #emph("decrease-key") ($T_("dk")$) and #emph("extract-minimum") ($T_("em")$) operations of that data structure: $O(|E| * T_("dk") + |V| * T_("em"))$. The simplest implementation is backed by an array or linked list for vertices and an adjacency list or matrix for edges and has a time complexity of $O(|E| + |V|^2)$. The most efficient implementation is backed by a Fibonacci Heap (which is a priority queue data structure) and has a time complexity of $O(|E| + |V|log|V|)$.

#figure(
  algorithm(
    caption: [Dijkstra's Algorithm (Priority Queue)],
    pseudocode-list[
      - *input:* data structure: `Graph`, vertex: `source`
      - *output:* array: `dist`, array: `prev`
      - * *
      + create vertex priority queue $Q$
      + create distances array `dist`
      + create pointer array `prev`

      + `dist`[`source`] ← `0`
      + $Q$.add_with_priority(`source`, `0`)

      + *for* vertex $v in$ `Graph`.vertices() *do*
          + *if* $v eq.not$ `source`
              + `prev`[$v$] ← UNDEFINED
              + `dist`[$v$] ← INFINITY
              + $Q$.add_with_priority($v$, INFINITY)
       
      + *while* $Q$ is not empty:
          + $u$ ← $Q$.extract_min()

          + *for* $v in$ `Graph`.neighbors_of($u$) *do*:
              + `alt` ← `dist`[$u$] + `Graph`.edge_weight($u$, $v$)
              + if `alt` < `dist`[$v$]:
                  + `prev`[$v$] ← $u$
                  + `dist`[$v$] ← `alt`
                  + $Q$.decrease_priority($v$, `alt`)

      + return `dist[]`, `prev[]`
    ]
  ),
  placement: auto,
)<algo-dijkstra>


== A\* Algorithm


The A\* algorithm @A-Star can be considered a more general case of Dijkstra's algorithm that uses a heuristic function to more quickly find the shortest path to the goal. However, A\* is a single-source, single-goal algorithm as opposed to a single-source all-goals algorithm as is Dijkstra's algorithm. This is a necessary consequence of using a goal-specific heuristic. This means that A\* is more suitable for finding the shortest path to a specific goal, and only when there is an appropriate heuristic available. As long as the heuristic is #emph("admissable"), that means that it never overestimates the true distance to the goal, A\* is guaranteed to return a least-cost path from start to goal. If $h(x) = 0, forall x in V$, then A\* is equivalent to Dijkstra's algorithm.

#figure(
  algorithm(
    caption: [A\* Algorithm (Priority Queue)],
    pseudocode-list[
      - *input:* data structure: `Graph`, vertex: `source`, vertex: `target`, function: `h`
      - *output:* array: `dist`, array: `prev`
      - * *
      + create vertex priority queue $Q$
      + create distances array `dist`
      + create pointer map `prev`

      + `dist`[`source`] ← `0`
      + $Q$.add_with_priority(`source`, h(`source`))

      + *for* vertex $v in$ `Graph`.vertices() *do*
          + *if* $v eq.not$ `source`
              + `prev`[$v$] ← UNDEFINED
              + `dist`[$v$] ← INFINITY
              + $Q$.add_with_priority($v$, INFINITY)
       
      + *while* $Q$ is not empty:
          + $u$ ← $Q$.extract_min()

          + *if* $u eq$ `target`
              + *break*
           
          + *for* $v in$ `Graph`.neighbors_of($u$) *do*:
              + `alt` ← `dist`[$u$] + `Graph`.edge_weight($u$, $v$)
              + if `alt` < `dist`[$v$]:
                  + `prev`[$v$] ← $u$
                  + `dist`[$v$] ← `alt`
                  + $Q$.decrease_priority($v$, `alt` + `h`($v$))

      + return `dist[]`, `prev[]`
    ]
  ),
  placement: auto,
)<algo-a-star>

For both algorithms @algo-dijkstra and @algo-a-star, Graph is assumed to be a data structure from which it is possible to access all vertices, neighbors of a certain vertex, and the edge weight of a certain ordered pair of connected vertices. `dist` is an array that contains the updated distances from `source` to each other vertex, where the array is indexed by a given vertex to obtain the corresponding distance. `prev` is, for Dijkstra's algorithm, an array that contains pointers to the previous vertices along the shortest paths from `source` to any given vertex where the array is indexed by that vertex to obtain the previous vertex in the path, and for A\* it is a HashMap containing pointers to the previous vertex in the single shortest path from the `source` to the the `target`. For both algorithms, the actual path can be reconstructed via `prev`.


== Bellman-Ford Algorithm


The Bellman-Ford algorithm @Bellman-Ford-Original is identical to Dijkstra's algorithm apart from a few key differences. Dijkstra's algorithm will fail when there are negative cycles while Bellman-Ford can be used to detect them. Dijkstra is also more efficient with a time complexity of $O(|E| + |V|log|V|)$ as opposed to Bellman-Fords $O(|E| * |V|)$, where $|E|$ is the number of edges and $|V|$ is the number of vertices in the graph. This is because Bellman-Ford performs a check (relaxation step) on each vertex in the graph, while Dijkstra only does this for the one with the best distance calculated so far. While this comparison step to find the best vertex makes it more complicated to implement in a distributed setting, Dijkstra has a superior time complexity compared to Bellman-Ford. If we are sure that negative cycles do not occur within our graph, as we usually are in our case because negative edge weights do not make sense when the the edge weights correspond to a distance metric based on the number of actions necessary to reach the vertex, then Dijkstra's algorithm will be the more efficient choice.


== Floyd-Warshall Algorithm


The Floyd-Warshall algorithm @Floyd-Warshall-Original is an all-pair shortest path algorithm, as opposed to Dijkstra's algorithm or the Bellman-Ford algorithm which are single source shortest path algorithms. The complexity of the Floyd-Warshall algorithm is $O(|V|^3)$, independent of the number of edges. This algorithm can therefore sometimes be favorable with extremely dense graphs but in most cases (provided there are no negative weights) it is still more efficient to simply run Dijkstra repeatedly for each vertex resulting in a time complexity of $O(|E| * |V| + |V|^2 log|V|)$

// This would need some citation or clear math:
// ... extremely dense graphs, where the number of edges exceeds $(|V|^2) / (log|V|)$, ...


== Johnson's Algorithm


Johnson's algorithm @Johnson is an all-pair shortest path algorithm, and it works by first running Bellman-Ford on the graph to transform it into a graph with no negative edges, then repeatedly running Dijkstra's algorithm for each vertex. This is basically the same as repeatedly running Dijkstra's algorithm for each vertex but also works when there are negative edge weights and has a similar time complexity of $O(|E| * |V| + |V|^2log|V|)$. For very dense graphs, Floyd-Warshall might have a better performance in practice.


= Prior Work <section-prior-work>


The problem statement of our method of interest, at the intersection of model-based and hierarchical reinforcement learning is quite specific and involves a number of moving parts. 

It aims to combine the worlds of graph-based planning and deep reinforcement learning by building a graph-based representation of the environment upon which a high-level, non-parametric graph-search algorithm operates to provide short-horizon sub-goals for a low-level, goal-conditioned RL controller to reach. This approach naturally applies to (visual) navigation tasks, as these are particularly suitable for the graph representation and allow for intuitive visualization.

The main difficulties with this approach involve the question of exploration for how to obtain a collection of well-distributed datapoints from which to build a graph that sufficiently covers the state space, how to define the edge weights of the graph, and how to best sparsify the graph in terms of landmarks or state-space coverage to arrive at a suitable temporal abstraction.

Some works have side-stepped the exploration issue by assuming the ability to spawn uniformly over the state space @SoRB@SGM@MSS@L3P, assuming access to human demonstration data @SPTM, or have mostly ignored the issue @LEAP. Others use some form of strategy to explore around the frontiers of thus-far explored areas @SFL. It is also possible to act in a latent state-space to hallucinate samples for building a graph in a zero-shot manner @HTM.

To the question of how to connect the nodes of a graph, or how to arrive at a suitable notion of distance between two states or nodes, some works have side-stepped that question by assuming access to domain knowledge @NTS, some build a graph by connecting trajectories based on transitions and matching (or similar) states @SPTM@LWG, while others learn a distance function that can provide these edge weights @SoRB@SGM@MSS. If a latent state-space is learned, then some cluster in this space in terms of reachability @L3P or use a cross-entropy maximization method to propose subgoals @LEAP.

Graph sparsification is important not just for the exponentially increasing computational complexity of operating on a dense graph, but also for minimizing the number of faulty edges (i.e. wormholes) that a graph-search algorithm will certainly exploit and, as a consequence, return an infeasible plan. Some works have nevertheless ignored this problem @SoRB, while others have devised a $Q$-irrelevant sparsification algorithm @SGM or, similarly, used a learned distance metric together with a cutoff threshold @SFL. Some have utilized sampling based approaches @MSS@HIGL to obtain a subset of nodes that still provide a good state-space coverage. While still others have used some form of latent space projection for states to arrive at a suitable set of subgoals @L3P@LEAP. Most methods use a number of additional tricks to reduce the number of faulty edges such as k-nearest-neighbor filtering @SGM, ensembles of networks @SoRB, distributional RL @SoRB, etc.

// Some utilize a form of adjacency constraint @HRAC and some learn a high-level subgoal generator @HIGL,

The localization of the agent within the internal graph representation can be done in many ways such as by simple pattern-matching with each node in memory @SoRB, by some similarity or distance metric @SGM@SFL@MSS or by training a retrieval network @SPTM.

The locomotion controller is naturally formulated as a goal-conditioned short-horizon reinforcement problem and it has the benefit of being able to be trained in isolation and on nearby goals to speed-up the learning process, because it only needs to learn enough of the dynamics of the environment to be able to select actions to traverse between subgoals.

With the graph representation at a suitable level of abstraction in place, the high-level controller is then trivial, with most of the approaches choosing some variant Dijkstra's algorithm @SPTM@NTS@SoRB@SGM@MSS although some also learn a high-level controller @LWG@LEAP@L3P.

We place a particular focus on @SoRB@SGM in this thesis, so we will provide an in-depth summary of those two papers as well as of @SPTM and @MSS which paved their way.


// Savinov et al. (2018)     (Dosovitskiy, Koltun)
== Semi-Parametric Topological Memory (2018) @SPTM


One of the first notable applications of these ideas within the context of deep learning was done in @SPTM as the Semi-Parametric Topological Memory. Here the authors are inspired by vision-based SLAM (Simultaneous Localization And Mapping) methods. These are methods of building a metric map of the environment from visual sensory data such as from cameras as well as movement data such as from motors that date back to the 80s @SLAM-History. However, differently to SLAM methods, they aim to build a topological map instead of a metric one and they do so utilizing deep learning methods.

#figure(
  image("images/SPTM-overview.png"),
  caption: [SPTM Algorithm, figure taken from #cite(<SPTM>, form: "prose")],
  placement: auto,
)<fig-SPTM>

Incoming observations are used directly as nodes in the internal graph representation, and these nodes are connected by edges if they directly follow each other chronologically or if they are sufficiently similar as determined by the retrieval network. Important to note here is that the authors use human demonstration data to bootstrap a qualitative initial dataset.

The retrieval network as well as the locomotion network are trained in a self-supervised fashion on the collected transitions in the buffer, where the buffer is treated simply as a labeled dataset. The retrieval network is trained to estimate the similarity between two observations, where two observations that are temporally close are considered similar. The locomotion network is trained to produce action probabilities, given a current observation and a goal observation (both sampled from the dataset, where the goal observation is separated from the current observation by no more than 20 timesteps). The high-level, non-parametric planner is chosen to be Dijkstra's algorithm.


// Huang et al. (2019)     (Liu, Su)
== Mapping State Space using Landmarks for Universal Goal Reaching (2019) @MSS

#figure(
  image("images/MSS-illustration.png"),
  caption: [Illustration of the graph-based approach, figure taken from #cite(<MSS>, form: "prose")],
  placement: auto,
)<fig-MSS>


In @MSS, a locomotion controller is pre-trained using a goal-conditioned reinforcement learning agent, or universal value function approximator (UVFA), and training is improved by using hindsight experience replay @HER which increases the sample efficiency by relabeling past transitions during training as if the resulting states had in fact been the correct goal. Because this agent is trained using the simple indicator reward function

#spaced_eq(
  $ r_t = R(s_t, a_t, g) = cases(
    quad &0 quad quad quad & norm(s'_t - g) lt delta,
    &-1 & "otherwise"
  ) $,
  "eq-reward-indicator-function"
)
\
(where $delta$ is chosen to be some small value) the value-function learned by the resulting local agent will correspond to a (negated) distance function between any two states $d(s, g)$, because the expected return from any state to any goal state is simply the negative of the number of steps required to reach it. The authors also note that this goal-conditioned agent fails at reaching far-away goals but successfully and consistently learns to reach short-horizon goals.

Due to the computational cost of considering every state in the replay buffer, the authors propose a landmark sampling strategy to build a sparse graph representation. They start by uniformly sampling a large number of transitions from the buffer and then perform farthest point sampling @FPS on that set with the goal of sufficiently covering the so-far discovered state space. The metric for farthest point sampling can either be the true euclidean distance between two states if known, or the learned distance metric from the pre-trained locomotion controller. They then build a graph from the resulting states using edge weights determined by the learned distance estimator, only connecting states if they are sufficiently close as determined by a hyperparameter: $d(s, g) lt tau$. 

The authors re-construct the graph at every timestep $t$ which means they can make sure that the current state is one of the nodes in the graph making retrieval trivial. With the resulting directed, weighted graph based on the estimated distance function they make use of the Bellman Ford algorithm for the high-level planner to find the shortest paths.


// Eysenbach et al. (2019)     (Salakhutdinov, Levine)
== Search on the Replay Buffer: Bridging Planning and Reinforcement Learning (2019) @SoRB

#figure(
  image("images/SoRB-illustration.png"),
  caption: [Illustration of the dense graph, figure taken from #cite(<SoRB>, form: "prose")],
  placement: auto,
)<fig-SoRB>


As in @MSS, in @SoRB a UVFA is pre-trained locally on close-together states and goals using the indicator reward function @eq-reward-indicator-function resulting in a locomotion controller and a learned distance function approximator. Differently to @MSS, the authors use distributional reinforcement learning @DistributionalRL as a trick to improve predicted distances where the agent is forced to learn not just the single-valued expected average return but more specifically the discretized distribution of returns where each of $N$ bins corresponds to the number of steps away from the goal (the last bin corresponds to "at least $N$ steps away"). Another trick the authors use to learn better distance estimates is to train an ensemble of estimators and pessimistically aggregate predictions. 

Previously seen observations from the replay buffer are used directly as nodes in the internal graph representation, but here the authors construct a dense, almost fully connected graph where every state in the buffer is connected to every other state by an edge with weight equal to the predicted distance from the pre-trained UVFA unless the distance is larger than some hyperparameter $"MAXDIST"$. The graph grows with new states over time and is otherwise fixed, but the shortest paths still need to be calculated anew after every timestep. The authors choose Dijkstra's algorithm to do this, but to amortize this cost they use the Floyd Warshall algorithm to efficiently compute the shortest paths between all points of the graph also reducing the number of necessary calls to the expensive value function.

This approach of building a dense graph using every node in the replay buffer suffers from the quadratic growth of edges with each node and quickly becomes unscalable. A large number of edges also increases the chance of faulty edges representing infeasible transitions which will be exploited by the high-level graph search algorithm.


// Laskin et al. (2020)     (Emmons, Jain, Kurutach, Abbeel, Pathak)
== Sparse Graphical Memory for Robust Planning (2020) @SGM


// SGM official blogpost
// https://bair.berkeley.edu/blog/2020/11/20/sgm/

#figure(
  image("images/SGM-illustration.png"),
  caption: [Illustration of the SGM sparsification, figure taken from #cite(<SGM>, form: "prose")],
  placement: auto,
)<fig-SGM>


The authors in @SGM build directly upon @SoRB and focus on sparsification to reduce faulty edges and computational complexity. They devise an algorithm to dynamically build a sparsified the graph based on a similarity metric they call two-way-consistency (TWC) to merge, or rather ignore, redundant nodes in a $tau$-approximate, $Q$-irrelevant manner for the high-level planner such that the quality of the original graph is preserved with respect to high-level plans up to a linear factor. The intuition here is that two states are redundant if they are both interchangeable as goals and interchangeable as starting states according to the goal-conditioned value function.

This sparse graph is built via a single pass through the replay buffer by an online, greedy algorithm which iteratively adds nodes from the buffer to the set of nodes to keep if these nodes are two-way-consistent with respect to the other nodes in the set to keep. If a node is added, edges are created and set to predicted distances unless the distance is larger than some hyperparameter $"MAXDIST"$. Further, nodes are limited to be connected to their $k$-nearest neighbors and during test-time edges are removed if the low-level agent is unable to traverse them. All other aspects are held equal to @SoRB. More details on the TWC criteria is provided later on in @section-methods-SGM.

The authors address the shortcomings of the previous approach @SoRB and show significant improvements in terms of performance and success rates on different environments as well as execution speed due to the induced graph sparsity that is provably error bound.


= Rust <section-rust>


One of the goals of this thesis was to evaluate and push forward the maturity of the Rust @Rust-book programming language in the field of machine learning and artificial intelligence research. To this end, instead of directly making use of the available code of @SoRB and @SGM it was entirely re-implemented in Rust and an open-source contribution to one of the few major machine-learning frameworks was made where certain tools were missing from the ecosystem.

Rust was created at Mozilla in 2006 by Graydon Hoare, was sponsored by Mozilla in 2010, released it's first stable version `1.0` in 2015, and became independent of Mozilla via the Rust Foundation in 2020. It was the first industry-supported programming language to overcome the longstanding trade-off between the safety guarantees of high-level languages and the performance via memory control of low-level languages @Rust-Jung. It does this by means of a strong type system, based on the ideas of #emph("ownership") and #emph("borrowing"), by which the compiler, infamously named the "borrow checker", statically manages memory at compile time without the need for a garbage collector and at the same time provably makes entire classes of bugs impossible @Rust-book@Rust-Jung.

A recent analysis of bugs at Microsoft revealed that 70\% of vulnerabilities that are assigned a common vulnerabilities and exposure (CVE) tag are due to memory safety bugs @Microsoft-memory-bugs. Fortunately, a Rust program that compiles is guaranteed, due to the compiler, not to have any memory safety bugs: use after free, dereferencing a null pointer, double free, buffer overflow and buffer overread. Additionally, it is guaranteed not to have any data races, allowing for lovingly called "fearless concurrency" in Rust.

The language focuses on performance by relying heavily on #emph("zero-cost abstractions") which are high-level abstractions such as data structures and methods that do not come with a runtime cost, only a compile time cost. It is also a compiled and therefore optimized language, and without a garbage collector it matches the performance of C/C++. The lack of a garbage collector due to the borrow-checking mechanism and lack of a required runtime, also comes with a drastically reduced memory footprint compared to other high-level languages such as Python and Java.

The adoption of Rust has seen a steady increase in the years since 2015 and a recent milestone is the adoption of Rust as the only other language apart from C so far into the Linux Kernel. In the yearly survey by StackOverflow, the latest one to-date being 2023, Rust has been voted the "Most Loved" programming language for 8 years in a row now @StackOverflow-Survey-2023 and the reasons for this, apart from the confidence in program correctness, is also due to the great tooling that comes with the language. The problems of dependency management (e.g. virtual environments in Python), build management (including cross compilation to different operating systems and into statically linked, standalone binaries), testing and benchmarking are solved with Rust's Cargo. Testable documentation is built directly into the code and when publishing a package (crate) it is directly published online on `docs.rs`. Clippy is a code analysis tool that provides helpful tips on how to improve your code. Rustfmt formats your code into a standardized specification.

One of the main, practical benefits to writing a pure-Rust application, is that it compiles down to a single standalone binary with no dependencies which immensely simplifies deployment, an often forgotten but incredibly complex step beyond the research phase.


== State of Machine Learning in Rust


To the start of this thesis, the reinforcement learning ecosystem in Rust was almost non-existent. There were some examples of deep reinforcement learning using `tch-rs` @Tch, a library providing Rust bindings to `libtorch` similarly to `PyTorch`, but no examples using one of the three available pure-Rust machine-learning frameworks: `dfdx` @Dfdx, `Burn` @Burn, or `candle` @Candle. To the best of our knowledge, deep reinforcement learning, if at all, has only ever been done before in pure Rust as a proof-of-concept curiosity a handful of times. 

The machine-learning libraries available were also at a very young stage of maturity. At the time this thesis was started (January 2023), `candle` had not even yet existed and `Burn` had just been announced:

- `dfdx` (first commit: August 2021) is the first pure-Rust machine learning framework. It is maintained by a single author and as a consequence, has only a simple feature set and a slow development speed.
- `burn` (first commit: July 2022) is a promising framework with some development momentum, but after many attempts turned out to be too complicated (due to the heavy use of traits) and opinionated for reinforcement learning research.
- `candle` (first commit: June 2023) is a well designed framework that despite being the youngest, is the most battle-tested due to an incredibly extensive set of state of the art models implemented in the examples. It also enjoys a fast development speed due to being backed by HuggingFace and gaining a large community.

Of the three frameworks, `candle` was considered the most promising because it used a more flexible and usable design in which the library user is not required to handle lifetimes (a quite complicated concept unique to Rust) and because it was backed by HuggingFace, a major open-source AI company, instead of being maintained by only a single developer. While `candle` has an impressive list of state-of-the-art models as examples in the repository, most of them related to large language models and no reinforcement learning examples were available. Our open-source contribution to the `candle` framework was to add the `DDPG` algorithm to the list of examples, providing not just the first pure-Rust deep reinforcement learning example to the ecosystem but also providing a number of helpful reference implementations such as for a replay buffer, the logic for soft-updates between a network and a target network, and a principled way to create and interact with the Python implementation of the popular reinforcement learning benchmarking library OpenAI Gym @Gymnasium, which is now hosted by the Farama Foundation aiming to standardize and maintain reinforcement learning tools.


= Methods <section-methods>


The setting we are interested in specifically is an (impure) off-policy, model-based, hierarchical reinforcement learning agent where the low-level controller is a goal-conditioned reinforcement learning agent and the high-level controller is a non-parametric planning algorithm operating on- and with reversible access to- a learned, graph-based world model. These algorithms have a number of inherent advantages due to the graph-based world model such as being semi-parametric where the high-level controller does not need to be learned nor does it have any hyperparameters that need to be tuned, and they can easily be inspected or even edited providing a huge benefit in terms of interpretability. The graph along with the goal-conditioned nature of the algorithm also provides us with the flexibility of not having to retrain the agent for small changes in the environment or to reach different goals.

We design one such algorithm, and base our implementation on the works on @SGM and, as a consequence, @SoRB, where a graph is built directly from previously encountered states. Like @SoRB@SGM, we also use an actor-critic architecture, in particular the DDPG algorithm, to train the low-level controller and the distance function simultaneously via the actor and the critic, respectively. Due to time constraints and a lack of suitable hardware to test on, we replaced the learned distances with the true euclidean distance function as these were significantly faster to compute, reducing the time taken per timestep (adding one node to a decently sized graph) from several minutes to a fraction of a second. We did not have the time to evaluate graph construction from distances learned by the critic.

We implemented the two-way-consistency criterion proposed in @SGM to sparsify the graph, and similarly to @SGM we introduced a clean-up procedure where we remove faulty edges that take more than $"SGM max tries"$ timesteps to reach. Unlike @SGM, we do this during training as well as during evaluation.

We benchmark a Hierarchical Graph-Based DDPG (HGB-DDPG) algorithm against a Hierarchical DDPG (H-DDPG) without the graph-based model on the same PointEnv environment as in @SoRB and @SGM.


== PointEnv Environment <section-methods-pointenv>


#figure(
  grid(
    columns: 3,
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
  caption: [The three environment wall-configurations (PointEnv-Empty, PointEnv-OneLine, and PointEnv-Hooks) across columns combined with the three goal state locations and radii (close, mid, and far) across rows. Spawn states are shown in gray while goal states are shown in green.],
  placement: auto,
)<fig-PointEnv>

We focus our experiments on the simple PointEnv environment as in @SoRB and @SGM, which is a 2-dimensional navigational environment with a continuous action space and a proprioceptive observation space. The observations are simply the locations of the agent, $s = (x, y) in RR^2$, and the actions, $a = (d x, d y) in RR^2$, are vectors within the unit circle around the agent that are added to the agents current location at every timestep unless there is wall blocking the path, in which case the agents location ends up being a small distance away from the collision point.

All environments are of the same size (10x10), and the differences between the environments are in wall configuration (Empty, OneLine, Hooks) and in the areas in which the spawing states and the goal states are sampled (close, mid, far). The wall configurations, in increasing difficulty, are either the empty environment with no walls, a single horizontal line through the center from the left edge extending towards the right, and two hooks extending from either edge towards each other almost locking arms. The spawing state is fixed to be centered around the point `(0.5, 0.5)` while the goal states and radii vary for different configurations, in increasing difficulty, around the point `(2.5, 2.5)` with radius `1.05` for close, around `(5.0, 5.0)` with radius `1.5` for mid, and around `(9.5, 9.5)` with radius `1.5` for far. These configurations make for a total of 9 different environments visualized in @fig-PointEnv. To end the episode successfully, the agent must change its own location to be within a radius of `0.5` of the goal state.


== Deep Deterministic Policy Gradient (DDPG)


To handle continuous action spaces, we choose the DDPG algorithm @DDPG which is an actor-critic reinforcement learning method. It uses some of the same "tricks" used by the highly successful DQN @NatureATARI algorithm to handle the violations of many of the assumptions that the convergence proofs are based on which make training in practice highly unstable. In particular, a replay buffer is used to retrieve training samples from to somewhat restore the violated i.i.d assumption on the (otherwise highly correlated) samples used to train a neural network, and a target network is used to somewhat restore the independence assumption between the target and the prediction in the loss function.

#figure(
  actor-critic-architecture,
  caption: [The actor-critic architecture, shown here as an (impure) off-policy implementation with a replay buffer. The critic helps determine the temporal difference (TD) error based on some transition, and this error is used to update both the actor and the critic networks.],
  placement: auto,
)<fig-actor-critic-architecture>

The actor-critic architecture dates back to @Original-Actor-Critic. These algorithms make use of an additional network to represent the policy independent of the value function @RL. This policy network is referred to as the actor, because it produces actions based on observations, while the value function network is referred to as the critic, because it critiques the actions selected by the actor by producing a scalar, reward-like output for the current and the following observations.

For each transition, the critic evaluates the quality of the action taken by computing the temporal difference error as:

#spaced_eq(
  $ "TD-ERROR" = R_(t+1) + gamma V_theta (O_(t+1)) - V_theta (O_t) $,
  "eq-td-error-actor-critic",
)
\
Where $V_theta$ is the value function as currently represented by the critic network. If the temporal difference error is positive, the action improved the value of the current state and the actor should be rewarded, otherwise it should not. This error term computed by the critic drives all learning in both the actor and the critic @RL. This general architecture is represented in @fig-actor-critic-architecture. 

In the DDPG algorithm, both the actor network as well as the critic network each have a more slowly updating copy of themselves referred to as the target network. Each target network (represented by the weights $theta'$), which starts out as an exact copy of the faster-changing learned network (represented by the weights $theta$), "follows" the learned network as it is updated, but changes more slowly so as to provide more stability during training. As the learned network is updated, at each timestep, the weights of the target network are updated as follows:

#spaced_eq(
  $ theta' <- tau theta + (1 - tau)theta'  $,
  "",
)
\
where $tau << 1$. 

To deal with the problem of exploration, especially at the start of the training process, a number of initial random actions are taken and, as in @DDPG, Ornstein-Uhlenbeck noise @OU-Noise is added to the output of the actor network to create the exploration policy $pi'$:

#spaced_eq(
  $ pi'_theta = pi_theta (S_t) + cal(N) $,
  ""
)
\
where $cal(N)$ is random noise generated by the Ornstein-Uhlenbeck process.


== Hierarchical DDPG (H-DDPG)


We can extend the DDPG algorithm to the goal-conditioned case by simply augmenting the observation space by the current goal as described in @section-HRL, and varying that goal over different episodes forcing the agent to learn a global policy that generalizes across any given goal. This simple change to the standard DDPG algorithm will be our baseline algorithm.


== Sparse Graphical Memory (SGM) <section-methods-SGM>


To build up to our HGB-DDPG algorithm, we first describe the SGM algorithm which is used by HGB-DDPG. It makes use of the two-way-consistency (TWC) criteria proposed by @SGM to construct a sparse graph. This results in a graph that is far more computationally feasible to perform graph-search on and has the added benefit of reducing the number of invalid edges which pose a problem for graph-search algorithms.

Consider a replay buffer $cal(B)$, containing a number of previously encountered states $cal(S)_cal(B)$, and any asymmetric distance function $d(dot, dot)$ between two states. Given $s_1 in cal(S)_cal(B)$ and $s_2 in cal(S)_cal(B)$, and iterating over all other states $omega in cal(S)_cal(B) - {s_1, s_2} $, if the maximum absolute difference in distance between starting in either $s_1$ or in $s_2$ and trying to reach $omega$ is below some threshold $tau$

#spaced_eq(
  $ C_("out") (s_1, s_2) = max_omega abs( d(s_1, omega) - d(s_2, omega) ) lt.eq tau $,
  "eq-d_TWC_out"
)
\
then the states $s_1$ and $s_2$ are considered interchangeable as starting states. Similarly, if the maximal difference in distance between attempting to reach either $s_1$ or $s_2$ while starting in $omega$ is below some threshold $tau$

#spaced_eq(
  $ C_("in") (s_1, s_2) = max_omega abs( d(omega, s_1) - d(omega, s_2) ) lt.eq tau $,
  "eq-d_TWC_in"
)
\
then the states $s_1$ and $s_2$ are considered interchangeable as goal states. If two states are interchangeable both as starting and as goal states, then they are considered redundant and one of these states can be dropped from memory.

#figure(
  SGM-node-merging,
  caption: [Node merging strategy in the SGM algorithm. This diagram is reconstructed from @SGM. Consider $s_1$ as already contained in the graph, and $s_2$ as a candidate to be added. For $C_("in")$, we consider $s_2$ a potential goal state and compare differences to $s_1$, while for $C_("out")$ we consider $s_2$ a potential starting state. ],
  placement: auto,
)<fig-sgm-node-merging>

This method of sparsification prioritizes the coverage of the state space in the resulting graph. The authors also provide a formal proof for the following theorem: Given a graph $G_cal(B)$ with all the states from a replay buffer $cal(B)$ as nodes and weights from any asymmetric distance function $d(dot, dot)$, and a graph $G_("TWC")$ that is constructed by aggregating states in $cal(B)$ according to TWC (where a state is not added to the graph if $C_("out") lt.eq tau$ and $C_("in") lt.eq tau$), then considering a shortest path $P_cal(B)$ with $k$ edges between any two states in $G_cal(B)$ and the corresponding path $P_("TWC")$ connecting the same two states in $G_("TWC")$:
- The weighted path length of $P_("TWC")$ minus the weighted path length of $P_cal(B)$ is no more than $2 k tau$
- If $d(dot, dot)$ has error at most $epsilon$, the weighted path length of $P_("TWC")$ is within $k epsilon + 2 k tau$ of the true weighted distance along $P_cal(B)$

In the case where a non-parametric high-level controller, with an action space defined by the states $omega in cal(B)$ (i.e. it chooses waypoints $omega$ for the low-level controller to reach based on the current goal), we can apply the TWC criteria as follows, for a $tau$-approximate, Q-irrelevent abstraction over $omega$ for the high-level controller:

#spaced_eq(
  $ max_omega abs( Q^("hl") (s_1, a=omega|g) - Q^("hl") (s_2, a=omega|g) ) lt.eq tau $,
  "eq-TWC_out"
)
#spaced_eq(
  $ max_omega abs( Q^("hl") (omega, a=s_1|g) - Q^("hl") (omega, a=s_2|g) ) lt.eq tau $,
  "eq-TWC_in"
)

\
The graph is constructed in an online fashion, where a newly observed state is either added to the graph if it satisfies TWC with respect to the nodes already in the graph or it is not added to the graph. This way, the algorithm has a time complexity of $O(|V|^2)$ for each node to be added, where $|V|$ is the number of nodes in the sparse graph at that moment.


== Hierarchical Graph-Based DDPG (HGB-DDPG)


When combining the ideas of goal-conditioned RL, off-policy RL via a replay buffer, and the actor-critic architecture, we have the opportunity to build an explicit graph-based model using previous observations collected from the transitions in the buffer as nodes and the learned value function of the goal-conditioned agent to determine the edge weights. While learning a goal-conditioned agent is much harder than a simple fixed-goal agent, especially for longer-horizon tasks, we only require it to reach short-horizon sub-goals while the graph-based model allows us to use a non-parametric graph-search algorithm as a high-level planner.

#figure(
  hierarchical-graph-based-ddpg,
  caption: [The Hierarchical Graph-Based DDPG (HGB-DDPG) algorithm. There top of the diagram shows the same actor-critic diagram as in @fig-actor-critic-architecture, and the goal-conditioned interaction with the environment is also identical to the diagrams we have discussed before, e.g. in @fig-goal-conditioned-rl-diagram. The difference here is the addition of a graph component that is capable of building a graph from the replay buffer and the critic network and generating plans from that graph.],
  placement: auto,
)<fig-hierarchical-graph-based-ddpg>


The HGB-DDPG algorithm is in essence a high-level agent which is a wrapper around a low-level H-DDPG agent, it uses the standard H-DDPG algorithm to reach short-horizon goals and graph-based methods to make long-horizon plans. At the start of training, it initializes a H-DDPG algorithm as well as a directed graph data structure $G = (V, E, w)$. It also makes a choice of whether to use a static distance function $d = d(s_"from", s_"to")$ if one is provided, or to use the goal-conditioned critic-network of the H-DDPG as a distance function by setting the goal to be equal to one of the states, e.g. $d = "Critic"(s_"from", s_"to", s_"to")$ where $s_"from", s_"to" in cal(S)$.

Note that the critic is an asymmetric distance function (i.e. $"Critic"(s_"from", s_"to", g_"current") eq.not "Critic"(s_"to", s_"from", g_"current")$), while the provided distance function does not have to be (i.e. the euclidean distance). The TWC criterion does not make an assumption here and works for both cases. The combination of goal-conditioned and asymmetric does however require some care when implementing, for example to remember setting the goal accordingly $g_"current" eq s_"to"$ or $g_"current" eq s_"from"$.

At each timestep $t$ the incoming state $s_t in cal(S)$ is added to the replay buffer of the H-DDPG agent and evaluated via the TWC sparsification criterion with respect to the distance function $d$ and states $s_n in V subset cal(S)$ currently in the graph, which decides whether the state will be added to the graph.

If the state satisfies the criterion, then it is added to the graph and edges are added in both directions between the new state $s_t$ and each other state $s_n$ with an edge weight equal to the output of the distance function of the corresponding direction (i.e. $w(s_t s_n) = d(s_t, s_n)$ and $w(s_n s_t) = d(s_n, s_t)$). If the edge weight is smaller than MAXDIST, then no edge is added:

#[
  #set math.equation(number-align: top)
  #spaced_eq(
    $
      w(x y) &= d(x, y)\
      V &= V union {s_t} \
      E &= E union {s_t s_n | s_n in V and w(s_t, s_n) < "MAXDIST"} \
      E &= E union {s_n s_t | s_n in V and w(s_n, s_t) < "MAXDIST"} \
    $,
    "",
  )
]
\

This graph grows over time while remaining sparse in such a way as to preserve the state coverage of the environment. To choose an action, the high-level agent first checks if the current goal is reachable via some waypoint in the graph by comparing the distance from each waypoint to the goal $d(w_"from", g_"current", g_"current")$ where $w_"from" in V$ and checking whether it is below some threshold. 

// TODO 
// in the code, the threshold for accepting a node as close_enough to the goal (or start) is the
// same thhreshold parameter as the threshold for considering a waypoint reached.
// - the waypoint reached should be identical to the environment threshold for goal reached
// - the treshold for accepting a candidate goal could be set more relaxed than that to get the agent to
//   reach more waypoints and learn faster?

If one or more candidates are found, a plan is generated by using Dijkstra's algorithm to find the shortest path between the the closest waypoint to the current state and the closest waypoint to the goal state. The high-level agent then provides the low-level H-DDPG agent with the current state and the next waypoint in the plan as the goal to get the next action. If no candidates were found and thus no plan could be generated, the HGB-DDPG policy defaults to standard H-DDPG policy by passing the current state and the current goal to get the next action.

The high-level agent generates a plan either at the beginning of each episode or if no plan was able to be generated it attempts to do so again at each timestep. It allows the low-level agent to attempt to reach the waypoint for a fixed number of timesteps after which it considers the transition infeasible and removes the edge from the graph and generates a new plan. This cleanup strategy is paramount to the success of the algorithm as otherwise any infeasible transition in a plan would result in a guaranteed failure to reach the goal, however it should be noted that the initial poor performance of the low-level agent while it is still learning will result in many feasible edges being incorrectly removed. This can be partially mitigated by reconstructing the graph anew from the states in the replay buffer every few episodes and letting the cleanup procedure continue, however the states in the buffer will at some points no longer be normally distributed over the state space as old states are dropped from memory resulting in the new graph no longer sufficiently covering the state space. This is potentially the most crucial problem to be solved in future work.

// TODO   !!!!!!!!!
// so... if you want(!), then rerun all 9 experiments with replenish + freq=100/150
// it only needs to happen 1/2 times per episode, and could lead to either
// 1) a performance improvement or 2) another hyperparameter tuning hell

At the end of each episode, the H-DDPG agent is trained for a number of iterations on the transitions collected in the replay buffer. Transitions in which the low-level agent was reaching a waypoint are saved in the replay buffer as such, with the current goal replaced by the waypoint and an internal reward is provided when a waypoint was reached. This self-supervised mechanism speeds-up the learning process and is similar to goal relabeling strategies such as @HER.

// TODO (maybe) algorithm flow-chart or pseudocode


== Experiment Setup


There are two main challenges with our approach. For one, while we are still learning the value function the distances will be very inaccurate and any invalid edge in which the distance between two nodes is underestimated will be exploited by the high-level planner resulting in infeasible plans. 

Another challenge is how to deal with the exploration issue because the high-level planner can only find paths to any goal if the graph sufficiently covers the state-space and while the Orenstein-Uhlenbeck process helps in exploration, it by far does not result in a uniform exploration of the state space when the spawing states are (relatively) fixed.

To deal with the first of these two problems, @SoRB@SGM@MSS have proposed a number of tricks to improve distances learned by the critic and to reduce the number of invalid edges, although all of these works have sidestepped the second problem by assuming the ability to spawn uniformly over the state space. We will sidestep both of these issues by assuming 1) access to the true euclidean distance function between states and 2) the ability to spawn uniformly over the state space (during an initial data collection phase).

The approach we will take is to first generate an initial set of uniformly distributed and hopefully valuable transitions during a data collection phase. During this phase, for a total of 3000 episodes, the agent is spawned uniformly over the state space and a goal is sampled somewhere within a radius of larger than the step-size of the agent but smaller than 1.5 times the step-size. The agent then transitions for a maximum of 5 timesteps (or until the goal is reached) with the random policy and these transitions are saved in the replay buffer. The agent is not trained during this phase. This starts the agent off with some uniformly distributed data and gives it, with a high probability, a few successful transitions as demonstration data at the same time to kickstart learning.

After this initial data collection period, the agent is trained normally on the environment with the spawing states and goal states restricted to certain areas. One training run consists of 300 episodes. At the end of each episode the agent is trained for 200 training iterations where at each iteration the agent is trained on a batch of 64 randomly sampled transitions from the replay buffer.

The hyperparameters of the agent are held fixed over the different environments, and the hyperparameters of the H-DDPG are held equal to the hyperparameters of the DDPG component of the HGB-DDPG (See @table-hyperparameters-ddpg, @table-hyperparameters-ghb, and @table-hyperparameters-ou). Similarly, the parameters of the environments are held equal with the exception of their explicit differences described in @section-methods-pointenv.

We will run both H-DDPG and HGB-DDPG on the 9 different variants of the PointEnv environment with the same hyperparameters and training configuration and setup, which we consider as in-distribution challenges, and observe the differences in performance. We will then investigate the performance of HGB-DDPG over H-DDPG on a select number of out-of-distribution challenges where an agent pretrained on an easier environment is evaluated on a harder environment. Finally, we will take a closer look at the internal graph model in different situations to make some conclusions about the behaviour of the agent and take the opportunity to showcase the qualitative benefits of the graph model.


#figure(
  table(
    columns: (auto, auto, auto),
    stroke: (x: none),
    row-gutter: (2.2pt, auto),

    table.header[Parameter][Value][Comments],
    [learning rate],                  [0.0003],     [Same for actor and critic],
    [gamma / discount],               [0.99],       [],
    [tau / soft-update rate],         [0.005],      [Soft update is done at every timestep],
    [hidden layer size \#1],          [256],        [Same network params for actor and critic],
    [hidden layer size \#2],          [256],        [Same network params for actor and critic],
    [replay buffer size],             [10,000],     [],
    [batch size],                     [64],         [],
  ),
  caption: [Both the H-DDPG and HGB-DDPG algorithms share these same DDPG-related hyperparameters.],
  placement: auto,
) <table-hyperparameters-ddpg>

#figure(
  table(
    columns: (auto, auto, auto),
    stroke: (x: none),
    row-gutter: (2.2pt, auto),

    table.header[Parameter][Value][Comments],
    [theta],                       [0.0],        [The mean to which the process returns],
    [kappa],                       [0.15],       [The speed with which the process returns to the mean],
    [sigma],                       [0.2],        [The volatility of the process],
  ),
  caption: [Hyperparameters for the Ornstein-Uhlenbeck noise process. Both the H-DDPG and HGB-DDPG algorithms use these same parameters.],
  placement: auto,
) <table-hyperparameters-ou>

#figure(
  table(
    columns: (auto, auto, auto),
    stroke: (x: none),
    row-gutter: (2.2pt, auto),

    table.header[Parameter][Value][Comments],
    [distance mode],              [True],       [Use the True distance function or the learned distances from the critic],
    [graph reconstruct freq],     [50],         [Number of timesteps after which to reconstruct the graph from the buffer],
    [max tries],                  [5],          [Number of timesteps to try reaching the waypoint before removing the edge],
    [close enough],               [0.5],        [The threshold distance for considering the waypoint to be reached (chosen to be equal to the environment)],
    [waypoint reward],            [0.0],        [The reward given for reaching a waypoint (chosen to be equal to the environment)],
    [max distance],               [1.0],        [The maximum distance allowed for two states to be connected by an edge],
    [$tau$],                      [0.4],        [Parameter $tau$ for graph sparsification (see @section-prior-work & @section-methods-SGM)],
  ),
  caption: [Hyperparameters exclusive to HGB-DDPG.],
  placement: auto,
) <table-hyperparameters-ghb>


= Results <section-results>

// plots are shown with SEM (standard error (of the mean)) --> MUUUCH better:
// https://stats.stackexchange.com/q/60484/289897
// https://math.stackexchange.com/q/504288

We can see that apart from on environments in which the goal state is very close to the spawing state, the HGB-DDPG algorithm consistently scores higher on in-distribution challenges and has a very clear advantage on out-of-distrbution challenges. The interpretability advantages of the graph module is showcased on a model which was early-stopped while training on the hardest environment, a typical case of cherry picking the model with the best performance only here we can be more certain of the true quality of the model, and on an out-of-distribution challenge where the agent was pretrained on the easiest- and then evaluated on the hardest environment. All plots are shown with the mean performance in terms of success-rate over 300 episodes, aggregated over 50 identical runs, visualized by a bold line and a shaded region is highlighted above and below that line visualizing the standard error of the mean. The color orange is consistently chosen to represent the baseline H-DDPG algorithm while blue shows our HGB-DDPG algorithm.


== In-Distribution Challenges


#figure(
  grid(
    columns: (10em, auto),
    rows: 3,
    image("images/PointEnvs/Empty-close.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-empty-close.png"),
    image("images/PointEnvs/OneLine-close.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-oneline-close.png"),
    image("images/PointEnvs/Hooks-close.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-hooks-close.png"),
  ),  
  caption: [The performance of the H-DDPG baseline (orange) vs our HGB-DDPG algorithm (blue) on the PointEnv environments with distance "close".],
  placement: auto,
)<fig-result-close>

#figure(
  grid(
    columns: (10em, auto),
    rows: 3,
    image("images/PointEnvs/Empty-mid.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-empty-mid.png"),
    image("images/PointEnvs/OneLine-mid.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-oneline-mid.png"),
    image("images/PointEnvs/Hooks-mid.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-hooks-mid.png"),
  ),  
  caption: [The performance of the H-DDPG baseline (orange) vs our HGB-DDPG algorithm (blue) on the PointEnv environments with distance "mid".],
  placement: auto,
)<fig-result-mid>

#figure(
  grid(
    columns: (10em, auto),
    rows: 3,
    image("images/PointEnvs/Empty-far.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-empty-far.png"),
    image("images/PointEnvs/OneLine-far.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-oneline-far.png"),
    image("images/PointEnvs/Hooks-far.png"),
    image("images/DDPG-vs-HGB/plot-ddpg-vs-hgb-hooks-far.png"),
  ),  
  caption: [The performance of the H-DDPG baseline (orange) vs our HGB-DDPG algorithm (blue) on the PointEnv environments with distance "far".],
  placement: auto,
)<fig-result-far>

We can see in @fig-result-close how the asymptotic performance of our algorithm for close distances (top and middle plots) is worse than the standard H-DDPG algorithm without the graph module, this is because the overhead of learning to reach waypoints and managing the internal graph representation is too high a cost when just reaching the nearby state is a very achievable goal. Indeed this effect can be seen again on in @fig-result-mid on the top plot where given enough training time, the model-free H-DDPG algorithm will surpass the performance of the model-based algorithm. 

However, the benefits of our algorithm are more obvious when 1) we are resource contrained with respect to training time and 2) the environment is more complex with respect to sparse rewards and long-horizon goals. We can see this in @fig-result-close (bottom), @fig-result-mid (middle, bottom) and in @fig-result-far (middle). These are long-horizon challenges, environments in which the agent must sometimes (or always) plan around obstacles to reach the goal, which are of course possible for the model-free H-DDPG algorithm to learn, in theory, but would require much more training time (at a rate increasing with the distance to the goal, i.e. the difficulty of the problem). 

On the hardest difficulty, @fig-result-far (bottom), even our HGB-DDPG does not perform well. This is due to the difficulty of training the low-level controller from scratch while simultaneously removing seemlingly infeasible edges, and it becomes a challenge of balancing the maximum number of tries before removing an edge with the graph reconstruction frequency (a testament to the more general problem of hyperparameter tuning in reinforcement learning). This parameter would need to be adjusted for this specific environment for better performance, which is unfortunate.

The dips in performance for the HGB-DDPG agent, visible in @fig-result-close (bottom), @fig-result-mid (middle, bottom), and @fig-result-far (middle, bottom), are due to the graph reconstruction at every 50 episodes resulting in the return of many previously removed invalid transitions but these are quickly removed again after a few episodes.


== Out-of-Distribution Challenges


#figure(
  grid(
    columns: (10em, auto),
    rows: 2,
    image("images/PointEnvs/Hooks-mid.png"),
    image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-hooks-mid.png"),
    image("images/PointEnvs/Hooks-far.png"),
    image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-hooks-far.png"),
  ),
  caption: [The performance of H-DDPG vs HGB-DDPG when the algorithm is pretrained on PointEnv-Empty-close and then evalutated on PointEnv-Hooks-mid and PointEnv-Hooks-far. The HGB-DDPG algorithm does quite well, often achieving 100% success rate between graph reconstructs, while the H-DDPG algorithm consistently fails with a 0% success rate.],
  placement: auto,
)<fig-result-pretrained-hooks>

#figure(
  grid(
    columns: (10em, auto),
    rows: 2,
    image("images/PointEnvs/OneLine-mid.png"),
    image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-oneline-mid.png"),
    image("images/PointEnvs/OneLine-far.png"),
    image("images/DDPG-vs-HGB/plot-pretrained-ddpg-vs-hgb-oneline-far.png"),
  ),
  caption: [The performance of H-DDPG vs HGB-DDPG when the algorithm is pretrained on PointEnv-Empty-close and then evalutated on PointEnv-OneLine-mid and PointEnv-OneLine-far. The HGB-DDPG algorithm does quite well, often achieving 100% success rate between graph reconstructs, while the H-DDPG algorithm consistently achieves 50% success for PointEnv-OneLine-mid and 20% for PointEnv-OneLine-far.],
  placement: auto,
)<fig-result-pretrained-oneline>


The out-of-distribution challenges are where the HGB-DDPG vastly outperforms the H-DDPG. In this case, the agent is pretrained on a PointEnv-Empty-close environment (the easiest) and then the agent is evaluated on a different (harder) environment in a zero-shot fashion, without any further training.

Here, the advantages of the graph module start to become clear as we can see in @fig-result-pretrained-hooks, where we focus on the two hardest difficulties (PointEnv-Hooks-far and PointEnv-Hooks-mid), as well as @fig-result-pretrained-oneline, with two easier difficulties but both with a potential obstacle in the way (PointEnv-OneLine-far and PointEnv-OneLine-mid). The H-DDPG agent consistently fails if there is any obstruction between the agent and the goal that was not present during training, while the HGB-DDPG agent can plan around these new obstacles with ease. Pretraining on an easy environment further benefits the HGB-DDPG agent such that it is now able to perform very well on the hardest environment which was hard-to-impossible to do previously (Compare @fig-result-pretrained-hooks (bottom) with @fig-result-far (bottom)).

Indeed the fact that we are pretraining the low-level controller on an easier task allows the high-level agent to produce a better model by not removing transitions it considers infeasible when they are just not reached due to the performance of the low-level controller. This also results in a better distribution of incoming datapoints as the agent reaches the goal quite quickly after the initial data collection phase. There is potential for improvement here, we note that one of the main problems (indeed a central problem in reinforcement learning) is keeping the set of datapoints in the buffer well distributed over the state space.


#[
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
    // placement: auto,
    caption: [The mean in-distribution performance in terms of success rate, as well as the standard error of the mean, of the H-DDPG and HGB-DDPG algorithms on the various environments.],
  ) <table-results-data>  
]

#[
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
    // placement: auto,
    caption: [The mean out-of-distribution performance in terms of success rate, as well as the standard error of the mean, of the H-DDPG and HGB-DDPG algorithms on the various environments.],
  ) <table-results-data>  
]

== Interpretability Benefits


We can also inspect the interal graph representation to gain insights into the behaviour of the agent, explain the reason for its choices, identify potential flaws in its model, and even manually correct these flaws if necessary. To this end, we have developed a graphical interface along with the Rust implementation that helps visualize this graph and observe the behaviour of the agent as it acts and learns.

As an example to showcase this we have cherry-picked the best model on the hardest environment (@fig-result-far (right) at timestep 49 on a favorable run), something which can be problematic due to the fact that this outlier of great performance could be caused by the model cheating or overfitting or otherwise not actually having learnt it is supposed to have. In this case, however, we can take a look inside the blackbox and make sure. We may already have a theory about how a solution would look like for the PointEnv-Hooks-far environment, but if we plot the agents graph representation on top of the environment (@fig-result-interpretability-example), and highlight the plan (yellow) that the agent has generated to reach the goal, we can see exactly that this is a valid solution. We could even edit this graph directly if we see an invalid edge present in the graph, or even a valid edge not present in the graph.

#figure(
  image("images/PointEnv-Graph/graph-interpretability-example.png"),
  caption: [A cherry picked model with great performance visualized such as to showcase the interpretability benefits of the graph module. The sparse graph shows the agents internal representation of the environment, and the yellow path shows the current plan in terms of successive waypoints that the agent is attempting to reach to reach the goal.],
  placement: auto,
)<fig-result-interpretability-example>

We can also observe the high-level agent adapt to an out-of-distribution challenge by visualizing the graph as it changes. Consider @fig-PointEnv-Graph where we visualize a HGB-DDPG agent that has been pretrained on PointEnv-Empty and that has just been deployed on PointEnv-Hooks. We can see that it has a well-distributed buffer of states (bottom left) due to our data-collection phase and we can see that the graph is sparsified in a way that still preserves this state-coverage (bottom right), but we can clearly see that the agent is suggesting an infeasible plan (top right) that would have been possible in the environment it was trained on but not in this new environment. Now consider @fig-PointEnv-Graph-50e, where we can see what happens after letting the agent run for 50 episodes. The plan is now ideal (top right), and we can also see #emph("why"): The agent has removed all those infeasible edges from the graph where it tried and failed to transition over, leaving gaps exactly there where the walls block the path and allowing for a feasible plan to be constructed and executed. At this point, the agent reaches the goal with a very high success rate.

#figure(
  grid(
    columns: 2,
    rows: 2,
    image("images/PointEnvs/Hooks-far.png"),
    image("images/PointEnv-Graph/PointEnv-Hooks-far--plan.png"),
    image("images/PointEnv-Graph/PointEnv-Hooks-far--buffer.png"),
    image("images/PointEnv-Graph/PointEnv-Hooks-far--graph-plan.png"),
  ),
  caption: [The state of the HGB-DDPG agent, pretrained on PointEnv-Empty-close, just deployed on PointEnv-Hooks-far and visualized in the environment (top left), with the generated plan (top right), the state of the replay buffer (bottom left), and the internal graph resentation including the plan (bottom right).],
  placement: auto,
)<fig-PointEnv-Graph>

#figure(
  grid(
    columns: 2,
    rows: 2,
    image("images/PointEnvs/Hooks-far.png"),
    image("images/PointEnv-Graph/PointEnv-Hooks-far--50e-plan.png"),
    image("images/PointEnv-Graph/PointEnv-Hooks-far--50e-buffer.png"),
    image("images/PointEnv-Graph/PointEnv-Hooks-far--50e-graph-plan.png"),
  ),
  caption: [The state of the HGB-DDPG agent, pretrained on PointEnv-Empty-close, deployed on PointEnv-Hooks-far and visualized in the environment (top left), with the generated plan (top right), the state of the replay buffer (bottom left), and the internal graph resentation including the plan (bottom right). The different to @fig-PointEnv-Graph is that this agent has run for 50 episodes instead of 0.],
  placement: auto,
)<fig-PointEnv-Graph-50e>


= Discussion & Future Work <section-discussion>


We have demonstrated that this method, combining graph-based planning and deep reinforcement learning, is indeed a promising approach providing a number of benefits in certain situations. The quantitative performance benefits on in-distribution challenges are marginal, only present if training time is a constraint and the goal is sufficiently far away, which is to be expected for a model-based vs a model-free method. However, when the low-level controller is pretrained, our method shows superior performance on all challanges without retraining and demonstrates a greater level of generalization and long-horizon planning. Furthermore, the model is interpretable and even editable which are major advantages for certain use-cases.

Due to the difficulties of operating within a young language without a mature ecosystem and the time constraints of this thesis, there are a number of easy improvements that we did not implement. For example, to improve training speed and stability, hindsight experience replay @HER can be implemented as well as distributional RL @DistributionalRL as proposed in @SoRB.

With better hardware and thus longer training times, a more in-depth hyperparameter analysis can be done and harder and more diverse environments could be tackled. Interesting topics might include how the interpretability of the graph transfers to non-navigational environments (i.e. where there is no notion of euclidean distance) and how to deal with the problem of perceptual aliasing in environments with high-dimensional observations (i.e. where similar observations might be temporally far apart).

The most interesting topics for future work certainly include addressing the two problematic assumptions we make on the environment in our thesis: 1) That we have access to the true underlying distance function between any two states, and 2) that we assume the ability to spawn the agent in locations randomly distributed over the state-space. For the former, the next logical step is to make use of the learned distance function in the critic network and make it work using, for example, the tricks proposed by @SoRB and @SGM such as pessimistically aggregating over ensembles of critic networks, using distributional RL, and normalizing observations correctly. For the latter, there is a lot of potential for improved exploration strategies that can be implemented to make use of the graph such as explicitly visiting nodes at the frontiers of the exploration horizon according to the graph and then randomly exploring from there or keeping track of information on the frequency of finding novel states nearby the nodes in the graph and then sampling high-potential exploration sub-goals intelligently with e.g. Thompson sampling.


= Acknowledgments


I would like to thank my supervisor, Dr. Matthia Sabatelli, for his guidance and support along the way, and to thank the University of Groningen for providing me with an excellent education. This thesis is especially dedicated to the memory of Dr. Marco Wiering, who was a friend and a mentor to me.














// TODO

// Notation consistency todo!
// Last re-read + looks good check

