class RbStoryStatusUpdateRule

  attr_accessor :original_story_statuses
  attr_accessor :new_task_status
  attr_accessor :new_story_status
  attr_accessor :check_all_task

  def self.of(original_story_statuses, new_task_status, new_story_status, check_all_task = false)
    rule = RbStoryStatusUpdateRule.new
    rule.original_story_statuses = original_story_statuses
    rule.new_task_status = new_task_status
    rule.new_story_status = new_story_status
    rule.check_all_task = check_all_task
    rule
  end

  def self.rules_from_json(rules)
    rules = '[]' if rules.blank?

    JSON.parse(rules).map{|hash|
      rule = self.new
      rule.original_story_statuses = hash['original_story_statuses']
      rule.new_task_status = hash['new_task_status']
      rule.new_story_status = hash['new_story_status']
      rule.check_all_task = hash['check_all_task']
      rule
    }
  end

  def to_s
    "RbStoryStatusUpdateRule{original_story_statuses=#{original_story_statuses}, new_task_status=#{new_task_status}, new_story_status=#{new_story_status}, check_all_task=#{check_all_task}}"
  end
end
