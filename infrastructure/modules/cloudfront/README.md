# CloudFront Module

This module provisions a CloudFront distribution in front of the ALB.

## Purpose

- Provide CDN caching and HTTPS for the ALB origin.
- Redirect HTTP to HTTPS.
- Allow optional custom aliases and ACM certificate.

## Inputs

- `project_name`
- `environment`
- `origin_domain_name`
- `origin_path`
- `aliases`
- `certificate_arn`
- `price_class`
- `tags`

## Outputs

- `distribution_id`
- `domain_name`
