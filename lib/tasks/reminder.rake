namespace :redmine do
  namespace :reminder_plugin do
    task :send_notifications => :environment do
      Mailer.with_synched_deliveries do
        ReminderMailer.due_date_notifications
      end
    end
    task :send_slack_notifications => :environment do
      SlackClient.new(Setting.plugin_due_date_reminder['slack_webhook_url']).send_due_date_notifications
    end
  end
end
