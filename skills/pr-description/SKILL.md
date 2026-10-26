---
name: pr-description
description: Return a concise PR description directly in chat, combining a plain-English change summary with existing screenshots. Does not save drafts, edit PRs, run tests, or capture screenshots.
---

# PR Description

Combine the output of [summarize-changes](../summarize-changes/SKILL.md)
with all relevant existing screenshots of the same scoped work. Use only the
images from prior UI testing, not its report, results table, testing instructions,
or logs.
User-supplied screenshots are also suitable when relevant.

Do not run tests, invoke a testing workflow, start services, capture new
screenshots, edit code, or change Git state. Return the description in chat only;
do not create or edit draft files, copy images, prefill browser forms, push,
create or edit PRs, or upload images as part of this skill.

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
For local files, resolve the actual paths before using them. Inventory the images
in the task-specific evidence directories even when individual paths are already
known; do not stop after finding the first useful pair.

If paths are absent, use a bounded filename search in the current repository's
artifact/output folders and task-specific temporary directories. Inspect project
documentation or existing report image links only as needed to locate files and
establish their provenance. For example, use `rg --files --hidden --no-ignore`
on a specific candidate directory, filtering for `.png`, `.jpg`, `.jpeg`, or
`.webp`. Exclude dependencies, Git internals, and build caches. Prefer directories
and filenames containing the feature, branch, PR number, screenshot, or evidence.
Do not scan the entire home directory or assume an agent-specific storage path.

Visually inspect candidate files using available image-reading tools. Include all
relevant images that contribute distinct evidence of the scoped work: reported
failures, baseline and fixed states, action transitions, adjacent interactions,
and tested layouts when available. Keep the prose concise without imposing an
image-count limit or dropping images merely because they show a failure. Verify
relevance from the conversation, capture context, or associated records;
modification time alone does not establish that an image depicts the current
work. Omit redundant captures of the same state, unrelated, unreadable, or stale
images, and images containing credentials or unrelated personal content. If
images cannot be inspected, ask for viewable images rather than inventing
captions.

Keep every relevant comparison pair complete, together, and in chronological
order; an action transition does not replace an available baseline/fixed pair.
Label before/after an action separately from before/after a code fix, and label
user-supplied historical evidence separately from controlled captures. If both
versions show normal completion, say so rather than implying the pair reproduces
the bug or proves an improvement. Do not infer a baseline or a passing test from
an image showing only the resulting state.

If no usable images are found, provide the summary draft and say: "No relevant
screenshots found. Please provide images or their local folder, or run UI testing
and share the generated screenshots." Do not run that testing yourself. If the
user explicitly wants a text-only description, honor that choice. Do not silently
fill the screenshot section with placeholders or unrelated images.

## Assemble the description

Use the opening summary, then a `## Screenshots` section with all relevant images
and short, factual captions describing the visible screen or state. Group images
by comparison or interaction when that makes the complete set easier to scan.
Add viewport or device information only when useful and known. Do not copy test statuses,
environment details, SQL, reports, or walkthrough text into the PR body. A visible
state supports only what it shows; never claim full verification from screenshots.

Return the assembled description directly in the final chat response, with
existing screenshots embedded inline. Use absolute paths for local images and
reuse accessible attachment URLs when available. Do not save the description
anywhere or add draft/report links, a preamble, or a closing offer.

Local image paths do not render on GitHub. When using them, add one short note
after the description telling the user to upload the images into the PR editor.
Keep that note and any missing-image notice outside the PR body.
