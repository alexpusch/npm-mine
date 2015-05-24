MongoClient = require('mongodb').MongoClient
async = require 'async'
_ = require "lodash"
ProgressBar = require "progress"

getNpmDownloadCount = require "./npm_downloads_counter"

MONGODB_URI = "mongodb://localhost:27017/npm"

query = {"downloadsInfo": {"$exists": 0}}
queryStep = 100
cuncurency = 8

getDownloadsCountTask = (task, done) ->
  skip = task.skip
  limit = task.limit
  modulesCollection = task.modulesCollection
  bar = task.bar

  modulesCollection.find(query, {key: 1}).skip(skip).limit(limit).toArray (err, modules) ->
    return done(err) if err?

    moduleNames = _(modules).pluck("key").value()
    getNpmDownloadCount moduleNames, (err, downloadData) ->
      if err?
        bar.tick moduleNames.length
        return done(err) 

      keys = _.keys(downloadData)

      if (downloadData.error?)
        bar.tick moduleNames.length
        return done()

      if(keys.length < moduleNames.length)
        bar.tick(moduleNames.length - keys.length)

      async.eachLimit keys, cuncurency, (key, eachDone) ->
        bar.tick(1)
        modulesCollection.update({key: key}, {$set: {downloadsInfo: downloadData[key]}}, eachDone)
      , done

async.auto 
  db: (done) ->
    MongoClient.connect MONGODB_URI, done

  ensureIndex: ["db", (done, results)->
    results.db.collection("modules").ensureIndex({key: 1}, done)
  ]

  count: ["db", "ensureIndex", (done, results) ->
    results.db.collection("modules").count(query, done)
  ]

  updateDownloadsCount: ["count", (done, results) ->
    moduleCount = results.count

    bar = new ProgressBar('[:bar] :current/:total (:percent) :elapsed :eta', { total: moduleCount });
    q = async.queue getDownloadsCountTask, cuncurency

    q.drain = ->
      done()
    
    n = Math.floor(moduleCount/queryStep)

    for i in [0...(n)]
      q.push
        skip: queryStep * i
        limit: queryStep
        modulesCollection: results.db.collection("modules")
        bar: bar
      , (err) ->
        console.log err if err?
  ]

  , (err, results) ->
    console.log(err) if err?
    console.log "DONE!"
    results.db.close()