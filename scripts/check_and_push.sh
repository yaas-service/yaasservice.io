#!/bin/bash
# check_and_push.sh - Safe Git Check and Push Script (Fixed Version)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking and Pushing YaaS Changes${NC}"

# Step 0: Check if we're in a detached HEAD state
echo -e "\n${BLUE}Checking git state...${NC}"
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)

if [ -z "$CURRENT_BRANCH" ]; then
  echo -e "${YELLOW}⚠️ You are in a detached HEAD state.${NC}"
  echo -e "${YELLOW}Creating a temporary branch to recover your changes...${NC}"
  
  # Create a temp branch and switch to it
  git branch temp-recovery-branch
  git checkout temp-recovery-branch
  
  echo -e "${GREEN}✅ Created and switched to temporary branch 'temp-recovery-branch'${NC}"
  echo -e "${YELLOW}After pushing, you may want to merge this branch into 'main'.${NC}"
  
  CURRENT_BRANCH="temp-recovery-branch"
fi

echo -e "${GREEN}Current branch: $CURRENT_BRANCH${NC}"

# Step 1: Check for uncommitted changes
echo -e "\n${BLUE}Checking for uncommitted changes...${NC}"
CHANGED_FILES=$(git status --porcelain)

if [ -z "$CHANGED_FILES" ]; then
  echo -e "${YELLOW}No changes to commit.${NC}"
else
  echo -e "${GREEN}Changes detected:${NC}"
  git status --short
  
  # Step 2: Check for sensitive files
  echo -e "\n${BLUE}Checking for sensitive files...${NC}"
  SENSITIVE_FILES=$(git status --porcelain | grep -E "\.env$|\.pem$|\.key$|password|secret|token" | grep -v "\.example$|\.sample$")
  
  if [ ! -z "$SENSITIVE_FILES" ]; then
    echo -e "${RED}⚠️ WARNING: Potentially sensitive files detected:${NC}"
    echo "$SENSITIVE_FILES"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Operation cancelled.${NC}"
      exit 1
    fi
  fi
  
  # Step 3: Run any tests or linting
  echo -e "\n${BLUE}Running quick tests...${NC}"
  TESTS_EXIST=false
  
  # Check if test script exists and run it
  if [ -f "scripts/test_yaas.sh" ]; then
    echo -e "${BLUE}Running API tests...${NC}"
    bash scripts/test_yaas.sh
    TEST_RESULT=$?
    TESTS_EXIST=true
    
    if [ $TEST_RESULT -ne 0 ]; then
      echo -e "${RED}❌ Tests failed. Fix errors before committing.${NC}"
      exit 1
    fi
  elif [ -f "test_yaas.sh" ]; then
    echo -e "${BLUE}Running API tests...${NC}"
    bash test_yaas.sh
    TEST_RESULT=$?
    TESTS_EXIST=true
    
    if [ $TEST_RESULT -ne 0 ]; then
      echo -e "${RED}❌ Tests failed. Fix errors before committing.${NC}"
      exit 1
    fi
  fi
  
  if [ "$TESTS_EXIST" = false ]; then
    echo -e "${YELLOW}⚠️ No tests found. Consider adding tests for your code.${NC}"
  else
    echo -e "${GREEN}✅ Tests passed.${NC}"
  fi
  
  # Step 4: Prompt for commit message
  echo -e "\n${BLUE}Creating commit...${NC}"
  read -p "Enter commit message: " COMMIT_MSG
  
  if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Update YaaS service $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${YELLOW}Using default commit message: $COMMIT_MSG${NC}"
  fi
  
  # Step 5: Add and commit changes
  git add .
  git commit -m "$COMMIT_MSG"
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Commit failed.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Changes committed.${NC}"
fi

# Step 6: Push changes
echo -e "\n${BLUE}Pushing changes to remote...${NC}"
# First check if the branch exists on remote
git ls-remote --heads origin $CURRENT_BRANCH > /dev/null
HAS_REMOTE=$?

if [ $HAS_REMOTE -eq 0 ]; then
  # Branch exists on remote, normal push
  echo -e "${BLUE}Branch exists on remote, pushing updates...${NC}"
  git push origin $CURRENT_BRANCH
else
  # Branch doesn't exist, set upstream
  echo -e "${BLUE}Branch doesn't exist on remote, creating it...${NC}"
  git push -u origin $CURRENT_BRANCH
fi

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Push failed.${NC}"
  echo -e "${YELLOW}You may need to pull remote changes first.${NC}"
  
  read -p "Force push changes? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️ Force pushing changes...${NC}"
    git push --force origin $CURRENT_BRANCH
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Force push failed.${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}✅ Changes force pushed successfully.${NC}"
  else
    echo -e "${YELLOW}Push operation cancelled.${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✅ Changes pushed successfully.${NC}"
fi

# Step 7: If we're on a temporary branch, offer to merge to main
if [ "$CURRENT_BRANCH" = "temp-recovery-branch" ]; then
  echo -e "\n${BLUE}You're on a temporary recovery branch.${NC}"
  read -p "Would you like to merge these changes into main now? (y/n) " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Switching to main and merging changes...${NC}"
    git checkout main
    git merge temp-recovery-branch
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Merge to main failed. You'll need to resolve conflicts manually.${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}✅ Successfully merged changes to main.${NC}"
    read -p "Delete the temporary branch now? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git branch -d temp-recovery-branch
      echo -e "${GREEN}✅ Temporary branch deleted.${NC}"
    fi
  else
    echo -e "${YELLOW}Kept temporary branch 'temp-recovery-branch'.${NC}"
    echo -e "${YELLOW}Remember to merge it into main later.${NC}"
  fi
fi

# Step 8: Check deployment status
echo -e "\n${BLUE}Checking deployment status...${NC}"

if command -v vercel &> /dev/null; then
  vercel ls 1>/dev/null
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Vercel project linked.${NC}"
    
    read -p "Deploy changes now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${BLUE}Deploying to Vercel...${NC}"
      
      if [ -f "scripts/deploy_yaas.sh" ]; then
        bash scripts/deploy_yaas.sh
      else
        vercel deploy --prod
      fi
      
      if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Deployment failed.${NC}"
        exit 1
      fi
      
      echo -e "${GREEN}✅ Deployment successful.${NC}"
    else
      echo -e "${YELLOW}Deployment skipped.${NC}"
    fi
  else
    echo -e "${YELLOW}⚠️ Vercel project not linked.${NC}"
  fi
else
  echo -e "${YELLOW}⚠️ Vercel CLI not installed. Skipping deployment check.${NC}"
fi

echo -e "\n${GREEN}🎉 All operations completed successfully!${NC}"
echo -e "${BLUE}Your YaaS changes have been pushed and (if selected) deployed.${NC}"
