require 'minitest/autorun'
require 'mocha/setup'
require 'mailgunner'
require 'faux'
require 'json'

class Net::HTTPGenericRequest
  def inspect
    if request_body_permitted?
      "<#{self.class.name} #{path} #{body}>"
    else
      "<#{self.class.name} #{path}>"
    end
  end
end

describe 'Mailgunner::Client' do
  before do
    @domain = 'samples.mailgun.org'

    @api_key = 'xxx'

    @client = Mailgunner::Client.new(domain: @domain, api_key: @api_key)

    @address = 'user@example.com'

    @encoded_address = 'user%40example.com'
  end

  def expect(request_class, arg)
    matcher = String === arg ? responds_with(:path, arg) : arg

    @client.http.expects(:request).with(all_of(instance_of(request_class), matcher)).returns(stub)
  end

  describe 'http method' do
    it 'returns a net http object that uses ssl' do
      @client.http.must_be_instance_of(Net::HTTP)

      @client.http.use_ssl?.must_equal(true)
    end
  end

  describe 'domain method' do
    it 'returns the value passed to the constructor' do
      @client.domain.must_equal(@domain)
    end

    it 'defaults to the domain in the MAILGUN_SMTP_LOGIN environment variable' do
      ENV['MAILGUN_SMTP_LOGIN'] = 'postmaster@samples.mailgun.org'

      Mailgunner::Client.new(api_key: @api_key).domain.must_equal(@domain)
    end
  end

  describe 'api_key method' do
    it 'returns the value passed to the constructor' do
      @client.api_key.must_equal(@api_key)
    end

    it 'defaults to the value of MAILGUN_API_KEY environment variable' do
      ENV['MAILGUN_API_KEY'] = @api_key

      Mailgunner::Client.new(domain: @domain).api_key.must_equal(@api_key)
    end
  end

  describe 'validate_address method' do
    it 'calls the address validate resource with the given email address and returns a response object' do
      expect(Net::HTTP::Get, "/v2/address/validate?address=#{@encoded_address}")

      @client.validate_address(@address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'parse_addresses method' do
    it 'calls the address parse resource with the given email addresses and returns a response object' do
      expect(Net::HTTP::Get, "/v2/address/parse?addresses=bob%40example.com%2Ceve%40example.com")

      @client.parse_addresses(['bob@example.com', 'eve@example.com']).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'send_message method' do
    it 'posts to the domain messages resource and returns a response object' do
      expect(Net::HTTP::Post, "/v2/#@domain/messages")

      @client.send_message({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the message attributes' do
      expect(Net::HTTP::Post, responds_with(:body, "to=#@encoded_address"))

      @client.add_domain({to: @address})
    end

    it 'encodes the message attributes as multipart form data when sending attachments' do
      # TODO
    end
  end

  describe 'get_domains method' do
    it 'fetches the domains resource and returns a response object' do
      expect(Net::HTTP::Get, '/v2/domains')

      @client.get_domains.must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'get_domain method' do
    it 'fetches the domain resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/domains/#@domain")

      @client.get_domain(@domain).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_domain method' do
    it 'posts to the domains resource and returns a response object' do
      expect(Net::HTTP::Post, '/v2/domains')

      @client.add_domain({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the domain attributes' do
      expect(Net::HTTP::Post, responds_with(:body, "name=#@domain"))

      @client.add_domain({name: @domain})
    end
  end

  describe 'get_unsubscribes method' do
    it 'fetches the domain unsubscribes resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/unsubscribes")

      @client.get_unsubscribes.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/unsubscribes?skip=1&limit=2")

      @client.get_unsubscribes(skip: 1, limit: 2)
    end
  end

  describe 'get_unsubscribe method' do
    it 'fetches the unsubscribe resource with the given address and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/unsubscribes/#@encoded_address")

      @client.get_unsubscribe(@address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'delete_unsubscribe method' do
    it 'deletes the domain unsubscribe resource with the given address and returns a response object' do
      expect(Net::HTTP::Delete, "/v2/#@domain/unsubscribes/#@encoded_address")

      @client.delete_unsubscribe(@address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_unsubscribe method' do
    it 'posts to the domain unsubscribes resource and returns a response object' do
      expect(Net::HTTP::Post, "/v2/#@domain/unsubscribes")

      @client.add_unsubscribe({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the unsubscribe attributes' do
      expect(Net::HTTP::Post, responds_with(:body, "address=#@encoded_address"))

      @client.add_unsubscribe({address: @address})
    end
  end

  describe 'get_complaints method' do
    it 'fetches the domain complaints resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/complaints")

      @client.get_complaints.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/complaints?skip=1&limit=2")

      @client.get_complaints(skip: 1, limit: 2)
    end
  end

  describe 'get_complaint method' do
    it 'fetches the complaint resource with the given address and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/complaints/#@encoded_address")

      @client.get_complaint(@address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_complaint method' do
    it 'posts to the domain complaints resource and returns a response object' do
      expect(Net::HTTP::Post, "/v2/#@domain/complaints")

      @client.add_complaint({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the complaint attributes' do
      expect(Net::HTTP::Post, responds_with(:body, "address=#@encoded_address"))

      @client.add_complaint({address: @address})
    end
  end

  describe 'delete_complaint method' do
    it 'deletes the domain complaint resource with the given address and returns a response object' do
      expect(Net::HTTP::Delete, "/v2/#@domain/complaints/#@encoded_address")

      @client.delete_complaint(@address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'get_bounces method' do
    it 'fetches the domain bounces resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/bounces")

      @client.get_bounces.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/bounces?skip=1&limit=2")

      @client.get_bounces(skip: 1, limit: 2)
    end
  end

  describe 'get_bounce method' do
    it 'fetches the bounce resource with the given address and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/bounces/#@encoded_address")

      @client.get_bounce(@address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_bounce method' do
    it 'posts to the domain bounces resource and returns a response object' do
      expect(Net::HTTP::Post, "/v2/#@domain/bounces")

      @client.add_bounce({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the bounce attributes' do
      expect(Net::HTTP::Post, responds_with(:body, "address=#@encoded_address"))

      @client.add_bounce({address: @address})
    end
  end

  describe 'delete_bounce method' do
    it 'deletes the domain bounce resource with the given address and returns a response object' do
      expect(Net::HTTP::Delete, "/v2/#@domain/bounces/#@encoded_address")

      @client.delete_bounce(@address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'get_stats method' do
    it 'fetches the domain stats resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/stats")

      @client.get_stats.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/stats?skip=1&limit=2")

      @client.get_stats(skip: 1, limit: 2)
    end

    it 'encodes an event parameter with multiple values' do
      expect(Net::HTTP::Get, "/v2/#@domain/stats?event=sent&event=opened")

      @client.get_stats(event: %w(sent opened))
    end
  end

  describe 'get_log method' do
    before do
      Kernel.stubs(:warn)
    end

    it 'fetches the domain log resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/log")

      @client.get_log.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/log?skip=1&limit=2")

      @client.get_log(skip: 1, limit: 2)
    end

    it 'emits a deprecation warning' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#get_log is deprecated/))

      @client.http.stubs(:request)

      @client.get_log
    end
  end

  describe 'get_events method' do
    it 'fetches the domain events resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/events")

      @client.get_events.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes optional parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/events?event=accepted&limit=10")

      @client.get_events(event: 'accepted', limit: 10)
    end
  end

  describe 'get_routes method' do
    it 'fetches the global routes resource and returns a response object' do
      expect(Net::HTTP::Get, '/v2/routes')

      @client.get_routes.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, '/v2/routes?skip=1&limit=2')

      @client.get_routes(skip: 1, limit: 2)
    end
  end

  describe 'get_route method' do
    it 'fetches the route resource with the given id and returns a response object' do
      expect(Net::HTTP::Get, '/v2/routes/4f3bad2335335426750048c6')

      @client.get_route('4f3bad2335335426750048c6').must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_route method' do
    it 'posts to the routes resource and returns a response object' do
      expect(Net::HTTP::Post, '/v2/routes')

      @client.add_route({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the route attributes' do
      expect(Net::HTTP::Post, responds_with(:body, 'description=Example+route&priority=1'))

      @client.add_route({description: 'Example route', priority: 1})
    end
  end

  describe 'update_route method' do
    it 'updates the route resource with the given id and returns a response object' do
      expect(Net::HTTP::Put, '/v2/routes/4f3bad2335335426750048c6')

      @client.update_route('4f3bad2335335426750048c6', {}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the route attributes' do
      expect(Net::HTTP::Put, responds_with(:body, 'priority=10'))

      @client.update_route('4f3bad2335335426750048c6', {priority: 10})
    end
  end

  describe 'delete_route method' do
    it 'deletes the route resource with the given id and returns a response object' do
      expect(Net::HTTP::Delete, '/v2/routes/4f3bad2335335426750048c6')

      @client.delete_route('4f3bad2335335426750048c6').must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'get_mailboxes method' do
    before do
      Kernel.stubs(:warn)
    end

    it 'fetches the domain mailboxes resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/mailboxes")

      @client.get_mailboxes.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/mailboxes?skip=1&limit=2")

      @client.get_mailboxes(skip: 1, limit: 2)
    end

    it 'emits a deprecation warning' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#get_mailboxes is deprecated/))

      @client.http.stubs(:request)

      @client.get_mailboxes
    end
  end

  describe 'add_mailbox method' do
    before do
      Kernel.stubs(:warn)
    end

    it 'posts to the domain mailboxes resource and returns a response object' do
      expect(Net::HTTP::Post, "/v2/#@domain/mailboxes")

      @client.add_mailbox({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the mailbox attributes' do
      expect(Net::HTTP::Post, responds_with(:body, 'mailbox=user'))

      @client.add_mailbox({mailbox: 'user'})
    end

    it 'emits a deprecation warning' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#add_mailbox is deprecated/))

      @client.http.stubs(:request)

      @client.add_mailbox({})
    end
  end

  describe 'update_mailbox method' do
    before do
      Kernel.stubs(:warn)
    end

    it 'updates the mailbox resource and returns a response object' do
      expect(Net::HTTP::Put, "/v2/#@domain/mailboxes/user")

      @client.update_mailbox('user', {}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the mailbox attributes' do
      expect(Net::HTTP::Put, responds_with(:body, 'password=secret'))

      @client.update_mailbox('user', {password: 'secret'})
    end

    it 'emits a deprecation warning' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#update_mailbox is deprecated/))

      @client.http.stubs(:request)

      @client.update_mailbox('user', {})
    end
  end

  describe 'delete_mailbox method' do
    before do
      Kernel.stubs(:warn)
    end

    it 'deletes the domain mailbox resource with the given address and returns a response object' do
      expect(Net::HTTP::Delete, "/v2/#@domain/mailboxes/user")

      @client.delete_mailbox('user').must_be_instance_of(Mailgunner::Response)
    end

    it 'emits a deprecation warning' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#delete_mailbox is deprecated/))

      @client.http.stubs(:request)

      @client.delete_mailbox('user')
    end
  end

  describe 'get_campaigns method' do
    it 'fetches the domain campaigns resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns")

      @client.get_campaigns.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns?skip=1&limit=2")

      @client.get_campaigns(skip: 1, limit: 2)
    end
  end

  describe 'get_campaign method' do
    it 'fetches the campaign resource with the given id and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id")

      @client.get_campaign('id').must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_campaign method' do
    it 'posts to the domain campaigns resource and returns a response object' do
      expect(Net::HTTP::Post, "/v2/#@domain/campaigns")

      @client.add_campaign({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the campaign attributes' do
      expect(Net::HTTP::Post, responds_with(:body, 'id=id'))

      @client.add_campaign({id: 'id'})
    end
  end

  describe 'update_campaign method' do
    it 'updates the campaign resource and returns a response object' do
      expect(Net::HTTP::Put, "/v2/#@domain/campaigns/id")

      @client.update_campaign('id', {}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the campaign attributes' do
      expect(Net::HTTP::Put, responds_with(:body, 'name=Example+Campaign'))

      @client.update_campaign('id', {name: 'Example Campaign'})
    end
  end

  describe 'delete_campaign method' do
    it 'deletes the domain campaign resource with the given id and returns a response object' do
      expect(Net::HTTP::Delete, "/v2/#@domain/campaigns/id")

      @client.delete_campaign('id').must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'get_campaign_events method' do
    it 'fetches the domain campaign events resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/events")

      @client.get_campaign_events('id').must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the optional parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/events?country=US&limit=100")

      @client.get_campaign_events('id', country: 'US', limit: 100)
    end
  end

  describe 'get_campaign_stats method' do
    it 'fetches the domain campaign stats resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/stats")

      @client.get_campaign_stats('id').must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the optional parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/stats?groupby=dailyhour")

      @client.get_campaign_stats('id', groupby: 'dailyhour')
    end
  end

  describe 'get_campaign_clicks method' do
    it 'fetches the domain campaign clicks resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/clicks")

      @client.get_campaign_clicks('id').must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the optional parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/clicks?groupby=month&limit=100")

      @client.get_campaign_clicks('id', groupby: 'month', limit: 100)
    end
  end

  describe 'get_campaign_opens method' do
    it 'fetches the domain campaign opens resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/opens")

      @client.get_campaign_opens('id').must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the optional parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/opens?groupby=month&limit=100")

      @client.get_campaign_opens('id', groupby: 'month', limit: 100)
    end
  end

  describe 'get_campaign_unsubscribes method' do
    it 'fetches the domain campaign unsubscribes resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/unsubscribes")

      @client.get_campaign_unsubscribes('id').must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the optional parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/unsubscribes?groupby=month&limit=100")

      @client.get_campaign_unsubscribes('id', groupby: 'month', limit: 100)
    end
  end

  describe 'get_campaign_complaints method' do
    it 'fetches the domain campaign complaints resource and returns a response object' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/complaints")

      @client.get_campaign_complaints('id').must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the optional parameters' do
      expect(Net::HTTP::Get, "/v2/#@domain/campaigns/id/complaints?groupby=month&limit=100")

      @client.get_campaign_complaints('id', groupby: 'month', limit: 100)
    end
  end

  describe 'get_lists method' do
    it 'fetches the domain lists resource and returns a response object' do
      expect(Net::HTTP::Get, '/v2/lists')

      @client.get_lists.must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, '/v2/lists?skip=1&limit=2')

      @client.get_lists(skip: 1, limit: 2)
    end
  end

  describe 'get_list method' do
    it 'fetches the list resource with the given address and returns a response object' do
      expect(Net::HTTP::Get, '/v2/lists/developers%40mailgun.net')

      @client.get_list('developers@mailgun.net').must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_list method' do
    it 'posts to the domain lists resource and returns a response object' do
      expect(Net::HTTP::Post, '/v2/lists')

      @client.add_list({}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the list attributes' do
      expect(Net::HTTP::Post, responds_with(:body, 'address=developers%40mailgun.net'))

      @client.add_list({address: 'developers@mailgun.net'})
    end
  end

  describe 'update_list method' do
    it 'updates the list resource and returns a response object' do
      expect(Net::HTTP::Put, '/v2/lists/developers%40mailgun.net')

      @client.update_list('developers@mailgun.net', {}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the list attributes' do
      expect(Net::HTTP::Put, responds_with(:body, 'name=Example+list'))

      @client.update_list('developers@mailgun.net', {name: 'Example list'})
    end
  end

  describe 'delete_list method' do
    it 'deletes the domain list resource with the given address and returns a response object' do
      expect(Net::HTTP::Delete, '/v2/lists/developers%40mailgun.net')

      @client.delete_list('developers@mailgun.net').must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'get_list_members method' do
    it 'fetches the list members resource and returns a response object' do
      expect(Net::HTTP::Get, '/v2/lists/developers%40mailgun.net/members')

      @client.get_list_members('developers@mailgun.net').must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes skip and limit parameters' do
      expect(Net::HTTP::Get, '/v2/lists/developers%40mailgun.net/members?skip=1&limit=2')

      @client.get_list_members('developers@mailgun.net', skip: 1, limit: 2)
    end
  end

  describe 'get_list_member method' do
    it 'fetches the list member resource with the given address and returns a response object' do
      expect(Net::HTTP::Get, "/v2/lists/developers%40mailgun.net/members/#@encoded_address")

      @client.get_list_member('developers@mailgun.net', @address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'add_list_member method' do
    it 'posts to the list members resource and returns a response object' do
      expect(Net::HTTP::Post, '/v2/lists/developers%40mailgun.net/members')

      @client.add_list_member('developers@mailgun.net', {}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the list attributes' do
      expect(Net::HTTP::Post, responds_with(:body, "address=#@encoded_address"))

      @client.add_list_member('developers@mailgun.net', {address: @address})
    end
  end

  describe 'update_list_member method' do
    it 'updates the list member resource with the given address and returns a response object' do
      expect(Net::HTTP::Put, "/v2/lists/developers%40mailgun.net/members/#@encoded_address")

      @client.update_list_member('developers@mailgun.net', @address, {}).must_be_instance_of(Mailgunner::Response)
    end

    it 'encodes the list member attributes' do
      expect(Net::HTTP::Put, responds_with(:body, 'subscribed=no'))

      @client.update_list_member('developers@mailgun.net', @address, {subscribed: 'no'})
    end
  end

  describe 'delete_list_member method' do
    it 'deletes the list member resource with the given address and returns a response object' do
      expect(Net::HTTP::Delete, "/v2/lists/developers%40mailgun.net/members/#@encoded_address")

      @client.delete_list_member('developers@mailgun.net', @address).must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'get_list_stats method' do
    it 'fetches the list stats resource and returns a response object' do
      expect(Net::HTTP::Get, '/v2/lists/developers%40mailgun.net/stats')

      @client.get_list_stats('developers@mailgun.net').must_be_instance_of(Mailgunner::Response)
    end
  end

  describe 'json method' do
    it 'emits a deprecation warning and returns the standard library json module' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#json is deprecated/))

      Mailgunner::Client.new.json.must_equal(JSON)
    end
  end

  describe 'json equals method' do
    it 'emits a deprecation warning' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#json= is deprecated/))

      Mailgunner::Client.new.json = nil
    end
  end

  describe 'when initialized with a different json implementation' do
    it 'emits a deprecation warning' do
      Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client :json option is deprecated/))

      Mailgunner::Client.new(domain: @domain, api_key: @api_key, json: stub)
    end

    describe 'json method' do
      it 'emits a deprecation warning and returns the value passed to the constructor' do
        json = stub

        Kernel.expects(:warn).once
        Kernel.expects(:warn).with(regexp_matches(/Mailgunner::Client#json is deprecated/))

        Mailgunner::Client.new(json: json).json.must_equal(json)
      end
    end
  end
end

describe 'Mailgunner::Response' do
  before do
    @http_response = mock()

    @response = Mailgunner::Response.new(@http_response)
  end

  it 'delegates missing methods to the http response object' do
    @http_response.stubs(:code).returns('200')

    @response.code.must_equal('200')
  end

  describe 'ok query method' do
    it 'returns true if the status code is 200' do
      @http_response.expects(:code).returns('200')

      @response.ok?.must_equal(true)
    end

    it 'returns false otherwise' do
      @http_response.expects(:code).returns('400')

      @response.ok?.must_equal(false)
    end
  end

  describe 'client_error query method' do
    it 'returns true if the status code is 4xx' do
      @http_response.stubs(:code).returns(%w(400 401 402 404).sample)

      @response.client_error?.must_equal(true)
    end

    it 'returns false otherwise' do
      @http_response.stubs(:code).returns('200')

      @response.client_error?.must_equal(false)
    end
  end

  describe 'server_error query method' do
    it 'returns true if the status code is 5xx' do
      @http_response.stubs(:code).returns(%w(500 502 503 504).sample)

      @response.server_error?.must_equal(true)
    end

    it 'returns false otherwise' do
      @http_response.stubs(:code).returns('200')

      @response.server_error?.must_equal(false)
    end
  end

  describe 'json query method' do
    it 'returns true if the response has a json content type' do
      @http_response.expects(:[]).with('Content-Type').returns('application/json;charset=utf-8')

      @response.json?.must_equal(true)
    end

    it 'returns false otherwise' do
      @http_response.expects(:[]).with('Content-Type').returns('text/html')

      @response.json?.must_equal(false)
    end
  end

  describe 'object method' do
    it 'decodes the response body as json and returns a hash' do
      @http_response.expects(:body).returns('{"foo":"bar"}')

      @response.object.must_equal({'foo' => 'bar'})
    end
  end
end

describe 'Mailgunner::Response initialized with an alternative json implementation' do
  before do
    @json = faux(JSON)

    @http_response = stub

    @response = Mailgunner::Response.new(@http_response, :json => @json)
  end

  describe 'object method' do
    it 'uses the alternative json implementation to parse the response body' do
      @http_response.stubs(:body).returns(response_body = '{"foo":"bar"}')

      @json.expects(:parse).with(response_body)

      @response.object
    end
  end
end
