PUBLISH_VERSION=$(shell echo ${NEW_VERSION} | sed 's/inner-999/1/g')

GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_ORIGIN=$(shell git config --get remote.origin.url)

build-jar-with-docker:
	rm -rf build
	# Build the build/libs/tutorial-V.V.V - which already includes the project sources in the jar
	docker run --rm -v "$(shell pwd)":/home/gradle/project -w /home/gradle/project gradle:4.8.0-jdk8-alpine gradle -i bootJar

build-jar-local:
	# Build the build/libs/tutorial-V.V.V - which already includes the project sources in the jar
	gradle -i bootJar

run-local:
	# Download the javaagent for local run
	wget "http://repository.sonatype.org/service/local/artifact/maven/redirect?r=central-proxy&g=com.rookout&a=rook&v=LATEST"  -O rook.jar
	# Run the app with the Rookout Java agent
	java  -javaagent:rook.jar -jar build/libs/tutorial-1.0.0.jar

build-img:
	docker build -t us-central1-docker.pkg.dev/rookoutdevelopment/development-images/dt-java:latest -t us-central1-docker.pkg.dev/rookoutdevelopment/development-images/dt-java:${PUBLISH_VERSION} --build-arg DT_SAAS_ADDRESS=${DT_SAAS_ADDRESS} --build-arg GIT_COMMIT=${GIT_COMMIT} --build-arg GIT_ORIGIN=${GIT_ORIGIN} .

upload-no-latest:
	gcloud docker -- push us-central1-docker.pkg.dev/rookoutdevelopment/development-images/dt-java:${PUBLISH_VERSION}

upload: upload-no-latest
	@if [ ${CIRCLE_BRANCH} = "master" ]; then \
		gcloud docker -- push us-central1-docker.pkg.dev/rookoutdevelopment/development-images/dt-java:latest;\
	fi

build-and-upload: build-img upload

