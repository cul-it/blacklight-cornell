#!/bin/bash
/bin/date
source /usr/local/rvm/scripts/rvm

# new for containerized version ...
cd "${WORKSPACE}/blacklight-cornell"
# ... end new

echo "BRANCH: ${BRANCH}"

#PATH=/opt/rh/devtoolset-2/root/usr/bin:$PATH

#rvm use ruby-2.5.5
#rvm use ruby-3.1.2
rvm use ruby-3.2.2
which ruby
#gem install bundler:1.17.3
#gem install bundler:2.5.25
#gem install bundler:2.3.9
gem install bundler:2.3.26
#export GEM_HOME=/usr/local/rvm/gems/ruby-2.5.5
#export GEM_PATH=/usr/local/rvm/gems/ruby-2.5.5:/usr/local/rvm/gems/ruby-2.5.5@global
#export GEM_HOME=/usr/local/rvm/gems/ruby-3.1.2
#export GEM_PATH=/usr/local/rvm/gems/ruby-3.1.2:/usr/local/rvm/gems/ruby-3.1.2@global
export GEM_HOME=/usr/local/rvm/gems/ruby-3.2.2
export GEM_PATH=/usr/local/rvm/gems/ruby-3.2.2:/usr/local/rvm/gems/ruby-3.2.2@global
gem install bootstrap-sass:3.4.1
echo "Directory now working in:$WORKSPACE"
echo $PATH
export RAILS_ENV="integration"
export LD_LIBRARY_PATH="/usr/lib/oracle/11.2/client64/lib"
printenv
echo "******** I don't remember why we did bundle install --local does this make any sense?"
echo "DOING bundle install --local"
#bundle install --local
bundle update blacklight_unapi
#bundle update --source blacklight_cornell_requests
bundle update blacklight_cornell_requests
#bundle update --source my_account
bundle update my_account
bundle update capistrano
TARGT=integration-ruby3
#gem install --version "=2.15.4" capistrano
#gem install --version "=3.14.1" capistrano
#gem install capistrano
#echo "which cap?"
#echo "**********running deploy setup "
#bundle exec cap $TARGT deploy:setup || exit 1
#bundle exec cap $TARGT deploy:check || exit 1
#echo "******** Running deploy ***********"
#bundle exec cap $TARGT --verbose deploy || exit 1
#bundle exec cap $TARGT --verbose deploy:migrations || exit 1
bundle exec cap --version
echo "************** running test ****************"
bundle exec cap $TARGT check_write_permissions --trace || exit 1
bundle exec cap $TARGT git:check --trace || exit 1
bundle exec cap $TARGT deploy:check --trace || exit 1
echo "******** Running deploy or rollback ***********"
bundle config unset deployment
if [ "$ACTION" = "Deploy" ] ; then
	bundle exec cap $TARGT -t deploy || exit 1
#	bundle exec cap $TARGT -t deploy:assets:precompile || exit 1
elif [ "$ACTION" = "Rollback" ] ; then
	bundle exec cap $TARGT -t 'deploy:rollback' || exit 1
fi


exit 0
