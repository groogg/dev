# Issue tracker: Jira

Issues and PRDs for this repo live as Jira issues. Use the `jira` CLI ([jira-cli](https://github.com/ankitpokhrel/jira-cli)) for all operations.

## Conventions

- **Create an issue**: `jira issue create -t Task -s "..." -b "..." -p <PROJECT_KEY>`. Use `-l` to apply labels.
- **Read an issue**: `jira issue view <ISSUE_KEY>` (e.g. `PROJ-123`).
- **List issues**: `jira issue list -p <PROJECT_KEY> --status "To Do" --plain --columns key,summary,status,labels`.
- **Comment on an issue**: `jira issue comment add <ISSUE_KEY> "..."`.
- **Apply labels**: `jira issue edit <ISSUE_KEY> --label "..."`.
- **Transition status**: `jira issue move <ISSUE_KEY> "<status>"` (e.g. `"In Progress"`, `"Done"`).
- **Link issues**: `jira issue link <ISSUE_KEY> <TARGET_KEY> "relates to"`.

The project key is inferred from the `PROJECT_KEY` configured during setup. If unknown, ask the user.

## When a skill says "publish to the issue tracker"

Create a Jira issue with `jira issue create`.

## When a skill says "fetch the relevant ticket"

Run `jira issue view <ISSUE_KEY>`. The user will normally pass the issue key directly.
