const assert = require('assert');

describe('Pixiurge input configuration', function() {
    describe('Keyboard input', function() {
        it('should send Pixiurge input messages', function() {
            let pixiurge_game = new Pixiurge();
            let mock_ws = Mock.get_mock_websocket();
            let mock_input = new Mock.FakeInput(pixiurge_game);

            pixiurge_game.setTransport(new Pixiurge.WebsocketTransport(pixiurge_game, mock_ws));
            let display = new Pixiurge.Display(pixiurge_game, { canvas: "displayCanvas" });
            pixiurge_game.setMessageHandler("display", display);

            pixiurge_game.setup();
            mock_ws.open();
            mock_ws.receive(JSON.stringify([ "display_init", { ms_per_tick: 300, width: 640, height: 480 }]));

            mock_input.sendKeypress(37);
            assert.deepEqual([JSON.stringify([ "game_msg", "keypress", [{ code: 37 }]])], mock_ws.getSent());
        });
    });
});
