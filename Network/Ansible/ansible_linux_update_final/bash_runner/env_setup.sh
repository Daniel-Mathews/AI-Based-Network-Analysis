#!/bin/bash

ansible-playbook -i /home/aniket/ansible_linux_update_final/hosts /home/aniket/ansible_linux_update_final/ansible_scripts/bandwidth_setup_runner.yml -e "ansible_become_password=Cottons@1327"
