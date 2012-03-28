#!/usr/local/bin/ruby -w

require "enumerator"

##
# Graph models directed graphs and subgraphs and outputs in graphviz's
# dot format.

class Graph
  VERSION = "2.5.0" # :nodoc:

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

  ##
  # Defines the brewer color schemes and the maximum number of colors
  # in each set.

  COLOR_SCHEME_MAX = {
    :accent   => 8,  :blues    => 9,  :brbg     => 11, :bugn     => 9,
    :dark2    => 8,  :gnbu     => 9,  :greens   => 9,  :greys    => 9,
    :oranges  => 9,  :orrd     => 9,  :paired   => 12, :pastel1  => 9,
    :pastel2  => 8,  :piyg     => 11, :prgn     => 11, :pubu     => 9,
    :pubugn   => 9,  :puor     => 11, :purd     => 9,  :purples  => 9,
    :rdbu     => 11, :rdgy     => 11, :rdylbu   => 11, :rdylgn   => 11,
    :reds     => 9,  :set1     => 9,  :set2     => 8,  :set3     => 12,
    :spectral => 11, :ylgn     => 9,  :ylgnbu   => 9,  :ylorbr   => 9,
    :ylorrd   => 9
  }

  SHAPES = %w(Mcircle Mdiamond Msquare box box3d circle component
              diamond doublecircle doubleoctagon egg ellipse folder
              hexagon house invhouse invtrapezium invtriangle none
              note octagon parallelogram pentagon plaintext point
              polygon rect rectangle septagon square tab trapezium
              triangle tripleoctagon)

  STYLES = %w(dashed dotted solid invis bold filled diagonals rounded)

  ARROW_RE = /(?:o?[lr]?(?:box|crow|diamond|dot|inv|none|normal|tee|vee)){1,4}/

  ARROWS = %w(box crow diamond dot inv none normal tee vee)

  STYLES.each do |name|
    define_method(name) { style name }
  end

  (BOLD_COLORS + LIGHT_COLORS).each do |name|
    define_method(name) { color name }
  end

  SHAPES.each do |name|
    method_name = name.downcase.sub(/none/, 'shape_none')
    define_method(method_name) { shape name }
  end

  ARROWS.each do |name|
    method_name = {
      "none"    => "none_arrow",
      "box"     => "box_arrow",
      "diamond" => "diamond_arrow",
    }[name] || name

    define_method(method_name) { arrowhead name }
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

    self.scheme = graph.scheme if graph
    node_attribs << scheme if scheme

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

  def arrowhead shape
    raise ArgumentError, "Bad arrow shape: #{shape}" unless shape =~ ARROW_RE
    Attribute.new "arrowhead = #{shape}"
  end

  def arrowtail shape
    raise ArgumentError, "Bad arrow shape: #{shape}" unless shape =~ ARROW_RE
    Attribute.new "arrowtail = #{shape}"
  end

  def arrowsize size
    Attribute.new "arrowsize = #{size}"
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
  # Provide some nodes which have to be on the same line

  def same_rank *node_names
    nodes = node_names.map{|n| %{"#{n}"} }.join('; ')
    @same_rank = "{ rank = same; #{nodes} }"  
  end
  
  ##
  # Shortcut method to create a new colorscheme Attribute instance. If
  # passed +n+, +name+ must match one of the brewer color scheme names
  # and it will generate accessors for each fillcolor as well as push
  # the colorscheme onto the node_attribs.

  attr_accessor :scheme

  def colorscheme name, n = nil
    self.scheme = Attribute.new "colorscheme = #{name}#{n}"
    max = COLOR_SCHEME_MAX[name.to_sym]

    node_attribs << scheme if max

    scheme
  end

  (1..COLOR_SCHEME_MAX.values.max).map { |m|
    define_method "c#{m}" do
      Graph::Attribute.new("fillcolor = #{m}")
    end
  }

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

  def font name
    Attribute.new "fontname = #{name.inspect}"
  end

  def fontsize size
    Attribute.new "fontsize = #{size}"
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
  # Shortcut method to create a clustered subgraph in the current
  # graph. Use with the top-level +digraph+ method in block form for a
  # graph DSL.

  def cluster name, &block
    subgraph "cluster_#{name}", &block
  end

  ##
  # Outputs a graphviz graph.

  def to_s
    result = []

    type = graph ? "subgraph " : "digraph "
    type << "\"#{name}\"" if name and !name.empty?
    result << type
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
      result << "    #{node};" if graph or node.attributes? or node.orphan?
    end

    edges.each do |from, deps|
      deps.each do |to, edge|
        result << "    #{edge};"
      end
    end
    
    result << "    #{@same_rank};" if @same_rank

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
      c = CompoundAttribute.new
      c.push self
      c.push style
      c
    end
  end

  class CompoundAttribute < Attribute
    def initialize attr = []
      super
    end

    def push attrib
      attr.push attrib
    end

    def << thing
      attr.each do |subattr|
        subattr << thing # allows for recursive compound attributes
      end
      self
    end

    def to_s
      attr.join ", "
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

    def connected?
      edges = graph.edges

      edges.include?(name) or edges.any? { |from, deps| deps.include? name }
    end

    def orphan?
      not connected?
    end

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
