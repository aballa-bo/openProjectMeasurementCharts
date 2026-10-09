# frozen_string_literal: true

class CreateMeasurementChartWidgets < ActiveRecord::Migration[7.0]
  def change
    create_table :measurement_chart_widgets do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.string :title, null: false
      t.string :chart_type, null: false, default: "line"
      t.integer :position

      t.timestamps
    end
  end
end
