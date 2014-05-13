#!/bin/bash
#this_dir=`dirname $0`
this_dir=${PWD}
unset GEM_HOME
unset GEM_PATH
export PATH=~/.rbenv/bin:"$PATH"
eval "$(~/.rbenv/bin/rbenv init -)"
err_log_file="${this_dir}/log/dispatch_err.log"
#echo "===========================================" >> "${err_log_file}"
#echo "this_dir is ${this_dir}" >> "${err_log_file}"
#env >> "${err_log_file}"
export LC_CTYPE=en_US.UTF-8
#echo "Content-type: text/html"
#echo ""
exec ~/.rbenv/shims/ruby "${this_dir}/code${PATH_INFO}" 2>>"${err_log_file}"
