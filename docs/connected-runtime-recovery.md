# Connected runtime recovery — Step A/B

This is a review-only recovery path for the missing npm v3 dependency lockfile. It does not certify PostgreSQL or enable financial operations. It uses an independent private GitHub repository; never push these files to CCC, ICA, or another existing project.

1. Create a new private repository `hunarjabbar/iraq-wholesale-enterprise` at https://github.com/new (or use `gh repo create hunarjabbar/iraq-wholesale-enterprise --private`). Grant the GitHub connector access to that repository if remote verification is desired.
2. Clone the supplied recovery bundle and push the certification branch as the first branch of the new repository. This is candidate code, not a production release. The initial default branch must contain the new workflow for manual dispatch.

```sh
git clone -b phase5/step-ab-certification /absolute/path/wholesale-enterprise-runtime-recovery.bundle iraq-wholesale-enterprise
cd iraq-wholesale-enterprise
git remote rename origin source-bundle
git remote add origin https://github.com/hunarjabbar/iraq-wholesale-enterprise.git
git push -u origin phase5/step-ab-certification
```

3. The review-only workflow can trigger on that branch's first push. Check Actions for `Dependency lockfile candidate (review only)`. If not triggered, manually run it after confirming the default branch contains the workflow:

```sh
gh workflow run dependency-lock-candidate.yml --ref phase5/step-ab-certification
gh run list --workflow dependency-lock-candidate.yml --branch phase5/step-ab-certification
```

4. Download the artifact named `wholesale-lockfile-candidate` from the completed run. Do not accept the artifact if the workflow failed, the audit exit code is nonzero, or the source commit differs from the checked-out commit. Review the full dependency graph and audit JSON. The connected runner uses `--ignore-scripts` during dependency resolution and validation; the actual application build and lifecycle scripts are covered only by the later full certification.

```sh
gh run download RUN_ID --name wholesale-lockfile-candidate --dir /tmp/wholesale-lock-review
(cd /tmp/wholesale-lock-review && sha256sum -c SHA256SUMS)
test "$(git rev-parse HEAD)" = "$(cat /tmp/wholesale-lock-review/source-commit.txt)"
test "$(cat /tmp/wholesale-lock-review/audit-exit-code.txt)" = 0
cp /tmp/wholesale-lock-review/package-lock.json .
npm run check:lock
# Review candidate package-lock.json and dependency-audit.json before committing.
git add package-lock.json
git commit -m 'Pin reviewed wholesale dependencies'
git push
```

5. The existing Enterprise acceptance workflow will now be eligible to run full PostgreSQL, Prisma, six application builds, HTTP/Chromium/IndexedDB, and concurrency acceptance on GitHub Actions. Review the run and artifacts; Step C remains locked until actual evidence is accepted. Branch protection must be separately configured. This recovery workflow has no repository write permission and no deployment or live provider credentials. A candidate artifact is not evidence of database acceptance.
