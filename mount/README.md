# Running local container with local gems

This documentation will demonstrate how to run two local gems with the local container setup.

    cd mount
    GIT CLONE blacklight-cornell-requests
    GIT CLONE cul-my-account
    cd ..

Before building the container image, update the blacklight-cornell/Gemfile.

    gem 'blacklight_cornell_requests', :path => '/app/blacklight-cornell-requests'
    gem 'my_account', :path => '/app/cul-my-account'

After changing the Gemfile, build the container image and run it locally.

    ./build_local_gems.sh -r rails_env/YOUR_ENV
    ./run_local_gems.sh -dr rails_env/YOUR_ENV
