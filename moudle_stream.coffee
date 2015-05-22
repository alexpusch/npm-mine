request = require "request"
Readable = require('stream').Readable
async = require "async"

NPM_COUCHDB_URI = "https://skimdb.npmjs.com/registry"

class ModuleReader
  constructor: (options) ->
    {@rowsPerPage} = options
    @buffer = []

  next: (done) ->
    @_ensureInit (err) =>
      return done(err) if err

      if @buffer.length > 0
        process.nextTick =>
          nextModule = @_popFromBuffer()
          done null, nextModule 
      else
        @_requestNextPage (err, modules) => 
          return done(err) if err

          if(modules.length == 0)
            return done null, null

          @nextStartKey = modules[modules.length - 1].id
          @buffer = modules
          nextModule = @_popFromBuffer()
          done null, nextModule 


  _popFromBuffer: ->
    nextModule = @buffer[0]
    @buffer.shift()

    return nextModule

  _ensureInit: (done) ->
    if @nextStartKey?
      process.nextTick ->
        done()
    else
      @_init done

  _init: (done) ->
    @_getFirstNodeModule (err, firstModule) =>
      return done(err) if err
      @nextStartKey = firstModule
      done()

  _requestNextPage: (done) ->  
    url = "#{NPM_COUCHDB_URI}/_all_docs?include_docs=true&startkey=\"#{@nextStartKey}\"&limit=#{@rowsPerPage+1}"
    request.get url, {json: true}, (err, response, body) ->
      return done(err) if err

      modules = body.rows
      # The first row is the last row of previous call, so delete it.
      modules.shift()
      done null, modules

  _getFirstNodeModule: (done) ->
    request.get "#{NPM_COUCHDB_URI}/_all_docs?limit=1", {json: true}, (err, response, body) ->
      return done(err) if err

      done null, body.rows[0].id

getModuleStream = (options) ->
  stream = new Readable {objectMode: true}
  moduleReader = new ModuleReader options

  stream._read = ->
    moduleReader.next (err, module) ->
      if err
        throw new Error(err)

      stream.push module

  return stream

getModuleCount = (done) ->
  request.get NPM_COUCHDB_URI, { json: true }, (err, response, body) ->
    if err
      done err
      return

    done null, body.doc_count

module.exports = {
  getModuleStream,
  getModuleCount
}