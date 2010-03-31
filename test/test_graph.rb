require "minitest/autorun"
require "tmpdir"
require "graph"

class TestGraph < MiniTest::Unit::TestCase
  def setup
    @graph = Graph.new
    @graph["a"] << "b"
  end

  def test_boxes
    expected = util_dot('"a" -> "b"')
    assert_equal expected, @graph.to_s

    @graph.boxes

    expected = util_dot('node [ shape = box ]',
                        '"a" -> "b"')
    assert_equal expected, @graph.to_s
  end

  def test_clear
    @graph.clear

    assert_empty @graph.prefix,  "prefix"
    assert_empty @graph.order,   "order"
    assert_empty @graph.attribs, "attribs"
    assert_empty @graph.edge,    "edge"
  end

  def test_counts
    expect = { "a" => 1, }
    assert_equal expect, @graph.counts

    @graph["a"] << "b"
    @graph["a"] << "c"
    @graph["b"] << "c"

    expect = { "a" => 3, "b" => 1, }
    assert_equal expect, @graph.counts
  end

  def test_delete
    assert_equal %w(b), @graph.delete("a")
    assert_equal [], @graph.order
  end

  def test_filter_size
    @graph.filter_size 2
    assert @graph.empty?
  end

  def test_global_attrib
    expected = util_dot('"a" -> "b"')
    assert_equal expected, @graph.to_s

    @graph.global_attrib "color = blue"

    expected = util_dot('"a" [ color = blue ]',
                        '"b" [ color = blue ]',
                        '"a" -> "b"')
    assert_equal expected, @graph.to_s
  end

  def test_invert
    @graph["a"] << "c"
    invert = @graph.invert
    assert_equal %w(a), invert["b"]
    assert_equal %w(a), invert["c"]
  end

  def test_keys_by_count
    @graph["a"] << "c"
    @graph["d"] << "e" << "f" << "g"
    assert_equal %w(d a), @graph.keys_by_count
  end

  def test_nodes
    assert_equal %w(a),   @graph.keys.sort
    assert_equal %w(a b), @graph.nodes.sort
  end

  def test_normalize
    @graph.clear
    @graph["a"] << "b" << "b" << "b" # 3 edges from a to b

    expect = { "a" => %w(b b b) }
    assert_equal expect, @graph

    @graph.normalize                 # clear all but one edge

    expect = { "a" => %w(b) }
    assert_equal expect, @graph
  end

  def test_orient
    @graph.orient "blah"

    assert_equal ["rankdir = blah"], @graph.prefix
  end

  def test_orient_default
    @graph.orient

    assert_equal ["rankdir = TB"], @graph.prefix
  end

  def test_order
    assert_equal %w(a), @graph.order
  end

  def test_rotate
    @graph.rotate "blah"

    assert_equal ["rankdir = blah"], @graph.prefix
  end

  def test_rotate_default
    @graph.rotate

    assert_equal ["rankdir = LR"], @graph.prefix
  end

  def test_save
    util_save "png"
  end

  def test_save_nil
    util_save nil
  end

  def test_to_s
    expected = util_dot '"a" -> "b"'
    assert_equal expected, @graph.to_s

    @graph["a"] << "c"

    expected = util_dot '"a" -> "b"', '"a" -> "c"'
    assert_equal expected, @graph.to_s
  end

  def test_to_s_attrib
    @graph.attribs["a"] << "color = blue"
    @graph["a"] << "c"

    expected = util_dot('"a" [ color = blue ]', '"a" -> "b"', '"a" -> "c"')
    assert_equal expected, @graph.to_s
  end

  def test_to_s_empty
    assert_equal util_dot, Graph.new.to_s
  end

  def test_to_s_prefix
    @graph.prefix << "blah"
    @graph["a"] << "c"

    expected = util_dot('blah', '"a" -> "b"', '"a" -> "c"')
    assert_equal expected, @graph.to_s
  end

  def util_dot(*lines)
    lines = lines.map { |l| "    #{l};" }.join("\n")
    "digraph absent\n  {\n#{lines}\n  }".sub(/\n\n/, "\n")
  end

  def util_save type
    path = File.join(Dir.tmpdir, "blah.#{$$}")

    $x = nil

    def @graph.system(*args)
      $x = args
    end

    @graph.save(path, type)

    assert_equal @graph.to_s, File.read("#{path}.dot")
    expected = ["dot -T#{type} #{path}.dot > #{path}.png"] if type
    assert_equal expected, $x
  ensure
    File.unlink path rescue nil
  end
end
