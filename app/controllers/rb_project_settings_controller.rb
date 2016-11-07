include RbCommonHelper
include ProjectsHelper

class RbProjectSettingsController < RbApplicationController
  unloadable

  def project_settings
    enabled = false
    enabled_scrum_stats = false
    default_story_tracker = nil
    if request.post? and params[:settings]
      enabled = true if params[:settings]["show_stories_from_subprojects"]=="enabled"
      enabled_scrum_stats = true if params[:settings]["show_in_scrum_stats"]=="enabled"
      default_story_tracker = params[:settings]["default_story_tracker"].to_i
    end
    settings = @project.rb_project_settings
    settings.show_stories_from_subprojects = enabled
    settings.show_in_scrum_stats = enabled_scrum_stats
    settings.default_story_tracker = default_story_tracker
    if settings.save
      flash[:notice] = t(:rb_project_settings_updated)
    else
      flash[:error] = t(:rb_project_settings_update_error)
    end
    redirect_to :controller => 'projects', :action => 'settings', :id => @project,
                :tab => 'backlogs'
  end

end
