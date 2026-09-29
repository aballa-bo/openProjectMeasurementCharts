# frozen_string_literal: true

class CreateMeasurementChartSeries < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_chart_series do |t|
      t.references :measurement_chart_widget, null: false, foreign_key: true, index: true
      t.references :custom_field, null: false, foreign_key: true
      t.string :label, null: false
      t.string :color, null: false, default: "#4bc0c0"
      t.string :axis_label
      t.float :value_offset, null: false, default: 0.0
      t.integer :position

      t.timestamps
    end
  end
end
