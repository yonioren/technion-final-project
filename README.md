# technion-final-project

This project is based on the previous projectplanner (https://github.com/yonioren/Midterm-for-technion).

For functionality, Please visit the repo.

## Folder structure

```
Terraform
│   README.md
└───ansible --- Files required for the ansible machine
│   │   user_data.sh --- On startup server customization (ansible install)
│   │   run_project_planner.yml --- Playbook to customize app machines to run the app
│   
└───main --- The main terraform module
│   │   ALB.tf ---- Load balancer resources
│   │   copy_keys.tf ---- handle post deploy actions to ansible machine
│   │   main.tf --- resources of main logic
│   │   provider.tf --- provider definition for the module
│   │   terraform.tfvars --- values for needed variables
│   │   variables.tf ---- variable definition
│   └───subfolder1
│       │   file111.txt
│       │   file112.txt
│       │   ...
│   
└───modules
    └───ec2 --- instance definition function
    └───keypair --- keypair definition function
    └───vpc --- network definition function
```

## How to run

After installing terraform and starting the AWS LAB:
1. Update lab info in `terraform.tfvars`
2. `cd <PATH>/Terraform/main`
3. `terraform init`
4. `terraform apply`
5. Confirm
6. Wait for LB DNS to show and surf

## How do destroy
1. `cd <PATH>/Terraform/main`
2. `terraform destroy`
3. Confirm