#!/usr/bin/ruby -w

require "graph"

digraph do
  # composite styles
  leaf_node = white + filled

  subgraph "cluster_0" do
    label "process #1"
    graph_attribs << filled << lightgray
    node_attribs  << leaf_node

    edge "a0", "a1", "a2", "a3"
  end

  subgraph "cluster_1" do
    label "process #2"
    graph_attribs << blue
    node_attribs  << filled

    edge "b0", "b1", "b2", "b3"
  end

  edge "start", "a0"
  edge "start", "b0"
  edge "a1", "b3"
  edge "b2", "a3"
  edge "a3", "a0"
  edge "a3", "end"
  edge "b3", "end"

  mdiamond << node("start")
  msquare  << node("end")

  save "cluster", "png"
end

