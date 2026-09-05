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
->Your current shell is running under a restricted web-server account.
->Look around the web server's directories carefully.

Hint 2

->Developers sometimes leave behind scripts, backups, configuration files, or other operational information.
->Look for files that don't belong to the normal web application.

Hint 3
->You are looking for information that can help you move from the web-server account to a local user.

Hint 4
->Once you identify another local account, investigate what access methods are available to you.
->Think about how administrators normally access Linux systems remotely.

Hint 5

->After switching users, don't immediately start attacking the portal.
->Look around the new user's home directory.
->Hidden files may contain useful information.

Hint 6
->The internal application is not necessarily exposed as a normal TCP service.
->Look at the information you discovered about how the internal service is connected.

Hint 7
->SSH can do more than provide an interactive shell.
->Investigate SSH port/socket forwarding.

Hint 8

->Once you reach the portal, start with the orientation page.
->Read the information provided by the application carefully.
->The orientation process is part of the challenge.

Hint 9
->The orientation expects you to investigate more than one type of lookup.
->Pay attention to the difference between:

    ->A lookup that succeeds
    ->A lookup that doesn't find a record
    ->An unusual input

Hint 10
->The orientation provides an incident reference.

->Keep that reference. You will need it later.

Hint 11

Now investigate the Record ID lookup.

Try to understand how the application handles your input rather than simply entering valid numbers.

Hint 12

Applications should treat user input as data.

What happens if the application doesn't?

Hint 13

An error message from PostgreSQL can reveal information about the backend query.

If you can trigger a database error, study what the error tells you.

Hint 14

The vulnerability is SQL injection.

The goal isn't simply to prove that injection exists.

Use it to investigate the database.

Hint 15

You will need to learn about the database structure.

Think about how SQL can be used to discover:

Tables
Columns
Records
Hint 16

The interesting information isn't necessarily in the application's normal records.

Look for tables containing internal or operational information.

Hint 17

If you discover an internal record that references another endpoint, investigate that endpoint.

Don't assume a 401 Unauthorized response means you've reached a dead end.

Hint 18

HTTP authentication challenges tell you something important about the service.

The endpoint exists.

Now you need to figure out where the application gets its authentication information.

Hint 19

Return to your database enumeration.

Search for information related to the audit system and its credentials.

Hint 20

If you find something that looks like a credential but doesn't look readable, don't immediately assume it's encrypted.

Identify the encoding first.

Hint 21

Base64 is commonly used to represent data in a transport-friendly format.

If something looks like Base64, decode it and inspect the result.

Final Hint

You should now have everything required to authenticate to the audit system.

The final stage contains the information you need to continue to Level 3.

Useful Knowledge

You may find the following topics useful:

Linux enumeration
Linux users and permissions
SSH
SSH forwarding
Unix sockets
HTTP
Web applications
SQL injection
PostgreSQL
SQL UNION queries
Database enumeration
HTTP Basic Authentication
Base64

You are free to use whatever tools you normally use during a CTF.

Rules
Only target the BUGATHON challenge infrastructure.
Do not attack other participants.
Do not attack infrastructure outside the challenge environment.
Do not perform denial-of-service attacks.
Do not attempt to access other challenge levels unless they are explicitly available to you.
Do not intentionally damage the challenge environment.
Keep any discovered credentials and challenge information inside the competition environment.
Getting Stuck?

Don't immediately start guessing.

Go back to the last piece of information you discovered and ask:

What does this tell me?

What system does this belong to?

What can I use this information for?

Is there another service, account, file, or endpoint connected to it?

The level is designed so that the clues build on each other.

Objective

Reach the final authenticated audit stage and retrieve the information required to proceed to Level 3.

Good luck.
