/**************************************
  STORY
***************************************/
RB.Story = RB.Object.create(RB.Issue, RB.EditableInplace, {
  initialize: function(el){
    var j;  // This ensures that we use a local 'j' variable, not a global one.
    var self = this;
    
    this.$ = j = RB.$(el);
    this.el = el;
    
    // Associate this object with the element for later retrieval
    j.data('this', this);

    if (RB.permissions.update_stories) {
      j.delegate('.editable', 'click', this.handleClick);
    }
  },

  afterUpdate: function(data, textStatus, xhr){
    this.$.parents('.backlog').data('this').recalcVelocity();
    this.$.parents('.backlog').data('this').drawMenu();
  },

  afterCreate: function(data, textStatus, xhr){
    this.$.parents('.backlog').data('this').recalcVelocity();
    this.$.parents('.backlog').data('this').drawMenu();
  },

  beforeSave: function(){
    // Do nothing
  },
  
  editDialogTitle: function(){
    return "Story #" + this.getID();
  },

  editorDisplayed: function(editor){
    var tracker = editor.find('.tracker_id.editor');
    var status = editor.find('.status_id.editor');
    var self = this;

    this.setAllowedStatuses(tracker, status);
    tracker.change(function() { self.setAllowedStatuses(tracker, status); });

    var fields = {};
    editor.children('[fieldgroupid]').each(function(){
      var field = RB.$(this);
      var groupId = field.attr('fieldgroupid') || null;
      var group = fields[groupId] || (fields[groupId] = {});
      var positionInGroup = field.attr('positioninfieldgroup') || null;
      if (positionInGroup) { positionInGroup = +positionInGroup; }
      group[positionInGroup] = RB.$(this);
    });

    var lastContainer;
    Object.keys(fields).sort().forEach(function(groupId){
      // create group containers and prepend them to editor in group id's natural order
      var groupContainer = RB.$(document.createElement("div")).addClass('fieldgroup').addClass(groupId);
      if (lastContainer == undefined) {
        editor.prepend(groupContainer);
        lastContainer = groupContainer;
      } else {
        groupContainer.insertAfter(lastContainer);
        lastContainer = groupContainer;
      }

      // move fields with group id into their group containers in positioninfieldgroup' numerical order
      Object.keys(fields[groupId])
        .sort(function(pos1, pos2){
          if (!pos1) { return -1; }
          if (!pos2) { return 1; }
          var intPos1 = parseInt(pos1, 10);
          var intPos2 = parseInt(pos2, 10);
          return intPos1 - intPos2;
        }).forEach(function(position){
          lastContainer.append(fields[groupId][position]);
        });
    });

    var name = editor.find('.name.editor');
    name.width(parseInt(name.attr('_rb_width'),10) - 10);
  },

  setAllowedStatuses: function(tracker, status) {
    var isNew = tracker.closest('li.story').attr('id') == undefined;
    var tracker_id = tracker.val();
    var user_status = this.$.find(".user_status").text();
    var status_id = status.val();

    // right after creation, no menu exists to pick from
    if (!status_id) { status_id = RB.constants.story_states['default']; }

    var states;
    if (isNew) {
      states = RB.constants.story_states['initial_statuses'][tracker_id];
    } else {
      states = RB.constants.story_states['transitions'][tracker_id][user_status][status_id];
      if (!states) {
        states = RB.constants.story_states['transitions'][tracker_id][user_status][RB.constants.story_states['transitions'][tracker_id][user_status]['default']];
      }
    }

    if (RB.$.inArray(status_id, states) == -1) { // a non-available state is currently selected, tracker has changed
      status_id = null;

      if (this.$.find('.tracker_id .v').text() == tracker_id) { // if we're switching back to the original tracker, select the original state
        status_id = this.$.find('.status_id .v').text();
      } else { // pick first available
        if (states.length > 0) {
          status_id = states[0];
        }
      }
    }

    status.empty();
    for (var i = 0; i < states.length; i++) {
      option = RB.$('<option/>');
      state = RB.constants.story_states['states'][states[i]];
      option.attr('value', states[i]).addClass(state.closed).text(state.name);
      if (states[i] == status_id) { option.attr('selected', 'selected'); }
      status.append(option);
    }
  },
  
  getPoints: function(){
    points = parseFloat( this.$.find('.story_points').first().text() );
    return ( isNaN(points) ? 0 : points );
  },

  getTracker: function(){
	return this.$.find('.tracker_id .t').text();
  },

  getType: function(){
    return "Story";
  },

  markIfClosed: function(){
    // Do nothing
  },
  
  newDialogTitle: function(){
    return "New Story";
  },

  saveDirectives: function(){
    var url;
    var j = this.$;
    var nxt = this.$.next();
    var sprint_id = this.$.parents('.backlog').data('this').isSprintBacklog() ? 
                    this.$.parents('.backlog').data('this').getSprint().data('this').getID() : '';
    var release_id = this.$.parents('.backlog').data('this').isReleaseBacklog() ? 
                    this.$.parents('.backlog').data('this').getRelease().data('this').getID() : '';
    var data = "next=" + (nxt.length==1 ? this.$.next().data('this').getID() : '') +
               "&fixed_version_id=" + sprint_id;
    if (release_id || !sprint_id) { /* when not sprint_id, issue goes to backlog, so remove release */
      data += "&release_id=" + release_id;
    }
    
    j.find('.editor').each(function() {
        var value = RB.$(this).val();  
        data += "&" + this.name + '=' + encodeURIComponent(value);
    });    
    
    if( this.isNew() ){
      url = RB.urlFor( 'create_story' );
    } else {
      url = RB.urlFor( 'update_story', { id: this.getID() } );
      data += "&_method=put";
    }
    
    return {
      url: url,
      data: data
    };
  }

});

