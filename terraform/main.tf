provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}
resource "google_compute_project_metadata" "ssh_keys" {
    metadata {
      ssh-keys = <<EOF
      appuser1:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHrKcnXHv0OPNbZySxyJ0FUTsawtFzJKZTop+DwmzM5fwGHznnDGvUSH3Bf6zU6tnikYBNVhFSW5NNHcG4ue4jTjiUuWTgKxvek3nlgxh2KC7cKCrRMy81f93s8Xsnx4JAuEpOP4/CzvE6ExLUxYCJ/HKsovy1X9iQumqrNM3tbe14e4O6abizOCMWKkm2a1i95pFw39SRAz416xQzxq5pWK5VQxMHSdTP/Wgipvzk2ILh7Ak6SqWimvInINWOF56nq75xlJdrSnP5gka4t/qeKc8W6XuJ1ZKOeWhcGBktUoYsqLjWt38MBlpaMIAs9WBFDo2DSq98FFDpgxcmw4zv appuser
      appuser2:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHrKcnXHv0OPNbZySxyJ0FUTsawtFzJKZTop+DwmzM5fwGHznnDGvUSH3Bf6zU6tnikYBNVhFSW5NNHcG4ue4jTjiUuWTgKxvek3nlgxh2KC7cKCrRMy81f93s8Xsnx4JAuEpOP4/CzvE6ExLUxYCJ/HKsovy1X9iQumqrNM3tbe14e4O6abizOCMWKkm2a1i95pFw39SRAz416xQzxq5pWK5VQxMHSdTP/Wgipvzk2ILh7Ak6SqWimvInINWOF56nq75xlJdrSnP5gka4t/qeKc8W6XuJ1ZKOeWhcGBktUoYsqLjWt38MBlpaMIAs9WBFDo2DSq98FFDpgxcmw4zv appuser
EOF
    }
}


resource "google_compute_instance" "app" {
  name         = "reddit-app${count.index}"
  machine_type = "g1-small"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]
  count        = "${var.count}"

  # определение загрузочного диска
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  # определение сетевого интерфейса
  network_interface {
    # сеть, к которой присоединить данный интерфейс
    network = "default"

    # использовать ephemeral IP для доступа из Интернет
    access_config {}
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"

  # Название сети, в которой действует правило
  network = "default"

  # Какой доступ разрешить
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  # Каким адресам разрешаем доступ
  source_ranges = ["0.0.0.0/0"]

  # Правило применимо для инстансов с перечисленными тэгами
  target_tags = ["reddit-app"]
}
