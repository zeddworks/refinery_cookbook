#
# Cookbook Name:: refinery
# Recipe:: default
#
# Copyright 2011, ZeddWorks
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

refinery = Chef::EncryptedDataBagItem.load("apps", "refinery")
#smtp = Chef::EncryptedDataBagItem.load("apps", "smtp")

refinery_url = refinery["refinery_url"]
refinery_path = "/srv/rails/#{refinery_url}"

package "memcached"

#gem_package "pg"
#gem_package "taps"
#gem_package "rails"
#package "libmagickwand-dev"
#gem_package "rmagick"

passenger_nginx_vhost refinery_url

postgresql_user "refinery" do
  password "refinery"
end

postgresql_db "refinery_production" do
  owner "refinery"
end

directories = [
                "#{refinery_path}/shared/config","#{refinery_path}/shared/log",
                "#{refinery_path}/shared/system","#{refinery_path}/shared/pids",
                "#{refinery_path}/shared/config/environments"
              ]
directories.each do |dir|
  directory dir do
    owner "nginx"
    group "nginx"
    mode "0755"
    recursive true
  end
end

cookbook_file "#{refinery_path}/shared/config/environments/production.rb" do
  source "production.rb"
  owner "nginx"
  group "nginx"
  mode "0400"
end

template "#{refinery_path}/shared/config/database.yml" do
  source "database.yml.erb"
  owner "nginx"
  group "nginx"
  mode "0400"
  variables({
    :db_adapter => refinery["db_adapter"],
    :db_name => refinery["db_name"],
    :db_host => refinery["db_host"],
    :db_user => refinery["db_user"],
    :db_password => refinery["db_password"]
  })
end

#template "#{redmine_path}/shared/config/configuration.yml" do
#  source "configuration.yml.erb"
#  owner "nginx"
#  group "nginx"
#  mode "0400"
#  variables({
#    :smtp_host => smtp["smtp_host"],
#    :domain => smtp["domain"],
#    :port => smtp["port"],
#    :attachments_path => redmine["attachments_path"]
#  })
#end

deploy_revision "#{refinery_path}" do
  repo "git://github.com/resolve/refinerycms.git"
  revision "1.0.3" # or "HEAD" or "TAG_for_1.0" or (subversion) "1234"
  user "nginx"
  enable_submodules true
#  before_migrate do
#    execute "rake generate_session_store" do
#      user 'nginx'
#      group 'nginx'
#      cwd release_path
#    end
#  end
  migrate true
  migration_command "rake db:migrate"
  symlink_before_migrate ({
                          "config/database.yml" => "config/database.yml",
                          "config/environments/production.rb" => "config/environments/production.rb"
                         })
#  before_symlink do
#    execute "rake redmine:load_default_data" do
#      user 'nginx'
#      group 'nginx'
#      cwd release_path
#      environment "RAILS_ENV" => "production", "REDMINE_LANG" => "en"
#    end
#  end
  environment "RAILS_ENV" => "production"
  action :deploy # or :rollback
  restart_command "touch tmp/restart.txt"
end
