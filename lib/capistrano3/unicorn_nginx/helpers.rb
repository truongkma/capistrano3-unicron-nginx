require "erb"

module Capistrano3
  module UnicornNginx
    module Helpers
      def sudo_upload!(from, to)
        filename = File.basename(to)
        to_dir = File.dirname(to)
        tmp_file = "/tmp/#{filename}"
        upload! from, tmp_file
        sudo :mv, tmp_file, to_dir
      end

      def file_exists?(path)
        test "[ -e #{path} ]"
      end

      def deploy_user
        capture :id, '-un'
      end

      def os_is_ubuntu?
        capture(:cat, "/etc/*-release").include? "ubuntu"
      end

      def nginx_config_file
        if os_is_ubuntu?
          "/etc/nginx/sites-available/#{fetch(:nginx_config_name)}.conf"
        else
          "/etc/nginx/conf.d/#{fetch(:nginx_config_name)}.conf"
        end
      end

      def unicorn_sock_path
        shared_path.join("tmp", "unicorn.sock")
      end

      def unicorn_config_path
        shared_path.join("config", "unicorn.rb")
      end

      def unicorn_pid_path
        shared_path.join("tmp", "pids", "unicorn.pid")
      end

      def unicorn_error_log_file
        shared_path.join("log", "unicorn.stderr.log")
      end

      def unicorn_log_file
        shared_path.join("log", "unicorn.stdout.log")
      end
    end
  end
end
