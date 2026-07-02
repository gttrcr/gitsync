# GitSync

GitSync is GitHub-based file manager written in bash.

## Configuration
```orgs.json``` is just a configuration file for GitSync. The structure of the ```orgs.json``` is the following:

```json
{
    "Organizations": [
        {
            "Organization": "name_of_organization_1",
            "Repos": [
                "repo_1",
                "repo_2",
                "-repo_3",
            ]
        },
        {
            "Organization": "name_of_organization_2",
            "Repos": [
                "repo_1",
                "repo_2",
            ]
        },
        {
            "Organization": "name_of_organization_3",
            "Repos": [
                "*"
            ]
        },
    ],
    "Path": "root/of/your/organizations"
}
```

The value ```"*"``` in ```Repos``` key means _every repo_ is the corresponding organization.

## Setup alias using the source code

```bash
cat >>~/.bashrc <<EOL
gitsync() {
    /home/iki/git/gttrcr/gitsync/script.sh "$1"
}
EOL
```

## Future improvements

```bash
git submodule update --remote --recursive --merge --init --force
git submodule foreach git pull
```
