require 'dep_analyzer'

$a ||= false

class RubygemsAnalyzer < DepAnalyzer
  def setup
    require "rubygems"
    ENV['GEM_PATH'] = `gem env home`
    Gem.clear_paths
  end

  def installed
    # don't cache so it updates every delete
    puts "scanning installed rubygems"
    Gem.source_index.gems.values.map { |gem| gem.name }.sort
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated rubygems"
    Gem.source_index.outdated.sort
  end

  def deps gem
    Gem.source_index.find_name(gem).first.dependencies.map { |dep| dep.name }
  end

  def decorate
    developer_dependency = g.gray

    installed = self.installed

    installed.each do |gem|
      deps = Gem.source_index.find_name(gem).first.dependencies

      deps.each do |dep|
        next if dep.type == :runtime
        name = dep.name
        developer_dependency << g[gem][name] if $a or installed.include? name
      end
    end
  end
end
