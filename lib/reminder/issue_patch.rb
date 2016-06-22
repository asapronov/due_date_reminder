module Reminder
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.after_create :send_slack_notification
      base.after_update :send_manager_slack_notification_about_accepted_task, if: :issue_accepted?
      base.after_update :send_manager_slack_notification_about_completed_task, if: :issue_completed?
    end
  end

  module InstanceMethods
    def days_before_due_date
      (due_date - Date.today).to_i
    end

    def remind?
      if !assigned_to.nil? and assigned_to.is_a?(User)
          return assigned_to.reminder_notification_array.include?(days_before_due_date)
      end
      false
    end

    private

    def send_slack_notification
      SlackClient.new(Setting.plugin_due_date_reminder['slack_webhook_url']).send_issue_added_notification(self)
    end

    def issue_accepted?
      status.name == 'Принята'
    end

    def issue_completed?
      status.name == 'Завершена'
    end

    def send_manager_slack_notification_about_accepted_task
      SlackClient.new(Setting.plugin_due_date_reminder['slack_webhook_url']).send_issue_accepted_notification(self)
    end

    def send_manager_slack_notification_about_completed_task
      SlackClient.new(Setting.plugin_due_date_reminder['slack_webhook_url']).send_issue_completed_notification(self)
    end

  end
end
