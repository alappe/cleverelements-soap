soap = require 'soap-js'

# Allow API access via SOAP to CleverElements until they have a fully
# working RESTful API.
module.exports = class CleverElements
  namespace: 'sendcockpit'
  name: 'validate'

  # Constructor
  #
  # @param [String] userid
  # @param [String] apikey
  # @param [String] mode Defaults to 'test, allowed values are 'test' and 'live'
  # @param [String] version Defaults to '1.0'
  # @param [String] wsdl Defaults to CleverElements SOAP API WSDL
  constructor: (@userid, @apikey, @mode = 'test', @version = '1.0', @wsdl = 'http://api.sendcockpit.com/server.php?wsdl') ->

  # Return all lists
  #
  # @param [Function] callback
  getLists: (callback) ->
    header = @_createHeader()
    client = soap.createClient @wsdl, (error, client) ->
      callback error, [] if error
      client.addSoapHeader header
      client.apiGetList '<apiGetList />', (error, result) ->
        callback error, result.Result.listResponse.item

  # Add a subscriber
  #
  # @overload addSubscriber(listId, address, callback)
  #   @param [Number] listId
  #   @param [String] address
  #   @param [Function] callback
  # @overload addSubscriber(listId, address, callback)
  #   @param [Number] listId
  #   @param [Array] address containing multiple addresses (up to 50)
  #   @param [Function] callback
  addSubscriber: (listId, address, callback) ->
    subscriberList = @_createSubscriberList listId, address
    @_getSoapClient (error, client) ->
      client.apiAddSubscriber subscriberList, (error, response) ->
        if error then success = false else success = true
        callback error, success

  # Add a subscriber with double opt-in
  #
  # @overload addSubscriber(listId, address, callback)
  #   @param [Number] listId
  #   @param [String] address
  #   @param [Function] callback
  # @overload addSubscriber(listId, address, callback)
  #   @param [Number] listId
  #   @param [Array] address containing multiple addresses (up to 50)
  #   @param [Function] callback
  addSubscriberDoi: (listId, address, callback) ->
    subscriberList = @_createSubscriberList listId, address
    @_getSoapClient (error, client) ->
      client.apiAddSubscriberDoi subscriberList, (error, response) ->
        if error then success = false else success = true
        callback error, success

  # Initialize the SOAP client, add the auth header etc.
  #
  # @private
  # @param [Function] callback
  _getSoapClient: (callback) ->
    header = @_createHeader()
    soap.createClient @wsdl, (error, client) ->
      callback error, null if error
      client.addSoapHeader header
      callback null, client

  # @private
  # @overload _createSubscriberList(listId, subscribers)
  #   @param [String] listId
  #   @param [Array] subscribers containing up to 50 email addresses
  #   @return [Object]
  # @overload _createSubscriberList(listId, subscribers)
  #   @param [String] listId
  #   @param [String] subscribers one address
  #   @return [Object]
  _createSubscriberList: (listId, subscribers) ->
    subscriberList =
      ctSubscriberRequest:
        subscriberList: []
    # We support up to 50 subscribers
    if Array.isArray subscribers
      throw new Error 'only 50 addresses allowed in one batch' if subscribers.length > 50
      subscribers.forEach (address) =>
        subscriberList.ctSubscriberRequest.subscriberList.push (@_createSubscriber listId, address)
    else
      # A single subscriber
      subscriberList.ctSubscriberRequest.subscriberList.push (@_createSubscriber listId, subscribers)
    subscriberList

  # Create a subscriber object
  #
  # @private
  # @param [Number] listId
  # @param [String] address
  # @return [Object]
  _createSubscriber: (listId, address) ->
    subscriber =
      listID: listId
      email: address
      customFields: []

  # As soap-js's normal method of adding an object didn't work
  # this is the manual approach which works.
  #
  # @private
  # @return [String]
  _createHeader: ->
    throw new Error 'UserID is missing' if @userid is null
    throw new Error 'ApiKey is missing' if @apikey is null
    throw new Error 'Mode needs to be either live or test' if @mode isnt 'live' and @mode isnt 'test'
    "<#{@namespace}:#{@name}><userid>#{@userid}</userid><apikey>#{@apikey}</apikey><version>#{@version}</version><mode>#{@mode}</mode></#{@namespace}:#{@name}>"
