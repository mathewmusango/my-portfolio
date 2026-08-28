# Toggle state for the site CloudFront distribution — read via
# `-var-file=.github/site-enabled.tfvars` by terraform.yml + toggle-env.yml
# (kept outside terraform/** so a toggle commit doesn't re-trigger the
# terraform apply pipeline). Edited + committed by the toggle-env workflow:
# `site_enabled = false` disables the staging site (attribute flip only —
# nothing is removed) and persists across future applies.
site_enabled = true
