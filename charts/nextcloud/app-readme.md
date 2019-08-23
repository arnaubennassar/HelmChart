# Nextcloud

This app consist of three components:

1. Nextcloud server
2. MariaDB
3. A cronjob that triggers the update mechanism for content in Nextcloud.

## Set up

By default the App won't be accessible outside of localhost, it Nextcloud won't be available outside of LAN.

To fix this:
1. Connect to the Nextcloud volume
2. Edit the config: `sudo nano config/config.php`. Add the necessary URLs / IPs to the trusted domains ```
'trusted_domains' =>
array (
  0 => '192.168.1.12',
  1 => 'your.url.com',
),
```

Now you should be able to access from the specified domain.

Make sure the URL is reachable inside the cluster to be able to run the cronjob
