build:
	hugo

# Start a dev server with draft posts as well
run:
	hugo server -D

# Deploys to cloudflare pages are automated as per 
# https://developers.cloudflare.com/pages/framework-guides/deploy-a-hugo-site/

.PHONY: build run
