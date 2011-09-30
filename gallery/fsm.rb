#!/usr/bin/ruby

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
