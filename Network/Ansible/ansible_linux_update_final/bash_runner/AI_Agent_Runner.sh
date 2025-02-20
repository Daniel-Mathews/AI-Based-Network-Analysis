#!/bin/bash
bash /home/aniket/ansible_linux_update_final/resources/AI_FINAL/db_clean.sh
ansible-playbook -i /home/aniket/ansible_linux_update_final/hosts /home/aniket/ansible_linux_update_final/ansible_scripts/AI_Agent_Runner.yaml -e "ansible_become_password=Cottons@1327"
