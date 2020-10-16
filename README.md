[![noswpatv3](http://zoobab.wdfiles.com/local--files/start/noupcv3.jpg)](https://ffii.org/donate-now-to-save-europe-from-software-patents-says-ffii/)
Simple Docker OMD
=================

This is a simple installation of OMD on a docker instance.

It can be used for evaluation of OMD, testing configurations, edit new ones, adhoc monitoring...

**IMPORTANT:** It is not designed to run in production! 
**IMPORTANT:** Contains a default insecure ssh key!

Quickstart
----------

Just run the docker instance like this:

	docker run -p 8888:80 --rm -t -i springersbm/basic-docker-omd:latest /sbin/my_init -- bash -l
	
To access the OMD web interfaces:

 * http://localhost:8888/master if docker is running locally
 * http://192.168.59.103/master typically if running boot2docker (check your actual ip with: `boot2docker ip`)
 * Select "Check_MK Multisite" for the best interface :)

Default credentials:

 * Login: omdadmin
 * Pass: omd
 
**NOTE** Localhost will display some warnings from incorrect mountpoints, interfaces. That's due the services autodiscovered while the creation of the image. It is not important. Run `su - master -c 'cmd -u -II && cmk -R'` to regenerate the config.
 
Moving around
-------------

Running it with `/sbin/my_init -- bash -l` will give you a shell interface as root. 

Some basic information:

 * All configuration in `/omd/sites/master`
 * Check_mk specific configuration in: `/omd/sites/master/etc/check_mk`
 * Use `su - master` login in the OMD site master. There you can:
   * Run `cmk -II` to discover new check_mk services.
   * Run `cmk -R` to recompile nagios configuration.

Note about DNS
--------------

If you want to monitor servers in your internal network, and the DNS name is resolved internally, you might need to specify an internal DNS server in docker:

	docker run --dns <local dns ip> -p 8888:80 --rm -t -i springersbm/basic-docker-omd:latest /sbin/my_init -- bash -l


How to test check_mk configurations (linux)
-------------------------------------------

**IMPORTANT**: This only will work if your desktop is a Linux box, won't work on MacOSX with boot2docker or similar. 

A very common case to use this image is to test configurations or scripts to feed check_mk itself. For most of the resources (hosts, services/rules, hostgroups, etc.) your `.mk` files can be dropped  under `/omd/sites/master/etc/check_mk/conf.d`. Special case are hosttags, that AFAIK must be in `/omd/sites/master/etc/check_mk/multisite.d`

In docker, you can simply mount a volume in docker. 


	docker run \
	    -v $(pwd)/conf.d:/omd/sites/master/etc/check_mk/conf.d/docker-host-conf.d \
	    -v $(pwd)/multisite.d:/omd/sites/master/etc/check_mk/multisite.d/docker-host-multisite.d  \
	    -p 8888:80 --rm -ti \
	    springersbm/basic-docker-omd:latest \
	    /sbin/my_init -- bash -l

How to test check_mk configurations (MacOSX)
-------------------------------------------

The easiest solution is just use rsync to copy the files across.

For that first you need to get the private **insecure** private key from the container:

	# Get the private key from the container
	docker run --entrypoint="/usr/bin/print_ssh_private_key" springersbm/basic-docker-omd:latest > insecure_docker_omd_key.pem
	chmod 600 insecure_docker_omd_key.pem 
		

Then, start docker exposing also the SSH port:

	docker run \
	    -p 8888:80 \
	    -p 2222:22 \
	    --rm -ti \
	    springersbm/basic-docker-omd:latest \
	    /sbin/my_init -- bash -l

Finally, to copy the files:
	
	# Given your docker ip
	DOCKER_HOST_IP=$(boot2docker ip &> /dev/null || 127.0.0.10)

	# copy the conf.d directory
	rsync -rvz -e 'ssh -q -p 2222 -i insecure_docker_omd_key.pem -oStrictHostKeyChecking=no' ./conf.d root@$DOCKER_HOST_IP:/omd/sites/master/etc/check_mk/conf.d/docker-host.d
	# copy the multisite.d directory
	rsync -rvz -e 'ssh -q -p 2222 -i insecure_docker_omd_key.pem -oStrictHostKeyChecking=no' ./multisite.d root@$DOCKER_HOST_IP:/omd/sites/master/etc/check_mk/conf.d/docker-host.d
	
**The difficult way:**

You can alternatelly follow the instructions here: https://github.com/boot2docker/boot2docker#folder-sharing, as follows:

	# Make a volume container (only need to do this once)
    $ docker run -v /omd/sites/master/etc/check_mk/{conf}.d/docker-host-conf.d /check-mk-multisite.d --name check-mk-data busybox true
    # Share it using Samba (Windows file sharing)
    $ docker run --rm -v /usr/local/bin/docker:/docker -v /var/run/docker.sock:/docker.sock svendowideit/samba check-mk-data
    # then find out the IP address of your Boot2Docker host
    $ boot2docker ip
    192.168.59.103

Then connect to cifs://192.168.59.103/check-mk-conf.d. Once mounted, will appear as /Volumes/check-mk-conf.d and /Volumes/check-mk-multisite.d

Then you can run the omd as:

	$ docker run \
	    --volumes-from my-data  \
	    -p 8888:80 --rm -ti \
	    springersbm/basic-docker-omd:latest \
	    /sbin/my_init -- bash -l
	
Once on the docker is running, link the directories (run this in the docker image)
	
	# ln -s /check-mk-conf.d /omd/sites/master/etc/check_mk/conf.d/
	# ln -s /check-mk-multisite.d /omd/sites/master/etc/check_mk/multisite.d/


 
More about OMD and Check_MK
---------------------------

You can find more information here:

 * OMD and Check_MK site https://mathias-kettner.de/checkmk_omd.html
 * Check_MK documentation http://mathias-kettner.com/checkmk.html

