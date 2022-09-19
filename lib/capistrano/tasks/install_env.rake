desc "Install .env file"
task :install_env do
    on primary :app do
        within current_path do
            with rails_env: fetch(:rails_env, :stage) do
                execute(:cp, "#{deploy_to}/../conf/latest-#{fetch(:rails_env, :stage)}.env", "#{release_path}/.env")
            end
        end
    end
end
