/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS205: Consider reworking code to avoid use of IIFEs
 */
// The top-level Pixiurge library sets up message handling for default graphical display and
// whatever the game wants to handle.

window.Pixiurge = class Pixiurge {
  constructor() {
    this.messageHandlers = [];
  }
  setTransport(transport) {
    return this.transport = transport;
  }
  setMessageHandler(prefix, handler) {
    return this.messageHandlers.push([prefix, handler]);
  }

  getTransport() { return this.transport; }
  setup(options) {
    if (options == null) { options = {}; }
    const pixiurgeObj = this;
    this.transport.onMessage((msgName, args) => pixiurgeObj.gotTransportCall(msgName, args));
    this.transport.setup();
    const result = [];
    for (let items of Array.from(this.messageHandlers)) {
      const handler = items[1];
      if (handler.setup != null) {
        result.push(handler.setup());
      } else {
        result.push(undefined);
      }
    }
  }

  gotTransportCall(msgName, args) {
    for (let items of Array.from(this.messageHandlers)) {
      const prefix = items[0];
      const handler = items[1];
      if ((prefix === "") || (msgName.slice(0, prefix.length) === prefix)) {
        return handler.message(msgName, args);
      }
    }

    // TODO: send back a warning to the server side?
    return console.warn(`Unknown message name: ${msgName}, args: ${args}`);
  }
};

// This is an example message-handling parent class
Pixiurge.Simulation = class Simulation {
  constructor(dcjs) {
    this.dcjs = dcjs;
  }
  setup() {}
  message(messageType, argArray) {
    if (messageType === "simNotification") {
      this.notification(argArray[0]);
    } else {
      console.warn(`Unknown simulation message type: ${messageType}!`);
    }
  }
  notification(data) {
    console.log("Implement a Pixiurge.Simulation subclass to do something with your notifications!");
  }
};
