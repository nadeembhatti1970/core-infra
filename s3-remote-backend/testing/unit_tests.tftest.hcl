# --------------------------------------------------------------------
# Unit tests: plan-only against mocked AWS and random providers
# (no credentials needed). The random suffix is pinned so bucket
# names are deterministic. Never touches the local terraform.tfstate.
# --------------------------------------------------------------------
mock_provider "aws" {
  override_during = plan
}

mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "abc123"
    }
  }
}

variables {
  environment_name = "dev"
  aws_region       = "eu-west-2"
}

run "bucket_name_follows_tfstate_pattern" {
  command = plan

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.bucket == "tfstate-dev-eu-west-2-abc123"
    error_message = "Bucket name must follow tfstate-<env>-<region>-<suffix>"
  }

  assert {
    condition     = random_string.suffix.length == 6 && !random_string.suffix.upper && !random_string.suffix.special
    error_message = "Suffix must be 6 lowercase alphanumeric characters to keep the bucket name DNS-compliant"
  }
}

run "bucket_versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.tfstate_versioning.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be Enabled so state history can be recovered"
  }
}

run "bucket_encrypted_with_aws_managed_kms" {
  command = plan

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.tfstate_encryption.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Default encryption must be SSE-KMS (aws:kms)"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.tfstate_encryption.rule).bucket_key_enabled == true
    error_message = "S3 Bucket Key must be enabled to reduce KMS request costs"
  }
}

run "public_access_fully_blocked" {
  command = plan

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.tfstate_block_public.block_public_acls,
      aws_s3_bucket_public_access_block.tfstate_block_public.block_public_policy,
      aws_s3_bucket_public_access_block.tfstate_block_public.ignore_public_acls,
      aws_s3_bucket_public_access_block.tfstate_block_public.restrict_public_buckets,
    ])
    error_message = "All four public access block flags must be true"
  }
}

run "lifecycle_prunes_noncurrent_versions_safely" {
  command = plan

  assert {
    condition = anytrue([
      for r in aws_s3_bucket_lifecycle_configuration.tfstate_lifecycle.rule :
      r.status == "Enabled" && length(r.noncurrent_version_expiration) == 1 &&
      r.noncurrent_version_expiration[0].noncurrent_days == 90 &&
      r.noncurrent_version_expiration[0].newer_noncurrent_versions == 10
    ])
    error_message = "An enabled rule must expire noncurrent versions after 90 days while keeping the 10 newest"
  }

  assert {
    condition = anytrue([
      for r in aws_s3_bucket_lifecycle_configuration.tfstate_lifecycle.rule :
      r.status == "Enabled" && length(r.abort_incomplete_multipart_upload) == 1 &&
      r.abort_incomplete_multipart_upload[0].days_after_initiation == 7
    ])
    error_message = "An enabled rule must abort incomplete multipart uploads after 7 days"
  }

  assert {
    condition = alltrue([
      for r in aws_s3_bucket_lifecycle_configuration.tfstate_lifecycle.rule : length(r.expiration) == 0
    ])
    error_message = "No rule may expire current object versions (live state files must never be deleted)"
  }

  assert {
    condition = alltrue([
      for r in aws_s3_bucket_lifecycle_configuration.tfstate_lifecycle.rule : length(r.filter) == 1
    ])
    error_message = "Every lifecycle rule must apply to the whole bucket (empty filter)"
  }
}

run "bucket_tags_identify_backend" {
  command = plan

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.tags["Name"] == "tfstate-dev-eu-west-2"
    error_message = "Name tag must be tfstate-<env>-<region>"
  }

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.tags["Environment"] == "dev"
    error_message = "Environment tag must equal var.environment_name"
  }

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.tags["Purpose"] == "terraform-backend"
    error_message = "Purpose tag must be terraform-backend"
  }

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.tags["Project"] == "remote-backend-for-devops-real-world-course"
    error_message = "Project tag must identify the remote-backend project"
  }
}

run "bucket_name_tracks_environment_and_region" {
  command = plan

  variables {
    environment_name = "prod"
    aws_region       = "us-east-1"
  }

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.bucket == "tfstate-prod-us-east-1-abc123"
    error_message = "Bucket name must reflect a non-default environment_name and aws_region"
  }

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.tags["Name"] == "tfstate-prod-us-east-1" && aws_s3_bucket.tfstate_bucket.tags["Environment"] == "prod"
    error_message = "Name/Environment tags must reflect a non-default environment_name and aws_region"
  }

  assert {
    condition     = length(aws_s3_bucket.tfstate_bucket.bucket) <= 63
    error_message = "Bucket name must not exceed the 63-character S3 limit"
  }
}
