// By default, bind the arrow keys, upper- and lower-case letters, and
// numbers. That's key ranges 37-40, 65-90, 48-57 and 97-122
var defaultKeyCodesToBind = [ 37, 38, 39, 40, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122 ];

Pixiurge.Input = class Input {
    constructor(pixiApp, options) {
        if(options == null) {
            options = {};
        }
        this.pixiApp = pixiApp;
        const keyCodesToBind = options["keysToBind"] || defaultKeyCodesToBind;
        $("body").keypress( (event) => {
            for(let keyCode of keyCodesToBind) {
                if(event.keyCode == keyCode) {
                    this.pixiApp.transport.sendMessage("keypress", { code: keyCode });
                    event.preventDefault();
                    return;
                }
            }
        });
    }
};
