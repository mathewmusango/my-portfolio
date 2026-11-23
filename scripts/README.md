# scripts

What runs on a developer's machine, and the scripts CI calls.

## The dev container

[`dev.sh`](dev.sh) drives the container declared in the root [`compose.yaml`](../compose.yaml) and
built from the root [`Dockerfile`](../Dockerfile).

```sh
scripts/dev.sh build      # build the image from the root Dockerfile
scripts/dev.sh start      # start the container, without building
scripts/dev.sh restart    # recreate the container from the compose file
scripts/dev.sh stop       # stop the container
```

Once per machine, before the first `build`:

```sh
mkcert -install
mkdir -p certs
mkcert -cert-file certs/portfolio.pem -key-file certs/portfolio-key.pem \
  portfolio.mathewmusango.test localhost 127.0.0.1
echo "127.0.0.1 portfolio.mathewmusango.test" | sudo tee -a /etc/hosts
```

Open <https://portfolio.mathewmusango.test:8000>; the container also answers `/health`. The image's
design notes — the `js` stage, the buildah caches, `.dockerignore` — are in the Dockerfile's own
history and the `my-portfolio` skill, not here.

## Scripts CI calls

| Script | Runs in | What it checks |
| --- | --- | --- |
| [`policy.py`](policy.py) | `CI: Policy` | workflow permissions, pinned `uses:`, public ACLs, wildcard IAM |
| [`links.py`](links.py) · [`translations.py`](translations.py) | `CI: Build` | internal links resolve; en / es / zh keep the same headings |
| [`browser.py`](browser.py) | `CI: Build` | the viewer pages still render |
| [`actions.py`](actions.py) | `CI: Build` | a composite's `run:` body executes under the runner's flags |

[`hooks/`](hooks/) holds the MkDocs build hooks (`releases.py` builds the timeline from the two
CHANGELOG files, `vendor.py` copies the JS bundles from `node_modules`), and
[`bootstraps/aws.sh`](bootstraps/aws.sh) is the one-command AWS bootstrap.
