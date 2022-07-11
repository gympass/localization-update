#!/bin/bash

while getopts h:f:d:i:n:p:c:b:s:e: flag
do
    case "${flag}" in
        h) localization_api_host=${OPTARG};;
        f) translation_format=${OPTARG};;
        d) translation_folder=${OPTARG};;
        i) individual_locale_files=${OPTARG};;
        n) translation_filename=${OPTARG};;
        p) branch_prefix=${OPTARG};;
        c) commit_changes=${OPTARG};;
        b) create_branch=${OPTARG};;
        s) namespace=${OPTARG};;
        e) feature=${OPTARG};;
    esac
done

git config user.name github-actions
git config user.email github-actions@github.com
git pull

if [[ -d "$translation_folder" ]]
then
    echo "Translations directory already exists. Gonna create new translation file inside it."
else
    mkdir -p ./"$translation_folder"
fi

# FORMATTING
if [ "$translation_format" == "flat" ] | [ "$translation_format" == "levels" ]
then 
    echo "Using the $translation_format format for translation file(s)"
else    
    echo "invalid translation json format was informed: '$translation_format'. Using 'flat' format."
    translation_format="flat"
fi

LOCALIZATION_ENDPOINT="$localization_api_host/v1/translations/$namespace/$feature?format=$translation_format"   
TRANSLATIONS=`/usr/bin/curl -v --URL "$LOCALIZATION_ENDPOINT"`
if [ "$individual_locale_files" = true ]
then
    echo $TRANSLATIONS | jq -r '. | keys[]' | 
    while IFS= read -r locale; do 
        echo $TRANSLATIONS | jq '.'"$locale"'' > ./"$translation_folder"/"$locale.json"
    done
else
    echo $TRANSLATIONS | jq > ./"$translation_folder"/"$translation_filename"
    echo 'New translations file created'
fi

if [ "$commit_changes" = true ]
then
    if [ "$create_branch" = true ]
    then
        timestamp=$(date +%s)
        new_branch="$branch_prefix"_"$timestamp"
        git checkout -b $new_branch
    fi

    git add .
    GITHUB_RESPONSE=$(git commit -m "new translations")
    GITHUB_RESPONSE_UPTODATE="nothing to commit, working tree clean" 

    if [[ "$GITHUB_RESPONSE" == *"$GITHUB_RESPONSE_UPTODATE"* ]]
    then
        echo "No changes were made."
    else
        git push --set-upstream origin $new_branch
    fi
fi

#gh pr create --title "Test PR" --body "OK"
#gh pr create --base master
