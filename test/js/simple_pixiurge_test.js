require('source-map-support').install();

const assert = require('assert');

describe('Simple Pixiurge configuration', function() {
    describe('window.Pixiurge', function() {
        it('should define Pixiurge on window', function() {
            assert.notEqual(undefined, window.Pixiurge);
        });
    });
    describe('Set up Pixiurge', function() {
        it('should set up Pixiurge without error', function() {
            window.pixiurge_game = new Pixiurge();

            var mock_ws = window.Mock.get_mock_websocket();
            pixiurge_game.setTransport(new Pixiurge.WebsocketTransport(pixiurge_game, mock_ws));
            var display = new Pixiurge.Display(pixiurge_game, { canvas: "displayCanvas" });
            pixiurge_game.setMessageHandler("display", display);

            pixiurge_game.setup();
            assert.equal(mock_ws, pixiurge_game.getTransport().ws);
        });

        it('should dispatch Pixiurge messages', function(done) {
            window.pixiurge_game = new Pixiurge();

            var mock_ws = window.Mock.get_mock_websocket();
            pixiurge_game.setTransport(new Pixiurge.WebsocketTransport(pixiurge_game, mock_ws));
            var display = new Pixiurge.Display(pixiurge_game, { canvas: "displayCanvas" });
            display.message = function(messageType, argArray) { if(messageType == "displayInit") done(); }
            pixiurge_game.setMessageHandler("display", display);

            pixiurge_game.setup();
            assert.equal(mock_ws, pixiurge_game.getTransport().ws);
            mock_ws.receive(JSON.stringify([ "game_msg", "displayInit", { width: 640, height: 480 }]));
        });
    });
});
