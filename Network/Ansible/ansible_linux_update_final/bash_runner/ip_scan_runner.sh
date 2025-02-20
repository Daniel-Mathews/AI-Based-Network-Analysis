#!/bin/bash

ansible-playbook -i /home/aniket/ansible_linux_update_final/hosts /home/aniket/ansible_linux_update_final/ansible_scripts/ip_db_scan_runner.yml -e "ansible_become_password=Cottons@1327"
