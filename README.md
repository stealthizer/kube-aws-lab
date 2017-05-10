# Kubernetes on AWS
Last updated: 2017/05/09 for kubernetes v1.6.2

Source informations:
* https://github.com/kubernetes-incubator/kube-aws
* https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html

To begin, source the aws account vars (useful script provided)
```
. ./export_aws.sh account
```

Create a KMS key for kube-aws

```
aws kms create-key --description="kube-aws assets" --profile awsprofile

{
    "KeyMetadata": {
        "Origin": "AWS_KMS",
        "KeyId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "Description": "kube-aws assets",
        "Enabled": true,
        "KeyUsage": "ENCRYPT_DECRYPT",
        "KeyState": "Enabled",
        "CreationDate": 1478855628.64,
        "Arn": "arn:aws:kms:eu-west-1:xxxx:key/xxxx",
        "AWSAccountId": "xxxxxxxxxxxx"
    }
}
```

You can add an alias to this kms key

```
aws kms create-alias --alias-name alias/kube-aws --target-key-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx --profile awsprofile
```

Create a bucket to store large cloudformation templates that the process will create

```
aws s3api create-bucket --bucket bucket-name --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1 --profile awsprofile
```

Initialize asset directory and create initial yaml config file

```
$ mkdir my-cluster
$ cd my-cluster
$ kube-aws init \
--cluster-name=cluster-kubernetes \
--external-dns-name=kube-aws.domain.net \
--region=eu-west-1 \
--availability-zone=eu-west-1c \
--key-name=devops \
--kms-key-arn="arn:aws:kms:eu-west-1:xxxx:key/xxxx"
```

A review of what the cluster.yaml can do is recommended, as it is highly configurable. For this example we will customize some keys:
* under the apiEndpoints section, change the createRecordSet to true and id with the zone id from route53

```
apiEndpoints:
- 
  name: default
  dnsName: kube-aws.domain.net
  loadBalancer:
    createRecordSet: true
    hostedZone:
      id: "XXXXXXXXXXXXX"
```

You can now render all needed files:

```
$ kube-aws render credentials --generate-ca
$ kube-aws render stack
```

Ensure the created assets are valid:

```
$ kube-aws validate --s3-uri s3://bucket-name
```

Create cluster from this asset directory:
```
$ kube-aws up --s3-uri s3://bucket-name
Creating AWS resources. Please wait. It may take a few minutes.
Success! Your AWS resources have been created:
Cluster Name:		cluster-kubernetes
Controller DNS Names:	cluster-k-APIEndpo-XXXXXXXXXXXX-XXXXXXXXX.eu-west-1.elb.amazonaws.com

The containers that power your cluster are now being downloaded.

You should be able to access the Kubernetes API once the containers finish downloading.
```
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

INGRESS

As seen on:
* http://www.dasblinkenlichten.com/kubernetes-networking-101-ingress-resources/

In this example we will use ingress to expose the service outside. We will clear everything we have done

```
kubectl --kubeconfig=my-cluster/kubeconfig delete deployments --all
kubectl --kubeconfig=my-cluster/kubeconfig delete pods --all
kubectl --kubeconfig=my-cluster/kubeconfig delete services --all
```

We will use both web and redis containers for this example, but as deployments

