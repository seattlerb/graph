#!/usr/bin/ruby -w

require 'graph'

digraph do
  # many ways to access/create edges and nodes
  edge "a", "b"
  self["b"]["c"]
  node("c") >> "a"

  square   << node("a")
  triangle << node("b")

  red   << node("a") << edge("a", "b")
  green << node("b") << edge("b", "c")
  blue  << node("c") << edge("c", "a")

  save "simple_example", "png"
end
