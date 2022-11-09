resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = local_file.public_key.content
  }
}
