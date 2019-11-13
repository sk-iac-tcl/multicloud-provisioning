 terragrunt = {
     terraform = {
         source = "..//foo"
         arguments = [
             "-var-file=terraform.tfvars"
         ]
     }
 }