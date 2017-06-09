From now we will work from outside the folder my-cluster

Connect to the cluster
```
$ kubectl --kubeconfig=my-cluster/kubeconfig get nodes -o wide
```
Launch some pods and services:
```
$ kubectl --kubeconfig=my-cluster/kubeconfig create -f app/web-pod.yml
$ kubectl --kubeconfig=my-cluster/kubeconfig create -f app/db-svc.yml
$ kubectl --kubeconfig=my-cluster/kubeconfig create -f app/db-pod.yml
$ kubectl --kubeconfig=my-cluster/kubeconfig create -f app/web-svc.yml
```
To find out where is the load balancer:
```
$ kubectl --kubeconfig=my-cluster/kubeconfig describe services web
```
To scale your app:
```
$ kubectl --kubeconfig=my-cluster/kubeconfig scale --replicas=2 -f app/web-deployment.yml
```