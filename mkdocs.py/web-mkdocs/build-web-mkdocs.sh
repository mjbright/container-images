#!/usr/bin/env bash

cd $(dirname $0)

python3 -m pip list | grep mkdocs ||
   python3 -m pip install mkdocs mkdocs-material

if [ "$1" = "-rm" ]; then
     set -x; rm -f docs/[0-9]*.md; set +x;
     exit
fi

#ls -altr ../

cp ../1.InstallTerraform/README.md            docs/1.InstallTerraform.md
cp ../2.Workflow/README.md                    docs/2.Workflow.md
cp ../3.TerraformVariables/README.md          docs/3.TerraformVariables.md
cp ../4.ControlStructures/README.md           docs/4.ControlStructures.md
cp ../5.TerraformDataSources/README.md        docs/5.TerraformDataSources.md

cp ../7.TerraformModules/README.md            docs/7.TerraformModules.md
cp ../8.ImportingResources/README.md          docs/8.ImportingResources.md

# TO EXCLUDE:
if [ 1 -eq 0 ]; then
    cp ../1.az.AzureContainersInstances/README.md docs/1.az.AzureContainersInstances.md
    cp ../2.az.Workflow/README.md                  docs/2.Workflow.md
    # ## cp ../2.az.Workflow/README.md                  docs/2.az.Workflow.md
    cp ../3.TerraformVariables/README.md          docs/3.TerraformVariables.md
    cp ../4.ControlStructures/README.md           docs/4.ControlStructures.md
    cp ../5.TerraformDataSources/README.md        docs/5.TerraformDataSources.md
    # cp ../6.StoringPersistentStates/README.md     docs/6.StoringPersistentStates.md
    cp ../7.TerraformModules/README.md            docs/7.TerraformModules.md
    cp ../8.ImportingResources/README.md          docs/8.ImportingResources.md
    # cp ../9.WorkingWithAKS/README.md              docs/9.WorkingWithAKS.md
fi

mkdir -p  docs/images
rsync -av ../images/ docs/images/

mkdocs build
# mkdocs serve -a 0.0.0.0:8080

pwd
cd site
python3 -m http.server --bind 0.0.0.0 8080

