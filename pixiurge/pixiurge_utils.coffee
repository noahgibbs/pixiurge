class Pixiurge.CookieLib
  constructor: () ->

  getCookie: (name) ->
    escape = (s) -> s.replace(/([.*+?\^${}()|\[\]\/\\])/g, '\\$1')
    match = document.cookie.match RegExp('(?:^|;\\s*)' + escape(name) + '=([^;]*)')
    if match
      match[1]
    else
      null

  setCookie: (name, value) ->
    document.cookie = "#{name}=#{value};secure"

  deleteCookie: (name) ->
    document.cookie = "#{name}=; expires=Thu, 01 Jan 1970 00:00:01 GMT;"

class Pixiurge.FakeCookieLib extends Pixiurge.CookieLib
  constructor: () ->
    super()
    @cookies = {}

  getCookie: (name) ->
    @cookies[name]

  setCookie: (name, value) ->
    @cookies[name] = value

  deleteCookie: (name) ->
    delete @cookies[name]

Pixiurge.ScreenShot = {

  # For this to work, have to pass preserveDrawingBuffer:true in the pixiOptions to your PixiurgeApp.
  saveCanvas: (canvas, suggestedFileName = "screenshot.png") ->
    uri = canvas.toDataURL('image/png')
    link = document.createElement("a")
    link.download = suggestedFileName
    link.href = uri
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link);

  dataURItoBlob: (dataURI) ->
    binary = atob(dataURI.split(',')[1])
    array = []
    for i in binary
      array.push(binary.charCodeAt i)
    new Blob([new Uint8Array(array)], {type: 'image/png'});
}
