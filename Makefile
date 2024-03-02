build:
	hugo

run:
	hugo server -D

# Deploys to cloudflare pages are automated as per 
# https://developers.cloudflare.com/pages/framework-guides/deploy-a-hugo-site/

.PHONY: build run
