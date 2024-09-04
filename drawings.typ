#import "@preview/cetz:0.2.0"
#import "@preview/diagraph:0.2.1": render as render-graph
#import cetz.draw: rect, circle, content, line, bezier, on-layer, mark



#let arrowhead = ">"
#let arrowhead-update = "<>"
#let color-black = black
#let color-yellow = rgb(255, 220, 0, 50%)
#let color-gray = luma(200)

#let tbox(
    a: (0, 0),
    b: (1, 1),
    label: "label",
    text: "",
    fill: none,
) = {
  rect(
    a, b,
    radius: 10pt,
    name: label,
    fill: fill,
  )
  content(
    label + ".center",
    align(
      center,
      box(
        fill: fill,
        text
      )
    )
  )
}







#let agent-environment-loop = cetz.canvas({
  let c1 = color-black
  let c2 = color-black
  let c3 = color-black
  let c4 = color-black
  let stroke1 = 2pt + c1
  let stroke2 = 2pt + c2
  let stroke3 = 1pt + c3
  let stroke4 = stroke3 // 1pt + c4
  
  let env_a = (1, 0)
  let env_b = (4, 1)

  let agent_a = (1.75, 3)
  let agent_b = (3.25, 4)

  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    text: "Agent",
  )
  tbox(
    a: env_a,
    b: env_b,
    label: "environment",
    text: "Environment",
  )


  // Left lines

  let mid_y = (env_b.last() + agent_a.last()) / 2
  let mid_x = (env_a.first() + env_b.first()) / 2

  let anchor_up = 160deg
  let anchor_lo = 200deg

  let x_line1 = env_a.first() - 2
  let x_line2 = env_a.first() - 1.5
  let x_line3 = env_b.first() + 1

  line(
    (name: "environment", anchor: anchor_lo),
    ((name: "environment", anchor: anchor_lo), "-|", (x_line1, mid_y)),
    (x_line1, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-state-t+1",
  )
  line(
    (x_line1, mid_y),
    ((x_line1, mid_y), "|-", (name: "agent", anchor: anchor_up)),
    (name: "agent", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-agent-state-t",
  )

  line(
    (name: "environment", anchor: anchor_up),
    ((name: "environment", anchor: anchor_up), "-|", (x_line2, mid_y)),
    (x_line2, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-reward-t+1",
  )
  line(
    (x_line2, mid_y),
    ((x_line2, mid_y), "|-", (name: "agent", anchor: anchor_lo)),
    (name: "agent", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
    name: "env-agent-reward-t",
  )

  line(
    (x_line1 - 1, mid_y),
    (x_line2 + 1, mid_y),
    stroke: (dash: "dotted"),
    name: "dotted",
  )

  content(
    (x_line1, mid_y),
    align(right, box(fill: white, "\n" + $O_(t+1)$)),
    padding: .1,
    anchor: "north-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, "\n" + $R_(t+1)$)),
    padding: .1,
    anchor: "north-west",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, $O_t$ + "\nobserv.")),
    padding: .1,
    anchor: "south-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, $R_t$ + "\nreward")),
    padding: .1,
    anchor: "south-west",
  )

  
  // Right line

  line(
    "agent",
    ("agent", "-|", (x_line3, mid_y)),
    ((x_line3, mid_y), "|-", "environment.east"),
    "environment.east",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "agent-env-action-t",
  )
  content(
    (x_line3, mid_y),
    align(left, box(fill: white, $A_t$ + "\naction")),
    padding: .1,
    anchor: "south-west",
  )
})



#let agent-environment-loop-goal-conditioned = cetz.canvas({
  let c1 = color-black
  let c2 = color-black
  let c3 = color-black
  let c4 = color-black
  let stroke1 = 2pt + c1
  let stroke2 = 2pt + c2
  let stroke3 = 1pt + c3
  let stroke4 = stroke3 // 1pt + c4
  
  let env_a = (1.5, 0)
  let env_b = (4, 1)

  let agent_a = (1.75, 3)
  let agent_b = (3.25, 4)

  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    text: "Agent",
  )
  tbox(
    a: env_a,
    b: env_b,
    label: "environment",
    text: "Environment",
  )


  // Left lines

  let mid_y = (env_b.last() + agent_a.last()) / 2
  let mid_x = (env_a.first() + env_b.first()) / 2

  let anchor_up = 160deg
  let anchor_lo = 200deg

  let x_line1 = env_a.first() - 1.5
  let x_line2 = env_a.first() - 1.0
  let x_line3 = env_b.first() + 1

  line(
    (name: "environment", anchor: anchor_lo),
    ((name: "environment", anchor: anchor_lo), "-|", (x_line1, mid_y)),
    (x_line1, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-state-t+1",
  )
  line(
    (x_line1, mid_y),
    ((x_line1, mid_y), "|-", (name: "agent", anchor: anchor_up)),
    (name: "agent", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-agent-state-t",
  )

  line(
    (name: "environment", anchor: anchor_up),
    ((name: "environment", anchor: anchor_up), "-|", (x_line2, mid_y)),
    (x_line2, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-reward-t+1",
  )
  line(
    (x_line2, mid_y),
    ((x_line2, mid_y), "|-", (name: "agent", anchor: anchor_lo)),
    (name: "agent", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
    name: "env-agent-reward-t",
  )

  line(
    (x_line1 - 1, mid_y),
    (x_line2 + 1, mid_y),
    stroke: (dash: "dotted"),
    name: "dotted",
  )

  content(
    (x_line1, mid_y),
    align(right, box(fill: white, "\n" + $G_(t+1), O_(t+1)$)),
    padding: .1,
    anchor: "north-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, "\n" + $R_(t+1)$)),
    padding: .1,
    anchor: "north-west",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, $G_t,O_t$ + "\nGC-observ.")),
    padding: .1,
    anchor: "south-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, $R_t$ + "\nreward")),
    padding: .1,
    anchor: "south-west",
  )

  
  // Right line

  line(
    "agent",
    ("agent", "-|", (x_line3, mid_y)),
    ((x_line3, mid_y), "|-", "environment.east"),
    "environment.east",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "agent-env-action-t",
  )
  content(
    (x_line3, mid_y),
    align(left, box(fill: white, $A_t$ + "\naction")),
    padding: .1,
    anchor: "south-west",
  )
})



