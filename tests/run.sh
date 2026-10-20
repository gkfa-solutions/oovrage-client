#!/bin/bash
# Lance tous les tests du plugin : `bash tests/run.sh`.
cd "$(dirname "$0")/.." || exit 1
statut=0
for t in tests/test-*.sh; do
  bash "$t" || statut=1
done
exit $statut
