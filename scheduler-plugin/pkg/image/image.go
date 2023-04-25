package image

import (
	"context"
	"fmt"
	"math"
	"math/rand"

	klog "k8s.io/klog/v2"

	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/kubernetes/pkg/scheduler/framework"
)

type ImageNode struct {
	handle framework.Handle
}

// var _ = framework.PreFilterPlugin(&ImageNode{})
var _ = framework.FilterPlugin(&ImageNode{})
var _ = framework.ScorePlugin(&ImageNode{})

const Name = "ImageNode"

func (i *ImageNode) Name() string {
	return Name
}

func New(_ runtime.Object, h framework.Handle) (framework.Plugin, error) {
	return &ImageNode{
		handle: h,
	}, nil
}

// func (i *ImageNode) PreFilter(ctx context.Context, state *framework.CycleState, pod *v1.Pod) *framework.Status {
// 	return framework.NewStatus(framework.Success, "")
// }

// func (i *ImageNode) PreFilterExtensions() framework.PreFilterExtensions {
// 	return i.PreFilterExtensions()
// }

func (i *ImageNode) Filter(ctx context.Context, state *framework.CycleState, pod *v1.Pod, nodeInfo *framework.NodeInfo) *framework.Status {
	if pod == nil {
		return framework.NewStatus(framework.Error, "pod is nil")
	}
	node := nodeInfo.Node()
	if node == nil {
		klog.Infof("node is nil")
		return framework.NewStatus(framework.Error, "node is nil")
	}
	nodes, nss, filterImage := isSpecialNS(i.handle.ClientSet(), pod.Namespace)

	if len(nodes) == 0 || len(nss) == 0 || len(filterImage) == 0 {
		klog.Infof("nodes, nss, filterImage is nil")
		return framework.NewStatus(framework.Success, "default")
	}

	workload := ""
	if len(pod.ObjectMeta.OwnerReferences) > 0 {
		workload = pod.ObjectMeta.OwnerReferences[0].Kind
	}
	if workload == "DaemonSet" {
		klog.Info("DaemonSet pass")
		return framework.NewStatus(framework.Success, "DaemonSet pass")
	}

	if isStringInList(node.Name, nodes) {
		if isStringInList(pod.Namespace, nss) && isSpecialImage(pod, filterImage) {
			klog.Infof("plugin hit")
			return framework.NewStatus(framework.Success, "plugin hit")
		} else {
			klog.Info(fmt.Printf("plugin disable pod %s special node %s", pod.Name, node.Name))
			return framework.NewStatus(framework.Unschedulable, "plugin disable special node")
		}
	}
	klog.Info("default pass")
	return framework.NewStatus(framework.Success, "default")
}

func (i *ImageNode) Score(ctx context.Context, cycleState *framework.CycleState, pod *v1.Pod, nodeName string) (int64, *framework.Status) {
	nodes, nss, filterImage := isSpecialNS(i.handle.ClientSet(), pod.Namespace)
	if len(nodes) > 0 && len(filterImage) > 0 && len(nss) > 0 {
		if isStringInList(nodeName, nodes) && isSpecialImage(pod, filterImage) {
			retScore := framework.MaxNodeScore - rand.Int63n(10)
			klog.Infof("special node score %d", retScore)
			return retScore, framework.NewStatus(framework.Success, "special node score")
		}
	}
	retScore := rand.Int63n(framework.MaxNodeScore - 50)
	klog.Infof("rand node score %d", retScore)
	return retScore, framework.NewStatus(framework.Success, "rand node score")
}

func (i *ImageNode) ScoreExtensions() framework.ScoreExtensions {
	return i
}

func (i *ImageNode) NormalizeScore(ctx context.Context, state *framework.CycleState, pod *v1.Pod, scores framework.NodeScoreList) *framework.Status {
	// Find highest and lowest scores.
	var highest int64 = -math.MaxInt64
	var lowest int64 = math.MaxInt64
	for _, nodeScore := range scores {
		if nodeScore.Score > highest {
			highest = nodeScore.Score
		}
		if nodeScore.Score < lowest {
			lowest = nodeScore.Score
		}
	}

	// Transform the highest to lowest score range to fit the framework's min to max node score range.
	oldRange := highest - lowest
	newRange := framework.MaxNodeScore - framework.MinNodeScore
	for i, nodeScore := range scores {
		if oldRange == 0 {
			scores[i].Score = framework.MinNodeScore
		} else {
			scores[i].Score = ((nodeScore.Score - lowest) * newRange / oldRange) + framework.MinNodeScore
		}
	}

	return nil
}
