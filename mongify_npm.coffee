MongoClient = require('mongodb').MongoClient
ProgressBar = require "progress"

{ getModuleStream, getModuleCount } = require "./moudle_stream"

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

  getModuleCount (err, count) ->
    console.log err if err
    bar = new ProgressBar('[:bar] :current/:total (:percent) :elapsed :eta', { total: count });

    modules = db.collection("modules")
    stream = getModuleStream
      rowsPerPage: 500

    stream.on "readable", () ->
      bar.tick(1);
      module = stream.read()

      unless module == null
        module = encodeDoc module
        modules.update {id: module.id}, module, {upsert: true}, (err) ->
          console.log err if err

    stream.on "end", ->
      console.log "done!!"
      db.close()

    stream.on "error", (err) ->
      console.log "ERROR", err
      db.close()
