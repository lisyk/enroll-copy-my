module Importers::Transcripts

  module EnrollmentActions

    def add_terminated_on(termination_date)
      if termination_date > TimeKeeper.date_of_record
        @enrollment.schedule_coverage_termination! if @enrollment.may_schedule_coverage_termination?
      else
        @enrollment.terminate_coverage! if @enrollment.may_terminate_coverage?
      end

      @enrollment.update!({:terminated_on => termination_date})
    end    

    def add_plan(association)
      @plan ||= Plan.where(hios_id: association['hios_id'], active_year: association['active_year']).first
      @enrollment.update_attributes({ plan_id: @plan.id, carrier_profile_id: @plan.carrier_profile_id })
    end

    def add_hbx_enrollment_members(association)
      other_enrollment_member = @other_enrollment.hbx_enrollment_members.detect{|member| member.family_member.hbx_id == association['hbx_id']}
      matching_person = match_person_instance(other_enrollment_member.family_member.person).first

      family = @enrollment.family
      family_member = family.add_family_member(matching_person, is_primary_applicant: false)

      @enrollment.hbx_enrollment_members.build({
        applicant_id: family_member.id,
        is_subscriber: other_enrollment_member.is_subscriber,
        eligibility_date: other_enrollment_member.coverage_start_on,
        coverage_start_on: other_enrollment_member.coverage_start_on,
        coverage_end_on: other_enrollment_member.coverage_end_on
        })

      family.save!
    end

    def update_effective_on(value)
      @enrollment.update!({:effective_on => value})
    end

    def update_terminated_on(value)
      @enrollment.update!({:terminated_on => value})

      if value > TimeKeeper.date_of_record
        @enrollment.schedule_coverage_termination! if @enrollment.may_schedule_coverage_termination?
      else
        @enrollment.terminate_coverage! if @enrollment.may_terminate_coverage?
      end
    end

    def update_hbx_id(hbx_id)
      if HbxEnrollment.by_hbx_id(hbx_id).blank?
        @enrollment.update!({:hbx_id => hbx_id})
      else
        @updates[:update][:base]['hbx_id'] = ["Success", "Add EDI DB foreign key #{@enrollment.hbx_id}"]
      end
    end

    def update_applied_aptc_amount(value)
      @enrollment.update!({:applied_aptc_amount => value})
    end
 
    def remove_terminated_on(value)
      @enrollment.update!({:terminated_on => nil})
      @enrollment.update!({:aasm_state => 'coverage_selected'})

      @enrollment.hbx_enrollment_members.each do |member|
        member.update!({coverage_end_on: nil})
      end
    end

    def hbx_enrollment_members_hbx_id_remove(value)
      family = @enrollment.family

      hbx_enrollment = family.active_household.hbx_enrollments.build({
        kind: @enrollment.kind,
        elected_aptc_pct: @enrollment.elected_aptc_pct,
        applied_aptc_amount: @enrollment.applied_aptc_amount,
        coverage_kind: @enrollment.coverage_kind,
        effective_on: @other_enrollment.effective_on,
        terminated_on: @other_enrollment.terminated_on,
        submitted_at: TimeKeeper.datetime_of_record,
        created_at: TimeKeeper.datetime_of_record,
        updated_at: TimeKeeper.datetime_of_record
      })

      if @market == 'shop'
        hbx_enrollment.benefit_group_id = @enrollment.benefit_group_id
        hbx_enrollment.benefit_group_assignment_id = @enrollment.benefit_group_assignment_id
        hbx_enrollment.employee_role_id = @enrollment.employee_role_id
      else
        hbx_enrollment.consumer_role_id = @enrollment.consumer_role.id
      end

      hbx_enrollment.select_coverage
      @enrollment.hbx_enrollment_members.each do |member| 
        next if member.hbx_id == value['hbx_id']
        hbx_enrollment.hbx_enrollment_members.build(member.attributes.except('_id'))
      end

      hbx_enrollment.plan = @enrollment.plan
      hbx_enrollment.save!
      hbx_enrollment.reload

      hbx_enrollment.terminate_coverage! if @other_enrollment.terminated_on.present?
      @enrollment.invalidate_enrollment! if @enrollment.may_invalidate_enrollment?

      # TODO: cancel/terminated @enrollment
    end

    def process_enrollment_remove(attributes)
      if @enrollment.blank?
        subscriber = @other_enrollment.family.primary_applicant
        matched_people = match_person_instance(subscriber.person)
        matched_person = matched_people.first
        family= Family.find_all_by_person(matched_person).first
      else
        family = @enrollment.family
      end

      enrollments = attributes['hbx_id']
      enrollments.each do |enrollment_hash|        
        if enrollment = family.active_household.hbx_enrollments.where(:hbx_id => enrollment_hash['hbx_id']).first
          enrollment.invalidate_enrollment! if enrollment.may_invalidate_enrollment?

          # TODO: Fix messages...to display multiple rows in CSV
          @updates[:remove][:enrollment]['hbx_id'] = ["Success", "Enrollment canceled successfully"]
        end
      end
    end

    def csv_row
      @people_cache = {}
      @plan = nil

      plan_details = (@transcript[:plan_details].present? ? @transcript[:plan_details].values : 4.times.map{nil})
      person_details = [
        @transcript[:primary_details][:hbx_id],
        @transcript[:primary_details][:ssn], 
        @transcript[:primary_details][:last_name], 
        @transcript[:primary_details][:first_name]
      ]

      details = person_details + plan_details
      if @market == 'shop'
        employer_details = (@transcript[:employer_details].present? ? @transcript[:employer_details].values : 3.times.map{nil})
        details += employer_details     
      end

      results = @comparison_result.changeset_sections.reduce([]) do |section_rows, section|
        actions = @comparison_result.changeset_section_actions [section]
        section_rows += actions.reduce([]) do |rows, action|
          attributes = @comparison_result.changeset_content_at [section, action]

          fields_to_ignore = ['_id', 'updated_by']
          rows = []
          attributes.each do |attribute, value|
            if value.is_a?(Hash)
              fields_to_ignore.each{|key| value.delete(key) }
              value.each{|k, v| fields_to_ignore.each{|key| v.delete(key) } if v.is_a?(Hash) }
            end

            action_taken = (@updates[:update_failed].present? ? @updates[:update_failed] : @updates[action.to_sym][section][attribute])

            if value.is_a?(Array)
              value.each do |val|
                rows << ([@transcript[:identifier]] + details + [action, "#{section}:#{attribute}", val] + (action_taken || []))
              end
            else
              rows << ([@transcript[:identifier]] + details + [action, "#{section}:#{attribute}", value] + (action_taken || []))
            end   
          end
          rows
        end
      end

      if results.empty?
        ([[@transcript[:identifier]] + details + ['update']])
      else
        results
      end
    end
  end
end