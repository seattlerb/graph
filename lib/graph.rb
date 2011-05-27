#!/usr/local/bin/ruby -w

require "enumerator"

##
# Graph models directed graphs and subgraphs and outputs in graphviz's
# dot format.

class Graph
  VERSION = "2.0.1" # :nodoc:

  LIGHT_COLORS = %w(gray lightblue lightcyan lightgray lightpink
                    lightslategray lightsteelblue white)

  # WTF -- can't be %w() because of a bug in rcov
  BOLD_COLORS = ["black", "brown", "mediumblue", "blueviolet",
                 "orange", "magenta", "darkgreen", "maroon",
                 "violetred", "purple", "greenyellow", "deeppink",
                 "midnightblue", "firebrick", "darkturquoise",
                 "mediumspringgreen", "chartreuse", "navy",
                 "lightseagreen", "chocolate", "lawngreen", "green",
                 "indigo", "darkgoldenrod", "darkviolet", "red",
                 "springgreen", "saddlebrown", "mediumvioletred",
                 "goldenrod", "tomato", "cyan", "forestgreen",
                 "darkorchid", "crimson", "coral", "deepskyblue",
                 "seagreen", "peru", "turquoise", "orangered",
                 "dodgerblue", "sienna", "limegreen", "royalblue",
                 "darkorange", "blue"]

  SHAPES = %w(Mcircle Mdiamond Msquare box box3d circle component
              diamond doublecircle doubleoctagon egg ellipse folder
              hexagon house invhouse invtrapezium invtriangle none
              note octagon parallelogram pentagon plaintext point
              polygon rect rectangle septagon square tab trapezium
              triangle tripleoctagon)

  STYLES = %w(dashed dotted solid invis bold filled diagonals rounded)

  STYLES.each do |name|
    define_method(name) { style name }
  end

  (BOLD_COLORS + LIGHT_COLORS).each do |name|
    define_method(name) { color name }
  end

  SHAPES.each do |name|
    define_method(name.downcase) { shape name }
  end

  ##
  # A parent graph, if any. Only used for subgraphs.

  attr_accessor :graph

  ##
  # The name of the graph. Optional for graphs and subgraphs. Prefix
  # the name of a subgraph with "cluster" for subgraph that is boxed.

  attr_accessor :name

  ##
  # Global attributes for edges in this graph.

  attr_reader :edge_attribs

  ##
  # The hash of hashes of edges in this graph. Use #[] or #node to create edges.

  attr_reader :edges

  ##
  # Global attributes for this graph.

  attr_reader :graph_attribs

  ##
  # Global attributes for nodes in this graph.

  attr_reader :node_attribs

  ##
  # The hash of nodes in this graph. Use #[] or #node to create nodes.

  attr_reader :nodes

  ##
  # An array of subgraphs.

  attr_reader :subgraphs

  ##
  # Creates a new graph object. Optional name and parent graph are
  # available. Also takes an optional block for DSL-like use.

  def initialize name = nil, graph = nil, &block
    @name = name
    @graph = graph
    graph << self if graph
    @nodes  = Hash.new { |h,k| h[k] = Node.new self, k }
    @edges  = Hash.new { |h,k|
      h[k] = Hash.new { |h2, k2| h2[k2] = Edge.new self, self[k], self[k2] }
    }
    @graph_attribs = []
    @node_attribs  = []
    @edge_attribs  = []
    @subgraphs     = []

    instance_eval(&block) if block
  end

  ##
  # Push a subgraph into the current graph. Sets the subgraph's graph to self.

  def << subgraph
    subgraphs << subgraph
    subgraph.graph = self
  end

  ##
  # Access a node by name

  def [] name
    nodes[name]
  end

  ##
  # A convenience method to set the global node attributes to use boxes.

  def boxes
    node_attribs << shape("box")
  end

  ##
  # Shortcut method to create a new color Attribute instance.

  def color color
    Attribute.new "color = #{color}"
  end

  ##
  # Shortcut method to create a new colorscheme Attribute instance.

  def colorscheme name
    Attribute.new "colorscheme = #{name}"
  end

  ##
  # Define one or more edges.
  #
  #   edge "a", "b", "c", ...
  #
  # is equivalent to:
  #
  #   edge "a", "b"
  #   edge "b", "c"
  #   ...

  def edge(*names)
    last = nil
    names.each_cons(2) do |from, to|
      last = self[from][to]
    end
    last
  end

  ##
  # Creates a new Graph whose edges point the other direction.

  def invert
    result = self.class.new
    edges.each do |from, h|
      h.each do |to, edge|
        result[to][from]
      end
    end
    result
  end

  ##
  # Shortcut method to create a new fillcolor Attribute instance.

  def fillcolor n
    Attribute.new "fillcolor = #{n}"
  end

  ##
  # Shortcut method to create a new font Attribute instance. You can
  # pass in both the name and an optional font size.

  def font name, size=nil
    Attribute.new "fontname = #{name.inspect}" +
      (size ? ", fontsize = #{size}" : "")
  end

  ##
  # Shortcut method to set the graph's label. Usually used with subgraphs.

  def label name
    graph_attribs << "label = \"#{name.gsub(/\n/, '\n')}\""
  end

  ##
  # Access a node by name, supplying an optional label

  def node name, label = nil
    n = nodes[name]
    n.label label if label
    n
  end

  ##
  # Shortcut method to specify the orientation of the graph. Defaults
  # to the graphviz default "TB".

  def orient dir = "TB"
    graph_attribs << "rankdir = #{dir}"
  end

  ##
  # Shortcut method to specify the orientation of the graph. Defaults to "LR".

  def rotate dir = "LR"
    orient dir
  end

  ##
  # Saves out both a dot file to path and an image for the specified type.
  # Specify type as nil to skip exporting an image.

  def save path, type = nil
    File.open "#{path}.dot", "w" do |f|
      f.puts self.to_s
    end
    system "dot -T#{type} #{path}.dot > #{path}.#{type}" if type
  end

  ##
  # Shortcut method to create a new shape Attribute instance.

  def shape shape
    Attribute.new "shape = #{shape}"
  end

  ##
  # Shortcut method to create a new style Attribute instance.

  def style name
    Attribute.new "style = #{name}"
  end

  ##
  # Shortcut method to create a subgraph in the current graph. Use
  # with the top-level +digraph+ method in block form for a graph DSL.

  def subgraph name = nil, &block
    Graph.new name, self, &block
  end

  ##
  # Outputs a graphviz graph.

  def to_s
    result = []

    type = graph ? "subgraph" : "digraph"
    result << "#{type} #{name}"
    result << "  {"

    graph_attribs.each do |line|
      result << "    #{line};"
    end

    unless node_attribs.empty? then
      result << "    node [ #{node_attribs.join(", ")} ];"
    end

    unless edge_attribs.empty? then
      result << "    edge [ #{edge_attribs.join(", ")} ];"
    end

    subgraphs.each do |line|
      result << "    #{line};"
    end

    nodes.each do |name, node|
      result << "    #{node};" if graph or node.attributes?
    end

    edges.each do |from, deps|
      deps.each do |to, edge|
        result << "    #{edge};"
      end
    end

    result << "  }"
    result.join "\n"
  end

  ##
  # An attribute for a graph, node, or edge. Really just a composable
  # string (via #+) with a convenience method #<< that allows you to
  # "paint" nodes and edges with this attribute.

  class Attribute < Struct.new :attr
    ##
    # "Paint" graphs, nodes, and edges with this attribute.
    #
    #   red << node1 << node2 << node3
    #
    # is the same as:
    #
    #   node1.attributes << red
    #   node2.attributes << red
    #   node3.attributes << red

    def << thing
      thing.attributes << self
      self
    end

    ##
    # Returns the attribute in string form.

    alias :to_s :attr

    ##
    # Compose a new attribute from two existing attributes:
    #
    #   bad_nodes = red + filled + diamond

    def + style
      Attribute.new "#{self}, #{style}"
    end
  end

  class Thingy < Struct.new :graph, :attributes
    def initialize graph
      super graph, []
    end

    def initialize_copy other # :nodoc:
      super
      self.attributes = other.attributes.dup
    end

    ##
    # Shortcut method to set the label attribute.

    def label name
      attributes.reject! { |s| s =~ /^label =/ }
      attributes << "label = \"#{name.gsub(/\n/, '\n')}\""
      self
    end

    ##
    # Does this thing have attributes?

    def attributes?
      not self.attributes.empty?
    end
  end

  ##
  # An edge in a graph.

  class Edge < Thingy

    attr_accessor :from, :to

    ##
    # Create a new edge in +graph+ from +from+ to +to+.

    def initialize graph, from, to
      super graph
      self.from = from
      self.to = to
    end

    ##
    # Returns the edge in dot syntax.

    def to_s
      fromto = "%p -> %p" % [from.name, to.name]
      if self.attributes? then
        "%-20s [ %-20s ]" % [fromto, attributes.join(',')]
      else
        fromto
      end
    end
  end

  ##
  # Nodes in the graph.

  class Node < Thingy

    attr_accessor :name

    ##
    # Create a new Node. Takes a parent graph and a name.

    def initialize graph, name
      super graph
      self.name = name
    end

    ##
    # Create a new node with +name+ and an edge between them pointing
    # from self to the new node.

    def >> name
      self[name] # creates node and edge
      self
    end

    alias :"<<" :">>"

    ##
    # Returns the edge between self and +dep_name+.

    def [] dep_name
      graph.edges[name][dep_name]
    end

    ##
    # Returns the node in dot syntax.

    def to_s
      if self.attributes? then
        "%-20p [ %-20s ]" % [name, attributes.join(',')]
      else
        "#{name.inspect}"
      end
    end
  end
end

##
# Convenience method to create a new graph. Used for DSL-style:
#
#   g = digraph do
#     edge "a", "b", "c"
#   end

def digraph name = nil, &block
  Graph.new name, &block
end
