# Make sure it matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
ARG GIT_COMMIT=0.0


################################
# new base with security patch #
################################

FROM ruby:${RUBY_VERSION}-slim-bookworm AS ruby_base

# default-libmysqlclient-dev is required for running the app
#   otherwise, mysql2.so will fail to load

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    default-libmysqlclient-dev=1.1.0 cron && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man && \
    # CVE-2023-36617⁠
    # uri gem version 0.12.1
    # For some reason, if we remove the default version here, it causes gem not found in bundler phase.
    # First let bundler phase run install with this uri gem and use prod_base as base for the final stage which has uri updated to 0.12.2.
    #
    # The blacklight-cornell app uses ostruct-0.5.5 but this base image contains ostruct-0.5.2 as a default gem.
    rm -rf "/usr/local/lib/ruby/gems/3.1.0/specifications/default/ostruct-0.5.2.gemspec" && \
    gem install -v 0.5.5 ostruct


#############
# prod base #
#############

FROM ruby_base AS prod_base

# CVE-2023-36617⁠
RUN gem install -v '0.12.2' uri && \
    rm -rf "/usr/local/lib/ruby/gems/3.1.0/specifications/default/uri-0.12.1.gemspec"


###############
# build stage #
###############

FROM ruby_base AS base_bundler

# How do we pin versions for build-essential & libvips?
# Install libvips for Active Storage preview support & git which is not included in slim base image
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libvips git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man


################
# test bundler #
################

FROM base_bundler AS test_bundler

# Set building environment
ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_ENV="development" \
    BUNDLE_PATH=/usr/local/bundle \
    APP_PATH=/blacklight-cornell

# I had some issue fixing aws-sdk-s3 gem and will not specify version for now.
WORKDIR ${APP_PATH}
COPY ./blacklight-cornell/Gemfile ./blacklight-cornell/Gemfile.lock ./
RUN bundle install
# && gem install aws-sdk-s3

# Copy blacklight-cornell app
COPY ./blacklight-cornell ${APP_PATH}
COPY ./exe/get_env.rb ${APP_PATH}/get_env.rb
COPY ./exe/set_env.sh ${APP_PATH}/set_env.sh
COPY ./exe/puma.sh ${APP_PATH}/puma.sh


######################
# prod bundler stage #
######################

FROM base_bundler AS prod_bundler
ARG RAILS_ENV

ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_ENV=${RAILS_ENV} \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_PATH=/usr/local/bundle \
    APP_PATH=/blacklight-cornell

WORKDIR ${APP_PATH}
COPY ./blacklight-cornell/Gemfile ./blacklight-cornell/Gemfile.lock ./
# I had some issue fixing aws-sdk-s3 gem and will not specify version for now.
RUN bundle config set --local with "${RAILS_ENV}" && \
    bundle config set --local without 'development test' && \
    bundle install && \
    gem install aws-sdk-s3 && \
    rm -rf ${BUNDLE_PATH}/cache/*.gem && \
    find ${BUNDLE_PATH}/ -name "*.c" -delete && \
    find ${BUNDLE_PATH}/ -name "*.o" -delete

COPY ./blacklight-cornell ${APP_PATH}
COPY ./exe/get_env.rb ${APP_PATH}/get_env.rb
COPY ./exe/set_env.sh ${APP_PATH}/set_env.sh
COPY ./exe/puma.sh ${APP_PATH}/puma.sh
COPY ./exe/puma.rb ${APP_PATH}/config/puma.rb
COPY ./.env .env
RUN bundle exec rake assets:precompile && rm .env


##############
# test stage #
##############

FROM ruby_base AS test
ARG GIT_COMMIT

ENV DEBIAN_FRONTEND noninteractive
# It was reported that features/catalog_search/advanced_search.feature fails
#   with libfontconfig.so.1 missing.
#   Does prod code use this library or is it OK to only put it in test image?
# How do we pin versions for build-essential & libvips?
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends vim=2:9.0.1378-2+deb12u2 chromium chromium-driver \
    libcurl4=7.88.1-10+deb12u5 curl=7.88.1-10+deb12u5 libfontconfig1=2.14.1-4 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /src/*.deb && \
    mkdir -p /root/.aws /root/user-data-0 /root/user-data-1 /root/user-data-2 /root/user-data-3 /root/user-data-4

ENV BUNDLE_PATH=/usr/local/bundle \
    APP_PATH=/blacklight-cornell \
    APP_VERSION=${GIT_COMMIT} \
    AWS_DEFAULT_REGION=us-east-1

WORKDIR ${APP_PATH}
COPY --from=test_bundler ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=test_bundler ${APP_PATH} ${APP_PATH}
COPY ./exe/test.sh ${APP_PATH}/test.sh

ENTRYPOINT ["/blacklight-cornell/test.sh"]


###############
# final stage #
###############

FROM prod_base
ARG GIT_COMMIT
ARG RAILS_ENV

# create container runner user to run the app as
ENV RAILS_ENV=${RAILS_ENV} \
    USER=crunner \
    GROUP=crunnergrp \
    APP_VERSION=${GIT_COMMIT} \
    AWS_DEFAULT_REGION=us-east-1 \
    BUNDLE_PATH=/usr/local/bundle \
    APP_PATH=/blacklight-cornell
COPY ./cron/crontab.txt /etc/cron.d/yaml_alert_cron
RUN groupadd -r ${GROUP} && useradd -r -g ${GROUP} ${USER} && \
    mkdir -p /home/crunner/.aws && \
    chown ${USER}:${GROUP} /home/crunner/.aws && \
    crontab -u ${USER} /etc/cron.d/yaml_alert_cron && \
    chmod u+s /usr/sbin/cron && \
    touch /var/log/cron.log

# Copy application code from builder
COPY --from=prod_bundler --chown=${USER}:${GROUP} ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=prod_bundler --chown=${USER}:${GROUP} ${APP_PATH} ${APP_PATH}

USER ${USER}
WORKDIR ${APP_PATH}

# Start the server by default, this can be overwritten at runtime
# expose port 9292 which is default for puma
EXPOSE 9292

# variable expansion doesn't work properly? e.g. CMD ["${APP_PATH}/puma.sh"] doesn't work!
CMD ["/blacklight-cornell/puma.sh"]
