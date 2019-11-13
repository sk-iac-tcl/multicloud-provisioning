# Terraform Azure Example

This folder contains a simple Terraform module that deploys resources in [Azure](https://azure.microsoft.com/) to demonstrate
how you can use Terratest to write automated tests for your Azure Terraform code. This module deploys a [Virtual
Machine](https://azure.microsoft.com/en-us/services/virtual-machines/) and gives that VM a `Name` tag with the value specified in the
`vm_name` variable.

Check out [test/terraform_azure_example_test.go](/test/terraform_azure_example_test.go) to see how you can write
automated tests for this module.

Note that the Virtual Machine in this module doesn't actually do anything; it just runs a Vanilla Ubuntu 16.04 image for
demonstration purposes. For slightly more complicated, real-world examples of Terraform modules, see
[terraform-http-example](/examples/terraform-http-example) and [terraform-ssh-example](/examples/terraform-ssh-example).

**WARNING**: This module and the automated tests for it deploy real resources into your Azure account which can cost you
money. The resources are all part of the [Azure Free Account](https://azure.microsoft.com/en-us/free/), so if you haven't used that up,
it should be free, but you are completely responsible for all Azure charges.





## Running this module manually

1. Sign up for [Azure](https://azure.microsoft.com/).
1. Configure your Azure credentials using one of the [supported methods for Azure CLI
   tools](https://docs.microsoft.com/en-us/cli/azure/azure-cli-configuration?view=azure-cli-latest).
1. Install [Terraform](https://www.terraform.io/) and make sure it's on your `PATH`.
1. Run `terraform init`.
1. Run `terraform apply`.
1. When you're done, run `terraform destroy`.




## Running automated tests against this module

1. Sign up for [Azure](https://azure.microsoft.com/).
1. Configure your Azure credentials using one of the [supported methods for Azure CLI
   tools](https://docs.microsoft.com/en-us/cli/azure/azure-cli-configuration?view=azure-cli-latest).
1. Install [Terraform](https://www.terraform.io/) and make sure it's on your `PATH`.
1. Install [Golang](https://golang.org/) and make sure this code is checked out into your `GOPATH`.
1. `cd test`
1. `dep ensure`
1. `go test -v -run TestTerraformAzureExample`
