curl -X POST http://127.0.0.1:3010/call \
  -H "Content-Type: application/json" \
  -d '{"agent":"main","sessionid":"isolated","message":"帮我查一下 ai-translate 最近15分钟异常日志"}'