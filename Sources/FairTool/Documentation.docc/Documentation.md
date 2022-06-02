# ``FairTool``

Utility to manage an ecosystem of apps.

## Installation

On systems with [Hombrew](https://brew.sh) installed, the simplest
way to install fairtool is with the commands:

```
brew tap appfair/app
brew install fairtool
```

## Usage

```
OVERVIEW: Manage a fair-ground ecosystem of apps.

USAGE: fairtool <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  welcome                 Show the welcome message.
  validate                Validate the project.
  merge                   Merge base fair-ground updates into the project.
  catalog                 Build the app catalog.
  appcasks                Build the enhanced appcasks catalog.
  fairseal                Generates fairseal from trusted artifact.
  icon                    Create an icon for the given project.

  See 'fairtool help <subcommand>' for detailed help.
```


## More Info

All the functionality in this tool is also available through
the [FairCore swift library](../faircore/).

