# frozen_string_literal: true

class CreateMeasurementChartSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_chart_settings do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.references :work_package_type, foreign_key: { to_table: :types }
      t.references :date_custom_field, foreign_key: { to_table: :custom_fields }
      t.integer :bin_count, null: false, default: 30
      t.integer :default_range_days, null: false, default: 30
      t.integer :refresh_interval_seconds, null: false, default: 300

      t.timestamps
    end
  end
end
