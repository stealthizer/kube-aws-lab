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
$ kubectl --kubeconfig=my-cluster/kubeconfig get nodes
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
$ kubectl --kubeconfig=cluster-dev/kubeconfig describe services web
```
To scale your app:
```
$ kubectl --kubeconfig=cluster-dev/kubeconfig scale --replicas=2 -f app/web-deployment.yml
```