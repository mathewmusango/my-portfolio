# scripts

`dev.sh` drives the dev container declared in the root `compose.yaml`:

```sh
scripts/dev.sh build | start | restart | stop
```

Once per machine, before the first `build`:

```sh
mkcert -install
mkdir -p certs
mkcert -cert-file certs/portfolio.pem -key-file certs/portfolio-key.pem \
  portfolio.mathewmusango.test localhost 127.0.0.1
echo "127.0.0.1 portfolio.mathewmusango.test" | sudo tee -a /etc/hosts
```

The site answers at <https://portfolio.mathewmusango.test:8000>, with `/health` for the container
check.

| Script | Runs in | What it checks |
| --- | --- | --- |
| `policy.py` | `CI: Policy` | workflow permissions, pinned `uses:`, public ACLs, wildcard IAM |
| `links.py` · `translations.py` | `CI: Build` | internal links resolve; en / es / zh keep the same headings |
| `browser.py` | `CI: Build` | the viewer pages still render |
| `actions.py` | `CI: Build` | a composite's `run:` body executes under the runner's flags |

`hooks/` holds the MkDocs build hooks; `bootstraps/aws.sh` is the AWS bootstrap.
