# -*- encoding: utf-8 -*-
# stub: jekyll-avatar 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "jekyll-avatar".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ben Balter".freeze]
  s.date = "2022-04-04"
  s.email = ["ben.balter@github.com".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze, "lib/jekyll-avatar.rb".freeze, "lib/jekyll-avatar/version.rb".freeze]
  s.homepage = "https://github.com/jekyll/jekyll-avatar".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "A Jekyll plugin for rendering GitHub avatars".freeze

  s.installed_by_version = "3.3.7" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<jekyll>.freeze, [">= 3.0", "< 5.0"])
    s.add_development_dependency(%q<bundler>.freeze, ["> 1.0", "< 3.0"])
    s.add_development_dependency(%q<kramdown-parser-gfm>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<rspec-html-matchers>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<rubocop-jekyll>.freeze, ["~> 0.12.0"])
    s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.0"])
  else
    s.add_dependency(%q<jekyll>.freeze, [">= 3.0", "< 5.0"])
    s.add_dependency(%q<bundler>.freeze, ["> 1.0", "< 3.0"])
    s.add_dependency(%q<kramdown-parser-gfm>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rspec-html-matchers>.freeze, ["~> 0.9"])
    s.add_dependency(%q<rubocop-jekyll>.freeze, ["~> 0.12.0"])
    s.add_dependency(%q<rubocop-rspec>.freeze, ["~> 2.0"])
  end
end
