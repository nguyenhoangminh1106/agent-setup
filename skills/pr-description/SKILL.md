---
name: pr-description
description: Prepare a concise PR body combining a plain-English change summary with relevant screenshots already generated locally. Use for PR descriptions with visual evidence; never runs tests or captures new screenshots.
---

# PR Description

Combine the output of [summarize-changes](../summarize-changes/SKILL.md)
with existing screenshots of the same scoped work. Use only the images from
prior UI testing, not its report, results table, testing instructions, or logs.
User-supplied screenshots are also suitable when relevant.

Do not run tests, invoke a testing workflow, start services, capture new
screenshots, edit code, or change Git state. Preparing a description does not
authorize pushing, creating a PR, uploading images, or editing a remote PR.

## Summary

Apply `summarize-changes` and its scope discovery. Reuse a summary and scope
already established in the conversation when they still match the current work;
otherwise read the sibling skill and follow it. If the dependency is not at the
linked path, locate it through the agent's available skill directories. Report
a missing dependency rather than inventing its instructions.

Keep its short, non-technical wording as the opening paragraph. This skill adds
screenshots to that output; it does not expand the summary into a test report.

## Find existing images

Start with image attachments, file paths, and evidence directories mentioned in
the current conversation. Reuse accessible attachment URLs when already supplied.
For local files, resolve the actual paths before using them.

If paths are absent, use a bounded filename search in the current repository's
artifact/output folders and task-specific temporary directories. Inspect project
documentation or existing report image links only as needed to locate files and
establish their provenance. For example, use `rg --files --hidden --no-ignore`
on a specific candidate directory, filtering for `.png`, `.jpg`, `.jpeg`, or
`.webp`. Exclude dependencies, Git internals, and build caches. Prefer directories
and filenames containing the feature, branch, PR number, screenshot, or evidence.
Do not scan the entire home directory or assume an agent-specific storage path.

Visually inspect candidate files using available image-reading tools. Select a
small set that clearly shows the scoped change. Verify relevance from the
conversation, capture context, or associated records; modification time alone
does not establish that an image depicts the current work. Skip unrelated,
unreadable, or stale captures. If images cannot be inspected, ask for viewable
images rather than inventing captions. Do not include credentials or unrelated
personal content.

Keep meaningful comparison pairs together and in chronological order. Label
before/after an action separately from before/after a code fix. Do not infer a
baseline or a passing test from an image showing only the resulting state.

If no usable images are found, provide the summary draft and say: "No relevant
screenshots found. Please provide images or their local folder, or run UI testing
and share the generated screenshots." Do not run that testing yourself. If the
user explicitly wants a text-only description, honor that choice. Do not silently
fill the screenshot section with placeholders or unrelated images.

## Assemble the description

Use the opening summary, then a `## Screenshots` section with the selected images
and short, factual captions describing the visible screen or state. Add viewport
or device information only when useful and known. Do not copy test statuses,
environment details, SQL, reports, or walkthrough text into the PR body. A visible
state supports only what it shows; never claim full verification from screenshots.

For a local draft, save Markdown in an existing task artifact directory or a
temporary evidence directory, outside tracked source by default. Use relative
image links, copying only the selected files beside the draft if necessary,
without overwriting originals. Return a link to the draft and preview the
selected images when the agent can display them. Keep the missing-image notice
and publishing instructions outside the PR body.

Local image paths do not render on GitHub. A local draft remains pending image
upload; do not call it published or GitHub-ready while those paths remain.

## When publication is requested

If the user also authorizes creating or updating a PR, use the prepared body and
upload the selected images through available authenticated GitHub tooling. Check
the installed tool's capabilities first; for example, a GitHub CLI supporting
`gh pr create --attach` or `gh pr edit --attach` can upload local images. Reuse
existing accessible attachment URLs instead of uploading duplicates. Ensure each
caption still refers to the right image and use returned attachment URLs rather
than local paths in the published description.

If authenticated upload is unavailable, preserve the draft and image files,
explain the limitation, and ask the user to attach the images in the GitHub PR
editor or provide hosted attachment URLs. Do not install tools, commit images,
or publish to another hosting service as a workaround. Do not push unless that
action was authorized. After a successful publication, read back the PR body to
verify the summary and image references, and return the PR link. Follow any
host-agent requirement to attach the PR to its task.

These instructions use standard Markdown and filesystem artifacts so the same
skill works in Claude, Codex, and Cursor. Choose equivalent tools actually
available in the active agent; no particular agent's API is required.
