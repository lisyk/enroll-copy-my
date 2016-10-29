require 'rails_helper'

RSpec.describe Importers::Transcripts::EnrollmentTranscript, type: :model do

  describe "find_or_build_family" do

    let!(:spouse)  { FactoryGirl.create(:person)}
    let!(:child1)  { FactoryGirl.create(:person)}
    let!(:child2)  { FactoryGirl.create(:person)}

    let!(:person) do
      p = FactoryGirl.build(:person)
      p.person_relationships.build(relative: spouse, kind: "spouse")
      p.person_relationships.build(relative: child1, kind: "child")
      p.person_relationships.build(relative: child2, kind: "child")
      p.save
      p
    end

    context "Family already exists" do

      let(:source_effective_on) { Date.new(TimeKeeper.date_of_record.year, 1, 1) }
      let(:other_effective_on) { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
      let!(:other_plan) { FactoryGirl.create(:plan) }
      let!(:source_plan) { FactoryGirl.create(:plan) }

      let(:other_family) {
        family = Family.new({
          hbx_assigned_id: '24112',
          e_case_id: "6754632"
          })

        primary = family.family_members.build(is_primary_applicant: true, person: person)
        dependent1 = family.family_members.build(is_primary_applicant: true, person: spouse)
        family
      }

      let(:dependent2) {
        other_family.family_members.build(is_primary_applicant: false, person: child1)
      }

      let(:other_enrollment) {
        enrollment = other_family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: other_plan, effective_on: other_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: other_family.primary_applicant.id, is_subscriber: true, coverage_start_on: other_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: dependent2.id, is_subscriber: false, coverage_start_on: other_effective_on })
        enrollment
      }

      let!(:source_family) { 
        family = Family.new({ hbx_assigned_id: '25112', e_case_id: "6754632" })
        primary = family.family_members.build(is_primary_applicant: true, person: person)
        dependent = family.family_members.build(is_primary_applicant: false, person: spouse)

        consumer_role = person.build_consumer_role({is_applicant: true})
        consumer_role.save

        enrollment = family.active_household.hbx_enrollments.build({ hbx_id: '1000001', kind: 'individual',plan: source_plan, effective_on: source_effective_on, terminated_on: source_effective_on.end_of_month, consumer_role_id: consumer_role.id })
        enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })
        enrollment.hbx_enrollment_members.build({applicant_id: dependent.id, is_subscriber: false, coverage_start_on: source_effective_on, eligibility_date: source_effective_on })

        enrollment = family.active_household.hbx_enrollments.build({ hbx_id: '1000002', kind: 'individual',plan: source_plan, effective_on: (source_effective_on + 1.month), aasm_state: 'coverage_selected'})
        enrollment.hbx_enrollment_members.build({applicant_id: primary.id, is_subscriber: true, coverage_start_on: (source_effective_on + 1.month), eligibility_date: (source_effective_on + 1.month) })

        family.save
        family
      }

      def build_transcript
       factory = Transcripts::EnrollmentTranscript.new
       factory.find_or_build(other_enrollment)
       factory.transcript
      end

      context "and enrollment member missing & plan hios is different" do

        it 'should have differences on hbx enrollment member and plan' do
          transcript = build_transcript

          importer = Importers::Transcripts::EnrollmentTranscript.new
          importer.transcript = transcript
          importer.process
        end
      end

    end
  end
end

