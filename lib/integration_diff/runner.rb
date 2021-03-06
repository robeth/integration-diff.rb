require 'time'
require 'json'
require 'integration_diff/run_details'
require 'integration_diff/uploader'
require 'integration_diff/utils'

module IntegrationDiff
  class Runner
    include Capybara::DSL

    def self.instance
      @runner ||= Runner.new(IntegrationDiff.project_name,
                             IntegrationDiff.javascript_driver)
    end

    def initialize(project_name, javascript_driver)
      @project_name = project_name
      @javascript_driver = javascript_driver

      dir = IntegrationDiff::Utils.images_dir
      Dir.mkdir('tmp') unless Dir.exist?('tmp')
      Dir.mkdir(dir) unless Dir.exist?(dir)
    end

    # TODO: Improve error handling here for network timeouts
    def start_run
      draft_run
      @uploader = IntegrationDiff::Uploader.build(@run_id)
    rescue StandardError => e
      IntegrationDiff.logger.fatal e.message
      raise e
    end

    # TODO: Improve error handling here for network timeouts
    def wrap_run
      @uploader.wrapup

      complete_run if @run_id
    rescue StandardError => e
      IntegrationDiff.logger.fatal e.message
      raise e
    end

    def screenshot(identifier)
      screenshot_name = IntegrationDiff::Utils.image_file(identifier)
      page.save_screenshot(screenshot_name, full: true)
      @uploader.enqueue(identifier)
    end

    private

    def draft_run
      run_name = @project_name + "-" + Time.now.iso8601

      details = IntegrationDiff::RunDetails.new.details
      branch = details.branch
      author = details.author
      project = @project_name

      response = connection.post('/api/v1/runs',
                                 name: run_name, project: project, group: branch,
                                 author: author, js_driver: @javascript_driver)

      @run_id = JSON.parse(response.body)["id"]
    end

    def complete_run
      connection.put("/api/v1/runs/#{@run_id}/status", status: "completed")
    end

    def connection
      @connection ||= IntegrationDiff::Utils.connection
    end
  end
end
