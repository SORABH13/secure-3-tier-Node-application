# ECR Module

This module provisions Amazon ECR repositories for the toptal application.

## Purpose

- Host container images for Web and API services.
- Enable image scanning on push.
- Enforce a lifecycle policy to retain the most recent 30 images.

## Inputs

- `project_name`
- `environment`
- `tags`
- `image_tag_mutability`

## Outputs

- `web_repository_uri`
- `api_repository_uri`
- `web_repository_arn`
- `api_repository_arn`
