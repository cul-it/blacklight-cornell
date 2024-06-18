desc "Compile assets on production only"
task :block_precompile do
    on roles(:all) do |host|
        with rails_env: fetch(:rails_env, :stage) do
            if "#{fetch(:rails_env, :stage)}" == 'production'
                # raise "not ready for production"
            else
                Rake::Task["deploy:compile_assets"].clear_actions
                # raise "no compile assets for #{fetch(:rails_env, :stage)}"
             end
        end
    end
end
