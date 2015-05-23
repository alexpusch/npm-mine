MongoClient = require('mongodb').MongoClient
ProgressBar = require "progress"
through2 = require 'through2'

{ getModuleStream, getModuleCount } = require "./npm_db_utils"

MONGODB_URI = "mongodb://localhost:27017/npm3"

# mongo object keys cannot contain "." or "$", so lets replace those chars with other shit
encodeDoc = (doc) ->
  for key, val of doc
    if key.indexOf(".") >= 0 || key.indexOf("$") >= 0
      delete doc[key]
      key = key.replace /\./g, "%"
      key = key.replace /\$/g, "^"
      doc[key] = val

    if typeof val == "object"
      encodeDoc val

  doc


MongoClient.connect MONGODB_URI, (err, db) ->
  console.log err if err

  updateDb = through2.obj (module, enc, callback)->
    module = encodeDoc module
    # db.collection("modules").update {id: module.id}, module, {upsert: true}, (err, o) =>
    db.collection("modules").insert module, (err, o) =>
      console.log(err) if err?
      this.push module
      callback()


  getModuleCount (err, count) ->
    console.log err if err
    bar = new ProgressBar('[:bar] :current/:total (:percent) :elapsed :eta', { total: count });
    
    stream = getModuleStream
      rowsPerPage: 500

    stream.pipe(updateDb).on "data", ->
      bar.tick(1)

    # stream.on "data", (data) ->
    #   console.log data.id

    stream.on "end", ->
      console.log "done!!"
      db.close()

    stream.on "error", (err) ->
      console.log "ERROR", err
      db.close()
