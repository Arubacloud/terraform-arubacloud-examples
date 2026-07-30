# Frequently Asked Questions

## Deployment

**Q: How long does deployment take?**

Typically 8–15 minutes. The majority of the time is spent on: VM boot (1–2 min), DBaaS provisioning (3–5 min for MySQL), package installation and application bootstrap via cloud-init (3–8 min).

**Q: The apply completed but the application is not accessible yet. Why?**

Terraform finishes when the VM and all resources are created. The cloud-init bootstrap continues running inside the VM after Terraform exits. Wait 3–5 minutes and retry. You can follow progress by SSH-ing into the VM and running:

```bash
sudo tail -f /var/log/cloud-init-output.log
```

**Q: I see "One or more validation errors" from the provider.**

Enable debug logging to see the full API error:

```bash
TF_LOG=DEBUG terraform apply 2>&1 | grep -A5 "error"
```

Common causes: resource name already exists from a previous failed run, Elastic IP quota exceeded, or missing project permissions.

**Q: How do I get the application password after deployment?**

Run `terraform output`. Sensitive values are redacted in the terminal; retrieve them with:

```bash
terraform output -raw admin_password
```

## Networking

**Q: Can I use a custom domain with HTTPS?**

Yes — set the `domain` variable to your domain name (e.g. `blog.example.com`) and point an A record to the VM's Elastic IP before running `terraform apply`. Certbot will issue a Let's Encrypt certificate automatically during cloud-init.

**Q: MySQL says "Error establishing a database connection".**

1. The DBaaS may still be starting when cloud-init runs. The bootstrap script waits up to 15 minutes; if that's not enough, SSH in and re-run the failed step.
2. Check that the `arubacloud_databasegrant` resource was created successfully — without a grant, MySQL rejects the user even with a correct password.
3. Verify the DBaaS security rule allows TCP 3306 from the VM's Elastic IP.

## Costs

**Q: Will I be charged if I run `terraform destroy`?**

You will be charged for the time the resources were running. After `terraform destroy` completes, all resources are deleted and billing stops.

**Q: Are Elastic IPs billed when not attached to a VM?**

Yes. `terraform destroy` always releases Elastic IPs. Do not remove individual resources from state without destroying them.

## Customization

**Q: Can I change the VM size after deployment?**

Update the `vm_flavor` variable and run `terraform apply`. Whether this requires a replacement depends on the provider's update behavior for the flavor attribute — check the plan output first.

**Q: Can I add more VMs to share the same DBaaS?**

Yes — you can add more `arubacloud_cloudserver` resources that connect to the same `arubacloud_dbaas`. Use a load balancer (e.g. the Traefik example) in front.
