# Basic OMD installation for testing
# ==================================
#
#  * Based on Ubuntu 13.10 (backport of phusion/baseimage-docker)
#  * Installs OMD from http://labs.consol.de/repo/stable (only has omd for ubuntu 13.10)
#  * Installs check_mk_agent in docker itself
#  * Creates a initial master site in OMD
#
FROM      springersbm/phusion-baseimage-ubuntu-13.10:latest
MAINTAINER Springer Platform Engineering Team <platform-engineering@springer.com>
MAINTAINER Hector Rivas <hector.rivas@springer.com>

# This image is for testing OMD, so it is nice to have a shell
ENTRYPOINT /sbin/my_init -- bash -l

EXPOSE 22 80 6556

#####################################################################################
# Install OMD from the repository http://labs.consol.de/repo/stable
# 

# First register the new repo
RUN gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7
RUN gpg --armor --export F8C1CA08A57B9ED7 | apt-key add -
RUN echo 'deb http://labs.consol.de/repo/stable/ubuntu saucy main' >> /etc/apt/sources.list

# Install OMD
RUN apt-get update
RUN apt-get -y install omd

# Install some tooling
RUN apt-get -y install net-tools netcat xinetd wget 

# Start some services
RUN /etc/init.d/apache2 start 
RUN /etc/init.d/xinetd start 

# Install the agent to monitor localhost
RUN wget http://mathias-kettner.de/download/check-mk-agent_1.2.4p5-2_all.deb -P /tmp/
RUN dpkg -i /tmp/check-mk-agent_1.2.4p5-2_all.deb

#####################################################################################
# Setup the initial OMD site 'master'
#
# This method is a little bit hacky, and I had to do some workarounds:
#  1. tmpfs is not supported by standard docker (can be recompiled). 
#    In OMD can be disabled, but I don't know how to do it before initilize the site. 
#
#    Solution: try to create the site and change the config after.
# 
#  2. Second issue: the new user created by OMD needs to be in the group crontab 
#     to be able to change the cronjobs. But you need first to get the user to change it!
#    
# Any about this feedback is appreciated.
#

# Create master site.  Will fail, as commented
RUN omd create master || true

# Disable the TMPFS in the new generated site conf... hacky, hacky :)
RUN sed "s/CONFIG_TMPFS='on'/CONFIG_TMPFS='off'/" -i /omd/sites/master/etc/omd/site.conf 

# Add the new user to crontab, to avoid error merging crontabs
RUN adduser master crontab 

# OK, now the site starts :)
RUN omd start master

#####################################################################################
# Initial configuration of the site and image

# Add localhost as node monitored
ADD hosts.mk /omd/sites/master/etc/check_mk/conf.d/wato/hosts.mk

# First OMD service discovery and compile
RUN /etc/init.d/xinetd start && su - master -c "cmk -II"
RUN su - master -c "cmk -R"

# Add scripts to start services in baseimage my_init:
ADD 10_startup_base_services /etc/my_init.d/10_startup_base_services
ADD 20_startup_omd_master /etc/my_init.d/20_startup_omd_master