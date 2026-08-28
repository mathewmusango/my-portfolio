#!/usr/bin/env sh
# scripts/invalidate_cloudfront.sh <staging|prod> [paths]
#
# Look up the site distribution by the comment convention (<project>-<env>-site)
# and create a CloudFront invalidation. PROJECT must be in the environment
# (the deploy workflows pass secrets.PROJECT); AWS credentials come from the
# ambient chain (the per-env deploy roles in CI). Default paths: "/*" (full
# invalidation). Missing distribution = skip, not fail (fresh deploy target).

set -eu

ENV="${1:?usage: scripts/invalidate_cloudfront.sh <staging|prod> [paths]}"
case "$ENV" in
  staging | prod) ;;
  *) echo "usage: scripts/invalidate_cloudfront.sh <staging|prod> [paths]"; exit 1 ;;
esac
PATHS="${2:-/*}"

PROJECT="${PROJECT:?set PROJECT in the environment (the workflows pass secrets.PROJECT)}"

ID="$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$PROJECT-$ENV-site'].Id" --output text)"
if [ -z "$ID" ]; then
  echo "distribution '$PROJECT-$ENV-site' not found — skipping invalidation (content synced)"
  exit 0
fi

echo "Invalidating CloudFront '$PROJECT-$ENV-site' ($ID): $PATHS"
aws cloudfront create-invalidation --distribution-id "$ID" --paths "$PATHS"
