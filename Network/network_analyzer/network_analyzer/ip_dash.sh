#!/bin/bash

/home/aniket/.local/bin/gunicorn  --workers 4 --bind 0.0.0.0:5000 IP_dashboard_v1:app --daemon
