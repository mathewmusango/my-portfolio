#!/usr/bin/env sh
# scripts/bootstrap-aws.sh <staging|prod>
#
# One-command bootstrap of the per-environment terraform plumbing:
#   - OIDC assume-role  github-actions-<project>-<env> (ref-scoped trust)
#   - state bucket      <project>-<env>-tfstate (versioned, encrypted)
#   - lock table        <project>-<env>-tfstate-lock
#   - deploy policies   scoped to <project>-<env>-site buckets
#
# Uses the local AWS 'prod' profile (root credentials — the one-time seed;
# everything after this runs via GitHub Actions OIDC).
#
# Portable: override PROJECT and AWS_REGION for a different project/region
# (defaults: my-portfolio / us-east-1). Run STAGING first — it creates the
# account-level GitHub OIDC provider; PROD reuses it (manage_provider=false).

set -eu

ENV="${1:?usage: scripts/bootstrap-aws.sh <staging|prod>}"
case "$ENV" in
  staging | prod) ;;
  *) echo "usage: scripts/bootstrap-aws.sh <staging|prod>"; exit 1 ;;
esac

PROJECT="${PROJECT:-my-portfolio}"
# Deployment value — must come from the caller's env (never hardcoded here).
AWS_REGION="${AWS_REGION:?set AWS_REGION (e.g. AWS_REGION=us-east-1) — not stored in the repo}"

cd terraform/ci

case "$ENV" in
  staging)
    REF_PATTERNS='["ref:refs/heads/main"]'
    MANAGE_PROVIDER=true
    ;;
  prod)
    REF_PATTERNS='["ref:refs/tags/v*"]'
    MANAGE_PROVIDER=false
    ;;
esac

AWS_PROFILE=prod terraform apply -auto-approve -no-color -input=false \
  -state="terraform.$ENV.tfstate" \
  -var "environment=$ENV" \
  -var "name_prefix=$PROJECT" \
  -var "aws_region=$AWS_REGION" \
  -var "role_name=github-actions-$PROJECT-$ENV" \
  -var "state_bucket=$PROJECT-$ENV-tfstate" \
  -var "state_lock_table=$PROJECT-$ENV-tfstate-lock" \
  -var "site_bucket_prefix=$PROJECT-$ENV-site" \
  -var "ref_patterns=$REF_PATTERNS" \
  -var "manage_provider=$MANAGE_PROVIDER" \
  -var "tags={\"project\":\"$PROJECT\",\"managed_by\":\"terraform\",\"environment\":\"$ENV\"}"

echo "Bootstrap complete for $PROJECT/$ENV ($AWS_REGION):"
echo "  role:          github-actions-$PROJECT-$ENV"
echo "  state bucket:  $PROJECT-$ENV-tfstate"
echo "  lock table:    $PROJECT-$ENV-tfstate-lock"
echo "  site buckets:  $PROJECT-$ENV-site*"
echo "  trust refs:    $REF_PATTERNS"
