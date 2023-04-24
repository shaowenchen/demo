build:
	docker build -t shaowenchen/scheduler-plugin:latest .
push:
	docker push shaowenchen/scheduler-plugin:latest
tidy:
	go mod tidy
	go mod vendor
run:
	export GOFLAGS="-mod=vendor"
	go run main.go \
	--leader-elect=true \
	--feature-gates=RotateKubeletServerCertificate=true,TTLAfterFinished=true,ExpandCSIVolumes=true,CSIStorageCapacity=true \
	--authentication-kubeconfig=/Users/shaowenchen/.kube/config \
	--authorization-kubeconfig=/Users/shaowenchen/.kube/config \
	--kubeconfig=/Users/shaowenchen/.kube/config \
	--config=/Volumes/Data/Code/Github/demo/scheduler-plugin/scheduler-plugin.yaml \
	--v=5
test:
	kubectl delete -f ./pod.yaml || exit 0
	kubectl apply -f ./pod.yaml
