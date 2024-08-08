desc "Install .env file"
task :install_env do
    on roles(:all) do
        within current_path do
            with rails_env: fetch(:rails_env, :stage) do
#                execute(:cp, "#{deploy_to}/../conf/latest-#{fetch(:rails_env, :stage)}.env", "#{shared_path}/.env")
#                 execute("#{deploy_to}/../conf/deploy_rails_env_to_int.sh")
                 execute("/usr/local/bin/aws", "s3", "cp", "s3://container-discovery/container_env_latest.env", "#{shared_path}/.env")
            end
        end
    end
end
