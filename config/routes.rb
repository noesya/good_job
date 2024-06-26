# frozen_string_literal: true

GoodJob::Engine.routes.draw do
  root to: redirect(path: 'jobs')

  resources :jobs, only: %i[index show destroy] do
    collection do
      get :mass_update, to: redirect(path: 'jobs')
      put :mass_update
    end

    member do
      put :discard
      put :force_discard
      put :reschedule
      put :retry
    end
  end
  get 'jobs/metrics/primary_nav', to: 'metrics#primary_nav', as: :metrics_primary_nav
  get 'jobs/metrics/job_status', to: 'metrics#job_status', as: :metrics_job_status

  resources :batches, only: %i[index show]

  resources :cron_entries, only: %i[index show], param: :cron_key do
    member do
      post :enqueue
      put :enable
      put :disable
    end
  end

  resources :processes, only: %i[index]

  resources :performances, only: %i[index]

  scope :frontend, controller: :frontends do
    get "modules/:name", action: :module, as: :frontend_module, constraints: { format: 'js' }
    get "static/:name", action: :static, as: :frontend_static, constraints: { format: %w[css js] }
  end
end
