_ = require "lodash"
async = require "async"
highland = require "highland"
ProgressBar = require "progress"

NpmDb = require "./npm_db"
{ cloneModule } = require("fishman")
{ getMongoStream } = require "./mongo_stream"

countModules = (options, callback) ->
  { threshold, mongoDBUri, path } = options

  NpmDb.connect mongoDBUri, (err, db) ->
    db.count threshold, (err, result) ->
      db.close()
      callback(err, result)

downloadModules = (options, callback) ->
  { threshold, mongoDBUri, path } = options

  async.auto {
    db: (done) ->
      NpmDb.connect mongoDBUri, done

    count: ["db", (done, results) ->
      results.db.count threshold, done
    ]

    download: ["count", (done, results) ->
      console.log "count: #{results.count}"
      
      bar = new ProgressBar('[:bar] :current/:total (:percent) :elapsed :eta', { total: results.count });

      modulesCursour = results.db.find threshold
      modulesStream = highland modulesCursour
      downloadStream = highland.wrapCallback (module, callback) ->
        cloneModule 
          manager: "npm"
          module: module.key
          basePath: path
          incDeps: true
          incDevDeps: false
        , callback

      modulesStream
        .map(downloadStream)
        # parallel does not work well :(
        .series()
        .each ->
          bar.tick(1)
        .done done
    ]
  }, (err, results) ->
    results.db.close()
    callback(err)

module.exports = { downloadModules, countModules }