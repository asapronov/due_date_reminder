class SlackClient
  include Redmine::I18n

  def initialize(webhook_url)
    @webhook_url = webhook_url
    @client = HTTPClient.new
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
		send_to_slack(
          text: message,
          channel: user.slack_username, # it should be with @
          mrkdwn: true
        )
  end

  def send_issue_added_notification(issue)
    user = issue.assigned_to
    return if user.slack_username.blank?
    set_language_if_valid user.language
    issue_url = Rails.application.routes.url_for(:controller => 'issues', :action => 'show',
                          :id => issue.id,
                    			:host => Setting.host_name)
    message = <<-MSG
#{ I18n.t(:text_issue_added, :id => "##{issue.id}", :author => issue.author) }
#{I18n.t(:field_due_date)}: `#{issue.due_date}`. <#{ issue_url }|#{I18n.t(:button_submit)}>
    MSG
		send_to_slack(
          text: message,
          channel: user.slack_username, # it should be with @
          mrkdwn: true
        )
  end

  def send_issue_accepted_notification(issue)
    user = issue.author
    return if user.slack_username.blank?
    set_language_if_valid user.language
    issue_url = Rails.application.routes.url_for(:controller => 'issues', :action => 'show',
                          :id => issue.id,
                    			:host => Setting.host_name)
    message = <<-MSG
#{ I18n.t(:text_issue_accepted, :id => "##{issue.id}", :assigned_to => issue.assigned_to) }
#{I18n.t(:field_due_date)}: `#{issue.due_date}`. <#{ issue_url }|#{I18n.t(:button_view)}>
    MSG
		send_to_slack(
          text: message,
          channel: user.slack_username, # it should be with @
          mrkdwn: true
        )
  end

  private

  def send_to_slack(params)
    @client.post @webhook_url, {:payload => params.to_json}
  end

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
