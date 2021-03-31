# AWS-ECR.SH

This is utility script in order to push image to aws ecr service. 
Aws Login use `get-authorization-token` method in order to authentication.

You can;
1. You build image without push to aws for your local development 
2. You build and push to aws and you can see image in the ecr service.

## Running

On the fly (I recommend) running.
```text
bash < (curl -s <raw aws-ecr.sh file URL>) [OPTIONS] COMMAND

For example;
bash <(curl -s https://raw.githubusercontent.com/omeroot/aws-ecr.sh/master/aws-ecr.sh) [OPTIONS] [COMMAND]

```

If you want to pass options when running script, you could create .env file and define variables which using in script.

.env file content
```text
URI=<ecr uri>
REPO=<image repository uri>
APP_NAME=<image name>
SSH_KEY=~/.ssh/<your_key_rsa>
```
> `SSH_KEY` is optional 

### OPTIONS

| OPTIONS            	| DESCRIPTION                                                               	|
|--------------------	|---------------------------------------------------------------------------	|
| -t \| --tag        	| Tag of your docker image (beta, latest, version x.x.x ...)                	|
| -r \| --repository 	| Your aws image repository (You should push same image to same repository) 	|
| -n \| --name       	| Image name                                                                	|
| -u \| --uri        	| Aws ecr url created according to your aws account.                        	|

### COMMAND

| COMMAND 	| DESCRIPTION                                 	|
|---------	|---------------------------------------------	|
| release 	| Push image to aws ecr                       	|
| build   	| Build image with tag version and tag latest 	|
| auth    	| Login to Aws Ecr with authenticated profile  	|


> If you dont pass no command script only build your image according to given options.