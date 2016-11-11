# Kubernetes on AWS 

Following this source informations:
https://github.com/coreos/coreos-kubernetes/tree/master/multi-node/aws
https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html

source the aws account vars
. ./export_aws.sh account

Create a KMS key for kube-aws

aws kms create-key --description="kube-aws assets"

output:
{
    "KeyMetadata": {
        "Origin": "AWS_KMS",
        "KeyId": "xxxx",
        "Description": "kube-aws assets",
        "Enabled": true,
        "KeyUsage": "ENCRYPT_DECRYPT",
        "KeyState": "Enabled",
        "CreationDate": 1478855628.64,
        "Arn": "arn:aws:kms:eu-west-1:xxxx:key/xxxx",
        "AWSAccountId": "xxxx"
    }
}


Initialize asset directory and create initial yaml config file

$ mkdir my-cluster
$ cd my-cluster

$ kube-aws init \
--cluster-name=cluster-kubernetes \
--external-dns-name=kube-aws.domain.net \
--region=eu-west-1 \
--availability-zone=eu-west-1c \
--key-name=devops \
--kms-key-arn="arn:aws:kms:eu-west-1:xxxx:key/xxxx"

Render files

(optional) Edit cluster.yaml to allow the creation of a dns record by specifying the next keys:
externalDNSName: my-cluster.domain.net
createRecordSet: true
hostedZoneId: XXXXXXXXX

$ kube-aws render

ensure all files have been created correctly

Ensure the assets are valid:
kube-aws validate

Create cluster from this asset directory:

$ kube-aws up

Creating AWS resources. This should take around 5 minutes.

Success! Your AWS resources have been created:
Cluster Name:	my-cluster
Controller IP:	xx.xx.xx.xx  

The containers that power your cluster are now being downloaded.

You should be able to access the Kubernetes API once the containers finish downloading.

From now we will work from outside the folder my-cluster

Connect to the cluster

kubectl --kubeconfig=my-cluster/kubeconfig get nodes

Launch some pods and services:

kubectl --kubeconfig=my-cluster/kubeconfig create -f app/web-pod.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/db-pod.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/db-svc.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/db-pod.yml
kubectl --kubeconfig=my-cluster/kubeconfig create -f app/web-service.yml
