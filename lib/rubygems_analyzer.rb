require 'dep_analyzer'

begin
  require "rubygems/cleanroom"
rescue LoadError
  warn "NOTE: Not using rubygems-cleanroom. Try it! You might like it."
end

# :stopdoc:

$a ||= false

class RubygemsAnalyzer < DepAnalyzer
  def installed
    # don't cache so it updates every delete
    puts "scanning installed rubygems"
    Gem::Specification.map(&:name).sort
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated rubygems"
    Gem::Specification.outdated.sort
  end

  def deps gem_name
    gem = Gem::Specification.find_by_name gem_name
    gem.dependencies
  end

  def decorate
    developer_dependency = g.gray

    installed = self.installed

    installed.each do |gem|
      deps = self.deps gem

      deps.each do |dep|
        next if dep.type == :runtime
        name = dep.name
        developer_dependency << g[gem][name] if $a or installed.include? name
      end
    end
  end
end
