require 'json'
require 'byebug'
class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    session_cookie = req.cookies['_rails_lite_app']
    @session = session_cookie ? JSON.parse(session_cookie) : {}
  end

  def [](key)
    @session[key]
  end

  def []=(key, val)
    @session[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.set_cookie('_rails_lite_app', {value: JSON.generate(@session), path: '/'})
  end
end
