#!/usr/bin/env sh
# scripts/toggle-cloudfront.sh <staging|prod> <site|metrics> <disable|enable>
#
# Flip `Enabled` on a CloudFront distribution WITHOUT removing anything — the
# invalidation-style toggle: look up the distro by the comment convention
# (<project>-<env>-<component>) and update Enabled in place. PROJECT must be
# in the environment (the workflows pass secrets.PROJECT); AWS credentials
# come from the ambient chain (the per-env deploy roles in CI).
#
# DRIFT CAVEAT: the distribution's Enabled flag lives outside terraform
# state — the next `terraform apply` (staging on main pushes, prod on tag
# applies) restores it to `true` (the config's value). Re-run this script to
# disable again after any apply. No terraform run deletes anything here.
#
# Examples:
#   scripts/toggle-cloudfront.sh staging site disable
#   scripts/toggle-cloudfront.sh prod metrics enable

set -eu

USAGE="usage: scripts/toggle-cloudfront.sh <staging|prod> <site|metrics> <disable|enable>"
ENV="${1:?$USAGE}"
COMPONENT="${2:?$USAGE}"
STATE="${3:?$USAGE}"

case "$ENV" in
  staging | prod) ;;
  *) echo "$USAGE"; exit 1 ;;
esac
case "$COMPONENT" in
  site | metrics) ;;
  *) echo "$USAGE"; exit 1 ;;
esac
case "$STATE" in
  disable | enable) ;;
  *) echo "$USAGE"; exit 1 ;;
esac

COMMENT="$PROJECT-$ENV-$COMPONENT"
if [ "$STATE" = "enable" ]; then
  ENABLED=true
else
  ENABLED=false
fi

ID="$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$COMMENT'].Id" --output text)"
if [ -z "$ID" ]; then
  echo "distribution not found for comment '$COMMENT' — nothing to toggle"
  exit 0
fi

ETAG="$(aws cloudfront get-distribution --id "$ID" --query ETag --output text)"
aws cloudfront get-distribution --id "$ID" --query DistributionConfig > /tmp/cf-toggle-config.json
jq --argjson enabled "$ENABLED" '.Enabled = $enabled' /tmp/cf-toggle-config.json > /tmp/cf-toggle-config-new.json
aws cloudfront update-distribution --id "$ID" --if-match "$ETAG" --distribution-config file:///tmp/cf-toggle-config-new.json
echo "cloudfront $COMMENT -> $STATE (distribution $ID)"
