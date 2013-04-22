assert = require 'should'
CleverElements = require '../lib/cleverelements'

describe 'CleverElements', ->
  cleverElements = null
  beforeEach ->
    cleverElements = new CleverElements 'MyID', 'ApiKey', 'test'

  describe '_createHeader', ->

    it 'should return an XML-string', ->
      header = cleverElements._createHeader()
      header.should.equal '<sendcockpit:validate><userid>MyID</userid><apikey>ApiKey</apikey><version>1.0</version><mode>test</mode></sendcockpit:validate>'

    it 'should throw an Error if userid is missing', ->
      cleverElements.userid = null
      (-> cleverElements._createHeader()).should.throwError 'UserID is missing'

    it 'should throw an Error if apikey is missing', ->
      cleverElements.apikey = null
      (-> cleverElements._createHeader()).should.throwError 'ApiKey is missing'

    it 'should throw an Error if mode is neither »test« nor »live« is missing', ->
      cleverElements.mode = 'stuff'
      (-> cleverElements._createHeader()).should.throwError 'Mode needs to be either live or test'

  describe '_createSubscriber', ->
    it 'should create a simple subscriber object', ->
      subscriber = cleverElements._createSubscriber 'myListId', 'myAddress@example.net'
      subscriber.listID.should.equal 'myListId'
      subscriber.email.should.equal 'myAddress@example.net'
      subscriber.customFields.should.be.an.instanceOf Array
      subscriber.customFields.length.should.equal 0

  describe '_ceateSubscriberList', ->
    it 'should create a list of subscribers if given listID and one email address', ->
      address = 'john@example.net'
      listID = '4711'
      list = cleverElements._createSubscriberList listID, address
      list.ctSubscriberRequest.subscriberList[0].listID.should.equal listID
      list.ctSubscriberRequest.subscriberList[0].email.should.equal address

    it 'should create of subscribers if given listID and two email addresses', ->
      addresses = ['john@example.net', 'mr.doe@example.net']
      listID = 4711
      list = cleverElements._createSubscriberList listID, addresses
      list.ctSubscriberRequest.subscriberList[0].listID.should.equal listID
      list.ctSubscriberRequest.subscriberList[0].email.should.equal addresses[0]
      list.ctSubscriberRequest.subscriberList[1].listID.should.equal listID
      list.ctSubscriberRequest.subscriberList[1].email.should.equal addresses[1]

    it 'should throw if more than 50 addresses are given (because API only allows 50)', ->
      addresses = Array(51)
      listID = 4711
      (-> cleverElements._createSubscriberList listID, addresses).should.throwError 'only 50 addresses allowed in one batch'

  describe '_getSoapClient', ->
    it 'should return soap client with header data set', (done) ->
      cleverElements.version = '2.4'
      cleverElements._getSoapClient (error, client) ->
        (client.soapHeaders.join '').should.match /<version>2.4<\/version>/
        done()


