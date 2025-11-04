#!/bin/bash

# This script helps synchronize changes between different environment branches
# It can push the current changes to dev, production, or dr branches

set -e

function show_usage() {
  echo "Usage: $0 [options] <target_branch>"
  echo "Options:"
  echo "  -h, --help           Show this help message"
  echo "  -m, --message MESSAGE  Specify commit message (default: 'Update infrastructure')"
  echo ""
  echo "Target branches:"
  echo "  main         Push changes to main branch (dev environment)"
  echo "  production   Push changes to production branch (production environment)"
  echo "  dr           Push changes to dr branch (disaster recovery environment)"
  echo ""
  echo "Example:"
  echo "  $0 -m 'Update EC2 instance type' production"
}

# Default values
COMMIT_MESSAGE="Update infrastructure"

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      show_usage
      exit 0
      ;;
    -m|--message)
      COMMIT_MESSAGE="$2"
      shift
      shift
      ;;
    *)
      TARGET_BRANCH="$1"
      shift
      ;;
  esac
done

# Validate target branch
if [[ ! "$TARGET_BRANCH" =~ ^(main|production|dr)$ ]]; then
  echo "Error: Invalid target branch. Must be one of: main, production, dr"
  show_usage
  exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"

# Check if there are uncommitted changes
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Warning: You have uncommitted changes. Commit them before continuing."
  git status
  read -p "Do you want to commit these changes? (y/n): " COMMIT_CHANGES
  
  if [[ "$COMMIT_CHANGES" == "y" ]]; then
    git add .
    git commit -m "$COMMIT_MESSAGE"
    echo "Changes committed."
  else
    echo "Aborting. Please commit your changes manually."
    exit 1
  fi
fi

# If target branch is the current branch, just push
if [[ "$TARGET_BRANCH" == "$CURRENT_BRANCH" ]]; then
  echo "Pushing changes to $TARGET_BRANCH..."
  git push origin $TARGET_BRANCH
else
  # If target branch exists locally, check it out and merge
  if git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
    echo "Checking out $TARGET_BRANCH branch..."
    git checkout $TARGET_BRANCH
    
    echo "Updating $TARGET_BRANCH branch from remote..."
    git pull origin $TARGET_BRANCH || true
    
    echo "Merging changes from $CURRENT_BRANCH into $TARGET_BRANCH..."
    git merge $CURRENT_BRANCH
    
    echo "Pushing changes to $TARGET_BRANCH..."
    git push origin $TARGET_BRANCH
    
    # Return to original branch
    git checkout $CURRENT_BRANCH
  else
    # If target branch doesn't exist locally but exists remotely
    if git show-ref --verify --quiet refs/remotes/origin/$TARGET_BRANCH; then
      echo "Creating local $TARGET_BRANCH branch from remote..."
      git checkout -b $TARGET_BRANCH origin/$TARGET_BRANCH
      
      echo "Merging changes from $CURRENT_BRANCH into $TARGET_BRANCH..."
      git merge $CURRENT_BRANCH
      
      echo "Pushing changes to $TARGET_BRANCH..."
      git push origin $TARGET_BRANCH
      
      # Return to original branch
      git checkout $CURRENT_BRANCH
    else
      # If target branch doesn't exist locally or remotely
      echo "Creating new $TARGET_BRANCH branch..."
      git checkout -b $TARGET_BRANCH
      
      echo "Pushing new $TARGET_BRANCH branch to remote..."
      git push -u origin $TARGET_BRANCH
      
      # Return to original branch
      git checkout $CURRENT_BRANCH
    fi
  fi
fi

# Show completion message
echo ""
echo "✅ Changes successfully synchronized to $TARGET_BRANCH branch!"
echo ""

# Show next steps based on the target branch
case $TARGET_BRANCH in
  main)
    echo "Your changes will be deployed to the DEV environment."
    ;;
  production)
    echo "Your changes will be deployed to the PRODUCTION environment."
    echo "After deployment, the DR environment will be automatically synchronized."
    ;;
  dr)
    echo "Your changes will be deployed to the DR environment."
    echo "Note: This is unusual. Typically, the DR environment should be synchronized from production."
    ;;
esac

echo ""
echo "You can check the deployment status in GitHub Actions."