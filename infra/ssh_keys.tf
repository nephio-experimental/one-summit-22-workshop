resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh-keys = file("keys/nephio")
  }
}

#to genereate the key: ssh-keygen -t rsa -f ~/.ssh/nephio.pub -C nephio -b 2048 and then edit keys/nephio and change it to the format username:ssh-rsa xxxxx username
