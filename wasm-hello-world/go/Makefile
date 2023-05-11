build: clear
	GOOS=js GOARCH=wasm go build -o ./dist/main.wasm
	cp $(shell go env GOROOT)/misc/wasm/wasm_* ./dist/
run: clear build
	node ./dist/wasm_exec_node.js ./dist/main.wasm
image: clear build
	docker build -t shaowenchen/wasm-hello-world:go .
container:
	docker run  --rm shaowenchen/wasm-hello-world:go
clear:
	rm -rf dist