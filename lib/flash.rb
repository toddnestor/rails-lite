require 'json'

class Flash
  attr_accessor :now

  def initialize(req)
    @req = req
    flash_cookie = req.cookies['_rails_lite_app_flash']
    @flash = flash_cookie ? JSON.parse(flash_cookie) : {}
  end

  def [](key)
    key = key.to_s
    @flash[key] || now[key]
  end

  def []=(key, val)
    @flash[key] = val
  end

  def now
    @now ||= {}
  end

  def store_flash(res)
    res.set_cookie('_rails_lite_app_flash', {value: JSON.generate(@flash), path: '/'})
  end
end
