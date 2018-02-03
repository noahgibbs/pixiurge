if(window.Mock === undefined) {
  window.Mock = {
  };
};

window.Mock.get_mock_websocket = function() {
    var mock = {
        _ready: 1,
        _onopen: undefined,
        _onclose: undefined,
        _onmessage: undefined,
        _sentData: [],

        get readyState() {
            return this._ready;
        },

        // onmessage_handler(evt)
        // evt.data - JSON data for the message
        set onmessage(value) {
            this._onmessage = value;
        },

        // onopen_handler()
        set onopen(value) {
            this._onopen = value;
        },

        // onclose_handler()
        set onclose(value) {
            this._onclose = value;
        },

        send: function (data) {
            this._sentData.push(data);
        },

        getSent: function() { return this._sentData; },

        receive: function(received_data) {
            if(this._onmessage != undefined) {
                this._onmessage({data: received_data});
            };
        },

        open: function() {
            if(this._onopen != undefined) {
                this._onopen();
            };
        },

        close: function() {
            if(this._onclose != undefined) {
                this._onclose();
            };
        }
    };
    return mock;
};

