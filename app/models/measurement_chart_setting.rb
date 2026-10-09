# frozen_string_literal: true

# Per-project source configuration: which work package type holds the
# "measurement" work packages, and which of its custom fields carries the
# measurement's date (used both to filter the requested date range and to
# group/bin the series on the dashboard).
class MeasurementChartSetting < ApplicationRecord
  belongs_to :project
  belongs_to :work_package_type, class_name: "Type", optional: true
  belongs_to :date_custom_field, class_name: "CustomField", optional: true

  validates :project, presence: true
  validates :bin_count, numericality: { only_integer: true, greater_than: 1, less_than_or_equal_to: 200 }
  validates :default_range_days, numericality: { only_integer: true, greater_than: 0 }
  validates :refresh_interval_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def configured?
    work_package_type_id.present?
  end
end
