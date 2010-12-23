#!/usr/bin/ruby -w

# /* courtesy Ian Darwin and Geoff Collyer, Softquad Inc. */
# digraph unix {
#   size="6,6";
#   node [color=lightblue2, style=filled];
#   "5th Edition" -> "6th Edition";
#   "5th Edition" -> "PWB 1.0";
#   "6th Edition" -> "LSX";
#   "6th Edition" -> "1 BSD";
#   "6th Edition" -> "Mini Unix";
#   "6th Edition" -> "Wollongong";
#   "6th Edition" -> "Interdata";
#   "Interdata" -> "Unix/TS 3.0";
#   "Interdata" -> "PWB 2.0";
#   "Interdata" -> "7th Edition";
#   "7th Edition" -> "8th Edition";
#   "7th Edition" -> "32V";
#   "7th Edition" -> "V7M";
#   "7th Edition" -> "Ultrix-11";
#   "7th Edition" -> "Xenix";
#   "7th Edition" -> "UniPlus+";
#   "V7M" -> "Ultrix-11";
#   "8th Edition" -> "9th Edition";
#   "1 BSD" -> "2 BSD";
#   "2 BSD" -> "2.8 BSD";
#   "2.8 BSD" -> "Ultrix-11";
#   "2.8 BSD" -> "2.9 BSD";
#   "32V" -> "3 BSD";
#   "3 BSD" -> "4 BSD";
#   "4 BSD" -> "4.1 BSD";
#   "4.1 BSD" -> "4.2 BSD";
#   "4.1 BSD" -> "2.8 BSD";
#   "4.1 BSD" -> "8th Edition";
#   "4.2 BSD" -> "4.3 BSD";
#   "4.2 BSD" -> "Ultrix-32";
#   "PWB 1.0" -> "PWB 1.2";
#   "PWB 1.0" -> "USG 1.0";
#   "PWB 1.2" -> "PWB 2.0";
#   "USG 1.0" -> "CB Unix 1";
#   "USG 1.0" -> "USG 2.0";
#   "CB Unix 1" -> "CB Unix 2";
#   "CB Unix 2" -> "CB Unix 3";
#   "CB Unix 3" -> "Unix/TS++";
#   "CB Unix 3" -> "PDP-11 Sys V";
#   "USG 2.0" -> "USG 3.0";
#   "USG 3.0" -> "Unix/TS 3.0";
#   "PWB 2.0" -> "Unix/TS 3.0";
#   "Unix/TS 1.0" -> "Unix/TS 3.0";
#   "Unix/TS 3.0" -> "TS 4.0";
#   "Unix/TS++" -> "TS 4.0";
#   "CB Unix 3" -> "TS 4.0";
#   "TS 4.0" -> "System V.0";
#   "System V.0" -> "System V.2";
#   "System V.2" -> "System V.3";
# }

require "graph"

digraph "unix" do
  graph_attribs << 'size="6,6"'
  node_attribs << lightblue << filled

  edge "5th Edition", "6th Edition"
  edge "5th Edition", "PWB 1.0"
  edge "6th Edition", "LSX"
  edge "6th Edition", "1 BSD"
  edge "6th Edition", "Mini Unix"
  edge "6th Edition", "Wollongong"
  edge "6th Edition", "Interdata"
  edge "Interdata", "Unix/TS 3.0"
  edge "Interdata", "PWB 2.0"
  edge "Interdata", "7th Edition"
  edge "7th Edition", "8th Edition"
  edge "7th Edition", "32V"
  edge "7th Edition", "V7M"
  edge "7th Edition", "Ultrix-11"
  edge "7th Edition", "Xenix"
  edge "7th Edition", "UniPlus+"
  edge "V7M", "Ultrix-11"
  edge "8th Edition", "9th Edition"
  edge "1 BSD", "2 BSD"
  edge "2 BSD", "2.8 BSD"
  edge "2.8 BSD", "Ultrix-11"
  edge "2.8 BSD", "2.9 BSD"
  edge "32V", "3 BSD"
  edge "3 BSD", "4 BSD"
  edge "4 BSD", "4.1 BSD"
  edge "4.1 BSD", "4.2 BSD"
  edge "4.1 BSD", "2.8 BSD"
  edge "4.1 BSD", "8th Edition"
  edge "4.2 BSD", "4.3 BSD"
  edge "4.2 BSD", "Ultrix-32"
  edge "PWB 1.0", "PWB 1.2"
  edge "PWB 1.0", "USG 1.0"
  edge "PWB 1.2", "PWB 2.0"
  edge "USG 1.0", "CB Unix 1"
  edge "USG 1.0", "USG 2.0"
  edge "CB Unix 1", "CB Unix 2"
  edge "CB Unix 2", "CB Unix 3"
  edge "CB Unix 3", "Unix/TS++"
  edge "CB Unix 3", "PDP-11 Sys V"
  edge "USG 2.0", "USG 3.0"
  edge "USG 3.0", "Unix/TS 3.0"
  edge "PWB 2.0", "Unix/TS 3.0"
  edge "Unix/TS 1.0", "Unix/TS 3.0"
  edge "Unix/TS 3.0", "TS 4.0"
  edge "Unix/TS++", "TS 4.0"
  edge "CB Unix 3", "TS 4.0"
  edge "TS 4.0", "System V.0"
  edge "System V.0", "System V.2"
  edge "System V.2", "System V.3"

  save "unix", "png"
end
