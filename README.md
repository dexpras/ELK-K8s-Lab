# ELK Kubernetes lab package

Start with ELK-Kubernetes-Lab-Guide.md or the included PDF.
Use Linux/Bash on your administration workstation.

1. Complete cluster, capacity, storage and permissions checks.
2. Copy lab.env.example to lab.env and select your StorageClass.
3. Follow the guide stage by stage. There is no automatic deployment script.

Contents:
- ELK-Kubernetes-Lab-Guide.md and PDF: full walkthrough and attention points.
- manifests/: Kubernetes YAML and parameterized templates.
- scripts/: rendering, lab certificate generation and authenticated API helpers.
- api/: retention, template and snapshot test request bodies.
- VALIDATION.txt: scope and limits of the checks performed.

The default architecture requires three eligible Linux nodes.
Snapshot storage and a production shared Kibana endpoint are environment-specific.
No live deployment was performed. Inspect and use server-side dry runs on your cluster.
Never share lab.env, .secrets or generated credentials.
