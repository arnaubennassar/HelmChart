# Nextcloud

This app consist of three components:

1. Nextcloud server
2. MariaDB
3. A cronjob that triggers the update mechanism for content in Nextcloud.

## Set up

By default the App won't be accessible outside of localhost, it means that cronjob won't work if deployed in a different node and that Nextcloud won't be available outside of LAN.

To fix this:

### Make DB accessible from other nodes

1. Connect to the pod console running MariaDB
2. Log in to the DB: `mysql -u root -p`. You can find the password on the provided secret.
3. Grant permissions outside of localhost to the appropriate USER and DATABASE (again, check the secret): `GRANT ALL PRIVILEGES ON DATABASE.* TO 'USER'@'%';`
4. Apply the changes: `FLUSH PRIVILEGES;`
5. Check that permissions are OK: `SHOW GRANTS FOR 'USER'@'%';`
6. Leave

Now the cronjob is able to run from any node

### Make Nextcloud available from internet

1. Connect to the Nextcloud volume
2. Edit the config: `sudo nano config/config.php`. Add the necessary URLs / IPs to the trusted domains ```
'trusted_domains' =>
array (
  0 => '192.168.1.12',
  1 => 'your.url.com',
),
```

Now you should be able to access from the specified domain.
