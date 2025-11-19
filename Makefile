# NOTE: After cloning the repo you must run the following to fill in the theme submodules
#   git submodule init
#   git submodule update

build:
	hugo

# Start a dev server with draft posts as well
run:
	hugo server --buildDrafts --buildFuture --watch

# Deploys to cloudflare pages are automated as per 
# https://developers.cloudflare.com/pages/framework-guides/deploy-a-hugo-site/

.PHONY: build run
