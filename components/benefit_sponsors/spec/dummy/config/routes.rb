Rails.application.routes.draw do
  mount BenefitSponsors::Engine => "/benefit_sponsors"
  mount SponsoredBenefits::Engine,      at: "/sponsored_benefits"

  devise_for :users

  root "welcome#index"
  get "document/download/:bucket/:key" => "documents#download", as: :document_download

  namespace :employers do

    resources :employer_profiles do
      get 'export_census_employees'
      resources :census_employees, only: [:new, :create, :edit, :update, :show] do
      end
    end
  end
end
