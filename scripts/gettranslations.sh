#!/bin/bash

while getopts h:f:d:r:i:n:p:c:o:b:m:s:e:t:l:k: flag
do
    case "${flag}" in
        h) localization_api_host=${OPTARG};;
        f) translation_format=${OPTARG};;
        d) translation_folder=${OPTARG};;
        r) translation_folder_overwrite=${OPTARG};;
        i) individual_locale_files=${OPTARG};;
        n) translation_filename=${OPTARG};;
        p) branch_prefix=${OPTARG};;
        c) commit_changes=${OPTARG};;
        o) commit_message=${OPTARG};;
        b) create_branch=${OPTARG};;
        m) main_branch_name=${OPTARG};;
        s) namespace=${OPTARG};;
        e) feature=${OPTARG};;
        t) separator=${OPTARG};;
        l) omit_key_first_level=${OPTARG};;
        k) on_error_bypass=${OPTARG};;
    esac
done

git config user.name github-actions
git config user.email github-actions@github.com
git pull

if [[ $translation_format == "flat" ]] || [[ $translation_format == "levels" ]] || [[ $translation_format == "pairs" ]]
then 
    echo "Using the $translation_format format for translation file(s)"
else    
    echo "invalid translation json format was informed: '$translation_format'. Using 'flat' format."
    translation_format="flat"
fi

if [ "$separator" == "" ]
then
    separator="."
fi

LOCALIZATION_ENDPOINT="$localization_api_host/v1/translations/$namespace/$feature?format=$translation_format&separator=$separator&omit_key_first_level=$omit_key_first_level"   
RES=$(/usr/bin/curl -s -w "\n%{http_code}" $LOCALIZATION_ENDPOINT)

TRANSLATIONS=${RES:0:${#RES}-4}
HTTP_STATUS_CODE=$(printf "%s" "$RES" | tail -c 3)

if [ "$HTTP_STATUS_CODE" -ne "200" ]  
then
    echo "Failed to get translations from localization-api: $HTTP_STATUS_CODE"
    FILES=(/"$translation_folder"/*)
    if ! [ ${#FILES[@]} -gt 0 ]; then exit 1; fi

    if [ "$on_error_bypass" = true ]
    then
        exit 0
    fi
    exit 1
fi

TRANSLATIONS=$(echo $TRANSLATIONS | jq 'del(.statusCode)')

if [[ -d "$translation_folder" ]]
then
    if [ "$translation_folder_overwrite" = true ]
    then
        echo "Translations directory already exists. Overwrite is enabled, so the directory will be overwritten."
        rm -rf "$translation_folder"
        mkdir -p ./"$translation_folder"
    else
        echo "Translations directory already exists. Gonna create new translation file inside it."
    fi    
else
    mkdir -p ./"$translation_folder"
fi

if [[ "$individual_locale_files" = true ]] && [[ $translation_format != "pairs" ]]
then    
    echo $TRANSLATIONS | jq -r '. | keys[]' | 
    while IFS= read -r locale; do 
        LOCALE_FILENAME=$(echo "$locale" | sed -r 's/[_]+/-/g')
        echo $TRANSLATIONS | jq '."'$locale'"' > ./"$translation_folder"/"$LOCALE_FILENAME.json"
    done
else
    echo $TRANSLATIONS | jq > ./"$translation_folder"/"$translation_filename"
    echo 'New translations file created'
fi

echo "# Do not change these files manually
Every change committed to the files in this folder are going to be replaced by the latest version of the translations available in the localization platform." > ./"$translation_folder/README.md"

if [ "$commit_changes" = true ]
then
    branch="$main_branch_name"
    if [ "$create_branch" = true ]
    then
        timestamp=$(date +%s)
        branch="$branch_prefix"_"$timestamp"
        git checkout -b $branch
    fi

    if [ "$commit_message" == "" ]
    then
        commit_message = "new translations"
    fi 
    git add .
    GITHUB_RESPONSE=$(git commit -m "$commit_message [skip ci]" )
    GITHUB_RESPONSE_UPTODATE="nothing to commit, working tree clean" 

    if [[ "$GITHUB_RESPONSE" == *"$GITHUB_RESPONSE_UPTODATE"* ]]
    then
        echo "No changes were made."
    else
        git push --set-upstream origin $branch
    fi    
fi
