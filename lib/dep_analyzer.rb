require 'graph'
require 'set'
require 'tsort'

class Cache
  def initialize(cache, timeout=24)
    @cache = cache
    @timeout = timeout
  end

  def cache(id, timeout=@timeout)
    Dir.mkdir @cache unless test ?d, @cache
    path = File.join @cache, id

    age = test(?f, path) ? (Time.now - test( ?M, path )) / 3600 : -1

    if age >= 0 and timeout > age then
      warn "from cache" if $DEBUG
      data = File.read(path)
    else
      warn "NOT from cache (#{age} hours old)" if $DEBUG
      data = yield
      File.open(path, "w") do |f|
        f.write data
      end
    end
    return data
  end
end

class Set
  def push *v
    v.each do |o|
      add(o)
    end
  end
end

class Hash
  include TSort

  alias tsort_each_node each_key

  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end

  def minvert
    r = Hash.new { |h,k| h[k] = [] }
    invert.each do |keys, val|
      keys.each do |key|
        r[key] << val
      end
    end
    r.each do |k,v|
      r[k] = v.sort
    end
    r
  end

  def transitive
    r = Hash.new { |h,k| h[k] = [] }
    each do |k,v|
      r[k].push(*t(k))
    end
    r
  end

  def t(k)
    r = Set.new
    self[k].each do |v|
      r.push(v, *t(v))
    end
    r.to_a.sort
  end
end

class DepAnalyzer < Cache
  def initialize
    super ".#{self.class}.cache"
  end

  def run(argv = ARGV)
    g = Graph.new
    ports = {}
    installed.each do |port|
      ports[port] = nil
    end

    old = {}
    outdated.each do |port|
      old[port] = nil
    end

    all_ports = ports.keys

    ports.each_key do |port|
      deps = self.deps(port)
      # remove things that don't intersect with installed list
      deps -= (deps - all_ports)
      deps.each do |dep|
        g[port] << dep
      end
      ports[port] = deps
    end

    indies = ports.keys - ports.minvert.keys
    indies.each do |k|
      g.attribs[k] << "color = blue"
    end
    old.each do |k,v|
      if indies.include? k then
        g.attribs[k] << "color = purple4"
      else
        g.attribs[k] << "color = red"
      end
    end

    puts "Looks like you can nuke:\n\t#{indies.join("\n\t")}"

    unless argv.empty? then
      argv.each do |pkg|
        hits = ports.transitive[pkg]
        sorted = ports.tsort.reverse
        topo = [pkg] + sorted.select { |o| hits.include? o }
        prune = ports.dup
        topo.each do |k|
          prune.delete(k)
        end
        topo -= prune.values.flatten.uniq

        puts topo.join(' ')
      end
    end

    g.save "#{self.class}"
    system "open #{self.class}.png"
  end
end

