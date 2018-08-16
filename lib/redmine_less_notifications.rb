module RedmineLessNotifications
  def self.settings
    Setting[:plugin_redmine_less_notifications].blank? ? {} : Setting[:plugin_redmine_less_notifications]
  end
end