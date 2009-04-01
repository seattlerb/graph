= graph

* http://rubyforge.org/projects/seattlerb

== DESCRIPTION:

Graph is a type of hash that outputs in graphviz's dot format. It
comes with a command-line interface that is easily pluggable.

It ships with plugins to graph dependencies and status of installed
rubygems, mac ports, and freebsd ports, coloring leaf nodes blue,
outdated nodes red, and outdated leaf nodes purple (red+blue).

== FEATURES/PROBLEMS:

* Very easy hash interface.
* Saves to dot and automatically converts to png (or whatever).
* edge and node attributes are easy to set.
* bin/graph includes a caching mechanism for slower fairly static data.

== SYNOPSIS:

    deps = Graph.new
    
    ObjectSpace.each_object Class do |mod|
      next if mod.name =~ /Errno/
      next unless mod < Exception
      deps[mod.to_s] = mod.superclass.to_s
    end
    
    deps.attribs["StandardError"] << "color = blue"
    deps.attribs["RuntimeError"]  << "color = red"
    deps.prefix << "rankdir = BT" # put Exception on top
    
    deps.save "exceptions"

== REQUIREMENTS:

* hoe

== INSTALL:

* sudo gem install graph

== LICENSE:

(The MIT License)

Copyright (c) 2009 Ryan Davis, seattle.rb

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
