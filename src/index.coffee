_ = require "lodash"

{ mongifyNpm } = require "./mongify_npm"
{ downloadModules } = require "./download_modules"

baseOptions = 
  mongoDBUri: "mongodb://localhost:27017/npm-mine"

metadata = ->
  mongifyNpm baseOptions, (err) ->
    console.log err if err?

download = (options) ->
  options = _.extend options, baseOptions
  downloadModules options, (err) ->
    console.log err if err?

module.exports = {
  metadata, download
}