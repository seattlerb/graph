require 'rubygems/command'
require 'rubygems_analyzer'

class Gem::Commands::GraphCommand < Gem::Command

  def initialize
    super 'graph', 'Graph dependency relationships of installed gems'
  end

  def execute
    RubygemsAnalyzer.new.run options[:args]

    say "Graph saved to:\n\tRubygemsAnalyzer.png"
  end

end

