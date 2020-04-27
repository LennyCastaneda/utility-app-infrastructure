# Build the infrastructure

After setting up your devops env and exporting your AWS user credentials to the environment build the infrastructure from within the **utility-app-infrastructure** directory by running the following commands:

``terraform init``

**For demonstration purposes there is no remote state configuration, so the Terraform state file will be set to your local machine.**

``terraform validate``

``terraform plan``

``terraform apply -auto-approve``

# Destroy the infrastructure

When you are ready to remove your infrastructure execute from inside the **utility-app-infrastructure** directory

``terraform destroy -auto-approve``