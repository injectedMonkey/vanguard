#!/bin/bash
foo="\"{'php': {'version': 7.1}}\""

echo $foo

ansible-playbook ansible/playbook-local.yml --limit localhost --extra-vars "$foo"
