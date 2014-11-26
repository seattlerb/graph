require "rubygems"
require "minitest/autorun"
require "tmpdir"
require "graph"

class String
  def clean
    gsub(/\s+(\[|\])/, ' \1')
  end
end

class TestGraph < Minitest::Test
  attr_accessor :graph

  def assert_attribute k, v, a
    assert_kind_of Graph::Attribute, a
    assert_equal "#{k} = #{v}", a.attr
  end

  def assert_graph graph, *lines
    lines = lines.map { |l| "    #{l};" }.join("\n")
    expected = "digraph \n  {\n#{lines}\n  }".sub(/\n\n/, "\n")
    assert_equal expected, graph.to_s.clean
  end

  def setup
    @graph = Graph.new
    @graph["a"] >> "b"
  end

  def test_boxes
    assert_graph graph, '"a" -> "b"'

    graph.boxes

    assert_graph graph, 'node [ shape = box ]', '"a" -> "b"'
  end

  def test_colorscheme
    assert_attribute "colorscheme", "blah", graph.colorscheme("blah")
    assert_empty graph.node_attribs
  end

  def test_colorscheme_n
    cs = graph.colorscheme("reds", 5)
    assert_attribute "colorscheme", "reds5", cs
    assert_equal [cs], graph.node_attribs
    assert_equal "fillcolor = 1", graph.c1.to_s
    assert_equal "fillcolor = 2", graph.c2.to_s
    assert_equal "fillcolor = 3", graph.c3.to_s
    assert_equal "fillcolor = 4", graph.c4.to_s
    assert_equal "fillcolor = 5", graph.c5.to_s
  end

  def test_fillcolor
    assert_attribute "fillcolor", "blah", graph.fillcolor("blah")
  end

  def test_font
    assert_attribute "fontname", '"blah"', graph.font("blah")
  end

  def test_font_size
    # cheating... but I didn't want to write a more complex assertion
    assert_attribute "fontname", '"blah"', graph.font("blah")
    assert_attribute "fontsize", '12',     graph.fontsize(12)
  end

  def test_digraph
    g = digraph do
      edge "a", "b", "c"
    end

    assert_kind_of Graph, g
    assert_equal %w(a b c), g.nodes.keys.sort
  end

  def test_edge
    @graph = Graph.new

    graph.edge "a", "b", "c"

    assert_graph graph, '"a" -> "b"', '"b" -> "c"'
  end

  def test_invert
    graph["a"] >> "c"
    invert = graph.invert
    assert_equal %w(a), invert.edges["b"].keys
    assert_equal %w(a), invert.edges["c"].keys
  end

  def test_node_orphan
    exp = 'digraph { "B"; }'

    y = digraph do node "B" end

    assert_equal exp, y.to_s.gsub(/\s+/m, " ")

    z = digraph do self["B"] end

    assert_equal exp, z.to_s.gsub(/\s+/m, " ")
  end


  def test_label
    graph.label "blah"

    assert_graph graph, 'label = "blah"', '"a" -> "b"'
  end

  def test_delete_node
    g = digraph do
      node "a"
      node "b"
    end

    assert_equal 2, g.nodes.length
    assert_equal 2, g.nodes_order.length
    assert_equal %w[a b], g.nodes.keys.sort

    g.delete_node "a"

    assert_equal 1, g.nodes.length
    assert_equal 1, g.nodes_order.length
    assert_equal %w[b], g.nodes.keys.sort
  end


  def test_label_html
    graph.label "<<B>blah</B>>"

    assert_graph graph, 'label = <<B>blah</B>>', '"a" -> "b"'
  end

  def test_label_quote
    graph.label 'blah"blah'

    assert_graph graph, 'label = "blah\\"blah"', '"a" -> "b"'
  end

  def test_label_newline
    graph.label "blah\nblah"

    assert_graph graph, 'label = "blah\\nblah"', '"a" -> "b"'
  end

  def test_left_shift
    subgraph = Graph.new "blah"

    graph << subgraph

    assert_equal graph, subgraph.graph
    assert_includes graph.subgraphs, subgraph
  end

  def test_nodes
    assert_equal %w(a b), graph.nodes.keys.sort
  end

  def test_orient
    graph.orient "blah"

    assert_equal ["rankdir = blah"], graph.graph_attribs
  end

  def test_orient_default
    graph.orient

    assert_equal ["rankdir = TB"], graph.graph_attribs
  end

  def test_rotate
    graph.rotate "blah"

    assert_equal ["rankdir = blah"], graph.graph_attribs
  end

  def test_rotate_default
    graph.rotate

    assert_equal ["rankdir = LR"], graph.graph_attribs
  end

  def test_save
    util_save "png"
  end

  def test_save_nil
    util_save nil
  end

  def test_shape
    assert_attribute "shape", "blah", graph.shape("blah")
  end

  def test_style
    assert_attribute "style", "blah", graph.style("blah")
  end

  def test_subgraph
    n = nil
    s = graph.subgraph "blah" do
      n = 42
    end

    assert_equal graph, s.graph
    assert_equal "blah", s.name
    assert_equal 42, n
  end

  def test_cluster
    n = nil
    s = graph.cluster "blah" do
      n = 42
    end

    assert_equal graph, s.graph
    assert_equal "cluster_blah", s.name
    assert_equal 42, n
  end

  def test_to_s
    assert_graph graph, '"a" -> "b"'

    graph["a"] >> "c"

    assert_graph graph, '"a" -> "b"', '"a" -> "c"'
  end

  def test_to_s_attrib
    graph.color("blue") << graph["a"]

    assert_graph graph, '"a" [ color = blue ]', '"a" -> "b"'
  end

  def test_to_s_edge_attribs
    graph.edge_attribs << "blah" << "halb"

    assert_graph graph, 'edge [ blah, halb ]', '"a" -> "b"'
  end

  def test_to_s_empty
    assert_graph Graph.new
  end

  def test_to_s_node_attribs
    graph.node_attribs << "blah" << "halb"

    assert_graph graph, 'node [ blah, halb ]', '"a" -> "b"'
  end

  def test_to_s_subgraph
    g = Graph.new "subgraph" do
      edge "a", "c"
    end

    graph << g

