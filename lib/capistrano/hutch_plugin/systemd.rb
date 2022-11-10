# frozen_string_literal: true

module Capistrano
  module HutchPlugin
    class Systemd < Capistrano::Plugin
      include HutchCommon
      def define_tasks
        eval_rakefile File.expand_path("../tasks/systemd.rake", __dir__)
      end

      def set_defaults
        set_if_empty :systemctl_bin, "/bin/systemctl"
        set_if_empty :hutch_service_unit_user, :user
        set_if_empty :hutch_systemctl_user, fetch(:hutch_service_unit_user, :user) == :user

        set_if_empty :hutch_service_unit_name, -> { "#{fetch(:application)}_hutch_#{fetch(:stage)}" }
        set_if_empty :hutch_lingering_user, -> { fetch(:lingering_user, fetch(:user)) }

        ## Hutch could have a stripped down or more complex version of the environment variables
        set_if_empty :hutch_service_unit_env_files, -> { fetch(:service_unit_env_files, []) }
        set_if_empty :hutch_service_unit_env_vars, -> { fetch(:service_unit_env_vars, []) }

        set_if_empty :hutch_service_templates_path, fetch(:service_templates_path, "config/deploy/templates")

        set_if_empty :hutch_use_config_file, false
      end

      def systemd_command(*args)
        command = [fetch(:systemctl_bin)]

        command << "--user" unless fetch(:hutch_service_unit_user) == :system

        command + args
      end

      def sudo_if_needed(*command)
        if fetch(:hutch_service_unit_user) == :system
          backend.sudo command.map(&:to_s).join(" ")
        else
          backend.execute(*command)
        end
      end

      def execute_systemd(*args)
        sudo_if_needed(*systemd_command(*args))
      end
    end
  end
end
