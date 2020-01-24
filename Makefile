build_or_publish:
	./build_or_publish.sh $(WORKSPACE)

local:
	docker stop nginxlocal
	docker container rm nginxlocal
	docker run --name nginxlocal -p 127.0.0.1:80:8080/tcp  -p 127.0.0.1:443:443/tcp \
	--env-file ./local.list \
	radaisystems/nginx-dynamic-acm:local

build_local:
	docker build \
    --cache-from radaisystems/nginx-dynamic-acm:local \
    -f Dockerfile.nginx \
    -t radaisystems/nginx-dynamic-acm:local \
    .
