module RbServerVariablesHelper
  unloadable

  # Calculates workflow transitions matrix.
  # Used to render server variables for javascript DnD handling
  #
  #   workflow_transitions(RbStory)
  def workflow_transitions(klass)
     roles = User.current.admin ? Role.all : User.current.roles_for_project(@project)
     transitions = {:states => {}, :transitions => {} , :default => 1, :initial_statuses => {}}
     transitions[:initial_statuses] = initial_statuses(klass, roles)

     klass.trackers.each {|tracker_id|
      tracker = Tracker.find(tracker_id)
      tracker_id = tracker_id.to_s

      default_status = tracker.default_status
      transitions[:default] = default_status if default_status
      transitions[:transitions][tracker_id] = {}

      tracker.issue_statuses.each {|status|
        status_id = status.id.to_s

        transitions[:states][status_id] = {:name => status.name, :closed => (status.is_closed? ? l(:label_closed_issues) + ' ' : '')}

        [[false, false], [true, true], [false, true], [true, false]].each{|creator, assignee|
          key = "#{creator ? '+' : '-'}c#{assignee ? '+' : '-'}a"

          transitions[:transitions][tracker_id][key] ||= {}

          begin
            allowed_statues = status.new_statuses_allowed_to(roles, tracker, creator, assignee)
          rescue #Workaround in order to support redmine 1.1.3
            allowed_statues = status.new_statuses_allowed_to(roles, tracker)
          end

          allowed = allowed_statues.collect{|s| s.id.to_s}

          transitions[:transitions][tracker_id][key][:default] ||= allowed[0]

          allowed.unshift(status_id)

          transitions[:transitions][tracker_id][key][status_id] = allowed.compact.uniq
        }
      }
     }
     transitions
   end

  private

  def initial_statuses(klass, roles)
    initial_statuses = {}
    WorkflowTransition.
      where(
        :old_status_id => 0,
        :role_id => roles.map(&:id),
        :tracker_id => klass.trackers,
        :author => false,
        :assignee => false
      ).
      order(
        :tracker_id => :asc,
        :new_status_id => :asc).
      pluck(:tracker_id, :new_status_id).
      uniq.
      each do |tracker_to_status|
        tracker_id = tracker_to_status[0]
        initial_statuses[tracker_id] = [] unless initial_statuses[tracker_id]
        tracker_statuses = initial_statuses[tracker_id]
        tracker_statuses << tracker_to_status[1]
      end
    initial_statuses
  end

end
