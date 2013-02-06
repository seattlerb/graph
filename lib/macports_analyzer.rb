require 'dep_analyzer'

# :stopdoc:

class MacportsAnalyzer < DepAnalyzer
  def installed
    # don't cache so it updates every delete
    puts "scanning installed ports"
    `port installed`.split(/\n/)[1..-1].map { |s| s.split.first }
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated ports"
    `port outdated`.split(/\n/)[1..-1].map { |s| s.split.first }
  end

  def deps port
    cache("#{port}.deps") {
      `port deps #{port}`
    }.scan(/Dependencies:\s*(.+)$/).join(', ').split(/, /)
  end
end
