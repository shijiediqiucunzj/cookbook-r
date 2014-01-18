#
# Author:: Steven Danna(<steve@opscode.com>)
# Cookbook Name:: R
# Recipe:: default
#
# Copyright 2011-2013, Steven S. Danna (<steve@opscode.com>)
# Copyright 2013, Mark Van de Vyver (<mark@taqtiqa.com>)
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

r_version = node['r']['version']
major_version = r_version.split(".").first

# Command to check if we should be installing R or not.
is_installed_command = "R --version | grep -q #{r_version}"

# install some extra packages to make this work right.
case node['platform_family']
  when "debian"
    # this is broken for centos 6.5 because kernel-devel isn't available??
    include_recipe "apt"
    include_recipe "build-essential"
    package "gfortran"
    execute "apt-get build-dep r-base -y" # this is required if you want full access to R (png, jpeg, tcltk, etc)
  when "rhel"
    # Add readline headers to make command line easier to use, and is needed for rinruby gems
    include_recipe "yum"
    %w(gcc-gfortran readline-devel libX11 libX11-devel libXt libXt-devel cairo libpng libpng-devel libjpeg-turbo libjpeg-turbo-devel zlib libtiff).each do |p|
      package p
    end
end

include_recipe "ark"
include_recipe "java"

ark "R-#{r_version}" do
  name "R"
  version r_version
  url "#{node['r']['cran_mirror']}/src/base/R-#{major_version}/R-#{r_version}.tar.gz"
  preautogen_command "sed -i 's/NCONNECTIONS 128/NCONNECTIONS 2560/' src/main/connections.c"
  autoconf_opts node['r']['config_opts'] if node['r']['config_opts']
  prefix_bin node['r']['prefix_bin']  
  
  # do not call configure then install_with_make, just call install_with_make.  If you call
  # both then it will download the file twice and fail.  The install_with_make configures with autoconf_opts.
  action :install_with_make   
  
  # This is skipped if the url/path exists
  not_if is_installed_command
end

# make sure that java is dynamically loaded (if needed)
if node['r']['add_ld_path']
  template "/etc/profile.d/r-config.sh" do
    source "r-config.sh.erb"
    owner "root"
    mode "0775"
  end
end

