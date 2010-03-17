#!/usr/local/bin/ruby -w

##
# Graph is a type of hash that outputs in graphviz's dot format.

class Graph < Hash
  VERSION = '1.1.0' # :nodoc:

  ##
  # A Hash of arrays of attributes for each node. Eg:
  #
  #   graph.attribs["a"] << "color = red"
  #
  # Will color node "a" red.

  attr_reader :attribs

  ##
  # An array of the order of traversal / definition of the nodes.
  #
  # You (generally) should leave this alone.

  attr_reader :order

  ##
  # An array of attributes to add to the front of the graph source. Eg:
  #
  #   graph.prefix << "ratio = 1.5"

  attr_reader :prefix

  ##
  # A Hash of a Hashes of Arrays of attributes for an edge. Eg:
  #
  #   graph.edge["a"]["b"] << "color = blue"
  #
  # Will color the edge between a and b blue.

  attr_reader :edge

  def []= key, val # :nodoc:
    @order << key unless self.has_key? key
    super
  end

  def clear # :nodoc:
    super
    @prefix.clear
    @order.clear
    @attribs.clear
    @edge.clear
  end

  def nodes
    (keys + values).flatten.uniq
  end

  def boxes
    global_attrib "shape = box"
  end

  def global_attrib attrib
    nodes.each do |key|
      attribs[key] << attrib
    end
  end

  ##
  # Returns a Hash with a count of the outgoing edges for each node.

  def counts
    result = Hash.new 0
    each_pair do |from, to|
      result[from] += 1
    end
    result
  end

  def delete key # :nodoc:
    @order.delete key
    # TODO: prolly needs to go clean up attribs
    super
  end

  ##
  # Overrides Hash#each_pair to go over each _edge_. Eg:
  #
  #   g["a"] << "b"
  #   g["a"] << "b"
  #   g.each_pair { |from, to| ... }
  #
  # goes over a -> b *twice*.

  def each_pair
    @order.each do |from|
      self[from].each do |to|
        yield from, to
      end
    end
  end

  ##
  # Deletes nodes that have less than minimum number of outgoing edges.

  def filter_size minimum
    counts.each do |node, count|
      next unless count < minimum
      delete node
    end
  end

  def initialize # :nodoc:
    super { |h,k| h[k] = [] }
    @prefix  = []
    @order   = []
    @attribs = Hash.new { |h,k| h[k] = [] }
    @edge    = Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = [] } }
  end

  ##
  # Creates a new Graph whose edges point the other direction.

  def invert
    result = self.class.new
    each_pair do |from, to|
      result[to] << from
    end
    result
  end

  ##
  # Returns a list of keys sorted by number of outgoing edges.

  def keys_by_count
    counts.sort_by { |key, count| -count }.map {|key, count| key }
  end

  ##
  # Specify the orientation of the graph. Defaults to the graphviz default "TB".

  def orient dir = "TB"
    prefix << "rankdir = #{dir}"
  end

  ##
  # Really just an alias for #orient but with "LR" as the default value.

  def rotate dir = "LR"
    orient dir
  end

  ##
  # Remove all duplicate edges.

  def normalize
    each do |k,v|
      v.uniq!
    end
  end

  ##
  # Saves out both a dot file to path and an image for the specified type.
  # Specify type as nil to skip exporting an image.

  def save path, type="png"
    File.open "#{path}.dot", "w" do |f|
      f.write self.to_s
    end
    system "dot -T#{type} #{path}.dot > #{path}.#{type}" if type
  end

  ##
  # Outputs a graphviz graph.

  def to_s
    result = []
    result << "digraph absent"
    result << "  {"

    @prefix.each do |line|
      result << "    #{line};"
    end

    @attribs.sort.each do |node, attribs|
      result << "    #{node.inspect} [ #{attribs.join ','} ];"
    end

    each_pair do |from, to|
      edge = @edge[from][to].join ", "
      edge = " [ #{edge} ]" unless edge.empty?
      result << "    #{from.inspect} -> #{to.inspect}#{edge};"
    end

    result << "  }"
    result.join "\n"
  end
end
