resource "terraform_data" "copy_KP1_to_control" {
    depends_on = [  module.EC2_Control,                 # Just in case
                    module.KP ]
    input = {
        key_checksum = sha256(local_sensitive_file.keypair_KP.content)
    }
    provisioner "file" {
        source      = "${path.module}/KP.pem"
        destination = "/home/ubuntu/KP.pem"
        connection {
            type        = "ssh"
            user        = "ubuntu"
            private_key = module.KP.private_key_pem
            host        = module.EC2_Control.Public_IP
    }
  }
    provisioner "remote-exec" {
        inline = [
            "chmod 0400 /home/ubuntu/KP.pem",
            "chown ubuntu:ubuntu /home/ubuntu/KP.pem"
        ]
       connection {
            type        = "ssh"
            user        = "ubuntu"
            private_key = module.KP.private_key_pem
            host        = module.EC2_Control.Public_IP
    }
  }
}


