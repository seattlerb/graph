require 'dep_analyzer'

# :stopdoc:

class HomebrewAnalyzer < DepAnalyzer
  def installed
    # don't cache so it updates every delete
    puts "scanning installed ports"
    `brew list`.scan(/\S+/).map { |s| s.split.first }
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated ports"
    `brew outdated`.split(/\n/).map { |s| s.split.first }
  end

  def deps port
    `brew deps #{port}`.scan(/\S+/)
  end
end
