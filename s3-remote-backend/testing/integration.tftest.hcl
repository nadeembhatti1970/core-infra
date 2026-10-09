# --------------------------------------------------------------------
# Integration tests: ephemeral apply against mocked AWS and random
# providers. Exercises outputs and wiring without touching AWS or the
# local terraform.tfstate (terraform test keeps its own in-memory state).
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "tfstate-dev-eu-west-2-abc123"
      arn = "arn:aws:s3:::tfstate-dev-eu-west-2-abc123"
    }
  }
}

mock_provider "random" {
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

run "apply_outputs_state_bucket" {
  command = apply

  assert {
    condition     = output.tfstate_bucket_id == "tfstate-dev-eu-west-2-abc123"
    error_message = "tfstate_bucket_id output must be the bucket name tfstate-<env>-<region>-<suffix>"
  }

  assert {
    condition     = output.tfstate_bucket_arn == "arn:aws:s3:::tfstate-dev-eu-west-2-abc123"
    error_message = "tfstate_bucket_arn output must be the bucket ARN"
  }

  assert {
    condition     = aws_s3_bucket.tfstate_bucket.bucket == "tfstate-dev-eu-west-2-abc123"
    error_message = "Applied bucket name must follow tfstate-<env>-<region>-<suffix>"
  }
}

run "apply_wires_controls_to_state_bucket" {
  command = apply

  assert {
    condition = alltrue([
      aws_s3_bucket_versioning.tfstate_versioning.bucket == output.tfstate_bucket_id,
      aws_s3_bucket_server_side_encryption_configuration.tfstate_encryption.bucket == output.tfstate_bucket_id,
      aws_s3_bucket_public_access_block.tfstate_block_public.bucket == output.tfstate_bucket_id,
      aws_s3_bucket_lifecycle_configuration.tfstate_lifecycle.bucket == output.tfstate_bucket_id,
    ])
    error_message = "Versioning, encryption, public access block and lifecycle must all target the state bucket"
  }

  assert {
    condition     = aws_s3_bucket_versioning.tfstate_versioning.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be Enabled after apply"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.tfstate_encryption.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Encryption must be aws:kms after apply"
  }
}