#let agent-model-environment-loop = cetz.canvas({
  let c1 = color-black
  let c2 = color-black
  let c3 = color-black
  let c4 = color-black
  let stroke1 = 2pt + c1
  let stroke2 = 2pt + c2
  let stroke3 = 1pt + c3
  let stroke4 = stroke3 // 1pt + c4
  
  let env_a = (1, 0)
  let env_b = (4, 1)

  let agent_a = (0.0, 2.75)
  let agent_b = (4.75, 6.25)

  let model_a = (1.75, 5.25)
  let model_b = (3.25, 6)

  let inner_agent_a = (0.5, 3)
  let inner_agent_b = (4.5, 3.75)


  
  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    fill: color-yellow,
  )
  tbox(
    a: model_a,
    b: model_b,
    label: "model",
    text: "Model",
  )
  tbox(
    a: inner_agent_a,
    b: inner_agent_b,
    label: "agent",
    text: "Agent",
  )

  
  tbox(
    a: env_a,
    b: env_b,
    label: "environment",
    text: "Environment",
  )



  // Left lines

  let mid_y = (env_b.last() + agent_a.last()) / 2
  let mid_x = (env_a.first() + env_b.first()) / 2

  let anchor_up = 160deg
  let anchor_lo = 200deg

  let x_line1 = env_a.first() - 2
  let x_line2 = env_a.first() - 1.5
  let x_line3 = env_b.first() + 1

  line(
    (name: "environment", anchor: anchor_lo),
    ((name: "environment", anchor: anchor_lo), "-|", (x_line1, mid_y)),
    (x_line1, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-state-t+1",
  )
  line(
    (x_line1, mid_y),
    ((x_line1, mid_y), "|-", (name: "agent", anchor: anchor_up)),
    (name: "agent", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-agent-state-t",
  )

  line(
    (name: "environment", anchor: anchor_up),
    ((name: "environment", anchor: anchor_up), "-|", (x_line2, mid_y)),
    (x_line2, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-reward-t+1",
  )
  line(
    (x_line2, mid_y),
    ((x_line2, mid_y), "|-", (name: "agent", anchor: anchor_lo)),
    (name: "agent", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
    name: "env-agent-reward-t",
  )

  line(
    (x_line1 - 1, mid_y),
    (x_line2 + 1, mid_y),
    stroke: (dash: "dotted"),
    name: "dotted",
  )

  content(
    (x_line1, mid_y),
    align(right, box(fill: white, "\n" + $O_(t+1)$)),
    padding: .1,
    anchor: "north-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, "\n" + $R_(t+1)$)),
    padding: .1,
    anchor: "north-west",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, $O_t$ + "\nobserv.")),
    padding: .1,
    anchor: "south-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, $R_t$ + "\nreward")),
    padding: .1,
    anchor: "south-west",
  )

  
  // Right line

  line(
    "agent",
    ("agent", "-|", (x_line3, mid_y)),
    ((x_line3, mid_y), "|-", "environment.east"),
    "environment.east",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "model-env-action-t",
  )
  content(
    (x_line3, mid_y),
    align(left, box(fill: white, $A_t$ + "\naction")),
    padding: .1,
    anchor: "south-west",
  )


  // Inner lines

  line(
    "model",
    ("model", "-|", (name: "agent", anchor: 45deg)),
    (name: "agent", anchor: 45deg),
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "model-agent",
  )
  line(
    (name: "agent", anchor: 135deg),
    ("model", "-|", (name: "agent", anchor: 135deg)),
    "model",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "agent-model",
  )
  content(
    "agent-model.mid",
    align(left, box(text("Update\nModel", hyphenate: false))),
    padding: .05,
    anchor: "north-west",
  )
  content(
    "model-agent.mid",
    align(left, box(text("Sample\nModel", hyphenate: false))),
    padding: .05,
    anchor: "north-east",
  )
})



