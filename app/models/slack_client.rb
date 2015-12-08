class SlackClient
  include Redmine::I18n

  def initialize(webhook_url)
    @webhook_url = webhook_url
  end

  def send_due_date_notifications
    data = {}
    issues = ReminderMailer.find_issues
    issues.each { |issue| ReminderMailer.insert(data, issue) }
    data.each do |user, projects|
      send_due_date_notification(user, projects)
    end
  end

  def send_due_date_notification(user, projects)
    return if user.slack_username.blank?
    set_language_if_valid user.language
    issues_url = Rails.application.routes.url_for(:controller => 'issues', :action => 'index',
                          :set_filter => 1, :assigned_to_id => user.id,
                    			:host => Setting.host_name, :sort => 'due_date:asc')
    message = <<-MSG
#{ I18n.t(:reminder_mail_body) }:
#{ prepare_projects_messages(projects) }
<#{ issues_url }|#{I18n.t(:show_tasks_link)}>
    MSG
		params = {
			:text => message,
      :channel => user.slack_username, # it should be with @
      :mrkdwn => true
		}
		client = HTTPClient.new
		client.post @webhook_url, {:payload => params.to_json}
  end

  private

  def prepare_projects_messages(projects)
    projects_messages = projects.map do |project, issues|
      "*#{project.name}*\n#{prepare_issues_captions(issues)}"
    end
    projects_messages.join("\n")
  end

  def prepare_issues_captions(issues)
    captions = issues.map do |issue|
      name = "#{issue.tracker} ##{issue.id}: #{issue.subject}"
      if issue.overdue?
        caption = "\>`#{I18n.t(:reminder_days_overdue, :days => issue.days_before_due_date.abs)}` - #{name}"
      else
        caption = "\>#{name} (#{I18n.t(:field_due_date)}: `#{issue.due_date}`)"
      end
      caption
    end
    captions.join("\n")
  end

end
