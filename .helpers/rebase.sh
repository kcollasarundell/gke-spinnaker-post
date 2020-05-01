#!/bin/bash

# A super dodgy script to help manage the branches for this repo.
# this exists to help me do bug fixes as I work on posts in the series

upstream=0-gke-and-spinnaker
for branch in 1-project-setup  2-gke-module 3-worker-clusters 4-iam-for-days; do
    echo $upstream $branch
    git rebase -v $upstream $branch
done