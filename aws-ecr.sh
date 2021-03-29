#!/bin/sh

# You should create aws authorized profile callaed `ecr-user`. You can see at line 24.
# in order to create this profile, you have to get api key and secret from aws iam service.
# If you want to change profile name fork and edit profile name.

bold=$(tput bold)
normal=$(tput sgr0)

# VARIABLES
user=
token=

# ARGUMENTS
# Firstly fetch from system environment. You may create .env file and export variables in this file.
# If cannot find variables, will look arguments
# URI=<url>
# REPO=<repo>
# APP_NAME=<app name>
# KEY=~/.ssh/<example_rsa>

FILE=.env
if test -f "$FILE"; then
	source .env
	export $(cut -d= -f1 .env)
fi

repository=$REPO
uri=$URI
name=$APP_NAME
command=
tag=

# If you need to ssh key according to fetch private repository codebase with ssh key, you can this variable.
# Own build `dockerBuild` function pass this value with SSH_KEY argument.
# You should get this build args in Dockerfile using ARG SSH_KEY top of file and call with $SSH_KEY wherever you want it.
ssh_key="${SSH_KEY:-''}"

# For nodeJS applications.
tag=$(awk -F'"' '/"version": ".+"/{ print $4; exit; }' package.json)

kill() {
	echo >&2 "$@"
	exit 1
}

awsLogin() {
	tokenbase64=$(aws ecr get-authorization-token --profile ecr-user --output text --query 'authorizationData[].authorizationToken')

	if [ -n $tokenbase64 ]; then
		credentials=$(echo $tokenbase64 | base64 --decode)

		tokens=(${credentials//:/ })
		user=${tokens[0]}
		token=${tokens[1]}

		echo "${bold}>>> Logging in Aws${normal}"

		docker login -u ${user} --password ${token} $uri
	fi
}

getEcrTags() {
	curl -H "Authorization: Basic $token" $uri
	echo '\n'
}

pushToEcr() {
	docker push $repository:$tag
}

dockerBuild() {
	docker build --no-cache --build-arg SSH_KEY=$base64 -t $name .
}

dockerTag() {
	echo "create tag: $tag"
	docker tag $name $repository:$tag
}

dockerTagLatest() {
	echo "create tag: latest"
	docker tag $name $repository:latest
}

# assign base64 private key
base64=$(cat $ssh_key | base64)

usage() {
	cat <<EOF
usage: bash ./scripts/packndeploy -n service_name
-t    | --tag       (Required)            Image tag / version
-r 		| --repo			(Required)						Repository
-u		| --uri				(Required)						Repository URL
-n    | --name			(Required)						Image name
-h    | --help                            Brings up this menu
EOF
}

while [ "$1" != "" ]; do
	case $1 in
	-t | --tag)
		shift
		tag=$1
		;;
	-r | --repo)
		shift
		repository=$1
		;;
	-n | --name)
		shift
		name=$1
		;;
	-u | --uri)
		shift
		uri=$1
		;;
	-h | --help)
		usage
		exit
		;;
	build)
		command="build"
		;;
	release)
		command="release"
		;;
	*)
		usage
		exit 1
		;;
	esac
	shift
done

echo "TAG = " $tag
echo "REPOSITORY = " $repository
echo "URI = " $uri
echo "NAME = " $name
echo "KEY = " $ssh_key
echo "COMMAND = " $command

if [ -z $repository ]; then
	echo "Repo is required, provide it with the flag: -r <aws repository url>"
	exit
fi

if [ -z $uri ]; then
	echo "Uri is required, provide it with the flag: -u <aws ecr url>"
	exit
fi

if [ -z $name ]; then
	echo "Name is required, provide it with the flag: -n <image name>"
	exit
fi

if [ -z $command ]; then
	echo "Command is missing: build | release"
	exit
fi

if [ "$command" = "build" ]; then
	echo ">>> ${bold}Build image with tag $tag${normal}"
	dockerBuild
	dockerTag
	dockerTagLatest
fi

if [ "$command" = "release" ]; then
	echo "${bold}>>> Pushing to awc ecr tag $tag${normal}"
	awsLogin
	pushToEcr
fi
