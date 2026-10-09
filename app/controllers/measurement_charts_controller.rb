# frozen_string_literal: true
require 'csv'

class MeasurementChartsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_setting

  menu_item :measurement_charts
  layout 'base'

  DEFAULT_BIN_COUNT = 30

  def index
    @widgets = @project.measurement_chart_widgets.ordered.includes(measurement_chart_series: :custom_field)
    @can_manage = User.current.allowed_in_project?(:manage_measurement_charts, @project)
  end

  def data
    unless @setting&.configured?
      render json: { error: I18n.t('measurement_charts.error_not_configured') }, status: :unprocessable_entity
      return
    end

    start_date, end_date = date_range
    field_ids = chart_field_ids
    measurements = load_measurements(start_date, end_date, field_ids)

    render json: {
      start_date: start_date.iso8601,
      end_date: end_date.iso8601,
      bin_count: @setting.bin_count,
      count: measurements.size,
      measurements:
    }
  end

  # CSV export of every individual measurement in the selected date range
  # (not binned/averaged), one row per work package, one column per custom
  # field charted by at least one series.
  def export
    unless @setting&.configured?
      render json: { error: I18n.t('measurement_charts.error_not_configured') }, status: :unprocessable_entity
      return
    end

    start_date, end_date = date_range
    field_ids = chart_field_ids
    field_names = CustomField.where(id: field_ids).pluck(:id, :name).to_h
    measurements = load_measurements(start_date, end_date, field_ids).sort_by { |m| m[:date] }

    csv = CSV.generate do |rows|
      rows << [
        I18n.t('measurement_charts.export_column_id'),
        I18n.t('measurement_charts.export_column_date'),
        I18n.t('measurement_charts.export_column_subject'),
        *field_ids.map { |id| field_names[id] || id.to_s }
      ]
      measurements.each do |m|
        rows << [m[:id], m[:date], sanitize_csv_cell(m[:subject]), *field_ids.map { |id| m[:values][id] }]
      end
    end

    send_data csv,
              filename: "measurement_charts_#{@project.identifier}_#{start_date.iso8601}_#{end_date.iso8601}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  private

  def chart_field_ids
    @project.measurement_chart_widgets
            .flat_map { |w| w.measurement_chart_series.map(&:custom_field_id) }
            .uniq
  end

  def find_setting
    @setting = @project.measurement_chart_setting
  end

  def date_range
    default_days = @setting&.default_range_days || DEFAULT_BIN_COUNT
    end_date = parse_date(params[:end_date]) || Date.current
    start_date = parse_date(params[:start_date]) || (end_date - default_days.days)
    [start_date, end_date]
  end

  def parse_date(value)
    return nil if value.blank?

    Date.iso8601(value)
  rescue ArgumentError
    nil
  end

  # Loads work packages of the configured "measurement" type within the given
  # date range (matched against the configured date custom field, falling
  # back to created_at when a work package has none) and extracts, for each
  # one, the raw numeric value of every custom field referenced by a chart
  # series. Each series' offset is applied client-side, from the widget
  # config embedded in the dashboard page, since the same custom field could
  # in principle be reused by two series with different offsets.
  def load_measurements(start_date, end_date, field_ids)
    work_packages = @project.work_packages
                             .visible
                             .where(type_id: @setting.work_package_type_id)
                             .includes(:custom_values)

    date_field_id = @setting.date_custom_field_id

    work_packages.filter_map do |wp|
      measured_on = date_field_id.present? ? wp.typed_custom_value_for(date_field_id) : nil
      measured_on = coerce_date(measured_on) || wp.created_at.to_date

      next if measured_on < start_date || measured_on > end_date

      values = field_ids.index_with { |cf_id| numeric_value_for(wp, cf_id) }

      {
        id: wp.id,
        subject: wp.subject,
        date: measured_on.iso8601,
        values:
      }
    end
  end

  def coerce_date(value)
    case value
    when Date then value
    when Time, DateTime then value.to_date
    when String then Date.iso8601(value)
    end
  rescue ArgumentError
    nil
  end

  # Neutralizes spreadsheet formula injection: a work package subject
  # starting with =, +, -, @ or a tab/CR would otherwise be interpreted as a
  # formula by Excel/Sheets when the CSV is opened.
  def sanitize_csv_cell(value)
    return value unless value.is_a?(String) && value.match?(/\A[=+\-@\t\r]/)

    "'#{value}"
  end

  def numeric_value_for(work_package, custom_field_id)
    raw = work_package.typed_custom_value_for(custom_field_id)
    return nil if raw.nil?

    Float(raw)
  rescue ArgumentError, TypeError
    nil
  end
end
