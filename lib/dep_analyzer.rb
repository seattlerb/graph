require 'graph'
require 'set'
require 'tsort'

##
# A simple file caching mechanism with automatic timeout.

class Cache

  ##
  # Create a cache at +cache+ path for a given +timeout+ (in hours).

  def initialize(cache, timeout=24)
    @cache = cache
    @timeout = timeout
  end

  ##
  # Add a cached item to +id+. Value is returned either from the cache
  # if it is new enough or by yielding.

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

class Set # :nodoc:

  ##
  # A simple batch-add to Set. Bad API is bad. Thank god for open classes.

  def push *v
    v.each do |o|
      add(o)
    end
  end
end

class Hash # :nodoc:
  include TSort

  alias tsort_each_node each_key

  def tsort_each_child(node, &block)
    fetch(node).each(&block)
  end

  ##
  # Return the #inverse of a hash, allowing for multiple keys having
  # the same values.

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

  ##
  # Calculate the transitive closure of the hash.

  def transitive
    r = Hash.new { |h,k| h[k] = [] }
    each do |k,v|
      r[k].push(*t(k))
    end
    r
  end

  ##
  # Calculates the (transitive) set of dependencies for a given key.

  def t(k)
    r = Set.new
    self[k].each do |v|
      r.push(v, *t(v))
    end
    r.to_a.sort
  end
end

##
# Abstract class to analyze dependencies. Intended to be subclassed
# for a given dependency system (eg rubygems). Subclasses must
# implement #deps, #installed, and #outdated at the very least.

class DepAnalyzer < Cache
  attr_accessor :g # :nodoc:

  def initialize # :nodoc:
    super ".#{self.class}.cache"
    @g = Graph.new
  end

  ##
  # Allows your subclass to add extra fancy stuff to the graph when
  # analysis is finished.

  def decorate
    # nothing to do by default
  end

  ##
  # Return the dependencies for a given port.

  def deps port
    raise NotImplementedError, "subclass responsibility"
  end

  ##
  # Return all installed items on the system.

  def installed
    raise NotImplementedError, "subclass responsibility"
  end

  ##
  # Return all outdated items currently installed.

  def outdated
    raise NotImplementedError, "subclass responsibility"
  end

  ##
  # Do the actual work.

  def run(argv = ARGV)
    setup

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

    rect   = g.rect
    blue   = g.color "blue"
    purple = g.color "purple4"
    red    = g.color "red"
    pink   = g.fill_lightpink

    indies = ports.keys - ports.minvert.keys
    indies.each do |k|
      rect << g[k]
      blue << g[k]
    end

    old.each do |k,v|
      pink << g[k]
      if indies.include? k then
        purple << g[k]
      else
        red << g[k]
      end
    end

    decorate

    puts "Looks like you can nuke:\n\t#{indies.sort.join("\n\t")}"

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

    g
  end

  ##
  # Allows subclasses to do any preparation before the run.

  def setup
    # nothing to do by default
  end
end
