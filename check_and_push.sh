#!/bin/bash
# check_and_push.sh - Safe Git Check and Push Script

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking and Pushing YaaS Changes${NC}"

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

# Step 6: Check for remote changes
echo -e "\n${BLUE}Checking for remote changes...${NC}"
git fetch

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})
BASE=$(git merge-base @ @{u})

if [ $LOCAL = $REMOTE ]; then
  echo -e "${GREEN}Local repository is up to date with remote.${NC}"
elif [ $LOCAL = $BASE ]; then
  echo -e "${YELLOW}⚠️ Remote has changes that need to be pulled.${NC}"
  
  read -p "Pull remote changes before pushing? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Pulling remote changes...${NC}"
    git pull
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Pull failed. Resolve conflicts manually.${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}✅ Remote changes pulled successfully.${NC}"
  else
    echo -e "${YELLOW}Continuing without pulling...${NC}"
  fi
elif [ $REMOTE = $BASE ]; then
  echo -e "${GREEN}Local changes ready to be pushed.${NC}"
else
  echo -e "${YELLOW}⚠️ Local and remote have diverged.${NC}"
  
  read -p "Proceed with a merge? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Merging changes...${NC}"
    git pull
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Merge failed. Resolve conflicts manually.${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}✅ Merge successful.${NC}"
  else
    echo -e "${YELLOW}Continuing without merging...${NC}"
  fi
fi

# Step 7: Push changes
echo -e "\n${BLUE}Pushing changes to remote...${NC}"
git push

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Push failed.${NC}"
  echo -e "${YELLOW}You may need to pull remote changes first.${NC}"
  
  read -p "Force push changes? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠️ Force pushing changes...${NC}"
    git push --force
    
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
