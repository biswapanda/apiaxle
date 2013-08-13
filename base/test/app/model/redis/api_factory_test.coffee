# This code is covered by the GPL version 3.
# Copyright 2011-2013 Philip Jackson.
async = require "async"

{ ValidationError } = require "../../../../lib/error"
{ FakeAppTest } = require "../../../apiaxle_base"

class exports.ApiKeyLinkTest extends FakeAppTest
  @empty_db_on_setup = true

  "test deleting unlinks keys": ( done ) ->
    fixture =
      api:
        facebook:
          endPoint: "example.com"
        twitter:
          endPoint: "example.com"
      key:
        phil: { forApis: [ "facebook", "twitter" ] }
        bob: { forApis: [ "facebook", "twitter" ] }

    @fixtures.create fixture, ( err, [ facebook, twitter, phil, bob ] ) =>
      @ok not err

      facebook.delete ( err ) =>
        @ok not err

        phil.supportedApis ( err, api_list ) =>
          # the keys should no longet know about facebook
          @ok "facebook" not in api_list

          done 3

class exports.ApiTest extends FakeAppTest
  @empty_db_on_setup = true

  "setup model": ( done ) ->
    @model = @app.model "apifactory"

    done()

  "test initialisation": ( done ) ->
    @equal @model.ns, "gk:test:apifactory"

    done 1

  "test #update ing an existing api": ( done ) ->
    fixture =
      api:
        twitter:
          endPoint: "example.com"

    @fixtures.create fixture, ( err, [ dbApi ] ) =>
      @ok not err
      @ok dbApi.data.createdAt
      @ok not dbApi.data.updatedAt?

      @fixtures.create fixture, ( err, [ dbApi2 ] ) =>
        @ok not err
        @ok dbApi2.data.updatedAt
        @equal dbApi.data.createdAt, dbApi2.data.createdAt

        done 6

  "test #create with bad structure": ( done ) ->
    newObj =
      apiFormat: "text"

    @model.create "twitter", newObj, ( err ) =>
      @ok err

      done 1

  "test #create with an invalid regex": ( done ) ->
    newObj =
      apiFormat: "xml"
      endPoint: "api.twitter.com"
      extractKeyRegex: "hello( "

    @fixtures.createApi "twitter", newObj, ( err ) =>
      @ok err
      @match err.message, /Invalid regular expression/

      done 2

  "test #create with good structure": ( done ) ->
    newObj =
      apiFormat: "xml"
      endPoint: "api.twitter.com"

    @fixtures.createApi "twitter", newObj, ( err ) =>
      @ok not err

      @model.find [ "twitter" ], ( err, results ) =>
        @ok not err

        @equal results.twitter.data.apiFormat, "xml"
        @ok results.twitter.data.createdAt

        done 4

  "test unlinkkey": ( done ) ->
    fixture =
      api:
        facebook:
          endPoint: "example.com"
        twitter:
          endPoint: "example.com"
      key:
        1234:
          forApis: [ "facebook", "twitter" ]

    @fixtures.create fixture, ( err, [ dbFacebook, rest... ] ) =>
      @ok not err

      dbFacebook.supportsKey "1234", ( err, supported ) =>
        @ok not err
        @equal supported, true

        dbFacebook.unlinkKeyById "1234", ( err ) =>
          @ok not err

          dbFacebook.supportsKey "1234", ( err, supported ) =>
            @ok not err
            @equal supported, false

            dbFacebook.getKeys 0, 100, ( err, keys ) =>
              @deepEqual keys, []

              done 7

  "test #supportsKey on an API": ( done ) ->
    fixture =
      api:
        facebook:
          endPoint: "example.com"
        twitter:
          endPoint: "example.com"
      key:
        1234:
          forApis: [ "facebook", "twitter" ]

    @fixtures.create fixture, ( err, objects ) =>
      @ok not err

      @app.model( "apifactory" ).find [ "facebook" ], ( err, results ) =>
        @ok not err
        @ok results.facebook

        # is supported
        results.facebook.supportsKey "1234", ( err, supported ) =>
          @ok not err
          @equal supported, true

          # isn't supported
          results.facebook.supportsKey "hello", ( err, supported ) =>
            @ok not err
            @equal supported, false

            done 7
