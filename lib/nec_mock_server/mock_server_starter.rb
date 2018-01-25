module NEC
  class MockServerStarter

    RUN_SCRIPT_NAME = 'run.rb'

    ###
    # Create new instance of SubAppUnitTestHelper
    #
    # @param [String] sub_app_dir_path
    # @param [Hash] opts
    # @option opts [String] :run_scrip_name Default is #RUN_SCRIPT_NAME
    # @option opts [Fixnum] :port
    def initialize(sub_app_dir_path, opts = {})
      @path = File.expand_path(sub_app_dir_path, File.dirname(__FILE__))
      @run_scrip_name = opts.fetch(:run_scrip_name) {RUN_SCRIPT_NAME}
      @port = opts[:port]
    end

    ###
    # The method start another sub application by defined path
    # Sub app will be started in new command line with irb
    #
    def run!
      return if @port && already_run?

      create_threat
    end

    ###
    # The method terminate exists thread of sub app
    def stop
      warn('! Method has no function implementation !')
      # fixme how to stop thread with cmd window | some process kill by pid ...
      @thread.terminate if @thread
    end

    private

    def already_run?
      begin
        Net::HTTP.get(URI("http://localhost:#{@port}"))
        return true
      rescue Errno::ECONNREFUSED
        return false
      end
    end

    ###
    # The method create new thread for sub app and start it in new cmd window.
    def create_threat
      stop

      @thread = Thread.new {
        system("cd #{@path} && start irb -I . -r #{@run_scrip_name}")
      }
    end

  end
end