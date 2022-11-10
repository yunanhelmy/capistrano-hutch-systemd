# frozen_string_literal: true

git_plugin = self

namespace :hutch do
  standard_actions = {
    start: "Start hutch",
    stop: "Stop hutch (graceful shutdown within timeout)",
    status: "Get hutch Status",
    restart: "Restart hutch"
  }
  standard_actions.each do |command, description|
    desc description
    task command do
      on roles fetch(:hutch_roles) do |role|
        git_plugin.switch_user(role) do
          git_plugin.config_files(role).each do |config_file|
            git_plugin.execute_systemd(command, git_plugin.hutch_service_file_name(config_file))
          end
        end
      end
    end
  end

  desc "Quiet hutch (stop fetching new tasks from Redis)"
  task :quiet do
    on roles fetch(:hutch_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.quiet_hutch(role)
      end
    end
  end

  desc "Install hutch systemd service"
  task :install do
    on roles fetch(:hutch_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.create_systemd_template(role)
      end
    end
    invoke "hutch:enable"
  end

  desc "Uninstall hutch systemd service"
  task :uninstall do
    invoke "hutch:disable"
    on roles fetch(:hutch_roles) do |role|
      git_plugin.switch_user(role) do
        git_plugin.rm_systemd_service(role)
      end
    end
  end

  desc "Enable hutch systemd service"
  task :enable do
    on roles(fetch(:hutch_roles)) do |role|
      git_plugin.config_files(role).each do |config_file|
        git_plugin.execute_systemd("enable", git_plugin.hutch_service_file_name(config_file))
      end

      if fetch(:hutch_systemctl_user) && fetch(:hutch_lingering_user)
        execute :loginctl, "enable-linger", fetch(:puma_lingering_user)
      end
    end
  end

  desc "Disable hutch systemd service"
  task :disable do
    on roles(fetch(:hutch_roles)) do |role|
      git_plugin.config_files(role).each do |config_file|
        git_plugin.execute_systemd("disable", git_plugin.hutch_service_file_name(config_file))
      end
    end
  end

  def fetch_systemd_unit_path
    if fetch(:hutch_systemctl_user) == :system
      "/etc/systemd/system/"
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, ".config", "systemd", "user")
    end
  end

  def create_systemd_template(role)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    backend.execute :mkdir, "-p", systemd_path if fetch(:hutch_systemctl_user)

    config_files(role).each do |config_file|
      ctemplate = compiled_template(config_file, use_config_file: fetch(:hutch_use_config_file))
      temp_file_name = File.join("/tmp", "hutch.#{config_file}.service")
      systemd_file_name = File.join(systemd_path, hutch_service_file_name(config_file))
      backend.upload!(StringIO.new(ctemplate), temp_file_name)
      if fetch(:hutch_systemctl_user)
        warn "Moving #{temp_file_name} to #{systemd_file_name}"
        backend.execute :mv, temp_file_name, systemd_file_name
      else
        warn "Installing #{systemd_file_name} as root"
        backend.execute :sudo, :mv, temp_file_name, systemd_file_name
      end
    end
  end

  def rm_systemd_service(role)
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)

    config_files(role).each do |config_file|
      systemd_file_name = File.join(systemd_path, hutch_service_file_name(config_file))
      if fetch(:hutch_systemctl_user)
        warn "Deleting #{systemd_file_name}"
        backend.execute :rm, "-f", systemd_file_name
      else
        warn "Deleting #{systemd_file_name} as root"
        backend.execute :sudo, :rm, "-f", systemd_file_name
      end
    end
  end

  def quiet_hutch(role)
    config_files(role).each do |config_file|
      hutch_service = hutch_service_unit_name(config_file)
      warn "Quieting #{hutch_service}"
      execute_systemd("kill -s TERM", hutch_service)
    end
  end

  def hutch_service_unit_name(config_file)
    if config_file != "hutch.yml"
      "#{fetch(:hutch_service_unit_name)}.#{config_file.split(".")[0..-2].join(".")}"
    else
      fetch(:hutch_service_unit_name)
    end
  end

  def hutch_service_file_name(config_file)
    ## Remove the extension
    config_file = config_file.split(".")[0..].join(".")

    "#{hutch_service_unit_name(config_file)}.service"
  end

  def config_files(role)
    role.properties.fetch(:hutch_config_files) ||
      fetch(:hutch_config_files)
  end
end
