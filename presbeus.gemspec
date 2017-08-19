Gem::Specification.new do |s|
  s.name        = 'presbeus'
  s.version     = '0.0.6'
  s.date        = '2017-08-19'
  s.summary     = "command line SMS client for pushbullet"
  s.description = "Allows to view/send pushbullet SMS"
  s.add_runtime_dependency 'rest-client', '~> 2'
  s.add_runtime_dependency 'time_ago_in_words', '~> 0'
  s.add_runtime_dependency 'highline', '~> 1'
  s.add_runtime_dependency 'colorize', '~> 0'
  s.add_runtime_dependency 'terminal-table', '~> 1'
  s.add_runtime_dependency 'kontena-websocket-client', '~> 1'
  s.authors     = ["Olivier Abdesselam"]
  s.executables << "presbeus"
  s.homepage    =
    'http://rubygems.org/gems/presbeus'
  s.license       = 'MIT'
end
