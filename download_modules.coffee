MongoClient = require('mongodb').MongoClient
async = require 'async'
_ = require "lodash"
ProgressBar = require "progress"

MONGODB_URI = "mongodb://localhost:27017/npm"
cloneModule = require("fishman").cloneModule

query = {"downloadsInfo.downloads": {"$gt" : 5000000}}
target = "test"

decodeDoc = (doc) ->
  for key, val of doc
    if key.indexOf("%") >= 0 || key.indexOf("^") >= 0
      delete doc[key]
      key = key.replace /\%/g, "."
      key = key.replace /\^/g, "$"
      doc[key] = val

    if typeof val == "object"
      decodeDoc val

  doc

async.auto {
  db: (done) ->
    MongoClient.connect MONGODB_URI, done

  count: ["db", (done, results) ->
    results.db.collection("modules").count(query, done)
  ]

  find: ["db", (done, results) ->
    results.db.collection("modules").find query, done
  ]

  download: ["count", "find", (done, results) ->
    # modules = results.toArray
    modulesCursour = results.find
    bar = new ProgressBar('[:bar] :current/:total (:percent) :elapsed :eta', { total: results.count });

    pgkGetter = (module, callback) ->
      results.db.collection("modules").findOne {"key": module}, (err, pkg) ->
        return callback(err) if err
        if !pkg?
          return callback "pgk: #{module} not found"
        callback null, decodeDoc(pkg.doc)

    finish = false
    
    async.whilst ()-> 
      !finish
    , (whilstDone) ->
      modulesCursour.nextObject (err, module) ->
        if module == null
          finish = true
          whilstDone()
        else
          cloneModule 
            manager: "npm"
            module: module.key
            basePath: target
            incDeps: true
            incDevDeps: false
          # , pgkGetter
          , (err) ->
            bar.tick 1
            console.log err if err
            whilstDone()
    , done
  ]
}, (err, results) ->
  console.log "DONE"
  console.log(err) if err?
  results.db.close()