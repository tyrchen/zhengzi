Players = new Meteor.Collection 'players'
Logs = new Meteor.Collection 'logs'
Comments = new Meteor.Collection 'comments'

reset_data = -> # Executes on both client and server.
  Players.remove {}
  Logs.remove {}
  Comments.remove {}
  Session.set 'username', ''

  names = [
    {name: 'Tyr', score: 2, icescream: 1},
    {name: 'Jason', score: 10, icescream: 0},
    {name: 'Xiao', score: 9, icescream: 0},
    {name: 'Chiyuan', score: 3, icescream: 1},
    {name: 'Xintao', score: 2, icescream: 0},
    {name: 'Hugh', score: 2, icescream: 0},
    {name: 'Kent', score: 3, icescream: 0},
    {name: 'Brian', score: 2, icescream: 0},
    {name: 'Iduu', score: 1, icescream: 0}
  ]
  logs = [
    {name: 'Xiao', text: '欧铁页面有问题', created: new Date()},
    {name: 'Xiao', text: '欧铁页面影响到原APP页面', created: new Date()},
  ]
  for item in names
    Players.insert
      name: item.name
      score: item.score
      icescream: item.icescream

  for item in logs
    Logs.insert
      name: item.name
      text: item.text
      created: item.created

if Meteor.is_client

  _.extend Template.navbar,
    events:
      'click .sort_by_name': -> Session.set 'sort', 0
      'click .sort_by_score': -> Session.set 'sort', 1
      'click .sort_by_icescream': -> Session.set 'sort', 2
      'click .reset_data': -> reset_data()

  _.extend Template.leaderboard,
    players: ->
      switch Session.get('sort')
        when 0 then sort = name: 1
        when 1 then sort = score: -1
        when 2 then sort = icescream: -1

      Players.find {}, sort: sort

    logs: ->
      sort = created: -1
      name = Session.get('selected_name')
      query = {}
      if name
        query = name: name

      Logs.find query, sort: sort

    comments: ->
      sort = created: -1
      Comments.find {}, sort: sort

    username: ->
      Session.get 'username'

    events:
      'click #add_button, keyup #player_name': (evt) ->
        return if evt.type is 'keyup' and evt.which isnt 13 # Key is not Enter.
        input = $('#player_name')
        if input.val()
          Players.insert
            name: input.val()
            score: 0
          input.val ''

      'click .view-all-log': ->
        Session.set('selected_name', '')

      'click #add_comment_button, keyup #comment': (evt) ->
        return if evt.type is 'keyup' and evt.which isnt 13 # Key is not Enter.
        input = $('#comment')
        if input.val()
          Comments.insert
            name: Session.get 'username'
            comment: input.val()
            created: new Date()
          input.val ''



  _.extend Template.player,
    events:
      'click .increment': ->
        $('#' + @name).modal()

      'click .log-increment': ->
        text = $('#' + @name + ' textarea')
        return if not text.val()
        Logs.insert
          name: @name
          text: text.val()
          created: new Date
        text.val ''
        Players.update @_id, $inc: {score: 1}
        $('#' + @name).modal('hide')

      'click .log-cancel': ->
        $('#' + @name).modal('hide')

      'click .icescream': ->
        if @score < 5
          return alert '别着急，你还没到兑现雪糕的时候'
        Logs.insert
          name: @name
          text: '兑现了雪糕，心里酸酸的'
          created: new Date
        Players.update @_id, $inc: {score: -5, icescream: 1}

      'click tr': ->
        Session.set('selected_name', @name)

      'click': -> $('.tooltip').remove()  # To prevent zombie tooltips.

    enable_tooltips: ->
      # Update tooltips after the template has rendered.
      _.defer -> $('[rel=tooltip]').tooltip()
      ''

  _.extend Template.log,
    formatted_time: ->
      moment(@created).fromNow()

  _.extend Template.comment,
   formatted_time: ->
     moment(@created).fromNow()



# On server startup, create some players if the database is empty.
if Meteor.is_server
  Meteor.startup ->
    reset_data() if Players.find().count() is 0

if Meteor.is_client
  Meteor.startup ->
    if not Session.get 'username'
      name = prompt "请输入你的名字（用于发表评论）"
      Session.set 'username', name || '匿名傻孩子'