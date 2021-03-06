require 'capistrano3/unicorn_nginx/helpers'
include Capistrano3::UnicornNginx::Helpers

namespace :load do
  task :defaults do
    set :unicorn_service, -> { "unicorn_#{fetch(:application)}" }
    set :user_home_path, -> { "/home/#{fetch(:user)}" }
    set :unicorn_config_path, -> { unicorn_config_path }
    set :unicorn_pid_path, -> { unicorn_pid_path }
    set :unicorn_sock_path, -> { unicorn_sock_path }
    set :unicorn_stdout_path, -> { unicorn_log_file }
    set :unicorn_stderr_path, -> { unicorn_error_log_file }
    set :unicorn_roles, -> { :app }
    set :unicorn_restart_sleep_time, 3
    set :unicorn_options, -> { '' }
    set :unicorn_env, -> { fetch(:rails_env) || 'deployment' }
    set :ruby_version, -> { fetch(:rvm_ruby_version) || fetch(:rbenv_ruby) }
    set :unicorn_worker_processes, 2
    set :unicorn_timeout, 30

    set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids')
  end
end

namespace :unicorn do
  desc "Start Unicorn"
  task :start do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        if test("[ -e #{fetch(:unicorn_pid_path)} ] && kill -0 #{pid}")
          info "unicorn is running..."
        else
          with rails_env: fetch(:rails_env) do
            execute :bundle, "exec unicorn", "-c", fetch(:unicorn_config_path), "-E", fetch(:unicorn_env), "-D", fetch(:unicorn_options)
          end
        end
      end
    end
  end

  desc "Stop Unicorn (QUIT)"
  task :stop do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        if test("[ -e #{fetch(:unicorn_pid_path)} ]")
          if test("kill -0 #{pid}")
            info "stopping unicorn..."
            execute :kill, "-s QUIT", pid
          else
            info "cleaning up dead unicorn pid..."
            execute :rm, fetch(:unicorn_pid_path)
          end
        else
          info "unicorn is not running..."
        end
      end
    end
  end

  desc "Reload Unicorn (HUP); use this when preload_app: false"
  task :reload do
    invoke "unicorn:start"
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "reloading..."
        execute :kill, "-s HUP", pid
      end
    end
  end

  desc "Restart Unicorn (USR2); use this when preload_app: true"
  task :restart do
    invoke "unicorn:start"
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "unicorn restarting..."
        execute :kill, "-s USR2", pid
      end
    end
  end

  desc "Duplicate Unicorn; alias of unicorn:restart"
  task :duplicate do
    invoke "unicorn:restart"
  end

  desc "Legacy Restart (USR2 + QUIT); use this when preload_app: true and oldbin pid needs cleanup"
  task :legacy_restart do
    invoke "unicorn:restart"
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        execute :sleep, fetch(:unicorn_restart_sleep_time)
        if test("[ -e #{fetch(:unicorn_pid_path)}.oldbin ]")
          execute :kill, "-s QUIT", pid_oldbin
        end
      end
    end
  end

  desc "Add a worker (TTIN)"
  task :add_worker do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "adding worker"
        execute :kill, "-s TTIN", pid
      end
    end
  end

  desc "Remove a worker (TTOU)"
  task :remove_worker do
    on roles(fetch(:unicorn_roles)) do
      within current_path do
        info "removing worker"
        execute :kill, "-s TTOU", pid
      end
    end
  end

  desc "Unicorn generate config file"
  task :init_config do
    on roles(fetch(:unicorn_roles)) do
      execute(:mkdir, '-pv', File.dirname(fetch(:unicorn_config_path))) unless file_exists?(fetch(:unicorn_config_file))
      upload! template('unicorn.rb.erb'), fetch(:unicorn_config_path)
    end
  end
end

def pid
  "`cat #{fetch(:unicorn_pid_path)}`"
end

def pid_oldbin
  "`cat #{fetch(:unicorn_pid_path)}.oldbin`"
end
