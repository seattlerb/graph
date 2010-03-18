require 'dep_analyzer'

class RakeAnalyzer < DepAnalyzer
  def run
    require 'graph'
    g = Graph.new
    g.rotate

    current = nil
    `rake -P -s`.each_line do |line|
      case line
      when /^rake (.+)/
        name = $1
        # current = (name =~ /pkg/) ? nil : name
        current = name
        g[current] if current # force the node to exist, in case of a leaf
      when /^\s+(.+)/
        g[current] << $1 if current
      else
        warn "unparsed: #{line.chomp}"
      end
    end


    g.boxes
    g.save "#{self.class}"
    system "open #{self.class}.png"
  end
end
