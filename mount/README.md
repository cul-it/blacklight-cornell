# Running local container with local gems

This documentation will demonstrate how to run two local gems with the local container setup.\
This example will use two local gem projects but any one or more can be used as well.

    cd mount
    git clone git@github.com:cul-it/blacklight-cornell-requests.git
    git clone git@github.com:cul-it/cul-my-account.git
    cd ..

Before building the container image, update the blacklight-cornell/Gemfile.

    gem 'blacklight_cornell_requests', :path => '/app/blacklight-cornell-requests'
    gem 'my_account', :path => '/app/cul-my-account'

After changing the Gemfile, build the container image and run it locally.

    ./build.sh -r rails_env/YOUR_ENV
    ./run.sh -dr rails_env/YOUR_ENV
