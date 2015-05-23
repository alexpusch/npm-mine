MongoClient = require('mongodb').MongoClient
async = require 'async'
_ = require "lodash"
ProgressBar = require "progress"

getNpmDownloadCount = require "./npm_downloads_counter"

MONGODB_URI = "mongodb://localhost:27017/npm3"

query = {}

getDownloadsCountTask = (task, done) ->
  skip = task.skip
  limit = task.limit
  modulesCollection = task.modulesCollection
  bar = task.bar

  modulesCollection.find(query, {key: 1}).skip(skip).limit(limit).toArray (err, modules) ->
    return done(err) if err?

    moduleNames = _(modules).pluck("key").value()
    getNpmDownloadCount moduleNames, (err, downloadData) ->
      return done(err) if err?

      keys = _.keys(downloadData)

      if (keys.length == 1)
        bar.tick moduleNames.length
        return queueDone()

      async.each keys, (key, eachDone) ->
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
    q = async.queue getDownloadsCountTask, 8

    queryStep = 100
    n = Math.floor moduleCount/queryStep

    for i in [0..n]
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