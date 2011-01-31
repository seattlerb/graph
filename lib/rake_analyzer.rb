require 'dep_analyzer'

class RakeAnalyzer < DepAnalyzer
  def run
    digraph do
      rotate
      boxes

      current = nil
      rake = Gem.bin_path('rake', 'rake') rescue 'rake'

      `#{Gem.ruby} -I#{$:.join File::PATH_SEPARATOR} -S #{rake} -P -s`.each_line do |line|
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

      save "RakeAnalyzer", "png"
    end
  end
end
