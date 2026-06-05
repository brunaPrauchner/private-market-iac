# Infrastructure Setup


AWS VPC
  private subnets only
  no public LoadBalancer
  no public app endpoint

EKS Cluster
  managed node group
  private nodes

Application
  simple nginx/hello-world pod
  Kubernetes ClusterIP service only

Observability
  CloudWatch logs from the cluster/pods








## Deployment Instructions



## Key Design Decisions
brief (1-2 paragraph) explanation of any key design decisions, as well as a link to the deployed service or a screenshot of the service running.


## Follow up questions:

How would you expose this application to the internet without a public EKS endpoint?

Justify any security decisions or tradeoffs you made during this design.