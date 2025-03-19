#!/bin/bash
/bin/date
source /usr/local/rvm/scripts/rvm

# new for containerized version ...
cd "${WORKSPACE}/blacklight-cornell"
# ... end new

echo "BRANCH: ${BRANCH}"

rvm use ruby-3.2.2
which ruby
export GEM_HOME=/usr/local/rvm/gems/ruby-3.2.2
export GEM_PATH=/usr/local/rvm/gems/ruby-3.2.2:/usr/local/rvm/gems/ruby-3.2.2@global
gem install bootstrap-sass:3.4.1
echo "Directory now working in:$WORKSPACE"
echo $PATH
export RAILS_ENV="integration"
export LD_LIBRARY_PATH="/usr/lib/oracle/11.2/client64/lib"
printenv
bundle update blacklight_unapi
bundle update blacklight_cornell_requests
bundle update my_account
bundle update capistrano
TARGT=integration
bundle exec cap --version
echo "************** running test ****************"
bundle exec cap $TARGT check_write_permissions --trace || exit 1
bundle exec cap $TARGT git:check --trace || exit 1
bundle exec cap $TARGT deploy:check --trace || exit 1
echo "******** Running deploy or rollback ***********"
bundle config unset deployment
if [ "$ACTION" = "Deploy" ] ; then
	bundle exec cap $TARGT -t deploy || exit 1
elif [ "$ACTION" = "Rollback" ] ; then
	bundle exec cap $TARGT -t 'deploy:rollback' || exit 1
fi

exit 0