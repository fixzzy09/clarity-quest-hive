# QuestHive
A gamified lifestyle dApp for tracking habits and daily goals on the Stacks blockchain.

## Overview
QuestHive allows users to create quests (goals/habits), complete them daily, and earn rewards. Users can:
- Create personal quests with rewards
- Complete quests daily 
- Earn experience points and level up
- View quest history and statistics

## Contract Functions
- `create-quest`: Create a new quest with title, description and reward (must be > 0)
- `complete-quest`: Mark a quest as complete for the day (must own the quest)
- `get-quest-status`: Check if a quest is completed for current day
- `get-user-level`: Get user's current level and experience points

## Contract Validation
- Quest rewards must be greater than 0
- Quests can only be completed by their owner
- Cannot complete non-existent quests
- Quests can only be completed once per day

## Installation & Testing
1. Install Clarinet
2. Clone repo
3. Run `clarinet test` to execute tests
