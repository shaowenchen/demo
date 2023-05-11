build: clear
	tinygo build -o ./build/main.wasm -target=wasm
run: clear build
	wasmedge ./build/main.wasm
image: clear build
	docker build -t shaowenchen/wasm-hello-world:tinygo .
container:
	docker run  --rm --runtime=io.containerd.wasmedge.v1 \
				shaowenchen/wasm-hello-world:tinygo
clear:
	rm -rf ./build
	mkdir ./build
