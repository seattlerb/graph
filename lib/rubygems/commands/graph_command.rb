require 'rubygems/command'
require 'rubygems_analyzer'

# :stopdoc:

class Gem::Commands::GraphCommand < Gem::Command # :nodoc: all

  def initialize
    super 'graph', 'Graph dependency relationships of installed gems'
  end

  def execute
    g = RubygemsAnalyzer.new.run options[:args]
    g.save "RubygemsAnalyzer", "png"

    say "Graph saved to:\n\tRubygemsAnalyzer.png"
  end
end
