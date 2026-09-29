# frozen_string_literal: true

# Configures, per project, which work package type holds the "measurement"
# work packages and which of its custom fields carries the measurement date.
class MeasurementChartSettingsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  menu_item :measurement_charts
  layout 'base'

  def edit
    @setting = @project.measurement_chart_setting || @project.build_measurement_chart_setting
    load_form_collections
  end

  def update
    @setting = @project.measurement_chart_setting || @project.build_measurement_chart_setting

    if @setting.update(setting_params)
      flash[:notice] = I18n.t('notice_successful_update')
      redirect_to edit_project_measurement_chart_settings_path(@project)
    else
      load_form_collections
      render :edit
    end
  end

  private

  def load_form_collections
    @types = @project.types.order(:position)
    @date_fields = WorkPackageCustomField.where(field_format: 'date').order(:name)
  end

  def setting_params
    params.require(:measurement_chart_setting)
          .permit(:work_package_type_id, :date_custom_field_id, :bin_count, :default_range_days,
                   :refresh_interval_seconds)
  end
end
