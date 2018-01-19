class Pixiurge.WebsocketTransport
  constructor: (@pixiurge, @ws, cookie_lib = undefined) ->
    @opened = false
    @ready = false
    @login_handler = false
    @failed_login_handler = false
    @pending_password = false
    @pending_username = false
    @cookie_lib = cookie_lib || new Pixiurge.CookieLib
    @on_open = false
    @queue = []

  setup: () ->
    transport = this
    @ws.onmessage = (evt) =>
      data = JSON.parse evt.data
      if data[0] == "failed_login" || data[0] == "failed_registration"
        if @failed_login_handler?
          @failed_login_handler(data[1]["message"])
        else
          console.log "No failed login handler set!"
        @pending_password = false
        @pending_hash = false
        @pending_save_login = false
        return
      if data[0] == "login_salt"
        bcrypt = dcodeIO.bcrypt
        salt = data[1]["salt"]
        hashed = bcrypt.hashSync(@pending_password, salt)
        @pending_password = false  # Tried it? Clear it.
        @pending_hash = hashed
        @sendMessageWithType "hashed_login", { username: @pending_username, bcrypted: hashed }
        return
      if data[0] == "login"
        console.log "Logged in as", data[1]["username"]
        if @pending_save_login && @pending_hash
          @cookie_lib.setCookie("pixiurge_username", data[1]["username"])
          @cookie_lib.setCookie("pixiurge_hash", @pending_hash)
          @pending_hash = false
        @logged_in_as = data[1]["username"]
        if @login_handler?
          @login_handler(data[1]["username"])
        else
          console.log "No login handler set!"
        return
      if data[0] == "registration"
        @considerAutoLogin()
        return

      return transport.message_handler data[0], data.slice(1)

    @ws.onclose = () ->
      console.log "socket closed"

    @ws.onopen = () ->
      @opened = true
      ready_check = () =>
        if transport.ws.readyState == 1
          transport.ready = true
          transport.clearQueue()
        else
          setTimeout ready_check, 0.25
      console.log "connected..."
      ready_check()
      if @on_open?
        @on_open()

  sendMessage: (msgName, args...) ->
    sendMessageWithType("game_msg", msgName, args...)

  sendMessageWithType: (msgType, msgName, args...) ->
    if @ready
      # Serialize as JSON, send
      @ws.send JSON.stringify([ msgType, msgName, args ])
    else
      @queue.push([msgType, msgName, args])
      setTimeout (() => @clearQueue()), 0.5

  clearQueue: () ->
    if @ready && @queue.length > 0
      for msg in @queue
        @ws.send JSON.stringify(msg)

  playerAction: (action_name, args...) ->
    @sendMessageWithType("player_action", action_name, args...)

  # Accepts a function like: transportHandler(apiCallName, argArray)
  # This handler is called by the Transport when a message is received from
  # the server
  onMessage: (@message_handler) ->

  onLogin: (@login_handler) ->

  onFailedLogin: (@failed_login_handler) ->

  onOpen: (@on_open) ->
    if @opened?
      @on_open()  # Already open? Call it.

  registerAccount: (username, password) ->
    bcrypt = dcodeIO.bcrypt;
    salt = bcrypt.genSaltSync(10);
    hashed = bcrypt.hashSync(password, salt);
    @sendMessageWithType("register_account", { username: username, salt: salt, bcrypted: hashed })

  login: (username, password, save_login_info = true) ->
    @pending_password = password
    @pending_username = username
    @pending_save_login = save_login_info
    @sendMessageWithType("get_salt", { username: username })

  logout: () ->
    @cookie_lib.deleteCookie('pixiurge_username')
    @cookie_lib.deleteCookie('pixiurge_hash')

  considerAutoLogin: () ->
    cookie_username = @cookie_lib.getCookie("pixiurge_username")
    cookie_hash = @cookie_lib.getCookie("pixiurge_hash")
    if cookie_username? && cookie_username != "" && cookie_hash? && cookie_hash != ""
      @sendMessageWithType "hashed_login", { username: cookie_username, bcrypted: cookie_hash }
