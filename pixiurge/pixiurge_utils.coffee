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
