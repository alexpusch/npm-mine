MongoClient = require('mongodb').MongoClient

class NpmDb
  constructor: (@_db) ->

  insert: (module, callback) ->
    module = @_encodeDoc module
    @_db.collection("modules").update {_id: module._id}, module, {upsert: true}, (err) ->
      callback(err, module)

  updateDownloadCount: (downloadData, callback) ->
    @_db.collection("modules").update {_id: downloadData.package}, {$set: {downloadCount: downloadData.downloads}}, callback

  find: (threshold, callback) ->
    query = @_getThresholdQuery threshold
    @_db.collection("modules").find query, callback

  count: (threshold, callback) ->
    query = @_getThresholdQuery threshold
    console.log query
    @_db.collection("modules").count query, callback

  close: () ->
    @_db.close()

  _getThresholdQuery: (threshold) ->
    {"downloadCount": {"$gt" : threshold}}

  _encodeDoc: (doc) ->
    id = doc.id
    doc._id = id
    delete doc.id

    @_escapeMongo doc

  # mongo object keys cannot contain "." or "$", so lets replace those chars with other shit
  _escapeMongo: (doc) ->
    for key, val of doc
      if key.indexOf(".") >= 0 || key.indexOf("$") >= 0
        delete doc[key]
        key = key.replace /\./g, "%"
        key = key.replace /\$/g, "^"
        doc[key] = val

      if typeof val == "object"
        @_escapeMongo val

    doc

  _decodeDoc = (doc) ->
    for key, val of doc
      if key.indexOf("%") >= 0 || key.indexOf("^") >= 0
        delete doc[key]
        key = key.replace /\%/g, "."
        key = key.replace /\^/g, "$"
        doc[key] = val

      if typeof val == "object"
        @_decodeDoc val

    doc

connect = (mongoDBUri, callback) ->
  MongoClient.connect mongoDBUri, (err, db) ->
      callback(err, new NpmDb(db))

module.exports = {
  connect
}
