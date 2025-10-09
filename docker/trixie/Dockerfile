# Make sure it matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.9
ARG GIT_COMMIT=0.0


##################################################################
# new base with essential libraries and potential security patch #
##################################################################

FROM ruby:${RUBY_VERSION}-slim-trixie AS ruby_base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential=12.* \
    cron=3.* default-libmysqlclient-dev=1.1.* git=1:2.47.* \
    libvips42t64=8.16.* pkg-config=1.8.* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man


################
# test bundler #
################

FROM ruby_base AS test_bundler

# Set building environment
ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_ENV="development" \
    BUNDLE_PATH=/usr/local/bundle \
    APP_PATH=/blacklight-cornell

WORKDIR ${APP_PATH}
COPY ./blacklight-cornell/Gemfile ./blacklight-cornell/Gemfile.lock ./
RUN bundle install

# Copy blacklight-cornell app
COPY ./blacklight-cornell ${APP_PATH}
COPY ./exe/get_env.rb ${APP_PATH}/get_env.rb
COPY ./exe/set_env.sh ${APP_PATH}/set_env.sh
COPY ./exe/puma.sh ${APP_PATH}/puma.sh


##########################
# web_app bundler stage #
##########################

FROM ruby_base AS web_app_bundler
ARG RAILS_ENV
ARG BUNDLE_WITHOUT=""

ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_ENV=${RAILS_ENV} \
    BUNDLE_WITHOUT=${BUNDLE_WITHOUT} \
    BUNDLE_PATH=/usr/local/bundle \
    APP_PATH=/blacklight-cornell

WORKDIR ${APP_PATH}
COPY ./blacklight-cornell/Gemfile ./blacklight-cornell/Gemfile.lock ./
COPY ./mount /app
RUN bundle config set --local with "${RAILS_ENV}" && \
    bundle config set --local without "${BUNDLE_WITHOUT}" && \
    bundle install && \
    gem install aws-sdk-s3 -v '~> 1.199' && \
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

ENV DEBIAN_FRONTEND=noninteractive
# It was reported that features/catalog_search/advanced_search.feature fails
#   with libfontconfig.so.1 missing.
#   Does prod code use this library or is it OK to only put it in test image?
# How do we pin versions for build-essential & libvips?
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends vim=2:9.1.* \
    chromium=141.0.* chromium-driver=141.0.* \
    libfontconfig1=2.15.0-2.* && \
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

FROM ruby_base
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
RUN groupadd -r ${GROUP} && useradd -r -g ${GROUP} ${USER} && \
    mkdir -p /home/crunner/.aws && \
    chown -R ${USER}:${GROUP} /home/crunner && \
    chmod gu+rw /var/run && chmod gu+s /usr/sbin/cron && \
    touch /var/log/cron.log

# Copy application code from builder
COPY --from=web_app_bundler --chown=${USER}:${GROUP} ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=web_app_bundler --chown=${USER}:${GROUP} ${APP_PATH} ${APP_PATH}

USER ${USER}
WORKDIR ${APP_PATH}

# Start the server by default, this can be overwritten at runtime
# expose port 9292 which is default for puma
EXPOSE 9292

# variable expansion doesn't work properly? e.g. CMD ["${APP_PATH}/puma.sh"] doesn't work!
CMD ["/blacklight-cornell/puma.sh"]
