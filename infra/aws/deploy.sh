#!/bin/bash
#
# QXLI Full Stack Deployment Script
# ==================================
# This script handles the complete deployment pipeline:
# 1. Pre-flight sanity checks
# 2. Terraform infrastructure provisioning
# 3. Wait for EC2 instance to be ready
# 4. Ansible application deployment
#
# Usage: ./deploy.sh [apply|destroy|ansible-only]
#

set -euo pipefail

export AWS_PROFILE="qxli"

# ============================================================
# Configuration
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

# Default SSH key paths (can be overridden via environment)
SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY:-${HOME}/.ssh/qxli-aws}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-${HOME}/.ssh/qxli-aws.pub}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================
# Helper Functions
# ============================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
    log_info "✓ $1 found"
}

# ============================================================
# Pre-flight Sanity Checks
# ============================================================
preflight_checks() {
    log_info "Running pre-flight checks..."
    echo ""

    # Check required commands
    log_info "Checking required tools..."
    check_command terraform
    check_command ansible
    check_command ansible-playbook
    check_command ssh
    check_command jq
    echo ""

    # Check SSH keys
    log_info "Checking SSH keys..."
    if [[ ! -f "${SSH_PUBLIC_KEY}" ]]; then
        log_error "SSH public key not found at: ${SSH_PUBLIC_KEY}"
        log_info "Generate one with: ssh-keygen -t ed25519 -f ~/.ssh/qxli-aws -C 'qxli-aws'"
        exit 1
    fi
    log_info "✓ SSH public key found: ${SSH_PUBLIC_KEY}"

    if [[ ! -f "${SSH_PRIVATE_KEY}" ]]; then
        log_error "SSH private key not found at: ${SSH_PRIVATE_KEY}"
        exit 1
    fi
    log_info "✓ SSH private key found: ${SSH_PRIVATE_KEY}"
    echo ""

    # Check terraform.tfvars
    log_info "Checking Terraform configuration..."
    if [[ ! -f "${TERRAFORM_DIR}/terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found. Please create it from terraform.tfvars.example"
        exit 1
    fi
    log_info "✓ terraform.tfvars found"
    echo ""

    # Check docker-compose.yml exists
    log_info "Checking project files..."
    if [[ ! -f "${PROJECT_ROOT}/docker-compose.yml" ]]; then
        log_error "docker-compose.yml not found at ${PROJECT_ROOT}"
        exit 1
    fi
    log_info "✓ docker-compose.yml found"
    echo ""

    # Check AWS credentials
    log_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        log_warn "AWS credentials not configured or invalid."
        log_info "Configure with: aws configure"
        exit 1
    fi
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    log_info "✓ AWS credentials valid (Account: ${AWS_ACCOUNT})"
    echo ""

    log_success "All pre-flight checks passed!"
    echo ""
}

# ============================================================
# Terraform Operations
# ============================================================
terraform_init() {
    log_info "Initializing Terraform..."
    cd "${TERRAFORM_DIR}"
    terraform init -upgrade
    log_success "Terraform initialized"
    echo ""
}

terraform_plan() {
    log_info "Running Terraform plan..."
    cd "${TERRAFORM_DIR}"
    terraform plan -out=tfplan
    echo ""
}

terraform_apply() {
    log_info "Applying Terraform configuration..."
    cd "${TERRAFORM_DIR}"
    
    if [[ -f tfplan ]]; then
        terraform apply tfplan
        rm -f tfplan
    else
        terraform apply -auto-approve
    fi
    
    log_success "Terraform apply complete"
    echo ""
}

terraform_destroy() {
    log_warn "This will DESTROY all infrastructure!"
    read -p "Are you sure? (yes/no): " confirm
    if [[ "${confirm}" != "yes" ]]; then
        log_info "Aborted."
        exit 0
    fi
    
    cd "${TERRAFORM_DIR}"
    terraform destroy -auto-approve
    log_success "Infrastructure destroyed"
}

get_terraform_outputs() {
    cd "${TERRAFORM_DIR}"
    ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null || echo "")
    INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
    
    if [[ -z "${ELASTIC_IP}" ]]; then
        log_error "Could not get Elastic IP from Terraform outputs"
        exit 1
    fi
    
    log_info "Elastic IP: ${ELASTIC_IP}"
}

# ============================================================
# Wait for Instance
# ============================================================
wait_for_instance() {
    log_info "Waiting for EC2 instance to be ready..."
    
    # Wait for instance to be running
    local max_attempts=30
    local attempt=1
    
    while [[ ${attempt} -le ${max_attempts} ]]; do
        log_info "Checking instance status (attempt ${attempt}/${max_attempts})..."
        
        # Check if SSH is available
        if ssh -o StrictHostKeyChecking=no \
               -o UserKnownHostsFile=/dev/null \
               -o ConnectTimeout=5 \
               -i "${SSH_PRIVATE_KEY}" \
               "ubuntu@${ELASTIC_IP}" \
               "echo 'SSH ready'" 2>/dev/null; then
            log_success "Instance is ready and accepting SSH connections!"
            echo ""
            return 0
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_error "Timeout waiting for instance to be ready"
    exit 1
}

# ============================================================
# Ansible Deployment
# ============================================================
generate_inventory() {
    log_info "Generating Ansible inventory..."
    
    export ELASTIC_IP
    export SSH_PRIVATE_KEY
    
    envsubst < "${ANSIBLE_DIR}/inventory.ini.tpl" > "${ANSIBLE_DIR}/inventory.ini"
    
    log_info "Generated inventory:"
    cat "${ANSIBLE_DIR}/inventory.ini"
    echo ""
}

run_ansible() {
    log_info "Running Ansible playbook..."
    cd "${ANSIBLE_DIR}"
    
    ansible-playbook \
        -i inventory.ini \
        deploy.yml \
        --ask-become-pass \
        -v
    
    log_success "Ansible deployment complete!"
    echo ""
}

# ============================================================
# Summary
# ============================================================
print_summary() {
    echo ""
    echo "============================================================"
    echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
    echo "============================================================"
    echo ""
    echo "Your QXLI stack is now running at:"
    echo ""
    echo "  Elastic IP:    ${ELASTIC_IP}"
    echo ""
    echo "  Services:"
    echo "    - QXLI UI:   https://${ELASTIC_IP}:8888"
    echo "    - n8n:       https://${ELASTIC_IP}:5678"
    echo "    - Qdrant:    https://${ELASTIC_IP}:6333"
    echo ""
    echo "  SSH Access:"
    echo "    ssh -i ${SSH_PRIVATE_KEY} ubuntu@${ELASTIC_IP}"
    echo ""
    echo "  View logs:"
    echo "    ssh -i ${SSH_PRIVATE_KEY} ubuntu@${ELASTIC_IP} 'cd /opt/qxli && docker compose logs -f'"
    echo ""
    echo "============================================================"
}

# ============================================================
# Main
# ============================================================
main() {
    local action="${1:-apply}"
    
    echo ""
    echo "============================================================"
    echo "  QXLI Deployment Script"
    echo "============================================================"
    echo ""
    
    case "${action}" in
        apply)
            preflight_checks
            terraform_init
            terraform_plan
            
            read -p "Proceed with terraform apply? (yes/no): " confirm
            if [[ "${confirm}" != "yes" ]]; then
                log_info "Aborted."
                exit 0
            fi
            
            terraform_apply
            get_terraform_outputs
            wait_for_instance
            generate_inventory
            run_ansible
            print_summary
            ;;
        
        destroy)
            terraform_destroy
            ;;
        
        ansible-only)
            log_info "Running Ansible only (skipping Terraform)..."
            get_terraform_outputs
            generate_inventory
            run_ansible
            print_summary
            ;;
        
        plan)
            preflight_checks
            terraform_init
            terraform_plan
            ;;
        
        *)
            echo "Usage: $0 [apply|destroy|ansible-only|plan]"
            echo ""
            echo "Commands:"
            echo "  apply        - Full deployment (Terraform + Ansible)"
            echo "  destroy      - Destroy all infrastructure"
            echo "  ansible-only - Run only Ansible (requires existing infra)"
            echo "  plan         - Run Terraform plan only"
            exit 1
            ;;
    esac
}

main "$@"
