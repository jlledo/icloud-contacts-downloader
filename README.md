# iCloud Contacts Downloader

A script for downloading contacts from iCloud using [pyicloud](https://github.com/picklepete/pyicloud).

It prints the raw contacts JSON to stdout.

## Authentication

The script does not handle authentication and is designed to reuse an existing pyicloud session. The recommended approach for creating one is through [icloudpd](https://github.com/icloud-photos-downloader/icloud_photos_downloader):

```sh
read username; icloudpd --username $username --auth-only
```

## Environment Variables

- `ICLOUD_USERNAME` (mandatory)
- `COOKIE_DIRECTORY` (optional, defaults to `~/.pyicloud`)