```
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/backend-web-deployment.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/db-pod.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/db-svc.yml
```
To test the application internally we will use an external container
```
kubectl --kubeconfig=my-cluster/kubeconfig run net-test --image=jonlangemak/net_tools

```
So far we have this pods:
```
kubectl --kubeconfig=my-cluster/kubeconfig get pods -o wide
NAME                       READY     STATUS    RESTARTS   AGE       IP           NODE
net-test-353103886-cbm9w   1/1       Running   0          2m        10.2.79.11   ip-10-0-0-90.eu-west-1.compute.internal
redis                      1/1       Running   0          3m        10.2.79.10   ip-10-0-0-90.eu-west-1.compute.internal
web-1301222806-21mpw       1/1       Running   0          5m        10.2.79.8    ip-10-0-0-90.eu-west-1.compute.internal
web-1301222806-wtnsk       1/1       Running   0          5m        10.2.79.9    ip-10-0-0-90.eu-west-1.compute.internal
```
We will test the application so far
```
kubectl --kubeconfig=my-cluster/kubeconfig exec -it net-test-353103886-cbm9w curl http://10.2.79.8:5000
Hello Container World! I have been seen 1 times.
kubectl --kubeconfig=my-cluster/kubeconfig exec -it net-test-353103886-cbm9w curl http://10.2.79.9:5000
Hello Container World! I have been seen 2 times.
```
We will create a service
```
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/backend-web-service.yml
```
A description of the services so far
```
kubectl --kubeconfig=my-cluster/kubeconfig get services
NAME         CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
kubernetes   10.3.0.1     <none>        443/TCP    23m
redis        10.3.0.11    <none>        6379/TCP   12m
web-svc      10.3.0.62    <none>        80/TCP     12s
```
Now we can ask for the service directly (to the name of the service)
```
kubectl --kubeconfig=my-cluster/kubeconfig exec -it net-test-353103886-cbm9w curl http://web-svc
Hello Container World! I have been seen 3 times.
```
We need now a default backend as fallback (a 404 page basically). For that we will create the deployment and service
```
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/default-backend-deployment.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/default-backend-service.yml

kubectl --kubeconfig=my-cluster/kubeconfig get service default-http-backend
NAME                   CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
default-http-backend   10.3.0.217   <none>        80/TCP    2m
```
testing the default-http-service
```
kubectl --kubeconfig=my-cluster/kubeconfig exec -it net-test-353103886-cbm9w curl http://default-http-backend
default backend - 404
```
We will now create the ingress controller, that needs a deployment and a config-map
```
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/nginx-ingress-controller-config-map.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/nginx-ingress-controller-deployment.yaml
```
As we haven't published any service on the ingress controller we will get the default http backend
```
kubectl --kubeconfig=my-cluster/kubeconfig get pods -o wide|grep nginx
nginx-ingress-controller-770078068-nvbxd   1/1       Running   0          3m        10.2.79.14   ip-10-0-0-90.eu-west-1.compute.internal

kubectl --kubeconfig=my-cluster/kubeconfig exec -it net-test-353103886-cbm9w curl http://10.2.79.14
default backend - 404
```
We will now create the ingress object

```
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/nginx-ingress.yml

kubectl --kubeconfig=my-cluster/kubeconfig get ingress
NAME            HOSTS                  ADDRESS         PORTS     AGE
nginx-ingress   kubertest.domain.test   34.248.28.164   80        17s
```
testing it...

```
kubectl --kubeconfig=my-cluster/kubeconfig exec -it net-test-353103886-cbm9w -- curl -H Host:kubertest.domain.test http://10.2.79.14
default backend - 404

kubectl --kubeconfig=my-cluster/kubeconfig exec -it net-test-353103886-cbm9w -- curl -H Host:kubertest.domain.test http://10.2.79.14/random
<html>
<head><title>503 Service Temporarily Unavailable</title></head>
<body bgcolor="white">
<center><h1>503 Service Temporarily Unavailable</h1></center>
<hr><center>nginx/1.11.3</center>
</body>
</html>
(error for now)
```
Creating the service we will expose it to the world
```
kubectl --kubeconfig=my-cluster/kubeconfig get services nginx-ingress -o wide
NAME            CLUSTER-IP   EXTERNAL-IP   PORT(S)                        AGE       SELECTOR
nginx-ingress   10.3.0.32    <nodes>       80:30000/TCP,18080:32767/TCP   32s       app=nginx-ingress-lb
```
Assign an A DNS register to the Address that a describe ingress shows

```
kubectl --kubeconfig=my-cluster/kubeconfig describe ingress
Name:			nginx-ingress
Namespace:		default
Address:		XXX.XXX.XXX.XXX
Default backend:	default-http-backend:80 (<none>)
Rules:
  Host			Path	Backends
  ----			----	--------
  kubertest.domain.test
    			/random 	web-svc:80 (<none>)
    			/nginx_status 	nginx-ingress:18080 (<none>)
Annotations:
Events:	<none>
```

Remember to attach a security with access to the exposed port in order to test it!

