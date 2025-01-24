#!/bin/bash

# Define the source and target repositories
SOURCE_REPO="ktlint"
TARGET_REPO="test-mirror"
ORG_NAME="cider-org"  # Replace with your GitHub organization name
GITHUB_TOKEN=$TOKEN_FOR_GITHUB_COM  # Replace with your GitHub token

# Log the repository URLs
echo "Source repository URL: https://github.com/$ORG_NAME/$SOURCE_REPO.git"
echo "Target repository URL: https://$GITHUB_TOKEN@github.com/$ORG_NAME/$TARGET_REPO.git"

# Clone the source repository as a mirror
echo "Cloning the source repository..."
if git clone --mirror https://github.com/$ORG_NAME/$SOURCE_REPO.git; then
    echo "Successfully cloned the source repository."
else
    echo "Failed to clone the source repository."
    exit 1
fi

cd $SOURCE_REPO.git

# Remove pull request refs
echo "Removing pull request refs..."
for ref in $(git for-each-ref --format='%(refname)' refs/pull); do
    git update-ref -d $ref
done

# Push the mirror to the target repository
echo "Pushing the mirror to the target repository..."
if git push --mirror https://$GITHUB_TOKEN@github.com/$ORG_NAME/$TARGET_REPO.git; then
    echo "Successfully pushed the mirror to the target repository."
else
    echo "Failed to push the mirror to the target repository."
    exit 1
fi

# Clean up
cd ..
rm -rf $SOURCE_REPO.git

echo "Repository mirrored from $SOURCE_REPO to $TARGET_REPO"
