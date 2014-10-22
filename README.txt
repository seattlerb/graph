= graph

home :: https://github.com/seattlerb/graph

== DESCRIPTION:

Graph is a type of hash that outputs in graphviz's dot format. It
comes with a command-line interface that is easily pluggable.

It ships with plugins to graph dependencies and status of installed
rubygems, rake tasks, homebrew ports, mac ports, and freebsd ports,
coloring leaf nodes blue, outdated nodes red, and outdated leaf nodes
purple (red+blue).

OSX quick tip: 

    % sudo gem install graph
    % sudo brew install graphviz
    % gem unpack graph
    % cd graph*
    % sudo gem install hoe
    % rake gallery
    % open gallery/*.png

== FEATURES/PROBLEMS:

* Very clean DSL interface and API.
* Saves to dot and can automatically convert to png (or whatever).
* graph, edge, and node attributes are easy to set.
* bin/graph includes a caching mechanism for slower fairly static data.

== SYNOPSIS:

    digraph do
      # many ways to access/create edges and nodes
      edge "a", "b"
      self["b"]["c"]
      node("c") >> "a"

      square   << node("a")
      triangle << node("b")

      red   << node("a") << edge("a", "b")
      green << node("b") << edge("b", "c")
      blue  << node("c") << edge("c", "a")

      save "simple_example", "png"
    end

== REQUIREMENTS:

* hoe

== INSTALL:

* sudo gem install graph

== LICENSE:

(The MIT License)

Copyright (c) Ryan Davis, seattle.rb

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
