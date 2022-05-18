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
    self.casks = normal `brew list --cask #{SHH}`
    ports + casks
  end

  def outdated
    # don't cache so it updates every delete
    puts "scanning outdated ports"
    ports = normal `brew outdated #{SHH}`
    puts "scanning outdated casks"
    casks = normal `brew outdated --cask #{SHH}`
    ports + casks
  end

  def alldeps
    # there's YET ANOTHER bug in homebrew whereby `brew deps -1
    # --installed` output is painfully different from all other output:
    #
    # % brew deps -1 --for-each pango
    #   pango: cairo fontconfig freetype fribidi glib harfbuzz
    # % brew deps -1 --installed | grep pango
    #   pango: cairo

    @alldeps ||= begin
      full_names = `brew list --full-name`.split
      `brew deps -n1 --for-each #{full_names.join " "}`
        .lines
        .map { |l| k, *v = l.delete(":").split; [clean(k), v] }
        .to_h
    end
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
