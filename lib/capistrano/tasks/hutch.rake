# frozen_string_literal: true

namespace :deploy do
  before :starting, :check_hutch_hooks do
    invoke "hutch:add_default_hooks" if fetch(:hutch_default_hooks)
  end
end

namespace :hutch do
  task :add_default_hooks do
    after "deploy:starting", "hutch:quiet" if Rake::Task.task_defined?("hutch:quiet")
    after "deploy:updated", "hutch:stop"
    after "deploy:published", "hutch:start"
    after "deploy:failed", "hutch:restart"
  end
end
