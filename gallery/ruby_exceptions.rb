#!/usr/bin/ruby -w

require "graph"

digraph do
  rotate
  boxes

  ObjectSpace.each_object Class do |mod|
    next if mod.name =~ /Errno/
    next unless mod < Exception

    edge mod.superclass.to_s, mod.to_s
  end

  blue << node("StandardError")
  red  << node("RuntimeError")

  save "ruby_exceptions", "png"
end
