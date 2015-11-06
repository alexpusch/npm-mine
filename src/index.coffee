_ = require "lodash"

{ mongifyNpm } = require "./mongify_npm"
{ downloadModules, countModules } = require "./download_modules"
config = requrie "../config"

baseOptions = config

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