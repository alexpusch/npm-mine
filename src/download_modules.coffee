async = require 'async'
_ = require "lodash"
ProgressBar = require "progress"
cloneModule = require("fishman").cloneModule

NpmDb = require "./npm_db"
MONGODB_URI = "mongodb://localhost:27017/npm-mine"

downloadModules = (options, callback) ->
  { threshold, mongoDBUri, path } = options

  async.auto {
    db: (done) ->
      NpmDb.connect MONGODB_URI, done

    count: ["db", (done, results) ->
      results.db.count threshold, done
    ]

    find: ["db", (done, results) ->
      results.db.find threshold, done
    ]

    download: ["count", "find", (done, results) ->
      console.log "count: #{results.count}"
      modulesCursour = results.find
      bar = new ProgressBar('[:bar] :current/:total (:percent) :elapsed :eta', { total: results.count });

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
              basePath: path
              incDeps: true
              incDevDeps: false
            , (err) ->
              bar.tick 1
              console.log err if err
              whilstDone()
      , done
    ]
  }, (err, results) ->
    results.db.close()
    callback(err)

module.exports = { downloadModules }