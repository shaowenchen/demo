MAC           = $(shell date -u '+%Y%m%d%I%M%S')
IMAGE_NAME    = shaowenchen/dockerhub-ratelimit


build:
	number=1 ; while [[ $$number -le 200 ]] ; do \
        echo ${IMAGE_NAME}:$$number ; \
        docker build --no-cache -t ${IMAGE_NAME}:$$number -f ./Dockerfile . ; \
        docker push ${IMAGE_NAME}:$$number ; \
        ((number = number + 1)) ; \
    done

clear:
	number=1 ; while [[ $$number -le 200 ]] ; do \
        docker rmi ${IMAGE_NAME}:$$number ; \
        ((number = number + 1)) ; \
    done
	