# frozen_string_literal: true

# One line/bar drawn on a MeasurementChartWidget, mapped to a single custom
# field of the project's measurement work packages.
#
# `value_offset` mirrors what the previous standalone script did in code for
# specific fields (e.g. correcting a sensor's temperature/humidity reading by
# a fixed amount) - here it is a per-series setting instead of hardcoded Python.
class MeasurementChartSeries < ApplicationRecord
  NUMERIC_FORMATS = %w[int float].freeze

  # Quick-pick swatches offered next to the native color picker in the series
  # form - common, visually distinct colors, not a per-chart assignment order.
  SWATCH_COLORS = %w[
    #e34948 #eb6834 #eda100 #bcbd22
    #008300 #1baf7a #17becf #2a78d6
    #3f51b5 #4a3aa7 #9467bd #e87ba4
    #8c564b #7f7f7f #495057 #000000
  ].freeze

  belongs_to :measurement_chart_widget
  belongs_to :custom_field

  acts_as_list scope: :measurement_chart_widget

  validates :label, presence: true
  validates :color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a hex color like #4bc0c0" }
  validate :custom_field_must_be_numeric

  before_validation :set_default_label, on: :create

  scope :ordered, -> { order(:position) }

  # Custom fields a series is allowed to be mapped to: numeric fields, scoped
  # down to the ones enabled for the configured "measurement" work package
  # type once one has been chosen.
  def self.available_custom_fields_for(setting)
    scope = WorkPackageCustomField.where(field_format: NUMERIC_FORMATS).order(:name)
    return scope if setting.blank? || setting.work_package_type_id.blank?

    scope.joins(:types).where(types: { id: setting.work_package_type_id }).distinct
  end

  private

  def custom_field_must_be_numeric
    return if custom_field.blank?

    unless NUMERIC_FORMATS.include?(custom_field.field_format)
      errors.add(:custom_field, "must be a numeric (integer or float) custom field")
    end
  end

  def set_default_label
    self.label = custom_field&.name if label.blank?
  end
end
