# frozen_string_literal: true

module OpenProject
  module MeasurementCharts
    module Patches
      module ProjectPatch
        extend ActiveSupport::Concern

        included do
          has_one :measurement_chart_setting, class_name: 'MeasurementChartSetting', dependent: :destroy
          has_many :measurement_chart_widgets, -> { order(:position) }, class_name: 'MeasurementChartWidget', dependent: :destroy
        end
      end
    end
  end
end
