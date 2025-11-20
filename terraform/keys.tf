resource "b2_application_key" "backup" {
  key_name = "lmbackup"
  capabilities = [
    "listBuckets",
    "listFiles",
    "readFiles",
    "writeFiles",
    "deleteFiles",
  ]
}
