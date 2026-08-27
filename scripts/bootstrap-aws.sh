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
# Order-free: the script checks whether the account-level GitHub OIDC provider
# already exists and sets manage_provider accordingly — the first run creates
# it, later runs reuse it.

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
REPOS="${REPOS:?set REPOS in .env (e.g. mathewmusango/my-portfolio)}"

# Space-separated repo list -> JSON array for -var repos (sh would strip inner
# quotes from a JSON literal stored in .env, so the script builds the array).
REPO_JSON=""
for _repo in $REPOS; do
  if [ -n "$REPO_JSON" ]; then
    REPO_JSON="$REPO_JSON, "
  fi
  REPO_JSON="$REPO_JSON\"$_repo\""
done
REPO_JSON="[$REPO_JSON]"

# Credentials — 'prod' profile by default, overridable via env/.env.
AWS_PROFILE="${AWS_PROFILE:-prod}"
export AWS_PROFILE

cd "$ROOT/terraform/ci"

case "$ENV" in
  staging)
    REF_PATTERNS='["ref:refs/heads/main"]'
    ;;
  prod)
    REF_PATTERNS='["ref:refs/tags/v*"]'
    ;;
esac

# Detect the account-level GitHub OIDC provider — whoever runs first creates it
# (manage_provider=true); later runs reuse it via the ci module's data lookup.
if ! PROVIDER_LIST="$(aws iam list-open-id-connect-providers --output text --query 'OpenIDConnectProviderList[].Arn' 2>&1)"; then
  echo "error: cannot list OIDC providers (check AWS_PROFILE / credentials)" >&2
  echo "$PROVIDER_LIST" >&2
  exit 1
fi
if echo "$PROVIDER_LIST" | grep -q "token.actions.githubusercontent.com"; then
  MANAGE_PROVIDER=false
  PROVIDER_NOTE="reusing (provider exists)"
else
  MANAGE_PROVIDER=true
  PROVIDER_NOTE="creating (provider not found)"
fi

AWS_PROFILE="$AWS_PROFILE" terraform apply -auto-approve -no-color -input=false \
  -state="terraform.$ENV.tfstate" \
  -var "environment=$ENV" \
  -var "aws_region=$AWS_REGION" \
  -var "name_prefix=$PROJECT" \
  -var "role_name=github-actions-$PROJECT-$ENV" \
  -var "repos=$REPO_JSON" \
  -var "state_bucket=$PROJECT-$ENV-tfstate" \
  -var "state_lock_table=$PROJECT-$ENV-tfstate-lock" \
  -var "site_bucket_prefix=$PROJECT-$ENV-site" \
  -var "ref_patterns=$REF_PATTERNS" \
  -var "manage_provider=$MANAGE_PROVIDER" \
  -var "tags={\"project\":\"$PROJECT\",\"managed_by\":\"terraform\",\"environment\":\"$ENV\"}"

echo "Bootstrap complete for $PROJECT/$ENV ($AWS_REGION):"
echo "  role:           github-actions-$PROJECT-$ENV"
echo "  state bucket:   $PROJECT-$ENV-tfstate"
echo "  lock table:     $PROJECT-$ENV-tfstate-lock"
echo "  site buckets:   $PROJECT-$ENV-site*"
echo "  oidc provider:  $PROVIDER_NOTE"
echo "  trust refs:     $REF_PATTERNS"
