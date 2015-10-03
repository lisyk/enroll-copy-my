class Exchanges::AgentsController < ApplicationController
  before_action :check_agent_role
  def home
     
     @title = current_user.agent_title
     @assister = current_user.has_assister_role?
     person_id = session[:person_id]
     if person_id && person_id != ''
       @person = Person.find(person_id)
       root = 'http://' + request.env["HTTP_HOST"]+'/exchanges/agents/resume_enrollment?person_id=' + person_id
       hbx_profile = HbxProfile.find_by_state_abbreviation('DC')
       message_params = {
         sender_id: hbx_profile.id,
         parent_message_id: hbx_profile.id,
         from: 'Plan Shopping Web Portal',
         to: "Agent Mailbox",
         subject: "Account link for  #{@person.full_name}. ",
         body: "<a href='" + root+"'>Link to access #{@person.full_name}</a>  <br>",
       }
       create_secure_message message_params, current_user.person, :inbox
     else
     	@person=nil
     end
     session[:person_id] = nil
     render 'home'
  end

  def begin_employee_enrollment
    session[:person_id] = nil
    session[:original_application_type] = params['original_application_type'] unless session[:original_application_type]
    redirect_to search_insured_employee_index_path
  end

  def begin_consumer_enrollment
    session[:person_id] = nil
    session[:original_application_type] = params['original_application_type'] unless session[:original_application_type]
    redirect_to search_insured_consumer_role_index_path
  end

  def resume_enrollment
    session[:person_id] = params[:person_id]
    session[:original_application_type] = params['original_application_type']
    person = Person.find(params[:person_id])
    consumer_role = person.consumer_role
    employee_role = person.employee_roles.last

    if consumer_role && consumer_role.bookmark_url
      redirect_to consumer_role.bookmark_url
    elsif employee_role && employee_role.bookmark_url
      redirect_to employee_role.bookmark_url
    else
      redirect_to family_account_path
    end
  end

  def inbox
    @inbox_provider = current_user.person
    @profile=@inbox_provider
    @folder = params[:folder] || 'inbox'
    @sent_box = false  
  end

  def show
  end

  def check_agent_role
    unless current_user.has_agent_role?
      redirect_to root_path, :flash => { :error => "You must be an Agent:  CSR, CAC, or IPA" }
    end
  end

end



