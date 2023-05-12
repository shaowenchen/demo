package main

import (
	"syscall/js"
)

func main() {
	js.Global().Get("console").Get("log").Invoke("Hello, World by Go")
	js.Global().Get("document").Call("getElementById", "hello").Set("innerHTML", "Hello, World! by Go")
	js.Global().Set("myfunc", js.FuncOf(myfunc))
	<-make(chan bool)
}

func myfunc(this js.Value, args []js.Value) interface{} {
	println("myfunc called")
	myfunc_arg0 := args[0].String()
	js.Global().Set("myfunc_arg0", myfunc_arg0)
	js.Global().Get("console").Get("log").Invoke(myfunc_arg0)
	return nil
}
