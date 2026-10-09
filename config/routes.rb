# frozen_string_literal: true

OpenProject::Application.routes.draw do
  scope 'projects/:project_id', as: 'project' do
    resources :measurement_charts, only: [:index], controller: 'measurement_charts' do
      collection do
        get :data
        get :export
      end
    end

    resource :measurement_chart_settings, only: %i[edit update], controller: 'measurement_chart_settings'

    resources :measurement_chart_widgets, controller: 'measurement_chart_widgets' do
      member do
        patch :move
      end

      resources :measurement_chart_series, only: %i[create edit update destroy],
                                            controller: 'measurement_chart_series'
    end
  end
end