#let algorithm-policy-environment-loop = cetz.canvas({
  let c1 = color-black
  let c2 = color-black
  let c3 = color-black
  let c4 = color-black
  let stroke1 = 2pt + c1
  let stroke2 = 2pt + c2
  let stroke3 = 1pt + c3
  let stroke4 = stroke3 // 1pt + c4
  
  let env_a = (1, 0)
  let env_b = (4, 1)

  let agent_a = (0.5, 2.75)
  let agent_b = (4.5, 6.25)

  let policy_a = (1.5, 5.25)
  let policy_b = (3.5, 6)

  let algo_a = (1.5, 3)
  let algo_b = (3.5, 3.75)


  
  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    fill: color-yellow,
  )
  tbox(
    a: policy_a,
    b: policy_b,
    label: "policy",
    text: "Policy " + $pi$,
  )
  tbox(
    a: algo_a,
    b: algo_b,
    label: "algo",
    text: "Algorithm",
  )

  
  tbox(
    a: env_a,
    b: env_b,
    label: "environment",
    text: "Environment",
  )



  // Left lines

  let mid_y = (env_b.last() + agent_a.last()) / 2
  let mid_x = (env_a.first() + env_b.first()) / 2

  let anchor_up = 160deg
  let anchor_lo = 200deg

  let x_line1 = env_a.first() - 2
  let x_line2 = env_a.first() - 1.5
  let x_line3 = env_b.first() + 1

  line(
    (name: "environment", anchor: anchor_lo),
    ((name: "environment", anchor: anchor_lo), "-|", (x_line1, mid_y)),
    (x_line1, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-state-t+1",
  )
  line(
    (x_line1, mid_y),
    ((x_line1, mid_y), "|-", "policy"),
    "policy",
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-policy-state-t",
  )
  line(
    ((x_line1, mid_y), "|-", (name: "algo", anchor: anchor_up)),
    (name: "algo", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-alg-state-t",
  )

  line(
    (name: "environment", anchor: anchor_up),
    ((name: "environment", anchor: anchor_up), "-|", (x_line2, mid_y)),
    (x_line2, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
    name: "env-agent-reward-t+1",
  )
  line(
    (x_line2, mid_y),
    ((x_line2, mid_y), "|-", (name: "algo", anchor: anchor_lo)),
    (name: "algo", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
    name: "env-alg-reward-t",
  )

  line(
    (x_line1 - 1, mid_y),
    (x_line2 + 1, mid_y),
    stroke: (dash: "dotted"),
    name: "dotted",
  )

  content(
    (x_line1, mid_y),
    align(right, box(fill: white, "\n" + $O_(t+1)$)),
    padding: .1,
    anchor: "north-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, "\n" + $R_(t+1)$)),
    padding: .1,
    anchor: "north-west",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, $O_t$ + "\nobserv.")),
    padding: .1,
    anchor: "south-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, $R_t$ + "\nreward")),
    padding: .1,
    anchor: "south-west",
  )

  
  // Right line

  line(
    "policy",
    ("policy", "-|", (x_line3, mid_y)),
    ((x_line3, mid_y), "|-", "environment.east"),
    "environment.east",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "policy-env-action-t",
  )
  content(
    (x_line3, mid_y),
    align(left, box(fill: white, $A_t$ + "\naction")),
    padding: .1,
    anchor: "south-west",
  )


  // Inner lines

  let right_between_policy = (
    (policy_b.first() + agent_b.first()) / 2,
    (policy_a.last() + policy_b.last()) / 2,
  )
  let right_between_algo = (
    (algo_b.first() + agent_b.first()) / 2,
    (algo_a.last() + algo_b.last()) / 2,
  )

  line(
    ("policy", "-|", right_between_policy),
    right_between_algo,
    "algo",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "policy-alg-action-t",
  )
  line(
    (name: "algo", anchor: 120deg),
    (name: "policy", anchor: 240deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke3,
    name: "alg-policy-update",
  )
  content(
    "alg-policy-update.mid",
    align(left, box(text("Policy\nUpdate", hyphenate: false))),
    padding: .2,
    anchor: "west",
  )
})



#let online-vs-offline-learning = cetz.canvas({
  let stroke = 1pt + color-black

  let anchor_up_left = 120deg
  let anchor_lo_left = 240deg
  let anchor_up_right = 60deg
  let anchor_lo_right = 300deg

  let box_width = 1.5
  let box_height = 1

  let x_distance = 3.0
  let y_distance = 5.5

  let env_a = (1, 0)
  let env_b = (
    env_a.first() + box_width,
    env_a.last() + box_height,
  )

  let agent_a = (1, y_distance)
  let agent_b = (
    agent_a.first() + box_width,
    agent_a.last() + box_height,
  )

  
  /////////// Leftmost 
  let idx = 0

  
  // Agent boxes
  let agent_name = "agent0" + str(idx)
  let env_name = "env0" + str(idx)
  let arr_up_name = "line_up0" + str(idx)
  let arr_lo_name = "line_lo0" + str(idx)
  
  tbox(
    a: (agent_a.first() + (idx * x_distance), agent_a.last()),
    b: (agent_b.first() + (idx * x_distance), agent_b.last()),
    label: agent_name,
    text: "Agent",
  )
  tbox(
    a: (env_a.first() + (idx * x_distance), env_a.last()),
    b: (env_b.first() + (idx * x_distance), env_b.last()),
    label: env_name,
    text: "Env.",
  )
  // Lines: Agent --> Env
  line(
    (name: agent_name, anchor: anchor_lo_left),
    (name: env_name, anchor: anchor_up_left),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: arr_up_name,
  )
  content(
    arr_up_name + ".mid",
    align(left, box($A_t$)),
    padding: .1,
    anchor: "east",
  )
  // Lines: Env --> Buffer --> Agent
  line(
    (name: env_name, anchor: anchor_up_right),
    (name: agent_name, anchor: anchor_lo_right),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: arr_lo_name,
  )
  content(
    arr_lo_name + ".mid",
    align(left, box($R_(t+1)$ + "\n" + $O_(t+1)$)),
    padding: .1,
    anchor: "west",
  )

  
  /////////// Middle
  let idx = 1

  
  // Agent boxes
  let agent_name = "agent" + str(idx)
  let env_name = "env" + str(idx)
  let arr_up_name = "line_up" + str(idx)
  let arr_lo_name = "line_lo" + str(idx)
  
  tbox(
    a: (agent_a.first() + (idx * x_distance), agent_a.last()),
    b: (agent_b.first() + (idx * x_distance), agent_b.last()),
    label: agent_name,
    text: "Agent",
  )
  tbox(
    a: (env_a.first() + (idx * x_distance), env_a.last()),
    b: (env_b.first() + (idx * x_distance), env_b.last()),
    label: env_name,
    text: "Env.",
  )
  // Lines: Agent --> Env
  line(
    (name: agent_name, anchor: anchor_lo_left),
    (name: env_name, anchor: anchor_up_left),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: arr_up_name,
  )
  content(
    arr_up_name + ".mid",
    align(left, box($A_t$)),
    padding: .1,
    anchor: "east",
  )
  // Buffer box
  let buf_name = "buffer"
  let anchor_buf_lo = 265deg
  let anchor_buf_up = 95deg

  let mid_y = ((agent_a.last() + env_b.last()) / 2) - 0.6
  let x_offset = 0.5

  tbox(
    a: (agent_a.first() + (idx * x_distance) + x_offset, mid_y - (box_height / 2)),
    b: (agent_b.first() + (idx * x_distance) + x_offset, mid_y + (box_height / 2)),
    label: buf_name,
    text: "Buffer",
    fill: color-gray,
  )
  // Lines: Env --> Buffer --> Agent
  line(
    (name: env_name, anchor: anchor_up_right),
    (name: buf_name, anchor: anchor_buf_lo),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: arr_lo_name,
  )
  content(
    arr_lo_name + ".mid",
    align(left, box($R_(t+1)$ + "\n" + $O_(t+1)$)),
    padding: .1,
    anchor: "west",
  )
  line(
    (name: buf_name, anchor: anchor_buf_up),
    (name: agent_name, anchor: anchor_lo_right),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: arr_lo_name,
  )
  content(
    arr_lo_name + ".mid",
    align(left, box(
      $O_(x)$
      + "\n"
      + $A_(x)$
      + "\n"
      + $R_(x+1)$
      + "\n"
      + $O_(x+1)$
    )),
    padding: .1,
    anchor: "west",
  )
  
  
  /////////// Right
  let idx = 2

  
  // Agent boxes
  let agent_name = "agent" + str(idx)
  let env_name = "env" + str(idx)
  let arr_up_name = "line_up" + str(idx)
  let arr_lo_name = "line_lo" + str(idx)
  
  tbox(
    a: (agent_a.first() + (idx * x_distance), agent_a.last()),
    b: (agent_b.first() + (idx * x_distance), agent_b.last()),
    label: agent_name,
    text: "Agent",
  )
  tbox(
    a: (env_a.first() + (idx * x_distance), env_a.last()),
    b: (env_b.first() + (idx * x_distance), env_b.last()),
    label: env_name,
    text: "Dataset",
    fill: color-gray,
  )
  // Lines: Env --> Buffer --> Agent
  line(
    (name: env_name, anchor: "north"),
    (name: agent_name, anchor: "south"),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: arr_lo_name,
  )
  content(
    arr_lo_name + ".mid",
    align(left, box(
      $O_(x)$
      + "\n"
      + $A_(x)$
      + "\n"
      + $R_(x+1)$
      + "\n"
      + $O_(x+1)$
    )),
    padding: .1,
    anchor: "west",
  )
})





