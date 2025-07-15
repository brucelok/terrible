# Terrible
When Terraform meets Ansible.  This repo is a demo to show the differences between Terraform and Ansible. The example walks you through how the Ansible playbook [nomad-ec2.yaml](https://github.com/brucelok/terrible/blob/main/nomad-ec2.yaml) and the Terraform code [main.tf](https://github.com/brucelok/terrible/blob/main/main.tf) build a single Nomad server on an AWS EC2 respectively.

To compare the outcomes, execute `terraform apply` and `ansible-playbook` together for the initial run. Then, perform a second run to identify the key differences in their behavior.
