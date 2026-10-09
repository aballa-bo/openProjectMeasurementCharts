# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-measurement_charts"
  s.version     = "1.0.0"
  s.authors     = ["OpenProject Customization"]
  s.email       = ["info@openproject.org"]
  s.summary     = "Measurement Charts for OpenProject"
  s.description = "Turns work packages of a configurable type (e.g. sensor 'measurements') into " \
                   "per-project dashboards of charts, where each chart series is freely mapped to " \
                   "a custom field, with a label, color, unit/axis and optional offset."
  s.license     = "GPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
end
