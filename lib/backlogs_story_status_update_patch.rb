require_dependency 'issue'

module Backlogs

  module StoryStatusUpdatePatch

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        after_save :update_parent_story_status_by_rules
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def update_parent_story_status_by_rules
        Rails.logger.debug("*** OnSave #{self}")

        parent = self.parent

        return if parent.nil?
        return unless self.is_task?
        return unless parent.is_story?
        return unless Backlogs.configured?(project)
        return unless Backlogs.setting[:story_follow_task_status] == 'nil' # to prevent conflict between backlog's status follow feature and this one
        return unless User.current.allowed_to?(:update_stories, parent.project)

        rules = Backlogs.setting[:story_status_update_rules]
        rules = RbStoryStatusUpdateRule.rules_from_json(rules)

        first_matching_rule = rules.
            select{|rule| rule.new_task_status == self.status.id}.
            select{|rule| rule.original_story_statuses.include? parent.status.id}.
            select{|rule| !rule.check_all_task || parent.children.all?{|child| rule.new_task_status == child.status.id}}.
            first

        Rails.logger.debug("*** Matching story status update rule: #{first_matching_rule}")

        if first_matching_rule
          new_story_status_id = first_matching_rule.new_story_status
          allowed_new_status_ids = parent.new_statuses_allowed_to().map{|s| s.id}

          Rails.logger.debug("*** Allowed new statuses for story: #{allowed_new_status_ids}")

          return unless allowed_new_status_ids.include?(new_story_status_id)

          Rails.logger.debug("*** Updating #{parent.id}'s status from #{parent.status.id} to #{new_story_status_id}")
          parent.journalized_update_attribute(:status_id, new_story_status_id)
        end
      end
    end
  end
end

Issue.send(:include, Backlogs::StoryStatusUpdatePatch) unless Issue.included_modules.include?(Backlogs::StoryStatusUpdatePatch)
