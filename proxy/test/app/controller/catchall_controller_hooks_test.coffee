url = require "url"
async = require "async"
libxml = require "libxmljs"
request = require "request"

{ waitUntil } = require "wait"
{ EventEmitter } = require "events"
{ ApiaxleTest } = require "../../apiaxle"

class exports.CatchallHooksTest extends ApiaxleTest
  @start_webserver = true
  @empty_db_on_setup = true

  "setup an api/key": ( done ) ->
    fixtures =
      api:
        facebook:
          endPoint: "example.com"
      key:
        bob:
          forApis: [ "facebook" ]

    @fixtures.create fixtures, done

  "test hook req-start": ( done ) ->
    # stub the lowerlevel request call
    stub = @getStub request, "get", ( options, cb ) ->
      body = "{}"
      api_res = { statusCode: 200 }

      return cb null, api_res, body

    @stubDns { "facebook.api.localhost": "127.0.0.1" }

    # note the waiting logic below!
    emitted = false
    @app.ee.on "req-start", ( verb, options, api, key, keyrings ) =>
      emitted = true

      @equal verb, "get"
      @equal api, "facebook"
      @equal key, "bob"
      @deepEqual keyrings, []

    options =
      path: "/?api_key=bob"
      host: "facebook.api.localhost"

    @GET options, ( err ) =>
      @ok not err

      hasRun = ( ) -> emitted
      waitUntil hasRun, -> done 5