g_s = "subgraph \"subgraph\"
  {
    \"a\";
    \"c\";
    \"a\" -> \"c\";
  }"

    assert_graph(graph,
                 g_s, # HACK: indentation is really messy right now
                 '"a" -> "b"')
  end

  def util_save type
    path = File.join(Dir.tmpdir, "blah.#{$$}")

    $x = nil

    def graph.system(*args)
      $x = args
    end

    graph.save(path, type)

    assert_equal graph.to_s + "\n", File.read("#{path}.dot")
    expected = ["dot -T#{type} #{path}.dot > #{path}.png"] if type
    assert_equal expected, $x
  ensure
    File.unlink path rescue nil
  end
end

class TestAttribute < Minitest::Test
  attr_accessor :a

  def setup
    self.a = Graph::Attribute.new "blah"
  end

  def test_lshift
    n = Graph::Node.new nil, nil

    a << n

    assert_equal [a], n.attributes
  end

  def test_plus
    b = Graph::Attribute.new "halb"

    c = a + b

    assert_equal [a, b], c.attr
    assert_equal "blah, halb", c.to_s
  end

  def test_to_s
    assert_equal "blah", a.to_s
  end
end

class TestCompoundAttribute < TestAttribute
  def test_lshift
    b = Graph::Attribute.new "halb"
    n = Graph::Node.new nil, nil

    c = a + b

    c << n # paint the node with a + b

    assert_equal [a, b], n.attributes
  end
end

class TestNode < Minitest::Test
  attr_accessor :n

  def setup
    self.n = Graph::Node.new :graph, "n"
  end

  def test_connected_eh
    graph = Graph.new
    self.n = graph.node "n"
    m = graph.node "m"

    refute n.connected?
    refute m.connected?

    graph.edge("n", "m")

    assert n.connected?
    assert m.connected?
  end

  def test_orphan_eh
    graph = Graph.new
    self.n = graph.node "n"
    m = graph.node "m"

    assert n.orphan?
    assert m.orphan?

    graph.edge("n", "m")

    refute n.orphan?
    refute m.orphan?
  end

  def test_rshift
    graph = Graph.new
    self.n = graph.node "blah"

    n2 = n >> "halb"
    to = graph["halb"]
    e = graph.edges["blah"]["halb"]

    assert_equal n, n2
    assert_kind_of Graph::Edge, e
    assert_kind_of Graph::Node, to
    assert_equal n, e.from
    assert_equal to, e.to
  end

  def test_index
    graph = Graph.new
    self.n = graph.node "blah"

    e = n["halb"]
    to = graph["halb"]

    assert_kind_of Graph::Edge, e
    assert_kind_of Graph::Node, to
    assert_equal n, e.from
    assert_equal to, e.to
  end

  def test_label
    n.label "blah"

    assert_equal ["label = \"blah\""], n.attributes
  end

  def test_label_html
    n.label "<<B>Foo</B>>"

    assert_equal ["label = <<B>Foo</B>>"], n.attributes
  end

  def test_label_newline
    n.label "blah\nblah"

    assert_equal ["label = \"blah\\nblah\""], n.attributes
  end

  def test_to_s
    assert_equal '"n"', n.to_s
  end

  def test_to_s_attribs
    n.attributes << "blah"

    assert_equal '"n" [ blah ]', n.to_s.clean
  end
end

class TestEdge < Minitest::Test
  attr_accessor :e

  def setup
    a = Graph::Node.new :graph, "a"
    b = Graph::Node.new :graph, "b"
    self.e = Graph::Edge.new :graph, a, b
  end

  def test_label
    e.label "blah"

    assert_equal ["label = \"blah\""], e.attributes
  end

  def test_label_newline
    e.label "blah\nblah"

    assert_equal ["label = \"blah\\nblah\""], e.attributes
  end

  def test_decorate
    e.decorate "true"

    assert_equal ["decorate = true"], e.attributes
  end

  def test_to_s
    assert_equal '"a" -> "b"', e.to_s
  end

  def test_to_s_attribs
    e.attributes << "blah"

    assert_equal '"a" -> "b" [ blah ]', e.to_s.clean
  end
end
