# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Services::IvlEnrollmentService, type: :model, :dbclean => :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person, e_case_id: nil)}
  let!(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, household: family.households.first, kind: "individual", is_any_enrollment_member_outstanding: true, aasm_state: "coverage_selected", applied_aptc_amount: 0.0)}
  let!(:hbx_enrollment_member) {FactoryBot.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month)}

  subject do
    Services::IvlEnrollmentService.new
  end

  context "send_reminder_notices_for_ivl" do

    it 'should trigger first reminder notice for unassisted families after 10 days of ENR notice' do
      person.verification_types.each{|type| type.fail_type && type.update_attributes(due_date: TimeKeeper.date_of_record + 85.days)}
      family.update_attributes(min_verification_due_date: TimeKeeper.date_of_record + 85.days)
      person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
      hbx_enrollment.save!
      expect(IvlNoticesNotifierJob).to receive(:perform_later)
      subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
    end

    it 'should not trigger first reminder notice for unassisted families before 10 days of ENR notice' do
      person.verification_types.each{|type| type.fail_type && type.update_attributes(due_date: TimeKeeper.date_of_record + 88.days)}
      family.update_attributes(min_verification_due_date: TimeKeeper.date_of_record + 88.days)
      person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
      hbx_enrollment.save!
      expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
      subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
    end

    it 'should not trigger reminder notice for unassisted families from curam' do
      family.update_attributes!(:e_case_id => "someecaseid")
      person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
      hbx_enrollment.save!
      expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
      subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
    end

    it 'should not trigger reminder notice for unassisted families with verified consumers' do
      person.consumer_role.update_attributes!(aasm_state: "fully_verified")
      hbx_enrollment.save!
      expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
      subject.send_reminder_notices_for_ivl(TimeKeeper.date_of_record)
    end
  end

  context ".begin_coverage_for_ivl_enrollments" do
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let!(:renewing_selected_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        effective_on: Date.new(TimeKeeper.date_of_record.year, 1, 1),
                        household: family.households.first,
                        kind: "individual",
                        is_any_enrollment_member_outstanding: true,
                        aasm_state: "renewing_coverage_selected",
                        applied_aptc_amount: 0.0)
    end

    it "should picks up the renewing_coverage_selected enrollment" do
      subject.begin_coverage_for_ivl_enrollments
      expect(renewing_selected_enrollment.reload.aasm_state).to eq "coverage_selected"
      expect(renewing_selected_enrollment.workflow_state_transitions.first.event).to eq "begin_coverage!"
    end
  end
end
