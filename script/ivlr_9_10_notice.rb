# rails runner script/ivlr_9_10_notice.rb <file_name> <event_name>
# rails runner script/ivlr_9_10_notice.rb 'test_notice_10.csv' 'ivl_renewal_notice_9'
  begin
    file = ARGV[0]
    NOTICE_GENERATOR = ARGV[1]
    csv_a = CSV.open(file,"r",:headers =>true)
    # @data= csv.to_a
  rescue Exception => e
    puts "Unable to open file #{e}"
  end
  field_names  = %w(
          family_id
          hbx_id
        )
  file_name = "#{Rails.root}/public/ivl_renewal_notice_1_report.csv"

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names

    case NOTICE_GENERATOR
    when 'ivl_renewal_notice_9'
      event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_9').first
    when 'ivl_renewal_notice_10'
      event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_10').first
    end

    notice_trigger = event_kind.notice_triggers.first
    csv_a.each do |d|
      begin
      enrollment_group_ids = []
      person = Person.where(:hbx_id => d["person.authority_member_id"]).first
      enrollment_group_ids << d["health_policy.eg_id"]
      enrollment_group_ids << d["dental_policy.eg_id"]
      consumer_role =person.consumer_role
      if consumer_role.present?
        builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
            template: notice_trigger.notice_template,
            subject: event_kind.title,
            mpi_indicator: notice_trigger.mpi_indicator,
            enrollment_group_ids: enrollment_group_ids,
            data: d,
            }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
            )
        builder.deliver
        csv << [
          nil,
          person.hbx_id
        ]
      else
        puts "No consumer role present for person.hbx_id : #{person.hbx_id}"
      end
      rescue Exception => e
        puts "Unable to deliver to #{person.hbx_id} for the following error #{e.backtrace}"
        next
      end
    end
  end
