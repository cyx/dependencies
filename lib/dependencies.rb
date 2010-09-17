require File.expand_path("./dependencies/dep", File.dirname(__FILE__))

Dep.new(File.read("dependencies")).require

