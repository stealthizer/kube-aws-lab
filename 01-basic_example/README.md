Basic Examples

For all this examples to work, all commands will be launched from inside this folder


01 - Basic Gatetes

Launch pod and service:
```
$ kubectl --kubeconfig=../my-cluster/kubeconfig create -f web-deployment.yml
deployment "web" created
$ kubectl --kubeconfig=../my-cluster/kubeconfig create -f web-service.yml
```
To show all pods:
```
$ kubectl --kubeconfig=../my-cluster/kubeconfig get pods
NAME                  READY     STATUS    RESTARTS   AGE
web-614602184-5jz6q   1/1       Running   0          1m
```
To be able to check if the if the page works from a local browser:
```
$ kubectl --kubeconfig=../my-cluster/kubeconfig port-forward web-614602184-5jz6q 5000:5000
```
As we are on AWS, by performing a describe service web we can see that an ELB has been created for this service:
```
kubectl --kubeconfig=../my-cluster/kubeconfig describe service web
Name:			web
Namespace:		default
Labels:			app=demo
			env=staging
			name=web
Annotations:		<none>
Selector:		app=demo,env=staging,name=web
Type:			LoadBalancer
IP:			10.3.0.207
LoadBalancer Ingress:	a1c004b724f6a11e7a7e30a6e77cc79d-1850366590.eu-west-1.elb.amazonaws.com
Port:			web	5000/TCP
NodePort:		web	30156/TCP
Endpoints:		10.2.85.8:5000
Session Affinity:	None
Events:
  FirstSeen	LastSeen	Count	From			SubObjectPath	Type		Reason			Message
  ---------	--------	-----	----			-------------	--------	------			-------
  3m		3m		1	service-controller			Normal		CreatingLoadBalancer	Creating load balancer
  3m		3m		1	service-controller			Normal		CreatedLoadBalancer	Created load balancer

```
To scale your app:
```
$ kubectl --kubeconfig=../my-cluster/kubeconfig scale --replicas=2 -f web-deployment.yml
```

Now you can test you application loading  http://a1c004b724f6a11e7a7e30a6e77cc79d-1850366590.eu-west-1.elb.amazonaws.com:5000 on your favourite browser

02 - Redis example

If you load in your browser http://a1c004b724f6a11e7a7e30a6e77cc79d-1850366590.eu-west-1.elb.amazonaws.com:5000/counter you will get an error.

```
ConnectionError: Error -2 connecting to redis:6379. Name or service not known.
```
We need to deploy the backend part of the application.
```
kubectl --kubeconfig=../my-cluster/kubeconfig create -f db-pod.yml
pod "redis" created
kubectl --kubeconfig=../my-cluster/kubeconfig create -f db-service.yml
service "redis" created
```
After that, the app will begin to work
```
Hello World! I have been seen 1 times. I am web-614602184-71phl
```