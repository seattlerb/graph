# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/graph.rb'

Hoe.plugin :seattlerb

Hoe.spec 'graph' do
  developer 'Ryan Davis', 'ryand-ruby@zenspider.com'
end

gallery = Dir["gallery/*.rb"]
pngs = gallery.map { |f| f.sub(/\.rb$/, ".png") }
dots = gallery.map { |f| f.sub(/\.rb$/, ".dot") }

file pngs
file dots
task :gallery => pngs

rule ".png" => ".rb" do |t|
  Dir.chdir "gallery" do
    ruby "-I../lib #{File.basename t.source}"
  end
end

task :clean do
  rm_f Dir[*pngs] + Dir[*dots]
end

# vim: syntax=ruby
