# Cornell University implementation of Blacklight

## ⚙️ Requirements

- Docker
- CUL VPN

## 🚧 Development Setup

1. Clone the GitHub repo
1. Set up your env file in the rails_env/ directory, e.g. at rails_env/.env.dev
    - Contact the Library Systems team for access to environment values
1. Connect to the library VPN
1. Build the blacklight-cornell container image for development: `./build.sh -dr rails_env/YOUR_DEV_ENV_FILE`
   - To rebuild the image without cache: `./build.sh -dnr rails_env/YOUR_DEV_ENV_FILE`
1. Run the docker image: `./run.sh -dr rails_env/YOUR_DEV_ENV_FILE`

The Blacklight instance should be accessible from:

    http://0.0.0.0:9292

Refer to [UI Development](https://github.com/cul-it/blacklight-cornell/wiki/UI-Development) for additional information.

## 🧪 Testing

1. Set up your env file in the rails_env/ directory, e.g. at rails_env/.env.test
    - Contact the Library Systems team for access to environment values
1. Build the test image: `./build_test.sh`
1. Ssh into a running test container: `./run_test.sh -ir rails_env/YOUR_TEST_ENV_FILE`
1. Run tests:
    - cucumber: `./jenkins-opts.sh features/assumptions/assume.feature`
    - rspec: `bundle exec rspec spec/helpers/advanced_helper_spec.rb`

For additional options and a more detailed explanation, refer to [Running Tests](https://github.com/cul-it/blacklight-cornell/wiki/Running-Tests).

## 🤖 MCP Server

A read-only [Model Context Protocol](https://modelcontextprotocol.io) endpoint at
`/mcp` lets an AI assistant search the catalog: eight read-only tools, no login,
rate limited. There is also a browser client for it at `/mcp/console`, that's on in
development.

Three READMEs, depending on what you are doing:

| Description                                                                              | Documentation                                                                                                                           |
|------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| **Using it** — the tools, connecting each assistant, limits, the console                 | [MCP_SERVER_README.md](MCP_SERVER_README.md)                                                                                            |
| **Developing on the MCP server** — the code layout, how a request travels, adding a tool | [app/mcp/BLACKLIGHT_MCP_README.md](blacklight-cornell/app/mcp/BLACKLIGHT_MCP_README.md)                                                 |
| **MCP Console** — its JavaScript code layout                                             | [app/assets/javascripts/mcp/console/MCP_CONSOLE_README.md](blacklight-cornell/app/assets/javascripts/mcp/console/MCP_CONSOLE_README.md) |