#let on-policy-vs-off-policy-algorithms = cetz.canvas({
  let stroke = 1pt + color-black
  let stroke_fat = 2pt + color-black
  
  let anchor_up = 160deg
  let anchor_lo = 200deg


  // LEFT BOX


  let big_box_width = 2.725
  let big_box_height = 7.5

  let small_box_height = 1
  let small_box_width = 1.5

  let x_offset = 0.1

  
  let agent_a = (x_offset, 0)
  let agent_b = (x_offset + big_box_width, big_box_height)

  let left_limit = agent_a.first() - 0.5
  let right_limit = agent_b.first() + 0.5

  let policy_a = (
    x_offset + 0.5,
    agent_b.last() - 0.5 - small_box_height,
  )
  let policy_b = (
    x_offset + 0.5 + small_box_width,
    agent_b.last() - 0.5,
  )

  let algo_shift = 3.0// 0.5// 2.75
  let algo_a = (
    x_offset + 0.5,
    agent_a.last() + algo_shift,
  )
  let algo_b = (
    x_offset + 0.5 + small_box_width,
    agent_a.last() + algo_shift + small_box_height,
  )


  // Agent box

  
  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    fill: color-yellow,
  )
  tbox(
    a: policy_a,
    b: policy_b,
    label: "policy",
    text: "Policy " + $pi$,
  )
  tbox(
    a: algo_a,
    b: algo_b,
    label: "algo",
    text: "Algo.",
  )



  // Left lines

  line(
    ((left_limit, 0), "|-", "policy"),
    "policy",
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "env-policy-state-t",
  )
  line(
    ((left_limit, 0), "|-", (name: "algo", anchor: anchor_up)),
    (name: "algo", anchor: anchor_up),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "env-alg-state-t",
  )
  line(
    ((left_limit, 0), "|-", (name: "algo", anchor: anchor_lo)),
    (name: "algo", anchor: anchor_lo),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "env-alg-reward-t",
  )
  content(
    "env-policy-state-t.start",
    align(right, box(fill: white, $O_(t+1)$)),
    padding: .2,
    anchor: "north",
  )
  content(
    "env-alg-state-t.start",
    align(right, box(fill: white, $O_(t+1)$)),
    padding: .3,
    anchor: "south",
  )
  content(
    "env-alg-reward-t.start",
    align(left, box(fill: white, $R_(t+1)$)),
    padding: .2,
    anchor: "north",
  )

  
  // Right line

  line(
    "policy",
    ("policy", "-|", (right_limit, 0)),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "policy-env-action-t",
  )
  content(
    "policy-env-action-t.end",
    align(left, box(fill: white, $A_t$)),
    padding: .2,
    anchor: "north",
  )


  // Inner lines

  let right_between_policy = (
    (policy_b.first() + agent_b.first()) / 2,
    (policy_a.last() + policy_b.last()) / 2,
  )
  let right_between_algo = (
    (algo_b.first() + agent_b.first()) / 2,
    (algo_a.last() + algo_b.last()) / 2,
  )

  line(
    ("policy", "-|", right_between_policy),
    right_between_algo,
    "algo",
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "policy-alg-action-t",
  )

  
  // Line: Policy update
  line(
    (name: "algo", anchor: 120deg),
    (name: "policy", anchor: 240deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke,
    name: "alg-policy-update",
  )
  content(
    "alg-policy-update.mid",
    align(left, box(text("Policy\nUpdate", hyphenate: false))),
    padding: .2,
    anchor: "west",
  )



  
  // DOTTED BORDER

  let dotted_x = 3.625

  line(
    (dotted_x, 0),
    (dotted_x, big_box_height),
    stroke: (dash: "dotted"),
    name: "dotted",
  )



  
  // RIGHT BOX


  let x_offset = 4.65

  
  let agent_a = (x_offset, 0)
  let agent_b = (x_offset + big_box_width, big_box_height)

  let left_limit = agent_a.first() - 0.5
  let right_limit = agent_b.first() + 0.5

  let policy_a = (
    x_offset + 0.5,
    agent_b.last() - 0.5 - small_box_height,
  )
  let policy_b = (
    x_offset + 0.5 + small_box_width,
    agent_b.last() - 0.5,
  )

  let algo_shift = 3.0
  let algo_a = (
    x_offset + 0.5,
    agent_a.last() + algo_shift,
  )
  let algo_b = (
    x_offset + 0.5 + small_box_width,
    agent_a.last() + algo_shift + small_box_height,
  )

  let policy2_a = (
    x_offset + 0.5,
    agent_a.last() + 0.5 + small_box_height,
  )
  let policy2_b = (
    x_offset + 0.5 + small_box_width,
    agent_a.last() + 0.5,
  )

  // Agent box

  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    fill: color-yellow,
  )
  tbox(
    a: policy_a,
    b: policy_b,
    label: "policy",
    text: "Policy " + $b$,
  )
  tbox(
    a: policy2_a,
    b: policy2_b,
    label: "policy2",
    text: "Policy " + $pi$,
  )
  tbox(
    a: algo_a,
    b: algo_b,
    label: "algo",
    text: "Algo.",
  )


  // Left lines

  line(
    ((left_limit, 0), "|-", "policy"),
    "policy",
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "env-policy-state-t",
  )
  line(
    ((left_limit, 0), "|-", (name: "algo", anchor: anchor_up)),
    (name: "algo", anchor: anchor_up),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "env-alg-state-t",
  )
  line(
    ((left_limit, 0), "|-", (name: "algo", anchor: anchor_lo)),
    (name: "algo", anchor: anchor_lo),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "env-alg-reward-t",
  )
  content(
    "env-policy-state-t.start",
    align(right, box(fill: white, $O_(t+1)$)),
    padding: .2,
    anchor: "north",
  )
  content(
    "env-alg-state-t.start",
    align(right, box(fill: white, $O_(t+1)$)),
    padding: .3,
    anchor: "south",
  )
  content(
    "env-alg-reward-t.start",
    align(left, box(fill: white, $R_(t+1)$)),
    padding: .2,
    anchor: "north",
  )

  
  // Right line

  line(
    "policy",
    ("policy", "-|", (right_limit, 0)),
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "policy-env-action-t",
  )
  content(
    "policy-env-action-t.end",
    align(left, box(fill: white, $A_t$)),
    padding: .2,
    anchor: "north",
  )


  // Inner lines

  let right_between_policy = (
    (policy_b.first() + agent_b.first()) / 2,
    (policy_a.last() + policy_b.last()) / 2,
  )
  let right_between_algo = (
    (algo_b.first() + agent_b.first()) / 2,
    (algo_a.last() + algo_b.last()) / 2,
  )

  line(
    ("policy", "-|", right_between_policy),
    right_between_algo,
    "algo",
    mark: (end: arrowhead, fill: color-black),
    stroke: stroke,
    name: "policy-alg-action-t",
  )

  
  
  
  // Line: Policy update
  line(
    (name: "algo", anchor: 240deg),
    (name: "policy2", anchor: 120deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke,
    name: "alg-policy-update",
  )
  content(
    "alg-policy-update.mid",
    align(left, box(text("Policy\nUpdate", hyphenate: false))),
    padding: .2,
    anchor: "west",
  )
})




