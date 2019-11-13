 terragrunt = {
     terraform = {
         source = "..//terraform-with-plan-error"
         arguments = [
             "-var-file=terraform.tfvars"
         ]
     }
 }