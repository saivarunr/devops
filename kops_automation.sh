#!/bin/sh
#Script file on basis of https://github.com/kubernetes/kops/blob/master/docs/aws.md
proceed_further(){
	echo "Do you want to continue (Y/n)?"
	read proceed_further_flag
	case "$proceed_further_flag" in
	y|Y ) continue;;
	* ) exit;;
	esac
}

check_package(){
	if ! type $1 > /dev/null; then
	  	echo "$2";
	  exit;
	fi
}

kops_aws(){
	check_package aws "aws-cli is not found on this machine, please install aws-cli to proceed further";
	echo "In order to build clusters within AWS we'll create a dedicated IAM user for kops. This user requires API credentials in order to use kops. Create the user, and credentials, using the AWS console.\nThe kops user will require the following IAM permissions to function properly:\n1) AmazonEC2FullAccess\n2) AmazonRoute53FullAccess\n3) AmazonS3FullAccess\n4) IAMFullAccess\n5) AmazonVPCFullAccess"
	proceed_further;
	echo "You might want to configure aws-cli with user credentials. (please hit enter for following few steps if already configured)"
	aws configure
	echo "In order to store the state of your cluster, and the representation of your cluster, we need to create a dedicated S3 bucket for kops to use. This bucket will become the source of truth for our cluster configuration.\nCreate a s3 bucket using aws console, if you already have, you may proceed further"
	proceed_further;
	echo "Provide s3 bucket name. (Example: s3://kops-test-bucket)"
	read KOPS_STATE_STORE
	export KOPS_STATE_STORE=$KOPS_STATE_STORE
	echo "Provide Access key ID (access key id of KOPS user)"
	read AWS_ACCESS_KEY_ID
	echo "Provide Secret access key (Secret access key of KOPS user)"
	read AWS_SECRET_ACCESS_KEY
	echo "-------------------------------------------"
	echo "Please choose any one of the following"
	echo "1) Gossip based cluster \n2) DNS based cluster"
	read cluster_type
	if [ "$cluster_type" -eq '1' ]
		then
			echo "Please provide name of the cluster, should end with \".k8s.local\" (since you opted for gossip based cluster)"

	elif [ "$cluster_type" -eq '2' ]
		then
			echo "Please provide name of the cluster, i.e., DNS name"

	else
		echo "Wrong option"
		exit;
	fi
	read NAME
	echo "Confirm cluster name"
	read confirm_cluster

	if [ "$NAME" != "$confirm_cluster" ]
		then
			echo "Cluster names do not match!!!"
			exit;
	fi
	export NAME=$NAME
	echo "-------------------------------------------"
	echo "Specifiy count of master nodes, defaults to 1"
	read kops_aws_master_count
	kops_aws_master_count=${kops_aws_master_count:-1}
	echo "Specifiy count of worker nodes, defaults to 2"
	read kops_aws_worker_count
	kops_aws_worker_count=${kops_aws_worker_count:-2}
	aws ec2 describe-availability-zones
	echo "Select atleast a zone from above available zones. (Example: \"us-east-1a\" or \"us-east-1a,us-east-1b\" )"
	read hosted_zones
	kops create cluster --name=$NAME --state=$KOPS_STATE_STORE --zones=$hosted_zones --master-count=$kops_aws_master_count --node-count=$kops_aws_worker_count

}

kops_gcloud(){
	echo "We are yet to work with gcloud, sorry for now!!!"
	exit;
}

echo "Kubernetes Operations Setup"
check_package kops "kops package is not installed on this machine, please install kops before proceeding any further"
check_package kubectl "kubectl is not installed on this machine, please install kubectl before proceeding any further"

echo "-------------------------------------------"
echo "Select your service provider"
echo "1) aws \n2) gcloud"

read cloud_provider
if [ "$cloud_provider" -eq '1' ] ; then
	kops_aws;
elif [ "$cloud_provider" -eq '2' ]; then
	kops_gcloud;
else
	exit;
fi
