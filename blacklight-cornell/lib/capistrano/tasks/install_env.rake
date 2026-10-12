desc "Install .env file"
task :install_env do
    on roles(:all) do
        within current_path do
            with rails_env: fetch(:rails_env, :stage) do
                execute("/usr/local/bin/aws", "s3", "cp", "s3://container-discovery/container_env_latest", "#{shared_path}/.env")
            end
        end
    end
end
