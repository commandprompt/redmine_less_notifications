Redmine::Plugin.register :redmine_less_notifications do
  name 'Redmine Less Notifications Plugin'
  author 'Eugene dubinin, Command Prompt Inc.'
  description 'This plugin reduces the amount of issue update emails by notifying only the involved users'
  version '0.0.2'
  url 'https://github.com/commandprompt/redmine_less_notifications'
  author_url 'https://www.commandprompt.com'

  project_module :issue_tracking do
    permission :suppress_unrelated_notifications, :suppress_email => [:update, :destroy]
  end

  settings :default => {whitelisted_priority_ids:[]}, :partial => 'settings/redmine_less_notifications_settings'
end

prepare_block = Proc.new do
  Issue.send(:include, RedmineLessNotifications::IssuePatch)
end

if Rails.env.development?
  ((Rails.version > "5")? ActiveSupport::Reloader : ActionDispatch::Callbacks).to_prepare { prepare_block.call }
else
  prepare_block.call
end
