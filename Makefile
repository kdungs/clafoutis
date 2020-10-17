all: check image

check: clafoutis
	shellcheck $^

image: Dockerfile clafoutis
	docker build --tag kdungs/clafoutis .
