# Scripts

Here are some scripts that may be useful for generating helm chart values for use with the `dgraph-sec` helm chart.

## make_tls_secrets.sh

For instructions run `./make_tls_secrets.sh --help`

As an example:

```bash
./make_tls_secrets.sh \
  --release "my-release" \
  --namespace "default" \
  --replicas 3 \
  --extra "ratel.example.com,alpha.example.com" \
  --client "dgraphuser" \
  --zero
```

You can verify Dgraph Alpha certificates and keys with:

```bash
## verify certificates and keys
dgraph-sec cert ls --dir ./dgraph_tls/alpha
## verify list of addresses supported
dgraph-sec cert ls --dir ./dgraph_tls/alpha | awk -F: '/Hosts/{gsub(/\[ ]+/, "", $2); print $2}' | tr , '\n'
```

You can verify Dgraph Zero certificates and keys with:

```bash
## verify certificates and keys
dgraph-sec cert ls --dir ./dgraph_tls/zero
## verify list of addresses supported
dgraph-sec cert ls --dir ./dgraph_tls/zero | awk -F: '/Hosts/{gsub(/\[ ]+/, "", $2); print $2}' | tr , '\n'
```

## Restoring from a binary backup

The chart takes binary backups (full + incremental) via the backup CronJobs, but
restoring is a deliberate, operator-driven action — there is no automatic restore.
This is the runbook for an on-call restore.

> **Before you start**
> - Restore is **offline**: stop writes (scale alpha to 0, or restore into a fresh
>   namespace/cluster) before importing, then bring alpha back up.
> - You need the **same encryption key** the backup was taken with if encryption at
>   rest was enabled, and the backup's **ACL/credentials** if ACL was enabled.
> - Restore into a cluster of the **same (or newer) Dgraph version**.

1. **Locate the backup.** Backups land at `backups.destination` under the
   date-stamped `backups.subpath` directory (e.g. `s3://…/<bucket>/dgraph_YYYYMMDD`,
   the NFS mount, or the mounted volume). A full backup plus its later incrementals
   in the same directory form one restorable set.

2. **Run the restore** with the `dgraph-sec` binary against an empty `--postings`
   (`p`) directory. Run it from an alpha pod (or a one-off pod using the same image
   and the data PVC) so the output lands on the alpha data volume:

   ```bash
   # filesystem / NFS / mounted volume:
   dgraph-sec restore -p /dgraph/p -l /dgraph/backups/dgraph_YYYYMMDD

   # S3 / MinIO (credentials via env, as the backup CronJob sets them):
   dgraph-sec restore -p /dgraph/p \
     -l s3://s3.<region>.amazonaws.com/<bucket>/dgraph_YYYYMMDD

   # add the encryption key if encryption at rest was enabled:
   #   --encryption key-file=/dgraph/enc/enc_key_file
   # add TLS/ACL flags if the source cluster used them.
   ```

3. **Restart alpha** (scale back up / let the StatefulSet roll). Zero assigns a
   fresh timestamp range on first contact; verify with `dgraph-sec` that the
   schema and a sample query return the expected data before re-enabling writes.

See the upstream guide for the full flag set and online-restore option:
https://docs.dgraph.io/admin/admin-tasks/binary-backups#restore-from-backup
