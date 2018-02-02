class Pixiurge.WebsocketTransport
  constructor: (@pixiurge, @ws, cookieLib = undefined) ->
    @opened = false
    @ready = false
    @loginHandler = false
    @failedLoginHandler = false
    @pendingPassword = false
    @pendingUsername = false
    @cookieLib = cookieLib || new Pixiurge.CookieLib
    @onOpenHandler = false
    @queue = []

  setup: () ->
    transport = this
    @ws.onmessage = (evt) =>
      data = JSON.parse evt.data
      if data[0] == "failed_login" || data[0] == "failed_registration"
        if @failedLoginHandler?
          @failedLoginHandler(data[1]["message"])
        else
          console.log "No failed login handler set!"
        @pendingPassword = false
        @pendingHash = false
        @pendingSaveLogin = false
        return
      if data[0] == "login_salt"
        bcrypt = dcodeIO.bcrypt
        salt = data[1]["salt"]
        hashed = bcrypt.hashSync(@pendingPassword, salt)
        @pendingPassword = false  # Tried it? Clear it.
        @pendingHash = hashed
        @sendMessageWithType "hashed_login", { username: @pendingUsername, bcrypted: hashed }
        return
      if data[0] == "login"
        console.log "Logged in as", data[1]["username"]
        if @pendingSaveLogin && @pendingHash
          @cookieLib.setCookie("pixiurge_username", data[1]["username"])
          @cookieLib.setCookie("pixiurge_hash", @pendingHash)
          @pendingHash = false
        @loggedInAs = data[1]["username"]
        if @loginHandler?
          @loginHandler(data[1]["username"])
        else
          console.log "No login handler set!"
        return
      if data[0] == "registration"
        @considerAutoLogin()
        return

      return transport.messageHandler data[0], data.slice(1)

    @ws.onclose = () ->
      console.log "socket closed"

    @ws.onopen = () ->
      @opened = true
      readyCheck = () =>
        if transport.ws.readyState == 1
          transport.ready = true
          transport.clearQueue()
        else
          setTimeout readyCheck, 0.25
      console.log "connected..."
      readyCheck()
      if @onOpenHandler?
        @onOpenHandler()

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

  playerAction: (actionName, args...) ->
    @sendMessageWithType("player_action", actionName, args...)

  # Accepts a function like: transportHandler(apiCallName, argArray)
  # This handler is called by the Transport when a message is received from
  # the server
  onMessage: (@messageHandler) ->

  onLogin: (@loginHandler) ->

  onFailedLogin: (@failedLoginHandler) ->

  onOpen: (@onOpenHandler) ->
    if @opened?
      @onOpenHandler()  # Already open? Call it.

  registerAccount: (username, password) ->
    bcrypt = dcodeIO.bcrypt;
    salt = bcrypt.genSaltSync(10);
    hashed = bcrypt.hashSync(password, salt);
    @sendMessageWithType("register_account", { username: username, salt: salt, bcrypted: hashed })

  login: (username, password, saveLoginInfo = true) ->
    @pendingPassword = password
    @pendingUsername = username
    @pendingSaveLogin = saveLoginInfo
    @sendMessageWithType("get_salt", { username: username })

  logout: () ->
    @cookieLib.deleteCookie('pixiurge_username')
    @cookieLib.deleteCookie('pixiurge_hash')

  considerAutoLogin: () ->
    cookieUsername = @cookieLib.getCookie("pixiurge_username")
    cookieHash = @cookieLib.getCookie("pixiurge_hash")
    if cookieUsername? && cookieUsername != "" && cookieHash? && cookieHash != ""
      @sendMessageWithType "hashed_login", { username: cookieUsername, bcrypted: cookieHash }
