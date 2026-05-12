variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true  # This hides the value in CLI output
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "gemini_api_key"{
    description = "Gemini API key"
    type = string
    sensitive = true
}


# --- 1. PROVIDER CONFIGURATION ---
provider "aws" {
    region = var.region
}


# --- 2. ECR REPOSITORY (The Image Storage) ---
resource "aws_ecr_repository" "bot_repo" {
    name = "pr-summarizer-bot"
}

# --- 3. SECURITY GROUP ---
resource "aws_security_group_rule" "allow_k3s_api"{
    type = "ingress"
    from_port = 6443
    to_port = 6443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "sg-0e2b51a05d006af52"
}



resource "aws_security_group_rule" "allow_ssh"{
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "sg-0e2b51a05d006af52"
}

# --- 4. EC2 INSTANCE (The K3s Node) ---
resource "aws_instance" "k3s_node" {
    ami = "ami-0dee22c13ea7a9a67" # Ubuntu 24.04 LTS in ap-south-1
    instance_type = "t3.micro"
    subnet_id = "subnet-050384300e7f328ef"
    vpc_security_group_ids = ["sg-0e2b51a05d006af52"]
    associate_public_ip_address = true

   user_data = <<-EOF
                #!/bin/bash
                # 1. Create a 2GB Swap file to prevent the t3.micro from freezing
                fallocate -l 2G /swapfile
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo '/swapfile none swap sw 0 0' >> /etc/fstab

                # 2. Update and install K3s with reduced memory footprint
                sudo apt-get update -y
                curl -sfL https://get.k3s.io | sh -s - --disable traefik

                # 3. Wait and setup Kubeconfig
                sleep 20
                mkdir -p /home/ubuntu/.kube
                sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
                sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
                
                # 4. Map Public IP for remote access
                PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
                sudo sed -i "s/127.0.0.1/$PUBLIC_IP/g" /home/ubuntu/.kube/config
                EOF
    tags = {
        Name = "k3s-bot-node"
    }
}

# --- 5. OUTPUT THE IP ---
output "k3s_public_ip" {
  value = aws_instance.k3s_node.public_ip
}

