#!/bin/bash

workspace=""
account=""
role="readonly"
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

while test $# -gt 0; do
  argument=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  case "$argument" in
    -h|--help)
      echo "usage: assume-role [options] <workspace>"
      echo " "
      echo "options:"
      echo "  -h, --help                show brief help"
      echo "  -a, --admin               assume role as admin with full-access"
      echo "                            (role is read-only by default)"
      echo "workspaces:"
      echo "  [dev|vbdev|qa|vbqa2|qc|integration|staging]"
      exit 0
      ;;
    -a|--admin)
      role="admin"
      shift
      ;;
    dev|vbdev|qa|vbqa2|qc|integration|staging)
      if [ -n "$workspace" ]; then
        echo -e "${RED}You cannot assume multiple roles${NC}"
        exit 0
      fi
      workspace="$argument"
      shift
      ;;
    *)
      [[ $argument == -* ]] && tokenType="option" || tokenType="argument"
      echo -e "${RED}Unrecognized $tokenType '$argument'${NC}"
      exit 0
      ;;
  esac
done

if [ -z "$workspace" ]; then
  echo -e "${RED}Workspace is required${NC}"
  exit 0
fi

case "$workspace" in
  dev|qa)
    account="dev/qa"
    ;;
  vbdev)
    account="vbdev"
    ;;
  vbqa2)
    account="vbqa2"
    ;;
  qc)
    account="qc"
    ;;
  integration|staging)
    account="integration/staging"
    ;;
  *)
    echo -e "${RED}Unknown workspace${NC}"
    exit 1
    ;;
esac

# export AWS_PROFILE="${account}_${role}"

echo -e "${GREEN}Successfully assumed role: ${account}_${role}${NC}"
