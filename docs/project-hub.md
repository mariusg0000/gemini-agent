# project-hub skill

`project-hub` is a persistent, per-project memory layer. It ensures that your ideas, plans, and decisions stay with your project files on disk, rather than being lost in a generic chat history.

## 🚀 Tutorial: Getting Started with Project Hubs

### 1. Initialize a Project
To start managing a project, you first need to register it.
> **You:** "Open project-hub for my new game 'Angry Towers' in /mnt/DATA/Work/AI/AngryTowers"

The agent will:
1.  Register the project in `~/.gemini-agent/projects.ini`.
2.  Create a `project-hub/` folder inside your game directory.
3.  Scaffold the core files: `00-home.md`, `01-current.md`, `02-inbox.md`, `03-plan.md`, and `04-knowledge.md`.

### 2. Passive Capture (The "Inbox")
Whenever you have a random idea or observation, just mention it. You don't need to be in the project context.
> **You:** "Am o idee: we should use a custom shader for the tower explosions in Angry Towers."

The agent will automatically identify the project and append your note to `project-hub/02-inbox.md`. It won't interrupt your current work.

### 3. Review and Integrate
When you are ready to work on the project, ask the agent to "Process the inbox."
> **You:** "Open project Angry Towers and process the inbox."

The agent will:
1.  Read your raw notes from `02-inbox.md`.
2.  Propose how to move them:
    -   Tasks go to `03-plan.md`.
    -   Facts/Decisions go to `04-knowledge.md`.
    -   The dashboard summary in `00-home.md` is updated.
3.  Clear the inbox once integrated.

### 4. Continuous Planning
As you finish tasks, the agent maintains the plan.
> **You:** "I finished the multiplayer relay. What's next for Angry Towers?"

The agent will check `03-plan.md`, mark the relay as `Done` (with a timestamp), and present the next item in the `Next` list.

---

## 📂 Structure

```
<project-root>/
  project-hub/
    00-home.md        Dashboard (Goals, Tech Stack, Progress)
    01-current.md     Active focus and immediate blockers
    02-inbox.md       Write-only capture for raw thoughts
    03-plan.md        The Task Matrix (Active, Next, Done, etc.)
    04-knowledge.md   Stable facts, architecture decisions, and conventions
```

## 🛠️ Configuration

The registry is stored at `~/.gemini-agent/projects.ini`. You can manually edit this file to add aliases or change paths:

```ini
[angrytower]
path=/mnt/DATA/Work/AI/AngryTowers
desc=Godot port and multiplayer relay implementation
aliases=angry towers, towers, game
```

## Safety Rules
- **No Fabrication**: The agent only documents what you tell it or what it observes in the code.
- **Verification**: After every update, the agent reads the hub files back to ensure no data was corrupted.
- **User Ownership**: The hub belongs to you. You can open these Markdown files in any editor (like Obsidian or VS Code) and edit them manually.
