# BUGATHON 2026 — Level 2

## The Developer's Mistake

**Difficulty:** Intermediate  
**Primary Skill:** SQL Injection

---

## Scenario

You've gained access to an internal Linux environment.

Something was left behind by the developers, and there are indications that an internal records system is still running somewhere inside the environment.

Your job is to investigate the system, follow the trail, and uncover what the developers accidentally exposed.

This challenge is designed as a chain of discoveries. The information you find at one stage should help you reach the next.

---

## Your Mission

Starting from your initial access, investigate the environment and:

- Identify useful information left behind on the server
- Discover the appropriate local account
- Pivot to the local account
- Investigate the hidden LPHU environment
- Discover how to reach the internal records portal
- Complete the portal's orientation process
- Investigate the record lookup functionality
- Identify the vulnerability in the application
- Enumerate the backend database
- Follow the internal record trail
- Investigate the protected audit endpoint
- Recover the information required to authenticate
- Reach the final audit stage

There are multiple checkpoints throughout the level.

Don't assume that the first interesting thing you find is the final objective.

---

# Starting Access

You begin with access to the server as:

```text
www-data
Hint 1
->Start by enumerating your current environment. Your initial user is not the account you ultimately need.

Hint 2
->Look through /var/www for files that may have been left behind by developers or administrators.

Hint 3
->The information you find should help you identify another local user and a way to access that account.

Hint 4
->After pivoting, inspect the new user's home directory carefully. Hidden files may contain important clues.

Hint 5
->The internal portal is not exposed like a normal web service. Think about SSH forwarding and Unix sockets.

Hint 6
->Once you reach the portal, complete the orientation process and pay attention to how different types of input are handled.

Hint 7
->The Record ID lookup does not properly handle all user input. Investigate what happens when you provide unexpected input.

Hint 8
->If you discover SQL injection, don't stop at confirming it. Use it to investigate the PostgreSQL database structure.

Hint 9
->Follow the database trail. An internal record will point you toward another protected service.

Hint 10
->The protected audit service requires credentials. Look back through the database for credential-related information, and remember that encoded data may need to be decoded before it becomes useful.
