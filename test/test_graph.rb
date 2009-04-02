require "test/unit"
require "tmpdir"
require "graph"

class TestGraph < Test::Unit::TestCase
  def setup
    @graph = Graph.new
    @graph["a"] << "b"
  end

  def test_to_s_empty
    assert_equal util_dot, Graph.new.to_s
  end

  def test_delete
    assert_equal %w(b), @graph.delete("a")
    assert_equal [], @graph.order
  end

  def test_filter_size
    @graph.filter_size 2
    assert @graph.empty?
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

  def test_order
    assert_equal %w(a), @graph.order
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

  def test_to_s_prefix
    @graph.prefix << "blah"
    @graph["a"] << "c"

    expected = util_dot('blah', '"a" -> "b"', '"a" -> "c"')
    assert_equal expected, @graph.to_s
  end

  def test_to_s_attrib
    @graph.attribs["a"] << "color = blue"
    @graph["a"] << "c"

    expected = util_dot('"a" [ color = blue ]', '"a" -> "b"', '"a" -> "c"')
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
