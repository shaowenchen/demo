wasm:
	tinygo build -o main.wasm -target=wasm
image:
	docker build -t shaowenchen/wasm-print:latest .
run:
	docker run  --rm --runtime=io.containerd.wasmedge.v1 \
				shaowenchen/wasm-print:latest