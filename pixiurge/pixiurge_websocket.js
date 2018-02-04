Pixiurge.WebsocketTransport = class WebsocketTransport {
  constructor(pixiurge, ws, cookieLib) {
    this.pixiurge = pixiurge;
    this.ws = ws;
    if (cookieLib == null) { cookieLib = undefined; }
    this.opened = false;
    this.ready = false;
    this.loginHandler = false;
    this.failedLoginHandler = false;
    this.pendingPassword = false;
    this.pendingUsername = false;
    this.cookieLib = cookieLib || new Pixiurge.CookieLib;
    this.onOpenHandler = false;
    this.queue = [];
  }

  setup() {
    const transport = this;
    this.ws.onmessage = evt => {
      const data = JSON.parse(evt.data);
      if ((data[0] === "failed_login") || (data[0] === "failed_registration")) {
        if (this.failedLoginHandler != null) {
          this.failedLoginHandler(data[1]["message"]);
        } else {
          console.log("No failed login handler set!");
        }
        this.pendingPassword = false;
        this.pendingHash = false;
        this.pendingSaveLogin = false;
        return;
      }
      if (data[0] === "login_salt") {
        const { bcrypt } = dcodeIO;
        const salt = data[1]["salt"];
        const hashed = bcrypt.hashSync(this.pendingPassword, salt);
        this.pendingPassword = false;  // Tried it? Clear it.
        this.pendingHash = hashed;
        this.sendMessageWithType("hashed_login", { username: this.pendingUsername, bcrypted: hashed });
        return;
      }
      if (data[0] === "login") {
        console.log("Logged in as", data[1]["username"]);
        if (this.pendingSaveLogin && this.pendingHash) {
          this.cookieLib.setCookie("pixiurge_username", data[1]["username"]);
          this.cookieLib.setCookie("pixiurge_hash", this.pendingHash);
          this.pendingHash = false;
        }
        this.loggedInAs = data[1]["username"];
        if (this.loginHandler != null) {
          this.loginHandler(data[1]["username"]);
        } else {
          console.log("No login handler set!");
        }
        return;
      }
      if (data[0] === "registration") {
        this.considerAutoLogin();
        return;
      }

      transport.messageHandler(data[0], data.slice(1));
    };

    this.ws.onclose = () => console.log("socket closed");

    this.ws.onopen = function() {
      this.opened = true;
      var readyCheck = () => {
        if (transport.ws.readyState === 1) {
          transport.ready = true;
          transport.clearQueue();
        } else {
          setTimeout(readyCheck, 0.25);
        }
      };
      console.log("connected...");
      readyCheck();
      if (this.onOpenHandler != null) {
        this.onOpenHandler();
      }
    };
  }

  sendMessage(msgName, ...args) {
      this.sendMessageWithType("game_msg", msgName, ...args);
  }

  sendMessageWithType(msgType, msgName, ...args) {
    if (this.ready) {
      // Serialize as JSON, send
      this.ws.send(JSON.stringify([ msgType, msgName, args ]));
    } else {
      this.queue.push([msgType, msgName, args]);
      setTimeout((() => this.clearQueue()), 0.5);
    }
  }

  clearQueue() {
    if (this.ready && (this.queue.length > 0)) {
      this.queue.map((msg) =>
        this.ws.send(JSON.stringify(msg)));
      this.queue.splice(0, this.queue.length);
    }
  }

  playerAction(actionName, ...args) {
    this.sendMessageWithType("player_action", actionName, ...args);
  }

  // Accepts a function like: transportHandler(apiCallName, argArray)
  // This handler is called by the Transport when a message is received from
  // the server
  onMessage(messageHandler) {
    this.messageHandler = messageHandler;
  }

  onLogin(loginHandler) {
    this.loginHandler = loginHandler;
  }

  onFailedLogin(failedLoginHandler) {
    this.failedLoginHandler = failedLoginHandler;
  }

  onOpen(onOpenHandler) {
    this.onOpenHandler = onOpenHandler;
    if (this.opened != null) {
      this.onOpenHandler();  // Already open? Call it.
    }
  }

  registerAccount(username, password) {
    const { bcrypt } = dcodeIO;
    const salt = bcrypt.genSaltSync(10);
    const hashed = bcrypt.hashSync(password, salt);
    this.sendMessageWithType("register_account", { username, salt, bcrypted: hashed });
  }

  login(username, password, saveLoginInfo) {
    if (saveLoginInfo == null) { saveLoginInfo = true; }
    this.pendingPassword = password;
    this.pendingUsername = username;
    this.pendingSaveLogin = saveLoginInfo;
    this.sendMessageWithType("get_salt", { username });
  }

  logout() {
    this.cookieLib.deleteCookie('pixiurge_username');
    this.cookieLib.deleteCookie('pixiurge_hash');
  }

  considerAutoLogin() {
    const cookieUsername = this.cookieLib.getCookie("pixiurge_username");
    const cookieHash = this.cookieLib.getCookie("pixiurge_hash");
    if ((cookieUsername != null) && (cookieUsername !== "") && (cookieHash != null) && (cookieHash !== "")) {
      this.sendMessageWithType("hashed_login", { username: cookieUsername, bcrypted: cookieHash });
    }
  }
};
