# NGINX Private ACM Proxy

This is a simple NGINX Proxy that pulls down keys from the AWS ACM.

## Environmental Variables

* `FQDN` - the fully qualified domain to use.
* `HTTP_PROXY_URL` - the URL you're pointing the proxy at.

That's it! From there the container downloads the certificate from the AWS ACM Private CA, configures the private key, certificate chain, and passphrase files, before launching nginx.

There are some additional environmental variables you can set-

* `PRIVATE_CA_NAME` and `PRIVATE_CA_URL` allow you to install a private CA on the server, which is useful if you're trying to proxy to another server running HTTPS. Ultimately though you should probably bake in the certificates another image if you go this route.

* `ENABLE_RATE_LIMITING` - when set to "true" Nginx rate limiting will be enabled in the default.conf file.
* `REAL_IP_ALLOWED_CIDR` - IP or CIDR range that is allowed to rewrite source IP using X-FORWARDED-FOR header/.
* `RATE_LIMIT_STATE_SIZE` - dictates how many IP state statuses are stored in memory (in MB). 1 = ~ 16,000 IPs.
* `RATE_LIMIT_REQUESTS` - dictates how many requests per second are allowed.
* `RATE_LIMIT_BURST_SIZE` - number of requests allowed to be sent to the burst queue. Set to "0" to disable.
* `RATE_LIMIT_BURST_NODELAY` - send requests from burst queue immediately with no delay.

* `DEBUG` - when set to "true" logging will be turned up and environmental variables will be printed on launch.

## Changing the nginx default configuration

The `default.conf` we use is different than the one shipped by nginx in two ways-

* It includes all the SSL and Proxy settings needed to do its job.
* It uses embedded tokens that get replaced on launch.

So if you want to change this file you should start with the one in this project (in conf/default.conf) and when you put it into the container you should place it at `/default.conf`- the launch script will find it, inject the appropriate settings in, and then move it to `/etc/nginx/conf.d/default.conf` for you. If you try to alter `/etc/nginx/conf.d/default.conf` directly it will get overwritten.
