# Secrets

The Terraform root module expects four files in this folder. These are used to populate secrets in the client repo via the GitHub personal access token.

The files may be downloaded from <https://github.com/Cloud-Direct-Monitoring/cd-monitoring-secrets> repo.

* action_group_webhook_uri.txt
* github_app.pem
* known_hosts.txt
* ssh_key.txt

The secrets are reference in the client repo's workflows.

Ideally these would all be held as secrets at the github.com/Cloud-Direct-Monitoring organisation level (including the GitHub App ID). However, the use of organisation level secrets in the workflows of private repos requires a different GitHub plan to the free version.
