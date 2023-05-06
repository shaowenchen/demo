go-build: clear
	GOOS=js GOARCH=wasm go build -o main.wasm
	cp $(shell go env GOROOT)/misc/wasm/wasm_* .
go-build-run: clear go-build
	node wasm_exec_node.js main.wasm

tinygo-build: clear
	tinygo build -o main.wasm -target=wasm
tinygo-build-run: clear tinygo-build
	wasmedge main.wasm

image: clear tinygo-build
	docker build -t shaowenchen/wasm-print:latest .
container:
	docker run  --rm --runtime=io.containerd.wasmedge.v1 \
				shaowenchen/wasm-print:latest

clear:
	rm -rf main.wasm
	rm -rf wasm_*