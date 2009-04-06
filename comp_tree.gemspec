
Gem::Specification.new { |g|
  g.author = "James M. Lawrence"
  g.email = "quixoticsycophant@gmail.com"
  g.summary = "Parallel Computation Tree"
  g.name = "comp_tree"
  g.rubyforge_project = "comptree"
  g.homepage = "comptree.rubyforge.org"
  g.version = "0.7.0"
  g.description =
    "Build a computation tree and execute it with N parallel threads."

  readme = "README"

  g.files = %W[
    CHANGES
    #{readme}
    Rakefile
    #{g.name}.gemspec
    install.rb
  ] + %w[lib rakelib test].inject(Array.new) { |acc, dir|
    acc + Dir[dir + "/**/*.rb"]
  }
  g.has_rdoc = true
  rdoc_files = [
    readme,
    "lib/comp_tree.rb",
    "lib/comp_tree/driver.rb",
    "lib/comp_tree/error.rb"
  ]
  g.extra_rdoc_files += [readme]

  g.rdoc_options += [
    "--main",
    readme,
    "--title",
    "#{g.name}: #{g.summary}"
  ] + (g.files - rdoc_files).inject(Array.new) { |acc, file|
    acc + ["--exclude", file]
  }
}
