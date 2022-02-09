# Cloud Three Ways

When I started working with cloud infrastructure I was like wow, where do I start? There are a number of public cloud providers and each one has a dizzying array of services. AWS has so many services and releases new ones so quickly that trying to count them would breach the CAP theorem. However, I eventually came to undertand that every single one of those services boils down to simply running some software on a virtual machine, and exposing that software via a network. 

Therefore, the best and fastest way to come to grips with the cloud(s) is to deploy a virtual machine into each of Azure, AWS and GCP. They each have their own unique characteristics, best understood by contrast with each other. And why not show off the breadth of Terraform's capabilities by deploying them all at the same time with the same tool?

## What is in this repo and how do I use it?

`main.tf` in the root of the repo orchestrates the sub-modules `azure`, `aws` and `gcp`, each of which deploys a virtual machine and the minimum supporting infrastructure. 

To use it:

1. Authenticate the `az`, `aws` and `gcloud` CLIs.
2. Generate an SSH key that you will use to log in to your new VMs, e.g. `ssh-keygen -t rsa -f some_key`
3. Run Terraform, e.g. `terraform apply -var ssh_public_key_file=some_key.pub`
4. Re-run Terraform, fixing whatever errors that threw out, e.g. you might need to set the `GOOGLE_CLOUD_PROJECT` environment variable so that the GCP provider knows where to deploy things. :-)
5. Log in to your new VMs with commands like `ssh -i some_key foomin@${hostname}`, where the username is set in the Terraform variable `vm_username` and the hostnames can be found in `terraform output`. (Note that the username on AWS is always `ubuntu`. Send me a PR if you know how to change it, lol.)

The code in this repo is very minimal. In part it is intended as a starting point for new infracoders: if you can get this to work on your machine, and understand how to fix the bits that are a bit flaky, then you have a really good start on your Terraform journey across the clouds.

Finally I should acknowledge that if you are an author of the Terraform documentation, you may find some of this code VERY FAMILIAR. As they say in the classics, plagiarism is the highest form of flattery. Thankyou for your work, it has been a beacon in the darkness so, so many times.
