{ mongifyNpm } = require "./mongify_npm"

options = 
  mongoDBUri: "mongodb://localhost:27017/npm-mine"

metadata = ->
  mongifyNpm options, (err) ->
    console.log err if err?

module.exports = {
  metadata
}