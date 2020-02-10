require 'dep_analyzer'

# :stopdoc:

class HomebrewAnalyzer < DepAnalyzer
  SHH = "2> /dev/null"

  attr_accessor :casks

  def installed
    # don't cache so it updates every delete
    puts "scanning installed ports"
    ports = normal `brew list #{SHH}`
    puts "scanning installed casks"
    self.casks = normal `brew cask list #{SHH}`
    ports + casks
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated ports"
    ports = normal `brew outdated #{SHH}`
    puts "scanning outdated casks"
    casks = normal `brew cask outdated #{SHH}`
    ports + casks
  end

  def alldeps
    @alldeps ||= `brew deps --installed`
      .lines
      .map { |l| k, *v = l.delete(":").split; [clean(k), v] }
      .to_h
  end

  def deps port
    return [] if @casks.include? port
    alldeps[port] ||= `brew deps #{port}`.scan(/\S+/)
  end

  def normal lines
    lines.split(/\n/).map { |s| clean s }
  end

  def clean name
    name.split("/").last
  end
end
