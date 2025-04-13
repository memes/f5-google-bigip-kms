# KMS encrypted BIG-IP

![GitHub release](https://img.shields.io/github/v/release/memes/f5-google-bigip-kms?sort=semver)
![Maintenance](https://img.shields.io/maintenance/yes/2025)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

This repo creates a testing environment for BIG-IP with KMS encrypted disks and
can run a small set of tests to verify that the BIG-IP is active.

## Usage

1. Create supporting resources

   The GDM template requires that VPC networks for external (data-plane, nic0)
   and management (control-plane, nic1) exist before deployment. The tests also
   use [Secret Manager] to store BIG-IP `admin` user password, and firewall rules
   to allow ingress for SSH and HTTP to verify BIG-IP instance(s) are functioning
   correctly.

   1. Create `test/terraform.tfvars` file to drive the test harness; see
      [terraform.tfvars.example](test/terraform.tfvars.example)

      ```hcl
      name       = "my-kms-test"
      project_id = "my-google-project-id"
      labels = {
        owner = "my_name"
      }
      ```

   1. Create the supporting resources

      <!-- spell-checker: disable -->
      ```shell
      tofu -chdir=test init
      tofu -chdir=test apply -auto-approve
      ```

      ```text
      ...
      Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

      Outputs:

      ...

      ```
      <!-- spell-checker: disable -->

1. Deploy a BIG-IP instance using Google Deployment Manager

   Step 1 will have created an F5 BIG-IP GDMv2 configuration for a standalone
   instance that attaches to the resources created in step 1 with a virtual
   server that responds with 200 OK on port 80. This can be used as-is, or as a
   starter example for your own testing.

   > NOTE: The file will be named according to the `name` value specified in step
   > 1.1 above.

   ```shell
   gcloud deployment-manager deployments create my-deployment-name \
       --quiet \
       --config my-kms-test-gdm-config.yaml \
       --project my-google-project-id
   ```

   ```text
   The fingerprint of the deployment is b'XXXX'
   Waiting for create [operation-XXXX]... done.
   WARNING: Create operation operation-XXXX completed with warnings:
   ---
   code: EXTERNAL_API_WARNING
   data:
   - key: disk_size_gb
     value: '120'
   - key: image_size_gb
     value: '40'
   message: "Disk size: '120 GB' is larger than image size: '40 GB'. You might need to\
     \ resize the root repartition manually if the operating system does not support\
     \ automatic resizing. See https://cloud.google.com/compute/docs/disks/add-persistent-disk#resize_pd\
     \ for details."

   NAME                             TYPE                 STATE      ERRORS  INTENT
   my-kms-test-bigip-vm-01          compute.v1.instance  COMPLETED  []
   ```

1. Verify the BIG-IPs are functional

   > NOTE: It takes a few minutes for the BIG-IP instances to boot and perform
   > initialization steps. Testing will *fail* if the instances have not been
   > given time to complete onboarding.

   Once you are certain the BIG-IPs have had enough time to onboard, you can run
   a set of tests to verify access to SSH on management interface and HTTP on
   data-plane interface.

   ```shell
   uv run pytest test.py
   ```

   <!-- spell-checker: disable -->
   ```text
   ============================ test session starts ============================
   platform linux -- Python 3.12.8, pytest-8.3.5, pluggy-1.5.0
   rootdir: /workspaces/f5-google-bigip-kms
   configfile: pyproject.toml
   plugins: testinfra-10.2.2
   collected 2 items
   test.py::test_hosts PASSED                                             [ 50%]
   test.py::test_services PASSED                                          [100%]

   ============================== 2 passed in 5.40s ============================
   ```
   <!-- spell-checker: enable -->

1. Clean-up resources

   1. Destroy GDM instances

   ```shell
   gcloud deployment-manager deployments delete my-deployment-name \
       --quiet \
       --project my-google-project-id
   ```

   ```text
   Waiting for delete [operation-XXXX]...done.
   Delete operation operation-XXXX completed successfully.
   ```

   1. Destroy test harness resources

   <!-- spell-checker: disable -->
   ```shell
   tofu -chdir=test destroy -auto-approve
   ```
   <!-- spell-checker: enable -->

   ```text
   ...
   Destroy complete! Resources: 23 destroyed.
   ```
