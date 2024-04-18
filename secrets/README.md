# Secrets

The Terraform root module expects four files in this folder. These are used to populate secrets in the client repo via the GitHub personal access token.

## Downloading

The files may be downloaded from <https://github.com/Cloud-Direct-Monitoring/cd-monitoring-secrets> repo.

* action_group_webhook_uri.txt
* github_app.pem
* known_hosts.txt
* ssh_key.txt

Check that the files are placed in this secrets folder and have LF for the end of line rather than CRLF. The Visual Studio Code status bar shows the end of line sequence. Click on it to change between CRLF and LF.

## Additional info

The secrets are referenced in the client repo's workflows.

Ideally these would all be held as secrets at the github.com/Cloud-Direct-Monitoring organisation level (including the GitHub App ID). However, the use of organisation level secrets in the workflows of private repos requires a different GitHub plan to the free version.
