class AddDefaultStoryTrackerToProjectSettings < ActiveRecord::Migration
  def self.up
    add_column :rb_project_settings, :default_story_tracker, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :rb_project_settings, :default_story_tracker
  end
end
