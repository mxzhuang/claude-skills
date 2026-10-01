# research-workflow

A Claude Code plugin for academic research: finding and reading papers, reviewing experiment designs before spending GPU time, running statistics, and handing work between sessions without losing context.

It is built for research, not product engineering. There are no coverage gates, TDD loops or CI checks here. The focus is on measurement, judgement and traceability.

> Skill and rule bodies are written in Traditional Chinese, with technical terms kept in English.

## Install

```
/plugin marketplace add mxzhuang/claude-skills
/plugin install research-workflow@research-workflow
```

The repository is private, so your GitHub account needs read access. Restart Claude Code after installing.

## What's inside

### Skills

| Skill | Use it to |
|---|---|
| `paper-search-pro` | Search OpenAlex, CrossRef, PubMed, arXiv and Semantic Scholar at a chosen depth, from a quick scan to a full audit trail. Outputs an HTML report and BibTeX. |
| `paper-analyst` | Summarise one paper into `.context/papers/`, tagging every claim as stated in the paper or inferred by the model. |
| `grill-me` | Interrogate a plan or experiment design one question at a time before it gets built. |
| `exp-design-check` | Check test assumptions, statistical power and group comparability before a sweep or ablation. |
| `handoff` | Compact a session into a handoff document that carries intent as well as status. |
| `humanizer-research-zhtw` | Check Traditional Chinese research writing for jargon, bare codenames and overclaiming. Reports only. |
| `project-setup` | Create a project's rules, hooks and `.context/` from `templates/`, then interview you to fill in the blanks. |

### Agents

| Agent | Does |
|---|---|
| `lit-scout` | Returns a ranked shortlist of related work for one question. |
| `paper-digest` | Reads one paper end to end and tags each claim. Run several in parallel. |
| `stat-runner` | Computes tests, effect sizes, confidence intervals and power. Returns numbers only, no interpretation. |
| `python-reviewer` | Reviews research Python: equation numbers, paper notation, path resolution, and keeping measurement separate from decisions. |
| `silent-failure-hunter` | Finds failures that raise no error, in code, config and docs. |
| `harness-optimizer` | Checks that hooks and context injection actually fire, verified by nonce rather than by asking the model. |

## Why this workflow

- **Three layers of memory.** Rules (`.claude/rules/`) hold what stays true across experiments. Knowledge (`.context/`) holds what was done, why, and where things stand. `CLAUDE.md` only points to both. A SessionStart hook injects the current focus into every new session and writes a one-time nonce, so you can confirm the injection really happened.
- **Claims are tagged.** Paper notes mark each claim `[原文陳述]` (stated in the paper) or `[模型推論]` (model inference), so an inference never gets cited later as fact.
- **Judgement stays with you.** Subagents investigate, analyse and summarise. Decisions that need a human are explicit gates the main agent must stop at.
- **Designs are reviewed before they run.** Plans go through `grill-me`, then a single adversarial reviewer (a subagent briefed with your criteria and asked for refutation conditions first, as described in `00-phase-routing`), then `exp-design-check`, all before any GPU time is spent.
- **Measurement traps are written down.** The rule templates name the mistakes that keep recurring: mismatched denominators, checks that cannot fail, and results from a cheap setting generalised to an expensive one.

## Set up a project's rules

Rules are not part of the plugin. Each project owns its own copy, so it can edit them freely.

**With the skill.** Open your project and ask Claude to "set up this research project". `project-setup` copies the templates and asks you for the blanks: environment, frozen files, directory layout and current focus.

**By hand.**

```bash
P=<your-project>
T=~/.claude/plugins/cache/research-workflow/research-workflow/*/templates   # or a clone of this repo

mkdir -p $P/.claude/rules $P/.claude/hooks
cp $T/rules/*.md $P/.claude/rules/ && rm $P/.claude/rules/README.md
cp $T/hooks/* $P/.claude/hooks/ && chmod +x $P/.claude/hooks/*
cp $T/settings.json $P/.claude/settings.json    # merge by hand if one already exists
cp -r $T/context $P/.context
cp $T/CLAUDE.md $P/CLAUDE.md
echo -e ".claude/hook-fired.log\n.context/log/" >> $P/.gitignore
```

Then:

1. Fill in the `<!-- 填入 -->` markers in `CLAUDE.md`, `10-environment.md` and `.context/current-focus.md`.
2. Delete `20-stable-core.md` if no files in the project are frozen.
3. If you don't write in Traditional Chinese, delete `80-reporting.md`, the two `humanizer` hooks, and the `Stop` hook entry in `settings.json`.

`templates/rules/README.md` explains the numbering and when to scope a rule with `paths:` frontmatter.

## Credits

Several skills and agents are adapted from these projects:

- [O0000-code/paper-search-pro](https://github.com/O0000-code/paper-search-pro) (Apache-2.0)
- [mattpocock/skills](https://github.com/mattpocock/skills) (MIT): `grill-me`, `handoff`
- [flyer-Li/paper-analyst](https://github.com/flyer-Li/paper-analyst) (MIT)
- [kevintsai1202/humanizer-zh-tw](https://github.com/kevintsai1202/humanizer-zh-tw) (MIT)
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) (MIT): base for three agents

Details are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Everything else is MIT-licensed.
