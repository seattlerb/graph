require 'dep_analyzer'

class RubygemsAnalyzer < DepAnalyzer
  def installed
    require 'rubygems'
    ENV['GEM_PATH'] = `gem env home`
    Gem.clear_paths
    # don't cache so it updates every delete
    puts "scanning installed rubygems"
    Gem.source_index.gems.values.map { |gem| gem.name }.sort
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated rubygems"
    Gem.source_index.outdated.sort
  end

  def deps port
    Gem.source_index.find_name(port).first.dependencies.map { |dep| dep.name }
  end
end
