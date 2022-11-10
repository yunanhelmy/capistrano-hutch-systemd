# frozen_string_literal: true

require "capistrano/bundler"
require "capistrano/plugin"

module Capistrano
  module HutchCommon
    def compiled_template(config_file = "hutch.yml", use_config_file: false)
      @use_config_file = use_config_file
      @config_file = config_file
      local_template_directory = fetch(:hutch_service_templates_path)
      search_paths = [
        File.join(local_template_directory, "hutch.service.capistrano.erb"),
        File.expand_path(
          File.join(*%w[.. templates hutch.service.capistrano.erb]),
          __FILE__
        )
      ]
      template_path = search_paths.detect { |path| File.file?(path) }
      template = File.read(template_path)
      ERB.new(template, trim_mode: "-").result(binding)
    end

    def expanded_bundle_path
      backend.capture(:echo, SSHKit.config.command_map[:bundle]).strip
    end

    def hutch_config
      "--config config/#{@config_file}" if @use_config_file
    end

    def hutch_systemd_env
      "RAILS_ENV=#{fetch(:hutch_env)}"
    end

    def switch_user(role, &block)
      su_user = hutch_user(role)
      if su_user == role.user
        yield
      else
        as su_user, &block
      end
    end

    def hutch_user(role = nil)
      if role.nil?
        fetch(:hutch_user)
      else
        properties = role.properties
        properties.fetch(:hutch_user) || # local property for hutch only
          fetch(:hutch_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
      end
    end
  end

  class Hutch < Capistrano::Plugin
    def define_tasks
      eval_rakefile File.expand_path("tasks/hutch.rake", __dir__)
    end

    def set_defaults
      set_if_empty :hutch_default_hooks, true

      set_if_empty :hutch_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:rake_env, fetch(:stage)))) }
      set_if_empty :hutch_roles, fetch(:hutch_role, :app)
      set_if_empty :hutch_configs, %w[hutch] # hutch.yml

      set_if_empty :hutch_log, -> { File.join(shared_path, "log", "hutch.log") }
      set_if_empty :hutch_error_log, -> { File.join(shared_path, "log", "hutch.log") }

      set_if_empty :hutch_config_files, ["hutch.yml"]

      # Rbenv, Chruby, and RVM integration
      append :rbenv_map_bins, "hutch", "hutchctl"
      append :rvm_map_bins, "hutch", "hutchctl"
      append :chruby_map_bins, "hutch", "hutchctl"
      # Bundler integration
      append :bundle_bins, "hutch", "hutchctl"
    end
  end

  module HutchPlugin
  end
end

require_relative "hutch_plugin/systemd"
