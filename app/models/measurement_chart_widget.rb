# frozen_string_literal: true

# A single chart on the dashboard (e.g. "Temperature and Humidity"). Its
# actual data series are freely mapped to custom fields via
# MeasurementChartSeries.
class MeasurementChartWidget < ApplicationRecord
  CHART_TYPES = %w[line bar].freeze

  belongs_to :project
  has_many :measurement_chart_series,
           -> { order(:position) },
           dependent: :destroy,
           inverse_of: :measurement_chart_widget

  acts_as_list scope: :project

  validates :title, presence: true
  validates :chart_type, inclusion: { in: CHART_TYPES }

  scope :ordered, -> { order(:position) }
end
