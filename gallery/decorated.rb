#!/usr/bin/ruby -w

require "graph"

digraph do
  e1 = edge "A", "B"

  e1.label "A to B"
  e1.decorate("true")

  save "decorated", "png"
end
