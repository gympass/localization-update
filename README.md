# localization-update

This action gets translation keys from the Gympass localization-api.

## How to use

This action can be included into a workflow of any GitHub repository by inserting the reference to it into the steps section of a job.
In order for this action to work, the source files must be cloned into the runner. It can be achieved by using the action actions/checkout@v2 for cloning the source files on a step before this action.
Example:

```
    steps:
    - uses: actions/checkout@v2

    - name: Update translations
      uses: gympass/localization-update@v2
```
Is important to notice that this action is gonna run everytime a commit is made to the repository, so it will act accordingly to the configuration parameters defined for the action everytime a commit is made.
If you don't want this to happen, you should define when this action should run by inserting an 'if' statement before it.
In the 'if' statement you can define the commit on which branch is gonna trigger this action, like in the example:

```
    if:  github.ref == 'refs/heads/master' || contains(github.ref, 'devint')

    steps:
    - uses: actions/checkout@v2

    - name: Update translations
      uses: gympass/localization-update@v2
```
In the example above, the action only runs if the commit is made to the 'mater' branche or a branch containing 'devint' in the name, otherwise it is skiped.
<br />
<br />
### Parameters

This action provides a set of parameters you can use for defining how the translation files are going to be created.
You can specify the folder where the translation files are going to be created, if the files are going to be commited to the repository, if the commit will be in a new branch, etc.

In the table bellow you see the possible parameters and theys purpose:
<br />
<br />

| Parameter               | Reason         | Required     | Default value |
| ----------------------- | -------------- | ------------ | ------------- |
| localization_api_host   | The localization-api host from where to get <br /> the translations | yes  | |
| translation_format      | The format of the json containing the <br /> translation keys. Possible values are: <br /> flat <br /> levels | yes | |
| translation_folder      | The folder on where the translation files are <br /> going to be created | yes | | 
| translation_folder_overwrite | Whether to overwrite a pre-existing translations <br /> folder or not | no | false |
| individual_locale_files | Indicates wheter to create an individual file <br /> for each locale or not | no | false |
| translation_filename    | The name of the file containing the translation <br /> keys. This applies only if the 'individual_locale_files' <br /> parameter is set to false | no | auto_gen_translations.json |
| commit_changes          | Indicate whether the translation files are <br /> going to be commited or not | no | true |
| commit_message          | A message to be included in the commit | no | new translations |
| create_branch           | Indicates wheather to create a branch with the <br /> new translation files or not. <br /> If set to false and the 'commit_changes' is set <br /> to true, the commit is made into the master branch. | no | true |
| branch_prefix           | Defines a prefix to be used in the branch name. <br /> Only applies if the 'create_branch' parameter is <br /> set to true | no | auto_gen_translations |
| main_branch_name        | Indicates the name of the main branch of the repository. <br /> The value defined here will define where the commits are <br /> made if the 'create_branch' parameter is set to false. | no | master |
| namespace               | The namespace in the localization service from where to get <br /> translation keys. | yes | |
| feature                 | The feature of the application. If all the keys, of all the features <br /> are wanted, this parameter should be set with the same <br /> value as the 'namespace' parameter | yes | 
| separator               | A character or string to be used as separator between the parts of the keys | no | . (period) |
| omit_key_first_level    | Whether to omit or not the first part of the key name, which is defined in the feature parameter | no | false | 
| on_error_bypass         | Whether to finish the execution of the script with success, even it fails, or not | no | false |

### Branch protection rules

If the repository is configured to have branch protection rules and commits directly to the master branch are not allowed, the action is not going to be able to commit the new translation files when configured to commit to the master.
In this case, you will need to include a secret in your repository, containing a personal token which have the administrator permissions, then include the secret to the workflow, like in the example:

```
steps:
    - uses: actions/checkout@v2
      with:
        token: ${{ secrets.SECRET_CONTAINING_THE_TOKEN }}
```
### Putting all together

This is an example of a workflow yaml using this action:

```
name: Build & Release

on:
  push:

jobs:
  release:
    runs-on: [self-hosted]

    if:  github.ref == 'refs/heads/master' || contains(github.ref, 'devint')

    steps:
    - uses: actions/checkout@v2
      with:
        token: ${{ secrets.SECRET_CONTAINING_THE_TOKEN }}

    - name: Update translations
      uses: gympass/localization-update@v2
      with:
        localization_api_host: https://localization-api.gympass.com
        translation_format: flat
        translation_folder: lang
        translation_folder_overwrite: true
        translation_filename: trs.json
        individual_locale_files: true
        commit_changes: true
        create_branch: true
        branch_prefix: auto_gen_branch
        main_branch_name: master
        namespace: account
        feature: account
```
