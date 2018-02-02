/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
Pixiurge.CookieLib = class CookieLib {
  constructor() {}

  getCookie(name) {
    const escape = s => s.replace(/([.*+?\^${}()|\[\]\/\\])/g, '\\$1');
    const match = document.cookie.match(RegExp(`(?:^|;\\s*)${escape(name)}=([^;]*)`));
    if (match) {
      return match[1];
    } else {
      return null;
    }
  }

  setCookie(name, value) {
    document.cookie = `${name}=${value};secure`;
  }

  deleteCookie(name) {
    document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:01 GMT;`;
  }
};

Pixiurge.FakeCookieLib = class FakeCookieLib extends Pixiurge.CookieLib {
  constructor() {
    super();
    this.cookies = {};
  }

  getCookie(name) {
    return this.cookies[name];
  }

  setCookie(name, value) {
    this.cookies[name] = value;
  }

  deleteCookie(name) {
    delete this.cookies[name];
  }
};

Pixiurge.ScreenShot = {

  // For this to work, have to pass preserveDrawingBuffer:true in the pixiOptions to your PixiurgeApp.
  saveCanvas(canvas, suggestedFileName) {
    if (suggestedFileName == null) { suggestedFileName = "screenshot.png"; }
    const uri = canvas.toDataURL('image/png');
    const link = document.createElement("a");
    link.download = suggestedFileName;
    link.href = uri;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  },

  dataURItoBlob(dataURI) {
    const binary = atob(dataURI.split(',')[1]);
    const array = [];
    for (let i of Array.from(binary)) {
      array.push(binary.charCodeAt(i));
    }
    return new Blob([new Uint8Array(array)], {type: 'image/png'});
  }
};
