Helm L10n Plugin
================
This plugin provides basic skeleton to localize a chart's informative messages,
and utilities to make the localization work-flow easier. 

## Usage

### Initialization: `helm l10n init <chart_path>`
This command creates the basic skeleton to add l10n support to the chart:
  `/chart.l10n.in`: This file is in .desktop like format and includes the sources
  strings for translation for this chart and any subcharts which needs
  localization. This is the file where you put any strings which should be
  translated.

  `/po/`: This directory will contain main .pot file and translated .po files

  `/templates/l10n.yaml`: This is a configmap that will contain all messages and
  their translations. It'll read `/chart.l10n` file which is generated with
  `helm l10n compile <chart_path>` command.

  `/templates/l10n-subcharts.yaml`: This template will generate a configmap for
  translation strings for each subchart. If this chart doesn't have sub-charts
  or does not provide translations for them, it can be removed.

`/chart.l10n.in` & `/po` are added to the `.helmignore` file.

### Extracting strings for translation: `helm l10n update_messages <chart_path>`
To extract source strings for translation from `chart.l10n.in` file,
you can use this command. Any time you update the source strings you should run
this command so that translation files are updated.

This command will generate a message catalogue file in `/po/<chart_name>.pot`,
which is the template for creating new .po files for translation. Additionally,
if there are any .po files in po/ directory, they'll be updated with new strings
too using `msgmerge` command.

### Generating the output file: `helm l10n compile <chart_path>`
Any time translation files are modified, this command should be used to create
the final output file containing all strings and their translations in .desktop
format inside `/chart.l10n` file. This file should be included in the helm package
and is used by l10n configmap template files inside `/templates` directory to
generate l10n configmaps when deployed.

## Example
### Adding localization support to an existing chart
```
> helm l10n init mychart

# Add/modify source strings for this chart and any subcharts in chart.l10n.in
> vim mychart/chart.l10n.in

# Create mychart/po/mychart.pot
> helm l10n update_messages mychart
Generating message catalogue file: mychart/po/mychart.pot
WARNING: No .po files found in mychart/po directory to update.

msginit -i mychart/po/mychart.pot -o mychart/po/fa.po -l fa_IR.UTF-8

# After translating strings in fa.po with an appropriate tool, we compile .po files
# into chart.l10n file containing all strings and their translations:
> helm l10n compile mychart

# Now, we can package the chart:
> helm package mychart
```

### Update existing translations
```
# Add/modify strings
> vim mychart/chart.l10n.in

# Update source strings in mychart.pot and all .po files under po/ directory
> helm l10n update_messages
Generating message catalogue file: mychart/po/mychart.pot
Updating translation file: mychart/po/fa.po
... done.

# Update po/fa.po translations with an appropriate tool (recommended) or a text editor
> vim mychart/po/fa.po

# Regenerate chart.l10n:
helm l10n compile mychart

# Create a new package
> helm package mychart
```

## Installation
```
helm plugin install https://gitlab.soc1.ir/devops/helm-l10n
```
Or you can manually extract the archive in your disk and run
```
helm plugin install path/to/plugin/dir
```
