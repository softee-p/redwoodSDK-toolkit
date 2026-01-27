# RedwoodSDK Toolkit

A collection of Claude Code skills and AI tooling for building apps with RedwoodSDK.


- **skills/** - Claude Code skills for RedwoodSDK development
- **docs/** - Local copy of RedwoodSDK documentation

## Using the skills

Copy the skills you want into your project's `.claude/skills/` folder, or point to them in your Claude settings.

Each skill has its own README/SKILL.md with usage details.


-- Skill creator prompt

Create a skill with the skill-creator skill named rwsdk-docs to be used by agents to get context from the official redwoodsdk docs.  There is a script @docs/scripts/update-docs.sh that pulls the most recent version of the docs from github and to be pulled  as markdown files into the docs/redwoodsdk-official folder with their original directory structure. I want to copy the whole contents of the redwoodsdk-official folder into the references folder of the skill and then go over all of the docs to create the index you will put into SKILL.md . Ultrathink.