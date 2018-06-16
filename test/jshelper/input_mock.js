if(window.Mock === undefined) {
  window.Mock = {};
};

window.Mock.FakeInput = class FakeInput extends Pixiurge.Input {
    constructor(pixiApp) {
        super(pixiApp);
    }

    sendKeypress(code) {
        this.pixiApp.transport.sendMessageWithType("player_action", "keypress", { code: code });
    }
}
