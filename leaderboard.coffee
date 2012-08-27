Players = new Meteor.Collection 'players'
Logs = new Meteor.Collection 'logs'
Comments = new Meteor.Collection 'comments'
spinner = null

reset_data = -> # Executes on both client and server.
  Players.remove {}
  Logs.remove {}
  Comments.remove {}
  Session.set 'username', ''

  names = [
    {name: 'Tyr', score: 2, icescream: 1, group: '开发'},
    {name: 'Jason', score: 10, icescream: 0, group: '开发'},
    {name: 'Xiao', score: 9, icescream: 0, group: '开发'},
    {name: 'Chiyuan', score: 3, icescream: 1, group: '开发'},
    {name: 'Xintao', score: 2, icescream: 0, group: '开发'},
    {name: 'Hugh', score: 1, icescream: 0, group: '开发'},
    {name: 'Kent', score: 3, icescream: 0, group: '开发'},
    {name: 'Brian', score: 2, icescream: 0, group: '开发'},
    {name: 'Iduu', score: 1, icescream: 0, group: '开发'}
  ]
  logs = [
    {name: 'Xiao', text: '欧铁页面有问题', created: new Date('2012-8-24 19:00')},
    {name: 'Xiao', text: '欧铁页面影响到原APP页面', created: new Date('2012-8-24 19:30')},
    {name: 'Kent', text: '打赌投篮输给Tyr', created: new Date('2012-8-22')},
    {name: 'Iduu', text: '在灭零行动中主动申请一笔', created: new Date('2012-8-24')},
    {name: 'Jason', text: '佗佗很生气，后果很严重', created: new Date('2012-8-24')},
    {name: 'Tyr', text: '不小心把水洒在地毯上被Brian鄙视', created: new Date('2012-8-23')},
    {name: 'Hugh', text: '冰箱门没关严??', created: new Date('2012-8-20')},
    {name: 'Brian', text: '碰坏楼上的网络', created: new Date('2012-8-14')},
    {name: 'Chiyuan', text: '和Tyr打赌代码质量，结果输了', created: new Date('2012-8-23')},
    {name: 'Xintao', text: '欧铁APP出现一大堆小问题', created: new Date('2012-8-23')}

  ]
  for item in names
    Players.insert
      name: item.name
      score: item.score
      icescream: item.icescream
      group: item.group

  for item in logs
    Logs.insert
      name: item.name
      text: item.text
      created: item.created

init_group = ->
  Players.update group: null, $set: group: '开发'

if Meteor.is_client

  _.extend Template.navbar,
    events:
      'click .sort_by_name': -> Session.set 'sort', 0
      'click .sort_by_score': -> Session.set 'sort', 1
      'click .sort_by_icescream': -> Session.set 'sort', 2
      'click .reset_data': -> reset_data()

  _.extend Template.leaderboard,
    onReady: ->
      Meteor.defer ->
        #delay = (ms, func) -> Meteor.setTimeout func, ms
        #delay 4000, ->
        spinner.stop()
        if not Session.get 'username'
          name = prompt "请输入你的名字（用于发表评论）"
          Session.set 'username', name || '匿名傻孩子'

    players: ->
      switch Session.get('sort')
        when 0 then sort = name: 1
        when 1 then sort = score: -1
        when 2 then sort = icescream: -1

      query = group: Session.get('selected_group') || '开发'

      Players.find query, sort: sort

    logs: ->
      sort = created: -1
      name = Session.get 'selected_name'
      query = {}
      if name
        query = name: name

      Logs.find query, sort: sort

    comments: ->
      sort = created: -1
      Comments.find {}, sort: sort

    username: ->
      Session.get 'username'

    group: ->
      Session.get('selected_group') || '开发'

    events:
      'click #add_button, keyup #player_name': (evt) ->
        return if evt.type is 'keyup' and evt.which isnt 13 # Key is not Enter.
        input = $('#player_name')
        group = Session.get('selected_group') || '开发'
        if input.val()
          Players.insert
            name: input.val()
            score: 0
            icescream: 0
            group: group

          Logs.insert
            name: input.val()
            text: '欢迎新童鞋进入正字地狱，我们的宗旨是：没有最差，只有更差；来了你就别想走'
            created: new Date()

          input.val ''

      'click #player-group .btn': (evt) ->
        # TODO: meteor breaks bootstrap js from being toggled
        Meteor.setTimeout (-> Session.set 'selected_group', $(evt.target).data('name')), 200



      'click .view-all-log': ->
        Session.set 'selected_name', ''

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
    last_log: ->
      log = Logs.find {name: @name}, sort: {created: -1}
      return log.fetch()[0]?.text

    events:
      'click .increment': ->
        $('#' + @name).modal()
      'click .decrement': ->
        Logs.insert
          name: @name
          text: '管理员对上一笔正字很不满意，故而减之'
          created: new Date()
        Players.update @_id, $inc: {score:-1}

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

      'click .buy-icescream': ->
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
    init_group() if Players.find({group: null}).count isnt 0

if Meteor.is_client
  Meteor.startup ->
    spinner = new Spinner().spin(document.getElementsByTagName('body')[0])