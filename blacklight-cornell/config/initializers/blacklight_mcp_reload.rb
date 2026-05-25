# Allow MCP code changes to work without server restarts
Rails.application.config.to_prepare do
  BlacklightMcp.reset! if defined?(BlacklightMcp)
end
