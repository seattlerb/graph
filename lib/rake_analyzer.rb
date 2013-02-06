require "rubygems"
require 'dep_analyzer'

# :stopdoc:

class RakeAnalyzer < DepAnalyzer
  def run
    digraph do
      rotate
      boxes

      current = nil
      rake = Gem.bin_path('rake', 'rake') rescue 'rake'
      path = $:.join File::PATH_SEPARATOR

      content =
        if $stdin.tty? then
          `#{Gem.ruby} -I#{path} -S #{rake} -P -s`
        else
          $stdin.read
        end

      content.each_line do |line|
        case line
        when /^rake (.+)/
          name = $1
          current = name
          node current if current
        when /^\s+(.+)/
          dep = $1
          next if current =~ /pkg/ and File.file? dep
          edge current, dep if current
        else
          warn "unparsed: #{line.chomp}"
        end
      end
    end
  end
end
