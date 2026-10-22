Investigated Terraform apply failure involving a Cloud SQL PostgreSQL read replica.

Terraform is attempting to update `disk_autoresize_limit` from `500` to `0` on the read replica. The apply fails with a Google API error indicating that the storage autoresize property cannot be updated in place on a read replica.

**References:**
- TFE Plan / Failed Apply: [Insert Link]
- GCP Cloud SQL Instance: [Insert Link]
- Terraform Configuration: [Insert GitHub Link]
- Custom Terraform Module: [Insert GitHub Link]

**Findings:**
- Verified that both primary and read replica currently have `disk_autoresize_limit = 500` in GCP.
- Terraform configuration specifies `500`, matching the existing GCP settings.
- Reviewed the custom Terraform module and found that `disk_autoresize_limit` is commented out under `google_sql_database_instance.read_replica`.
- Suspect the omitted attribute is causing the Terraform provider to default to `0`, resulting in an unnecessary update.
- Cloud SQL read replicas inherit storage autoresize settings from the primary instance and do not allow independent updates to this property.

**Potential Resolution:**

Adding a lifecycle `ignore_changes` rule for `settings[0].disk_autoresize_limit` within the read replica resource may prevent Terraform from attempting the unsupported update. However, this requires modifying the shared custom module, which is outside our current access.

**Next Steps:**

Requesting next-shift assistance to investigate possible workarounds or determine whether escalation to the module owners is required. No changes have been made to the existing Cloud SQL configuration.
