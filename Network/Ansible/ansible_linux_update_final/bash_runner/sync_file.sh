#!/bin/bash

ansible-playbook -i /home/aniket/ansible_linux_update_final/hosts /home/aniket/ansible_linux_update_final/ansible_scripts/network_analyzer_sync.yaml -e "ansible_become_password=Cottons@1327"
