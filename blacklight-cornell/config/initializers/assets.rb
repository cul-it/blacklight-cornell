# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w[ aeon.css aeon.js search_form.js ]

# The MCP pages (/mcp and /mcp/console) render outside the Blacklight layout,
# so their bundle is not reachable from application.css/js. Production sets
# config.assets.compile = false, which means an unlisted asset here is a 500
# on those pages rather than a missing stylesheet.
Rails.application.config.assets.precompile += %w[ mcp.css mcp_console.js ]
