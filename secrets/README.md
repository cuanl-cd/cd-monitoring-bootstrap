# Secrets

The <https://github.com/Cloud-Direct-Monitoring/cd-monitoring-bootstrap> module expects four files in a secrets subfolder. These are used to populate secrets in the client repo via the GitHub personal access token.

## Downloading

The files may be downloaded from the <https://github.com/Cloud-Direct-Monitoring/cd-monitoring-secrets> repo.

* action_group_webhook_uri.txt
* github_app.pem
* known_hosts.txt
* ssh_key.txt

Check that the files are placed in this secrets folder and have LF for the end of line rather than CRLF. The Visual Studio Code status bar shows the end of line sequence. Click on it to change between CRLF and LF.

## Bash Commands

If you have read access to the <https://github.com/Cloud-Direct-Monitoring/cd-monitoring-secrets> repo then you can use the Bash commands to pull the files down.

⚠️ Use with caution!!

```bash
[[ -d secrets/ ]] && rm -fr secrets/
git clone https://github.com/Cloud-Direct-Monitoring/cd-monitoring-secrets secrets && rm -fr secrets/.git/
```
