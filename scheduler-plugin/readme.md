V1.21 通过给 kube-system 命名空间打 annotation

```bash
kubectl annotate namespace kube-system com.chenshaowen.scheduler-plugin.filterimage=cdn
kubectl annotate namespace kube-system com.chenshaowen.scheduler-plugin.nodes=node2
kubectl annotate namespace kube-system com.chenshaowen.scheduler-plugin.ns=default
```

允许

- 允许 default 命名空间下，镜像包含 cdn 字符串的 Pod 优先调度到 node2 节点

禁止

- 禁止镜像不包含 cdn 字符串的 Pod 调度到 node2 节点
- 禁止其他命名空间调度到 node2 节点

清理 annotation

```bash
kubectl annotate namespace kube-system com.chenshaowen.scheduler-plugin.filterimage-
kubectl annotate namespace kube-system com.chenshaowen.scheduler-plugin.nodes-
kubectl annotate namespace kube-system com.chenshaowen.scheduler-plugin.ns-
```
