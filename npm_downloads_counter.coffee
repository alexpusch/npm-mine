request = require "request"

getDownloadCount = (modules, done) ->
  queryString = _buildQueryString modules
  url = "https://api.npmjs.org/downloads/point/last-month/#{queryString}"
  request.get url, {json: true}, (err, response, body) ->
    done null, body

_buildQueryString = (modules) ->
  s = ""
  for module in modules
    if s == ""
      s = "#{module}" 
    else
      s = "#{s},#{module}"
  s

module.exports = getDownloadCount