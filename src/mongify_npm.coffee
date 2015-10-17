ProgressBar = require "progress"
highland = require('highland');

{ getModuleStream, getModuleCount, getDownloadCount } = require "./npm_reader"
NpmDb = require "./npm_db"

mongifyNpm = (options, callback) ->
  NpmDb.connect options.mongoDBUri, (err, db) ->
    return callback(err) if err?

    insertStream = highland.wrapCallback db.insert.bind(db)
    updateStream = highland.wrapCallback db.updateDownloadCount.bind(db)
    getDownloadCountStream = highland.wrapCallback getDownloadCount
    modulesStream = highland getModuleStream(
      rowsPerPage: 1000
    )
    
    getModuleCount (err, count) ->
      return callback(err) if err?

      bar = new ProgressBar('[:bar] :current/:total (:percent) :elapsed :eta', { total: count });

      data = modulesStream

      # pull items from modules stream as fast as we can
      # incoming data blow up RAM, TODO: find solution      
      # d2 = data.fork().apply()

      data
        # .observe()
        .filter (doc) ->
          doc.key.match(/^_design.*$/) == null
        .flatMap(insertStream)
        .batch(100)
        .map(getDownloadCountStream)
        .parallel(5)
        .errors (err, push) ->
          console.log "error!", err
          bar.tick(100)
          unless err.statusCode == 404
            push(err)
        .flatten()
        .flatMap(updateStream)
        .each ->
          bar.tick(1)
        .done ->
          db.close();
          callback();

module.exports = { mongifyNpm }