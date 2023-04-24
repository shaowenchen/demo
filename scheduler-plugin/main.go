package main

import (
	"github.com/shaowenchen/scheduler-plugin/pkg/image"
	"k8s.io/kubernetes/cmd/kube-scheduler/app"
	"math/rand"
	"time"
	"os"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	command := app.NewSchedulerCommand(
		app.WithPlugin(image.Name, image.New),
	)
	if err := command.Execute(); err != nil {
		println(os.Stderr, "%v\n", err)
		os.Exit(1)
	}
}
