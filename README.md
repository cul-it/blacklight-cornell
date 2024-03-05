# Cornell University implementation of Blacklight

<a name="Project structure"/>
<a name="Building docker image"/>
<a name="Running Docker image locally"/>
<a name="Running tests with Docker"/>

## Project structure

```
.
├── blacklight-cornell
├── docker
│   └── bookworm
│       └── Dockerfile
├── docker-compose-cred-development.yaml
├── docker-compose-development.yaml
├── docker-compose-test-interactive.yaml
├── docker-compose-test.yaml
├── docker-compose.yaml
├── exe
│   ├── get_env.rb
│   ├── puma.rb
│   ├── puma.sh
│   ├── set_env.sh
│   └── test.sh
├── rails_env
│   └── test.env.example
├── CHANGELOG.md
├── LICENSE
├── README.md
├── build.sh
├── build_test.sh
├── run.sh
└── run_test.sh
```

## Building Docker image

To run the containerized blacklight-cornell application, you need to have correct remote MySQL information.\
That information can be found at LastPass shared folder `Sahred-Discovery and Access-Library Systems` -> `container-discovery POC admin`.\
**PLEASE USE THE CREDENTIALS UNDER THE NOTES SECTION!**\
If you don't have access to the shared folder, please contact the library systems team.\
**To build and run the application locally, you will need to be in the library VPN**.

    GIT CLONE blacklight-cornell
    cd blacklight-cornell
    ./build.sh -r YOUR_RAILS_ENV_FILE

Above command will build the docker image as container-discovery with the git commit hash as the image tag.\
It is recommended that YOUR_RAILS_ENV_FILE is inside the rails_env directory.\
Git will ignore all files inside that directory.

## Running Docker image locally

To run the Docker image locally, you need to provide a rails .env file.\
You can run the Docker image locally with the following command.

    ./run.sh -r YOUR_RAILS_ENV_FILE

The Blacklight instance should be accessible from:

    http://0.0.0.0:9292

## Running tests with Docker

Testing via Docker will be split into 2 parts - build and run.\
For more detailed explanation on running the tests, refer to [Running Tests](https://github.com/cul-it/blacklight-cornell/wiki/Running-Tests).

    ./build_test.sh

Without any additional arguments at the end of the test run command, it will run all of the tests.\
Optionally, you can specify a specific test at the end.\
At the minimum, you will need a valid SOLR URL in YOUR_RAILS_ENV_FILE for running tests.\
It uses test Sqlite3 and any database setting in the env file will be ignored.\
You can run RSPEC tests by supplying -s flag.

    ./run_test.sh -r
    ./run_test.sh -r YOUR_RAILS_ENV_FILE -f features/assumption/assume.feature
    ./run_test.sh -r YOUR_RAILS_ENV_FILE -f features/catalog_search/item_view.feature
    ./run_test.sh -sr YOUR_RAILS_ENV_FILE
    ./run_test.sh -sr YOUR_RAILS_ENV_FILE -f spec/helpers/advanced_helper_spec.rb
