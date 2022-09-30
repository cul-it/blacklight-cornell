namespace :apache do
    desc "Restart Apache httpd"
    task :restart_httpd do
        on roles(:web), in: :sequence, wait: 15 do |host|
            info "Restart on #{host}..."
            info "Restarting"
            execute "sudo systemctl reload httpd.service"
            info "Restart finished."
        end
    end
end