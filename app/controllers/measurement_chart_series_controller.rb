# frozen_string_literal: true

class MeasurementChartSeriesController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_widget
  before_action :find_series, only: %i[edit update destroy]

  menu_item :measurement_charts
  layout 'base'

  def create
    @series = @widget.measurement_chart_series.build(series_params)

    if @series.save
      flash[:notice] = I18n.t('notice_successful_create')
    else
      flash[:error] = @series.errors.full_messages.join(', ')
    end
    redirect_to edit_project_measurement_chart_widget_path(@project, @widget)
  end

  def edit
    @available_custom_fields = MeasurementChartSeries.available_custom_fields_for(@project.measurement_chart_setting)
  end

  def update
    if @series.update(series_params)
      flash[:notice] = I18n.t('notice_successful_update')
      redirect_to edit_project_measurement_chart_widget_path(@project, @widget)
    else
      @available_custom_fields = MeasurementChartSeries.available_custom_fields_for(@project.measurement_chart_setting)
      render :edit
    end
  end

  def destroy
    @series.destroy
    flash[:notice] = I18n.t('notice_successful_delete')
    redirect_to edit_project_measurement_chart_widget_path(@project, @widget)
  end

  private

  def find_widget
    @widget = @project.measurement_chart_widgets.find(params[:measurement_chart_widget_id])
  end

  def find_series
    @series = @widget.measurement_chart_series.find(params[:id])
  end

  def series_params
    params.require(:measurement_chart_series).permit(:custom_field_id, :label, :color, :axis_label, :value_offset)
  end
end