#let actor-critic-architecture = cetz.canvas({
  let c1 = color-black
  let c2 = color-black
  let c3 = color-black
  let c4 = color-black
  let stroke1 = 1pt + c1
  let stroke2 = 1pt + c2
  let stroke3 = 1pt + c3
  let stroke4 = stroke3 // 1pt + c4
  
  let env_a = (1.25, 0)
  let env_b = (5.5, 1)

  let agent_a = (0.5, 2.75)
  let agent_b = (6.25, 6.25)

  let policy_a = (2.75, 5.25)
  let policy_b = (5.5, 6)

  let algo_a = (2.75, 3)
  let algo_b = (5.5, 3.75)

  let buffer_a = (1.0, 3.0)
  let buffer_b = (2.0, 6)


  
  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    fill: color-yellow,
  )
  tbox(
    a: policy_a,
    b: policy_b,
    label: "policy",
    text: "Actor / Policy",
  )
  tbox(
    a: algo_a,
    b: algo_b,
    label: "algo",
    text: "Critic / Value F.",
  )
  tbox(
    a: buffer_a,
    b: buffer_b,
    label: "buffer",
    text: "Buffer",
    fill: color-gray,
  )

  
  tbox(
    a: env_a,
    b: env_b,
    label: "environment",
    text: "Environment",
  )



  // Left lines

  let mid_y = (env_b.last() + agent_a.last()) / 2
  let mid_x = (env_a.first() + env_b.first()) / 2

  let anchor_up = 160deg
  let anchor_lo = 200deg

  let x_line1 = env_a.first() - 1.5
  let x_line2 = env_a.first() - 1
  let x_line3 = env_b.first() + 1

  // Lines: Env --> Buffer
  line(
    (name: "environment", anchor: anchor_lo),
    ((name: "environment", anchor: anchor_lo), "-|", (x_line1, mid_y)),
    (x_line1, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
  )
  line(
    (x_line1, mid_y),
    ((x_line1, mid_y), "|-", (name: "buffer", anchor: anchor_up)),
    (name: "buffer", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
  )

  // Lines: Env --> Buffer
  line(
    (name: "environment", anchor: anchor_up),
    ((name: "environment", anchor: anchor_up), "-|", (x_line2, mid_y)),
    (x_line2, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
  )
  line(
    (x_line2, mid_y),
    ((x_line2, mid_y), "|-", (name: "buffer", anchor: anchor_lo)),
    (name: "buffer", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
  )
  
  // Lines: Buffer --> Policy
  line(
    ((buffer_b.first(), mid_y), "|-", "policy"),
    "policy",
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "buffer-policy-x",
  )

  // Lines: Buffer --> Value Function
  line(
    ((buffer_b.first(), mid_y), "|-", (name: "algo", anchor: anchor_lo)),
    (name: "algo", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
    name: "env-alg-reward-t",
  )
  line(
    ((buffer_b.first(), mid_y), "|-", (name: "algo", anchor: anchor_up)),
    (name: "algo", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-alg-state-t",
  )


  // Lines: Dotted
  line(
    (x_line1 - 1, mid_y),
    (x_line2 + 1, mid_y),
    stroke: (dash: "dotted"),
    name: "dotted",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, "\n" + $O_(t+1)$)),
    padding: .1,
    anchor: "north-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, "\n" + $R_(t+1)$)),
    padding: .1,
    anchor: "north-west",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, $O_t$ + "\nobserv.")),
    padding: .1,
    anchor: "south-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, $R_t$ + "\nreward")),
    padding: .1,
    anchor: "south-west",
  )

  
  // Right line

  line(
    "policy",
    ("policy", "-|", (x_line3, mid_y)),
    ((x_line3, mid_y), "|-", "environment.east"),
    "environment.east",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "policy-env-action-t",
  )
  content(
    (x_line3, mid_y),
    align(left, box(fill: white, $A_t$ + "\naction")),
    padding: .1,
    anchor: "south-west",
  )


  // Inner lines

  let right_between_policy = (
    (policy_b.first() + agent_b.first()) / 2,
    (policy_a.last() + policy_b.last()) / 2,
  )
  let right_between_algo = (
    (algo_b.first() + agent_b.first()) / 2,
    (algo_a.last() + algo_b.last()) / 2,
  )

  line(
    ("policy", "-|", right_between_policy),
    right_between_algo,
    "algo",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "policy-alg-action-t",
  )
  let policy_update_start = (name: "algo", anchor: 100deg)
  line(
    policy_update_start,
    (name: "policy", anchor: 260deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke2,
    name: "alg-policy-update",
  )
  bezier(
    policy_update_start,
    (name: "algo", anchor: 60deg),
    (name: "policy", anchor: 260deg),
    mark: (end: arrowhead-update, scale: 2),
  )

  content(
    "alg-policy-update.mid",
    align(left, box(text("TD\nUpdate", hyphenate: false))),
    padding: .2,
    anchor: "east",
  )
})






#let actor-critic-architecture-hierarchical = cetz.canvas({
  let c1 = color-black
  let c2 = color-black
  let c3 = color-black
  let c4 = color-black
  let stroke1 = 1pt + c1
  let stroke2 = 1pt + c2
  let stroke3 = 1pt + c3
  let stroke4 = stroke3 // 1pt + c4
  
  let env_a = (1.25, 0)
  let env_b = (5.5, 1)

  let agent_a = (0.5, 2.75)
  let agent_b = (6.25, 6.25)

  let policy_a = (2.75, 5.25)
  let policy_b = (5.5, 6)

  let algo_a = (2.75, 3)
  let algo_b = (5.5, 3.75)

  let buffer_a = (1.0, 3.0)
  let buffer_b = (2.0, 6)


  
  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    fill: color-yellow,
  )
  tbox(
    a: policy_a,
    b: policy_b,
    label: "policy",
    text: "Actor / Policy",
  )
  tbox(
    a: algo_a,
    b: algo_b,
    label: "algo",
    text: "Critic / Value F.",
  )
  tbox(
    a: buffer_a,
    b: buffer_b,
    label: "buffer",
    text: "Buffer",
    fill: color-gray,
  )

  
  tbox(
    a: env_a,
    b: env_b,
    label: "environment",
    text: "Environment",
  )



  // Left lines

  let mid_y = (env_b.last() + agent_a.last()) / 2
  let mid_x = (env_a.first() + env_b.first()) / 2

  let anchor_up = 160deg
  let anchor_lo = 200deg

  let x_line1 = env_a.first() - 1.5
  let x_line2 = env_a.first() - 1
  let x_line3 = env_b.first() + 1

  // Lines: Env --> Buffer
  line(
    (name: "environment", anchor: anchor_lo),
    ((name: "environment", anchor: anchor_lo), "-|", (x_line1, mid_y)),
    (x_line1, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
  )
  line(
    (x_line1, mid_y),
    ((x_line1, mid_y), "|-", (name: "buffer", anchor: anchor_up)),
    (name: "buffer", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
  )

  // Lines: Env --> Buffer
  line(
    (name: "environment", anchor: anchor_up),
    ((name: "environment", anchor: anchor_up), "-|", (x_line2, mid_y)),
    (x_line2, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
  )
  line(
    (x_line2, mid_y),
    ((x_line2, mid_y), "|-", (name: "buffer", anchor: anchor_lo)),
    (name: "buffer", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
  )
  
  // Lines: Buffer --> Policy
  line(
    ((buffer_b.first(), mid_y), "|-", "policy"),
    "policy",
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "buffer-policy-x",
  )

  // Lines: Buffer --> Value Function
  line(
    ((buffer_b.first(), mid_y), "|-", (name: "algo", anchor: anchor_lo)),
    (name: "algo", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
    name: "env-alg-reward-t",
  )
  line(
    ((buffer_b.first(), mid_y), "|-", (name: "algo", anchor: anchor_up)),
    (name: "algo", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-alg-state-t",
  )


  // Lines: Dotted
  line(
    (x_line1 - 1, mid_y),
    (x_line2 + 1, mid_y),
    stroke: (dash: "dotted"),
    name: "dotted",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, "\n" + $G_(t+1), O_(t+1)$)),
    padding: .1,
    anchor: "north-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, "\n" + $R_(t+1)$)),
    padding: .1,
    anchor: "north-west",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, $G_t,O_t$ + "\nGC-observ.")),
    padding: .1,
    anchor: "south-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, $R_t$ + "\nreward")),
    padding: .1,
    anchor: "south-west",
  )

  
  // Right line

  line(
    "policy",
    ("policy", "-|", (x_line3, mid_y)),
    ((x_line3, mid_y), "|-", "environment.east"),
    "environment.east",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "policy-env-action-t",
  )
  content(
    (x_line3, mid_y),
    align(left, box(fill: white, $A_t$ + "\naction")),
    padding: .1,
    anchor: "south-west",
  )


  // Inner lines

  let right_between_policy = (
    (policy_b.first() + agent_b.first()) / 2,
    (policy_a.last() + policy_b.last()) / 2,
  )
  let right_between_algo = (
    (algo_b.first() + agent_b.first()) / 2,
    (algo_a.last() + algo_b.last()) / 2,
  )

  line(
    ("policy", "-|", right_between_policy),
    right_between_algo,
    "algo",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "policy-alg-action-t",
  )
  let policy_update_start = (name: "algo", anchor: 100deg)
  line(
    policy_update_start,
    (name: "policy", anchor: 260deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke2,
    name: "alg-policy-update",
  )
  bezier(
    policy_update_start,
    (name: "algo", anchor: 60deg),
    (name: "policy", anchor: 260deg),
    mark: (end: arrowhead-update, scale: 2),
  )

  content(
    "alg-policy-update.mid",
    align(left, box(text("TD\nUpdate", hyphenate: false))),
    padding: .2,
    anchor: "east",
  )
})







#let hierarchical-graph-based-ddpg = cetz.canvas({
  let c1 = color-black
  let c2 = color-black
  let c3 = color-black
  let c4 = color-black
  let stroke1 = 1pt + c1
  let stroke2 = 1pt + c2
  let stroke3 = 1pt + c3
  let stroke4 = stroke3 // 1pt + c4
  
  let env_a = (1.5, 0)
  let env_b = (5.5, 1)

  let agent_a = (1.0, 2.75)
  let agent_b = (6.0, 12)
  
  let actor_a = (3.25, 11.5)
  let actor_b = (5.25, 10.75)

  let critic_a = (3.25, 9.25)
  let critic_b = (5.25, 8.5)

  let buffer_a = (1.5, 8.5)
  let buffer_b = (2.5, 11.5)

  let graphbox_a = (1.5, 7.5)
  let graphbox_b = (5.5, 5.0)

  let actor2_a = (3.25, 4.25)
  let actor2_b = (5.25, 3.5)

  
  tbox(
    a: agent_a,
    b: agent_b,
    label: "agent",
    fill: color-yellow,
  )
  tbox(
    a: actor_a,
    b: actor_b,
    label: "actor",
    text: "Actor",
  )
  tbox(
    a: critic_a,
    b: critic_b,
    label: "critic",
    text: "Critic",
  )
  tbox(
    a: buffer_a,
    b: buffer_b,
    label: "buffer",
    text: "Buffer",
    fill: color-gray,
  )
  tbox(
    a: graphbox_a,
    b: graphbox_b,
    label: "graphbox",
    text: "",
    fill: color-gray,
  )
  tbox(
    a: actor2_a,
    b: actor2_b,
    label: "actor2",
    text: "Actor",
  )

  
  tbox(
    a: env_a,
    b: env_b,
    label: "environment",
    text: "Environment",
  )



  // Left lines

  let mid_y = (env_b.last() + agent_a.last()) / 2
  let mid_x = (env_a.first() + env_b.first()) / 2

  let anchor_up = 160deg
  let anchor_lo = 200deg

  let x_line1 = env_a.first() - 1.5
  let x_line2 = env_a.first() - 1
  let x_line3 = env_b.first() + 1

  // Lines: Env --> Buffer
  line(
    (name: "environment", anchor: anchor_lo),
    ((name: "environment", anchor: anchor_lo), "-|", (x_line1, mid_y)),
    (x_line1, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
  )
  line(
    (x_line1, mid_y),
    ((x_line1, mid_y), "|-", (name: "buffer", anchor: anchor_up)),
    (name: "buffer", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
  )
  line(
    (name: "environment", anchor: anchor_up),
    ((name: "environment", anchor: anchor_up), "-|", (x_line2, mid_y)),
    (x_line2, mid_y),
    mark: (end: arrowhead, fill: c3),
    stroke: stroke3,
  )
  line(
    (x_line2, mid_y),
    ((x_line2, mid_y), "|-", (name: "buffer", anchor: anchor_lo)),
    (name: "buffer", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
  )

  // Lines: Dotted
  line(
    (x_line1 - 1, mid_y),
    (x_line2 + 1, mid_y),
    stroke: (dash: "dotted"),
    name: "dotted",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, "\n" + $G_(t+1), O_(t+1)$)),
    padding: .1,
    anchor: "north-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, "\n" + $R_(t+1)$)),
    padding: .1,
    anchor: "north-west",
  )
  content(
    (x_line1, mid_y),
    align(right, box(fill: white, $G_t,O_t$ + "\nGC-observ.")),
    padding: .1,
    anchor: "south-east",
  )
  content(
    (x_line2, mid_y),
    align(left, box(fill: white, $R_t$ + "\nreward")),
    padding: .1,
    anchor: "south-west",
  )

  // Right line
  line(
    "actor2",
    ("actor2", "-|", (x_line3, mid_y)),
    ((x_line3, mid_y), "|-", "environment.east"),
    "environment.east",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "actor-env-action-t",
  )
  content(
    (x_line3, mid_y),
    align(left, box(fill: white, $A_t$ + "\naction")),
    padding: .1,
    anchor: "south-west",
  )

  // Inner lines

  // Lines: Buffer --> Policy
  line(
    ((buffer_b.first(), mid_y), "|-", "actor"),
    "actor",
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
  )

  // Lines: Buffer --> Value Function
  line(
    ((buffer_b.first(), mid_y), "|-", (name: "critic", anchor: anchor_lo)),
    (name: "critic", anchor: anchor_lo),
    mark: (end: arrowhead, fill: c4),
    stroke: stroke4,
    name: "env-critic-reward-t",
  )
  line(
    ((buffer_b.first(), mid_y), "|-", (name: "critic", anchor: anchor_up)),
    (name: "critic", anchor: anchor_up),
    mark: (end: arrowhead, fill: c1),
    stroke: stroke1,
    name: "env-critic-state-t",
  )

  let right_between_actor = (
    (actor_b.first() + agent_b.first()) / 2,
    (actor_a.last() + actor_b.last()) / 2,
  )
  let right_between_critic = (
    (critic_b.first() + agent_b.first()) / 2,
    (critic_a.last() + critic_b.last()) / 2,
  )

  // Lines: TD-Update
  line(
    "actor",
    ("actor", "-|", right_between_actor),
    right_between_critic,
    "critic",
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "actor-critic-action-t",
  )
  line(
    (name: "critic", anchor: 100deg),
    (name: "actor", anchor: 260deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke2,
    name: "critic-actor-update",
  )
  bezier(
    (name: "critic", anchor: 100deg),
    (name: "critic", anchor: 60deg),
    (name: "actor", anchor: 260deg),
    mark: (end: arrowhead-update, scale: 2),
  )
  content(
    "critic-actor-update.mid",
    align(left, box(text("TD\nUpdate", hyphenate: false))),
    padding: .2,
    anchor: "east",
  )

  // Lines: Buffer / Critic --> Graph
  line(
    (name: "buffer", anchor: 270deg),
    (name: "graphbox", anchor: 126.9deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke2,
    name: "buffer-graph-update",
  )
  line(
    (name: "critic", anchor: 270deg),
    (name: "graphbox", anchor: 69deg),
    mark: (end: arrowhead-update, scale: 2),
    stroke: stroke2,
    name: "critic-graph-update",
  )
  content(
    ((graphbox_a.first() + graphbox_b.first()) / 2, graphbox_a.last() - 0.1),
    // "buffer-graph-update.mid",
    align(left, box(text("Graph", hyphenate: false))),
    padding: .0,
    anchor: "north",
  )
  
  // Lines: Graph --> Actor
  line(
    (name: "graphbox", anchor: 240deg),
    ((name: "actor2", anchor: 180deg), "-|", (name: "graphbox", anchor: 240deg)),
    (name: "actor2", anchor: 180deg),
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "graph-actor-waypoint",
  )
  content(
    "graph-actor-waypoint.mid",
    align(left, box(text($omega_t, O_t$, hyphenate: false))),
    padding: .3,
    anchor: "north",
  )

  // Graph & Plan

  // X: 1.5 -- 5.5
  // Y: 5.0 -- 7.5

  let gmid_x = 2.45
  let gmid_y = 6.45
  let gsize = 0.4
  let node_radius = 3pt

  let garr_mid_x = (agent_a.first() + agent_b.first()) / 2
  let garr_mid_y = (graphbox_a.last() + graphbox_b.last()) / 2

  let pmid_x = gmid_x + 2 * (garr_mid_x - gmid_x)
  let pmid_y = gmid_y

  // Graph
  circle(
    (gmid_x - gsize, gmid_y),
    radius: node_radius,
    name: "g3",
  )
  circle(
    (gmid_x + gsize, gmid_y),
    radius: node_radius,
    name: "g1",
  )
  circle(
    (gmid_x, gmid_y + gsize),
    radius: node_radius,
    name: "g2",
  )
  circle(
    (gmid_x, gmid_y - gsize),
    radius: node_radius,
    name: "g4",
  )
  circle(
    (gmid_x - gsize, gmid_y - 2 * gsize),
    radius: node_radius,
    name: "g5",
  )
  line("g1", "g2")
  line("g1", "g4")
  line("g3", "g2")
  line("g3", "g4")
  line("g4", "g5")
  content(
    "g2.mid",
    text($G_t$),
    padding: .4,
    anchor: "south",
  )
  content(
    "g5.mid",
    text($O_t$),
    padding: .15,
    anchor: "north",
  )

  // Arrow
  line(
    (garr_mid_x - 0.25, garr_mid_y),
    (garr_mid_x + 0.25, garr_mid_y),
    mark: (end: arrowhead, fill: c2),
    stroke: stroke2,
    name: "graph-to-plan",
  )

  // Plan
  circle(
    (pmid_x - gsize, pmid_y),
    radius: node_radius,
    name: "p3",
  )
  circle(
    (pmid_x, pmid_y + gsize),
    radius: node_radius,
    name: "p2",
  )
  circle(
    (pmid_x, pmid_y - gsize),
    radius: node_radius,
    name: "p4",
  )
  circle(
    (pmid_x - gsize, pmid_y - 2 * gsize),
    radius: node_radius,
    name: "p5",
  )
  line("p3", "p2")
  line("p3", "p4")
  line("p4", "p5")
  content(
    "p2.mid",
    text($G_t$),
    padding: .4,
    anchor: "south",
  )
  content(
    "p5.mid",
    text($O_t$),
    padding: .15,
    anchor: "north",
  )
  content(
    "p4.mid",
    text($omega_t$),
    padding: .15,
    anchor: "west",
  )

})







#let SGM-node-merging = cetz.canvas({
  let green-color = olive
  let black-color = black
  let writeolive(x) = text(fill: green-color, $#x$)
  let yellow-ellipse = rgb(255, 220, 0, 55)

  // Left points

  circle(
    (1, 3.5),
    radius: 5pt,
    name: "in1",
  )
  circle(
    (1, 1.5),
    radius: 5pt,
    name: "in2",
  )

  // Center points

  circle(
    (3, 3),
    radius: 5pt,
    name: "S1",
    fill: black-color,
  )

  circle(
    (3, 2),
    radius: 5pt,
    name: "S2",
    fill: green-color,
  )

  // Right point

  circle(
    (5, 2.5),
    radius: 5pt,
    name: "out1",
  )


  // Green lines
  
  line(
    "in1", "S2",
    stroke: (dash: "dashed", paint: green-color),
    mark: (end: ">"),
    fill: green-color,
  )
  line(
    "in2", "S2",
    stroke: (dash: "dashed", paint: green-color),
    mark: (end: ">"),
    fill: green-color,
  )
  line(
    "S2", "out1",
    stroke: (dash: "dashed", paint: green-color),
    mark: (end: ">"),
    fill: green-color,
  )


  // Black lines
  
  line(
    "in1", "S1",
    stroke: (paint: black-color),
    mark: (end: ">"),
    fill: black-color,
  )
  line(
    "in2", "S1",
    stroke: (paint: black-color),
    mark: (end: ">"),
    fill: black-color,
  )
  line(
    "S1", "out1",
    stroke: (paint: black-color),
    mark: (end: ">"),
    fill: black-color,
  )

  
  // Labels

  content(
    "out1.north",
    box()[$C_("out")(s_1, writeolive(s_2))$],
    padding: .2,
    anchor: "south-west",
  )
  content(
    "in2.south-west",
    box()[$C_("in")(s_1, writeolive(s_2))$],
    padding: .3,
    anchor: "north",
  )
  content(
    "S2.south",
    box()[$writeolive(s_2)$],
    padding: .1,
    anchor: "north",
  )
  content(
    "S1.north",
    box()[$s_1$],
    padding: .2,
    anchor: "south",
  )

  
  // Yellow ellipse

  on-layer(-1, {
    circle(
      (3,2.5),
      radius: (0.75, 1.25),
      fill: yellow-ellipse,
      stroke: (dash: "dashed"),
    )
  })
})





#let example-graph = render-graph(
  "digraph mygraph {
    layout=\"twopi\";
    node [shape=circle];
    A -> B [label=\"1.5\"];
    B -> A [label=\"3.9\"];
    B -> C [label=\"3.2\"];
    C -> B [label=\"0.5\"];
    B -> D [label=\"2.3\"];
    D -> B [label=\"3.1\"];
    C -> F [label=\"4.7\"];
    F -> C [label=\"2.5\"];
    D -> F [label=\"1.3\"];
    F -> D [label=\"3.5\"];
    A -> F [label=\"4.1\"];
    F -> A [label=\"3.0\"];
  }"
)









#import "template.typ": ieee
#show: ieee.with()


#figure(
  agent-environment-loop,
  placement: auto,
)

#figure(
  agent-model-environment-loop,
  placement: auto,
)

#figure(
  online-vs-offline-learning,
  placement: auto,
)



#figure(
  agent-environment-loop-goal-conditioned,
  placement: auto,
)

#figure(
  algorithm-policy-environment-loop,
  placement: auto,
)

#figure(
  on-policy-vs-off-policy-algorithms,
  placement: auto,
)




#figure(
  SGM-node-merging,
  placement: auto,
)

#figure(
  actor-critic-architecture,
  placement: auto,
)

#figure(
  hierarchical-graph-based-ddpg,
  placement: auto,
)

