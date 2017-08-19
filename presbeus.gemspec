Gem::Specification.new do |s|
  s.name        = 'presbeus'
  s.version     = '0.0.1'
  s.date        = '2017-08-19'
  s.summary     = "command line SMS client for pushbullet"
  s.description = "Allows to view/send pushbullet SMS"
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'time_ago_in_words'
  s.add_runtime_dependency 'terminal-table'
  s.add_runtime_dependency 'highline'
  s.add_runtime_dependency 'colorize'
  s.authors     = ["Olivier Abdesselam"]
  s.executables << "presbeus"
  s.homepage    =
    'http://rubygems.org/gems/presbeus'
  s.license       = 'MIT'
end
