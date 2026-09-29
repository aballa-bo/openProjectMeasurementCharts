# frozen_string_literal: true

class MeasurementChartWidgetsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_widget, only: %i[edit update destroy move]

  menu_item :measurement_charts
  layout 'base'

  def index
    @widgets = @project.measurement_chart_widgets.ordered.includes(measurement_chart_series: :custom_field)
    @setting = @project.measurement_chart_setting
  end

  def new
    @widget = @project.measurement_chart_widgets.build
  end

  def create
    @widget = @project.measurement_chart_widgets.build(widget_params)

    if @widget.save
      flash[:notice] = I18n.t('notice_successful_create')
      redirect_to edit_project_measurement_chart_widget_path(@project, @widget)
    else
      render :new
    end
  end

  def edit
    load_series_form_data
  end

  def update
    if @widget.update(widget_params)
      flash[:notice] = I18n.t('notice_successful_update')
      redirect_to project_measurement_chart_widgets_path(@project)
    else
      load_series_form_data
      render :edit
    end
  end

  def destroy
    @widget.destroy
    flash[:notice] = I18n.t('notice_successful_delete')
    redirect_to project_measurement_chart_widgets_path(@project)
  end

  def move
    direction = params[:direction]
    case direction
    when 'higher' then @widget.move_higher
    when 'lower' then @widget.move_lower
    end
    redirect_to project_measurement_chart_widgets_path(@project)
  end

  private

  def find_widget
    @widget = @project.measurement_chart_widgets.find(params[:id])
  end

  def load_series_form_data
    @series = @widget.measurement_chart_series.ordered
    @new_series = @widget.measurement_chart_series.build
    @available_custom_fields = MeasurementChartSeries.available_custom_fields_for(@project.measurement_chart_setting)
  end

  def widget_params
    params.require(:measurement_chart_widget).permit(:title, :chart_type)
  end
end
