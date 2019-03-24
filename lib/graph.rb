#!/usr/local/bin/ruby -w

require "enumerator"

##
# Graph models directed graphs and subgraphs and outputs in graphviz's
# dot format.

class Graph
  VERSION = "2.8.3" # :nodoc:

  # :stopdoc:

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

  alias :invisible :invis

  (BOLD_COLORS + LIGHT_COLORS).each do |name|
    define_method(name) { color name }
    define_method("bg_#{name}") { bgcolor name }
    define_method("fill_#{name}") { fillcolor name }
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

  # :startdoc:

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

  # TODO: remove if/when I drop 1.8 support.
  attr_reader :nodes_order # :nodoc:
  attr_reader :edges_order # :nodoc:

  ##
  # Creates a new graph object. Optional name and parent graph are
  # available. Also takes an optional block for DSL-like use.

  def initialize name = nil, graph = nil, &block
    @name = name
    @graph = graph
    graph << self if graph
    @nodes_order = []
    @nodes  = Hash.new { |h,k| @nodes_order << k; h[k] = Node.new self, k }
    @edges_order = []
    @edges  = Hash.new { |h,k|
      h[k] = Hash.new { |h2, k2|
        @edges_order << [k, k2]
        h2[k2] = Edge.new self, self[k], self[k2]
      }
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

  ##
  # Shortcut method for creating an arrowhead attribute.

  def arrowhead shape
    raise ArgumentError, "Bad arrow shape: #{shape}" unless shape =~ ARROW_RE
    Attribute.new "arrowhead = #{shape}"
  end

  ##
  # Shortcut method for creating an arrowtail attribute.

  def arrowtail shape
    raise ArgumentError, "Bad arrow shape: #{shape}" unless shape =~ ARROW_RE
    Attribute.new "arrowtail = #{shape}"
  end

  ##
  # Shortcut method for creating an arrowsize attribute.

  def arrowsize size
    Attribute.new "arrowsize = #{size}"
  end

  ##
  # Shortcut method to set the global node attributes to use boxes.

  def boxes
    node_attribs << shape("box")
  end

  ##
  # Shortcut method to create a new color Attribute instance.

  def color color
    Attribute.new "color = #{color}"
  end

  ##
  # Shortcut method to create a new colorscheme Attribute instance. If
  # passed +n+, +name+ must match one of the brewer color scheme names
  # and it will generate accessors for each fillcolor as well as push
  # the colorscheme onto the node_attribs.

  attr_accessor :scheme

  ##
  # Shortcut method to create and set the graph to use a colorscheme.

  def colorscheme name, n = nil
    self.scheme = Attribute.new "colorscheme = %p" % ["#{name}#{n}"]
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
    Attribute.new "fillcolor = %p" % [n]
  end

  ##
  # Shortcut method to create a new fillcolor Attribute instance.

  def bgcolor n
    Attribute.new "bgcolor = %p" % [n]
  end

  ##
  # Shortcut method to create a new font Attribute instance. You can
  # pass in both the name and an optional font size.

  def font name
    Attribute.new "fontname = %p" % [name]
  end

  ##
  # Shortcut method to create a new fontsize Attribute instance.

  def fontsize size
    Attribute.new "fontsize = #{size}"
  end

  def self.escape_label s
    s = s.to_s.gsub(/\n/, '\n').gsub(/\"/, '\\\"')
    if s[0] == ?< and s[-1] == ?> then
      s
    else
      "\"#{s}\""
    end
  end

  ##
  # Shortcut method to set the graph's label. Usually used with subgraphs.

  def label name
    graph_attribs << "label = #{Graph.escape_label name}"
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
  # Specify cmd as the command name like "neato" to use a command other than "dot".

  def save path, type = nil, cmd = "dot"
    File.open "#{path}.dot", "w" do |f|
      f.puts self.to_s
    end
    system "#{cmd} -T#{type} #{path}.dot > #{path}.#{type}" if type
  end

  ##
  # Shortcut method to create a new shape Attribute instance.

  def shape shape
    Attribute.new "shape = %p" % [shape]
  end

  ##
  # Shortcut method to create a new style Attribute instance.

  def style name
    Attribute.new "style = %p" % [name]
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
  # Deletes a node from the graph
  def delete_node node_name
    nodes.delete node_name
    nodes_order.delete node_name

    edges_order.each do |(a, b)|
      edges[a].delete b if b == node_name
      edges.delete a if a == node_name
      edges.delete a if edges[a].empty?
    end

    edges_order.delete_if { |ary| ary.include? node_name }
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

    nodes_order.each do |name|
      node = nodes[name]
      result << "    #{node};" if graph or node.attributes? or node.orphan?
    end

    edges_order.uniq.each do |(from, to)|
      edge = edges[from][to]
      result << "    #{edge};"
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
      c = CompoundAttribute.new
      c.push self
      c.push style
      c
    end
  end

  ##
  # An attribute... that's compound. So much for self-documenting code. :(

  class CompoundAttribute < Attribute
    def initialize attr = [] # :nodoc:
      super
    end

    ##
    # Push an attribute into the list o' attributes.

    def push attrib
      attr.push attrib
    end

    ##
    # "Paint" a thingy with an attribute. Applies the attribute to the
    # thingy. In this case, does it recursively.

    def << thing
      attr.each do |subattr|
        subattr << thing # allows for recursive compound attributes
      end
      self
    end

    def to_s # :nodoc:
      attr.join ", "
    end
  end

  ##
  # You know... THINGY!
  #
  # Has a pointer back to its graph parent and attributes.

  class Thingy < Struct.new :graph, :attributes
    def initialize graph # :nodoc:
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
      attributes << "label = #{Graph.escape_label name}"
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

    attr_accessor :from, :to # :nodoc:

    ##
    # Create a new edge in +graph+ from +from+ to +to+.

    def initialize graph, from, to
      super graph
      self.from = from
      self.to = to
    end

    ##
    # Sets the decorate attribute.
    # Decorate connects the label to the deg with a line

    def decorate decorate
      self.attributes << "decorate = #{decorate}"
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

    attr_accessor :name # :nodoc:

    ##
    # Is this node connected to the graph?

    def connected?
      edges = graph.edges

      edges.include?(name) or edges.any? { |from, deps| deps.include? name }
    end

    ##
    # Is this node an orphan? (ie, not connected?)

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

class Object # :nodoc:
##
# Convenience method to create a new graph. Used for DSL-style:
#
#   g = digraph do
#     edge "a", "b", "c"
#   end

def digraph name = nil, &block
  Graph.new name, &block
end
end
