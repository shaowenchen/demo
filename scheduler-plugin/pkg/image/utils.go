package image

import (
	"context"
	"strings"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	clientset "k8s.io/client-go/kubernetes"
)

const (
	SpecialNSImageKey = "com.chenshaowen.scheduler-plugin.filterimage"
	SpecialNSNodesKey = "com.chenshaowen.scheduler-plugin.nodes"
	SpecialNSKey      = "com.chenshaowen.scheduler-plugin.ns"
	SpecialDataNS     = "kube-system"
)

func isSpecialNS(client clientset.Interface, ns string) (nodes []string, nss []string, filterImage string) {
	dataNSObject, err := client.CoreV1().Namespaces().Get(context.Background(), SpecialDataNS, metav1.GetOptions{})
	if err != nil {
		println(err.Error())
		return
	}
	if dataNSObject.Annotations == nil {
		return
	}
	if nodesStr, ok := dataNSObject.Annotations[SpecialNSNodesKey]; ok {
		if filterImage, ok := dataNSObject.Annotations[SpecialNSImageKey]; ok {
			if nssStr, ok := dataNSObject.Annotations[SpecialNSKey]; ok {
				nodes = strings.Split(nodesStr, ",")
				nss = strings.Split(nssStr, ",")
				return nodes, nss, filterImage
			}
		}
	}
	return
}

func isSpecialImage(pod *v1.Pod, filterImage string) (mached bool) {
	if pod.Spec.Containers == nil {
		return
	}
	for _, container := range pod.Spec.Containers {
		if strings.Contains(container.Image, filterImage) {
			return true
		}
	}
	return
}

func isStringInList(str string, list []string) bool {
	for _, s := range list {
		if s == str {
			return true
		}
	}
	return false
}
