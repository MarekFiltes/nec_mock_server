module NEC

  ###
  # Module of Mock Server
  module MockServer

    ###
    # Server class. Represent main class of module #MockServe
    class Server

      attr_reader :router, :app

      ###
      # The method creates new instance of Rack::Server
      #
      # @param [MockServer::Router] router
      # @param [Hash] application_opts
      # @option application_opts [String] :application_name
      # @option opts [Regexp] :matcher Define how to split parts of all request URL. Default is to #MATCHERS[:base]
      # @option opts [Boolean] :only_registered_awid If set to true all requests that wasn't call on registered awid (by sys/iniAppWorkspace) will be rejected
      # @option opts [Hash{TID => Array<AWID>}] :awids
      # @option opts [Hash{TID => Array<ASIDS>}] :asids
      def initialize(router, application_opts = {})
        @router = (router || Router).new(application_opts[:application_name])
        @app = Application.new(@router, application_opts)
      end

      ###
      # The method stars server of instance
      #
      # @param [Numeric] port
      # @param [String] host Default to 'localhost'
      def run!(port, host = 'localhost')
        @server = Rack::Server.start(app: @app, Port: port, Host: host)
      end
    end

    ###
    # Class represent trivial application to handle requests by defined router.
    class Application

      MATCHERS = {
          base: /:\d+(\/(?<product>[\-\w]+)){0,1}(\/(?<tid>\w+)\-(?<awid>\w+)){0,1}(?<resource>(\/\w+)+)(\?(?<parameters>.*)){0,1}/
      }

      REGISTER_AWID_RESOURCE = '/sys/initAppWorkspace'

      attr_reader :awids, :asids

      ###
      # The method create new instance of Application
      #
      # @param [MockServer::Router] router
      # @param [Hash] opts
      # @option opts [Regexp] :matcher Define how to split parts of all request URL. Default is to #MATCHERS[:base]
      # @option opts [Boolean] :only_registered_awid If set to true all requests that wasn't call on registered awid (by sys/iniAppWorkspace) will be rejected
      # @option opts [Hash{TID => Array<AWID>}] :awids
      # @option opts [Hash{TID => Array<ASIDS>}] :asids
      def initialize(router, opts = {})
        @router = router
        @only_registered_awid = opts[:only_registered_awid]
        @url_parts_matcher = opts.fetch(:matcher) {MATCHERS[:base]}
        @awids = opts.fetch(:awids){ {} }
        @asids = opts.fetch(:asids){ {} }
      end

      ###
      # The method prepare request and process request
      #
      # @param [Hash] env
      def call(env)
        request = Rack::Request.new(env)
        serve_request(request)
      end

      ###
      # The method handle received request.
      #
      # @param [Rack::Request] request
      def serve_request(request)
        parts = get_url_parts(request.url)

        begin
          io = request.body
          data = io.read
        ensure
          io.close if io && io.respond_to?(:close) && io.respond_to?(:closed?) && !io.closed?
        end

        if parts[:resource] && parts[:resource] == REGISTER_AWID_RESOURCE
          process_sys_init_app_workspace(parts, data)
        end

        if @only_registered_awid
          return @router.no_registered_awid(parts[:tid], parts[:awid]) unless is_registered_resource?(parts[:tid], parts[:awid])
        end

        @router.route(parts, data)
      end

      private

      def is_registered_awid?(tid, awid)
        @awids[tid] && !(@awids[tid] & [awid]).empty?
      end

      def is_registered_asid?(tid, asid)
        @awids[tid] && !(asids[tid] & [asid]).empty?
      end

      def is_registered_resource?(tid, awid)
        is_registered_awid?(tid, awid) || is_registered_asid?(tid, awid)
      end

      def process_sys_init_app_workspace(parts, data)
        hash = data.is_a?(Hash) ? data : JSON.parse(data.to_s, symbolize_names: true)

        @awids[parts[:tid]] ||= []
        @awids[parts[:tid]] << hash[:awid] if (@awids[parts[:tid]] & [hash[:awid]]).empty?

        @asids[parts[:tid]] ||= []
        @asids[parts[:tid]] << parts[:awid] if (@awids[parts[:tid]] & [parts[:awid]]).empty?

        nil
      end

      ###
      # The method helps to parse request url
      def get_url_parts(path)
        result = path.match(@url_parts_matcher)
        result ? result.names.map {|name| name.to_sym}.zip(result.captures).to_h : {resource: ''}
      end
    end

    ###
    # Class represents all routes that application can served.
    # For customize own mock application is necessary to create own router class by inheritance of this class
    class Router

      DEFAULT_APPLICATION_NAME = "Mock Server"

      CONTENT_TYPES = {
          text: {
              plain: "text/plain"
          },
          application: {
              json: "application/json"
          }
      }

      DEFAULT_HEADER = {"Content-Type" => CONTENT_TYPES[:text][:plain]}
      JSON_HEADER = {"Content-Type" => CONTENT_TYPES[:application][:json]}

      ###
      # The method create new instance of router
      #
      # @param [String] application_name
      def initialize(application_name)
        @application_name = application_name || DEFAULT_APPLICATION_NAME
      end

      ###
      # The method process all operation on defined request URL and return response data
      #
      # @param [Hash] parts All parts find by specified matcher of URL request
      # @param [String] request_data Received data by request
      def route(parts, request_data)
        case parts[:resource]
          when "/", ""
            home
          when "/error"
            error("Application exception")
          else
            not_found(parts[:resource])
        end
      end

      ###
      # The method represent default home route on "/" or ""
      # Return 200 OK a and #application_name
      def home
        ok(@application_name)
      end

      ###
      # The method represent base success response, 200 OK
      #
      # @param [Object] body Body of response
      # @param [Hash] headers Headers of response
      #
      # @return [Array] response_data
      def ok(body = nil, headers = DEFAULT_HEADER)
        prepare_response_data(200, headers, body)
      end

      ###
      # The method represent base not found response, 404 Not Found
      #
      # @param [String] resource Resource is required route part, which was no defined.
      #
      # @return [Array] response_data
      def not_found(resource)
        prepare_response_data(404, DEFAULT_HEADER, "Undefined Mock Server resource '#{resource}' for #{@application_name}")
      end

      ###
      # The method represent specific not found response for request on no registered pair tid-awid
      #
      # @param [String] tid
      # @param [String] awid
      def no_registered_awid(tid, awid)
        prepare_response_data(404, DEFAULT_HEADER, "Mock Server has no registered TID-AWID '#{tid}-#{awid}' for #{@application_name}")
      end

      ###
      # The method represent base server error response, 500 Internal Server Error
      #
      # @param [Object] body Body of response
      # @param [Hash] headers Headers of response
      #
      # @return [Array] response_data
      def error(body, headers = DEFAULT_HEADER)
        prepare_response_data(500, headers, body)
      end

      private

      ###
      # The method prepare response data as Array
      #
      # @param [String] http_code
      # @param [Hash] headers
      # @param [Object] body
      #
      # @param [Array] response_data
      def prepare_response_data(http_code, headers, body)
        body = body.nil? ? '' : body
        body = body.to_json if body.is_a?(Hash)
        body = body.to_s unless body.is_a?(String)

        [http_code, headers.nil? ? DEFAULT_HEADER : headers, [body]]
      end
    end


  end

end