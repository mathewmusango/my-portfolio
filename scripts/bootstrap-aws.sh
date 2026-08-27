#!/usr/bin/env sh
# scripts/bootstrap-aws.sh <staging|prod>
#
# One-command bootstrap of the per-environment terraform plumbing:
#   - OIDC assume-role  github-actions-<project>-<env> (ref-scoped trust)
#   - state bucket      <project>-<env>-tfstate (versioned, encrypted)
#   - lock table        <project>-<env>-tfstate-lock
#   - deploy policies   scoped to <project>-<env>-site buckets
#
# Deployment values (PROJECT / AWS_REGION / REPOS) are picked from .env at the
# repo root (gitignored — see .env.sample); nothing deployment-specific lives
# in code. AWS credentials come from the 'prod' profile (or AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY env vars).
#
# Run STAGING first — it creates the account-level GitHub OIDC provider; PROD
# reuses it (manage_provider=false).

set -eu

ENV="${1:?usage: scripts/bootstrap-aws.sh <staging|prod>}"
case "$ENV" in
  staging | prod) ;;
  *) echo "usage: scripts/bootstrap-aws.sh <staging|prod>"; exit 1 ;;
esac

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
if [ -f "$ROOT/.env" ]; then
  set -a
  . "$ROOT/.env"
  set +a
fi

# Deployment values — required from .env, never hardcoded here.
PROJECT="${PROJECT:?set PROJECT in .env (see .env.sample)}"
AWS_REGION="${AWS_REGION:?set AWS_REGION in .env (see .env.sample)}"
REPOS="${REPOS:?set REPOS in .env (e.g. [\"owner/repo\"])}"

cd "$ROOT/terraform/ci"

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
  -var "aws_region=$AWS_REGION" \
  -var "name_prefix=$PROJECT" \
  -var "role_name=github-actions-$PROJECT-$ENV" \
  -var "repos=$REPOS" \
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
