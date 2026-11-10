# Cloudflare

Terraform for the Cloudflare side of my public ingress. It manages:

* The `tks-ingress` tunnel and its ingress rules, which send every hostname in [terraform.tfvars](terraform.tfvars) to the Istio gateway
* A proxied `CNAME` for each of those hostnames
* The API token cert-manager uses for DNS-01 challenges

Its outputs become the `cloudflared-token` and `cloudflare-api-token` secrets in Kubernetes-Manifests' [Secrets and Volumes](https://github.com/zimmertr/Kubernetes-Manifests#secrets-and-volumes).

The state is in [HCP Terraform](https://app.terraform.io), in the `cloudflare` workspace of the `Yggdrasil-Org` organization. Its *Default Execution Mode* is *Local*, otherwise HCP tries to run the plan itself and can't.

`terraform-cloudflare.yml` plans every PR that touches this folder and applies the plan on merge. It authenticates with the `CLOUDFLARE_API_TOKEN` Actions secret (and the Dependabot secret of the same name), a Cloudflare API token with **Account → Cloudflare Tunnel → Edit**, **Account → Account API Tokens → Edit**, **Zone → Zone → Read** and **Zone → DNS → Edit**. The API Tokens permission is what lets it create cert-manager's token.

To add a public hostname, add it to `terraform.tfvars` in a PR and merge it. cloudflared picks up the new rule without a restart.

To read an output for its secret, from the repo's root:

```bash
docker run --rm -it -v "$PWD:/w" -w /w/terraform/cloudflare --entrypoint sh hashicorp/terraform:1.17.1 -c \
  'terraform login && terraform init -input=false > /dev/null && terraform output -raw tunnel_token'
```

Swap `tunnel_token` for `cert_manager_token` for the other one, and pass each to `kubectl create secret` as Kubernetes-Manifests' README shows.
