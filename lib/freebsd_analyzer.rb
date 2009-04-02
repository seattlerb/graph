require 'dep_analyzer'

class FreebsdAnalyzer < DepAnalyzer
  def installed
    # don't cache so it updates every delete
    puts "scanning installed ports"
    `pkg_info`.split(/\n/).map { |s| s.split.first }
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated ports"
    `pkg_version -vL=`.split(/\n/)[1..-1].map { |s| s.split.first }
  end

  def deps port
    cache("#{port}.deps") {
      `pkg_info -r #{port}`
    }.grep(/Dependency:/).map { |s| s.split[1] }
  end
end
