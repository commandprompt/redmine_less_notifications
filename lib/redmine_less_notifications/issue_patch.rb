module RedmineLessNotifications
  def settings
    Setting[:plugin_redmine_less_notifications].blank? ? {} : Setting[:plugin_redmine_less_notifications]
  end

  module IssuePatch
    unloadable

    def self.included(base)
      base.class_eval do
        alias_method_chain :notified_users, :remove_uninvolved
      end
    end

    def whitelisted?
      whitelisted_priority_ids = RedmineLessNotifications.settings['whitelisted_priority_ids'].to_a
      whitelisted_priority_ids.include? self.priority_id.to_s
    end

    def previous_assignees
      previous_assignee_ids = JournalDetail.where(journal: journals).where(prop_key: :assigned_to_id).pluck(:value).uniq
      Principal.where(id: previous_assignee_ids)
    end

    def notified_users_with_remove_uninvolved
      notified_users_without_remove_uninvolved.tap do |users|
        # dont filter reciepients and forcefully add those who muted their notifications if the issue has whitelisted priority
        if whitelisted?
          users += project.members.preload(:principal).select {|m| m.principal.present? && m.mail_notification != 'none'}.collect {|m| m.principal}
          users.uniq!
        else
          involved = []

          involved << author if author

          if assigned_to
            involved += (assigned_to.is_a?(Group) ? assigned_to.users : [assigned_to])
          end

          previous_assignees.each do |prev|
            involved += (prev.is_a?(Group) ? prev.users : [prev])
          end

          #issue watchers also should be notified
          involved += User.find(watcher_user_ids)

          # cleanup the recipients list if issue does not have whitelisted priority
          users.reject! do |user|
            #user can have no permissions at all in some cases, thus the guard initialization
            user_permissions = user.roles_for_project(project).collect{|r| r.permissions}.flatten! || []
            rejectable = (user_permissions.include? :suppress_unrelated_notifications) && (involved.exclude? user)
            logger.info "LessNotifications: removing uninvolved recipient from issue #{self.id} email notification: #{user.login}" if rejectable
            rejectable
          end
        end
      end
    end
  end
end
