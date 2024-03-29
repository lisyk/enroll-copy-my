# frozen_string_literal: true

require 'rake'

describe 'load_rate_reference:update_rating_areas' do
  before :all do
    DatabaseCleaner.clean

    Rake.application.rake_require "tasks/migrations/plans/load_rating_areas"
    Rake::Task.define_task(:environment)

    if Settings.aca.state_abbreviation.downcase == 'ma'
      glob_pattern = File.join(Rails.root, "db/seedfiles/cca/locations_seed.rb")
      load glob_pattern
      load_cca_locations_county_zips_seed
    else
      create(:benefit_markets_locations_county_zip, county_name: Settings.aca.state_name)
    end
  end

  let :run_rake_task do
    Rake::Task["load_rate_reference:update_rating_areas"].reenable
    Rake.application.invoke_task("load_rate_reference:update_rating_areas[#{Rails.root}/spec/test_data/plan_data/rating_areas/#{Settings.aca.state_abbreviation.downcase}/2019/SHOP_ZipCode_CY2019_FINAL.xlsx]")
  end

  describe "test rake task" do

    it "should be empty before running rake" do
      expect(RatingArea.all.count).to eq 0
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 0
    end

    it "should be not be empty after running rake" do
      run_rake_task
      expect(RatingArea.all.count).to eq 1
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 1
    end

    it "should not create multiple records when ran multiple times" do
      run_rake_task
      expect(RatingArea.all.count).to eq 1
      expect(BenefitMarkets::Locations::RatingArea.all.count).to eq 1
    end

    context "match attributes for old model" do
      subject { RatingArea.first }
      it { is_expected.to have_attributes(zip_code: RatingArea.first.zip_code) }
      it { is_expected.to have_attributes(county_name: RatingArea.first.county_name) }
      it { is_expected.to have_attributes(zip_code_in_multiple_counties: false) }
      it { is_expected.to have_attributes(rating_area: RatingArea.first.rating_area) }
    end

    context "match attributes for new model" do
      subject { BenefitMarkets::Locations::RatingArea.first }
      it { is_expected.to have_attributes(exchange_provided_code: BenefitMarkets::Locations::RatingArea.first.exchange_provided_code) }
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end
end
