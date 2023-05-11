FROM node:12-alpine
ADD ./dist /dist
ENTRYPOINT ["node","/dist/wasm_exec_node.js", "/dist/main.wasm"]