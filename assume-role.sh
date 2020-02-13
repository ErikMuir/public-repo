#!/bin/bash

isAdmin=0
workspace=""
account=""

RED="\e[0;31m"
GREEN="\e[0;32m"
NC="\e[0m"

showHelp() {
  echo "usage: assume-role [options] <workspace>"
  echo " "
  echo "options:"
  echo "  -h, --help                show brief help"
  echo "  -a, --admin               assume role as admin with full-access"
  echo "                            (role is read-only by default)"
  echo "workspaces:"
  echo "  [dev|vbdev|qa|vbqa2|qc|integration|staging|prod]"
}

setAccount() {
  case "$1" in
    dev)
      account="????dev????"
      ;;
    vbdev)
      account="????vbdev????"
      ;;
    qa)
      account="????qa????"
      ;;
    vbqa2)
      account="????vbqa2????"
      ;;
    qc)
      account="????qc????"
      ;;
    integration)
      account="????integration????"
      ;;
    staging)
      account="????staging????"
      ;;
    prod)
      account="????prod????"
      ;;
    *)
      echo -e "${RED}Error: Unknown workspace${NC}"
      exit 1
      ;;
  esac
}

while test $# -gt 0; do
  case "${1,,}" in
    -h|--help)
      showHelp
      exit 0
      ;;
    -a|--admin)
      isAdmin=1
      shift
      ;;
    dev|vbdev|qa|vbqa2|qc|integration|staging|prod)
      if [ -n "$workspace" ]; then
        echo -e "${RED}Error: You cannot assume multiple roles${NC}"
        exit 0
      fi
      workspace="$1"
      shift
      ;;
    *)
      [[ $1 == -* ]] && tokenType="option" || tokenType="argument"
      echo -e "${RED}Error: Unrecognized $tokenType '$1'${NC}"
      exit 0
      ;;
  esac
done

if [ -z "$workspace" ]; then
  echo -e "${RED}Error: Workspace is required${NC}"
  exit 0
fi

setAccount $workspace

echo "$account"
