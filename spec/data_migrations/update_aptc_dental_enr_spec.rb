require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_aptc_dental_enr")


describe UpdateAptcDentalEnr do
  let(:given_task_name) { "update_aptc_dental_enr" }
  subject { UpdateAptcDentalEnr.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating the applied aptc amount for a Dental Plan" do
    let(:person) { FactoryGirl.create(:person, :with_family, hbx_id: "1234567890") }
    let(:family) { person.primary_family }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :coverage_kind => "dental", applied_aptc_amount: 100.00, hbx_id: "0987654321", household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("1234567890")
      allow(ENV).to receive(:[]).with("enr_hbx_id").and_return("0987654321")
    end

    it "should update aptc amount only for dental plan" do
      expect(family.active_household.hbx_enrollments).to include hbx_enrollment
      expect(hbx_enrollment.applied_aptc_amount.to_f).to eq 100.00
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.applied_aptc_amount.to_f).to eq 0.00
    end
  end

  describe "should not update for a Health Plan" do
    let(:person) { FactoryGirl.create(:person, :with_family, hbx_id: "1234567000") }
    let(:family) { person.primary_family }
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :coverage_kind => "health", applied_aptc_amount: 100.00, hbx_id: "09876543210", household: family.active_household)}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("1234567000")
      allow(ENV).to receive(:[]).with("enr_hbx_id").and_return("09876543210")
    end

    it "should not update aptc amount if it is a health plan" do
      expect(hbx_enrollment.applied_aptc_amount.to_f).to eq 100.00
      subject.migrate
      hbx_enrollment.reload
      expect(hbx_enrollment.applied_aptc_amount.to_f).not_to eq 0.00
    end
  end
end
