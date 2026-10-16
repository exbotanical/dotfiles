.PHONY: all
.DELETE_ON_ERROR:

SRCS := $(wildcard src/*) rollup.config.js tsconfig.json

all: startpage.html bundle.js

startpage.html bundle.js &: node_modules $(SRCS)
	npm run gen

node_modules: package.json package-lock.json
	npm i
	touch $@
