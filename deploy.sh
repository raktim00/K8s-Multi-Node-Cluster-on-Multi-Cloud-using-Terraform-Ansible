cd terraform-ws/
terraform init
terraform validate
terraform apply --auto-approve
cd ../ansible-ws
ansible-inventory --graph
ansible-playbook setup.yml