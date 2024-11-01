#!/bin/bash

# Create the run-jit-config.sh script
cat <<EOF > /home/ubuntu/actions-runner/run-jit-config.sh
#!/bin/bash

# Get the GitHub token from SSM Parameter Store
GITHUB_TOKEN=\$(aws ssm get-parameter --name "/githubpp/token" --with-decryption --query "Parameter.Value" --output text)

# Authenticate to GitHub
echo \$GITHUB_TOKEN | gh auth login -h githubpp.vodafone.com --with-token

# Generate the JIT config
encoded_jit_config=\$(gh api --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  --hostname githubpp.vodafone.com \
  /orgs/test-actions/actions/runners/generate-jitconfig \
  -f "name=\$(hostname)" \
  -F "runner_group_id=7" \
  -f "labels[]=self-hosted" \
  -f "labels[]=X64" \
  -f "labels[]=linux" \
  -f "work_folder=_work" | jq -r ".encoded_jit_config")

# Run the action with the generated config
/home/ubuntu/actions-runner/run.sh --jitconfig "\$encoded_jit_config"

EOF

# Change ownership to ubuntu user
chown ubuntu:ubuntu /home/ubuntu/actions-runner/run-jit-config.sh

# Make the script executable
chmod 750 /home/ubuntu/actions-runner/run-jit-config.sh

# Create the unit file for JIT config
cat <<EOF > /etc/systemd/system/ghe-runner-jit-config.service
[Unit]
Description=Github Actions Runner JIT Configuration Service
After=network.target

[Service]
ExecStart=/home/ubuntu/actions-runner/run-jit-config.sh
User=ubuntu
WorkingDirectory=/home/ubuntu
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=5min

[Install]
WantedBy=multi-user.target
EOF

# Enable the service to start on boot without starting it immediately
systemctl enable ghe-runner-jit-config.service
