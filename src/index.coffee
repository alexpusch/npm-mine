_ = require "lodash"

{ mongifyNpm } = require "./mongify_npm"
{ downloadModules, countModules } = require "./download_modules"

baseOptions = 
  mongoDBUri: "mongodb://localhost:27017/npm-mine"

metadata = ->
  mongifyNpm baseOptions, (err) ->
    console.log err if err?

download = (options) ->
  options = _.extend options, baseOptions
  downloadModules options, (err) ->
    console.log err if err?

count = (options) ->
  options = _.extend options, baseOptions
  countModules options, (err, result) ->
    console.log err if err?

    console.log "#{result} Npms have more that #{options.threshold} downloads last month"

module.exports = {
  metadata, download, count
}