# frozen_string_literal: true
require 'open_project/plugins'

module OpenProject
  module MeasurementCharts
    class Engine < ::Rails::Engine
      engine_name :openproject_measurement_charts

      include OpenProject::Plugins::ActsAsOpEngine

      register 'openproject-measurement_charts',
               author_url: 'https://www.openproject.org',
               bundled: true do

        project_module :measurement_charts do
          permission :view_measurement_charts,
                     { measurement_charts: %i[index data export] },
                     permissible_on: :project,
                     public: true

          permission :manage_measurement_charts,
                     { measurement_chart_settings: %i[edit update],
                       measurement_chart_widgets: %i[index new create edit update destroy move],
                       measurement_chart_series: %i[create edit update destroy] },
                     permissible_on: :project,
                     require: :member
        end

        menu :project_menu,
             :measurement_charts,
             { controller: '/measurement_charts', action: 'index' },
             caption: ->(_project) { I18n.t('measurement_charts.label_measurement_charts', default: 'Measurement Charts') },
             icon: 'graph',
             after: :bim
      end

      initializer 'measurement_charts.register_assets' do |app|
        app.config.assets.paths << root.join('app/assets/javascripts')
      end

      config.to_prepare do
        require 'open_project/measurement_charts/hooks'
        Project.include OpenProject::MeasurementCharts::Patches::ProjectPatch unless Project.included_modules.include?(OpenProject::MeasurementCharts::Patches::ProjectPatch)
      end
    end
  end
end
