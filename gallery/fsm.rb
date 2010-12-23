#!/usr/bin/ruby

# digraph finite_state_machine {
#   rankdir=LR;
#   size="8,5"
#   node [shape = doublecircle]; LR_0 LR_3 LR_4 LR_8;
#   node [shape = circle];
#   LR_0 -> LR_2 [ label = "SS(B)" ];
#   LR_0 -> LR_1 [ label = "SS(S)" ];
#   LR_1 -> LR_3 [ label = "S($end)" ];
#   LR_2 -> LR_6 [ label = "SS(b)" ];
#   LR_2 -> LR_5 [ label = "SS(a)" ];
#   LR_2 -> LR_4 [ label = "S(A)" ];
#   LR_5 -> LR_7 [ label = "S(b)" ];
#   LR_5 -> LR_5 [ label = "S(a)" ];
#   LR_6 -> LR_6 [ label = "S(b)" ];
#   LR_6 -> LR_5 [ label = "S(a)" ];
#   LR_7 -> LR_8 [ label = "S(b)" ];
#   LR_7 -> LR_5 [ label = "S(a)" ];
#   LR_8 -> LR_6 [ label = "S(b)" ];
#   LR_8 -> LR_5 [ label = "S(a)" ];
# }

require "graph"

digraph do
  rotate
  graph_attribs << 'size="8,5"'

  node_attribs << circle
  doublecircle << node("LR_0") << node("LR_3") << node("LR_4") << node("LR_8")

  edge("LR_0", "LR_2").label "SS(B)"
  edge("LR_0", "LR_1").label "SS(S)"
  edge("LR_1", "LR_3").label "S($end)"
  edge("LR_2", "LR_6").label "SS(b)"
  edge("LR_2", "LR_5").label "SS(a)"
  edge("LR_2", "LR_4").label "S(A)"
  edge("LR_5", "LR_7").label "S(b)"
  edge("LR_5", "LR_5").label "S(a)"
  edge("LR_6", "LR_6").label "S(b)"
  edge("LR_6", "LR_5").label "S(a)"
  edge("LR_7", "LR_8").label "S(b)"
  edge("LR_7", "LR_5").label "S(a)"
  edge("LR_8", "LR_6").label "S(b)"
  edge("LR_8", "LR_5").label "S(a)"

  save "fsm", "png"
end
