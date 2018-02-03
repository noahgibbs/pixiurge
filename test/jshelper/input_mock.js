if(window.Mock === undefined) {
  window.Mock = {};
};

window.Mock.FakeInput = class FakeInput extends Pixiurge.Input {
    constructor(pixiApp) {
        super(pixiApp);
    }

    sendKeypress(code) {
        this.pixiApp.transport.sendMessage("keypress", { code: code });
    }
}
