module Reminder
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.after_create :send_slack_notification
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
      # if Setting.notified_events.include?('issue_added')
        # Mailer.deliver_issue_add(self)
        SlackClient.new(Setting.plugin_due_date_reminder['slack_webhook_url']).send_issue_added_notification(self)
      # end
    end

  end
end
