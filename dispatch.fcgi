#!/bin/bash
this_dir=`dirname $0`
unset GEM_HOME
unset GEM_PATH
export PATH=~/.rbenv/bin:"$PATH"
eval "$(~/.rbenv/bin/rbenv init -)"
err_log_file="${this_dir}/log/dispatch_err.log"
exec ~/.rbenv/shims/ruby "${this_dir}/dispatch_fcgi.rb" "$@" 2>>"${err_log_file}"
