Players = new Meteor.Collection 'players'
Logs = new Meteor.Collection 'logs'

reset_data = -> # Executes on both client and server.
  Players.remove {}
  Logs.remove {}
  names = [ 'Tyr',
            'Jason',
            'Xiao',
            'Chiyuan',
            'Xintao',
            'Hugh',
            'Kent',
            'Brian',
            'iduu'
          ]
  for name in names
    Players.insert
      name: name
      score: 0

if Meteor.is_client

  _.extend Template.navbar,
    events:
      'click .sort_by_name': -> Session.set 'sort_by_name', true
      'click .sort_by_score': -> Session.set 'sort_by_name', false
      'click .reset_data': -> reset_data()

  _.extend Template.leaderboard,
    players: ->
      sort = if Session.get('sort_by_name') then name: 1 else score: -1
      Players.find {}, sort: sort

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

    logs: ->
      sort = _id: -1
      name = Session.get('selected_name')
      query = {}
      if name
        query = name: name

      Logs.find query, sort: sort

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
        Players.update @_id, $inc: {score: -5}

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



# On server startup, create some players if the database is empty.
if Meteor.is_server
  Meteor.startup ->
    reset_data() if Players.find().count() is 0
