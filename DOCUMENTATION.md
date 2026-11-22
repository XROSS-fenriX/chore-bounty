## 1. Project Title

# ChoreBounty
*Turning Chores into bounty*  
Gamified Household Task & Roommate Accountability System (Flutter Client + Laravel 13 REST API)  
*(Repository Workspaces: `chore_bounty_application` [Flutter Mobile Client] & `chore-bounty-api` [Laravel 13 REST API]; Presentation Reference: "ChoreBounty: System Walkthrough & Architecture")*

## 2. Project Members

* Serafica, France Aaron D.
* Bautista, Kervy S.
* Escosio, Jero
* Joven, Francis
* Alba, Lawrence

## 3. Project Overview / Description

### 3.1 Executive Summary
**ChoreBounty** is a full-stack, cross-platform mobile task management and roommate accountability system that transforms shared domestic chores into a structured, verifiable bounty marketplace. Rather than relying on informal verbal agreements, ad-hoc group messages, or passive reminders, household members publish chores with explicit token bounties and optional deadlines, claim open tasks under concurrency-safe locking, submit photographic and textual completion proof, and await verification from the task creator before points are disbursed and tallied on a competitive household leaderboard.

### 3.2 Primary Purpose & Target Users
The system is designed for co-living peers sharing domestic spaces (such as apartment roommates, dormitory suitemates, and multi-member households) who need an objective, friction-free mechanism to distribute, verify, and gamify recurring household labor. Within the household, users operate under two primary roles:

1. **Roommates (Household Members):** Co-living users belonging to one or more shared households who can post chores, claim open tasks, submit completion proof, and verify peer submissions.
2. **Household Owner (`role: owner`):** The creator of a household (or subsequent transferee) authorized to rename the household, regenerate its 8-character invite code, remove non-owner members, transfer ownership, or delete an empty household.

### 3.3 High-Level Technical Architecture & Stack
The repository is organized into two decoupled sub-projects communicating over a JSON REST API:

* **Frontend Client (`chore_bounty_application`):** Cross-platform mobile application built with Flutter (Dart) and Material 3, using Dio for REST communication, secure on-device storage for authentication tokens and active household context, and device camera/gallery integration for proof uploads.
* **Backend API (`chore-bounty-api`):** RESTful API built with Laravel 13 (PHP) and Laravel Sanctum for token-based authentication, backed by a MySQL relational database, policy-based authorization, local public disk storage for proof images, and gzip response compression.

## 4. Problems Solved by the System

Cross-referencing the problem context defined in the attached presentation storyboard with the implemented application features reveals four primary roommate coordination challenges and how ChoreBounty resolves them:

### 4.1 Invisible Domestic Labor
* **Problem:** In shared apartments and dormitories, routine chores are easily overlooked, and unacknowledged cleaning efforts create resentment when roommates have no shared record of who completed which tasks.
* **Solution:** Every completed chore is logged with timestamps, completion notes, and photographic proof. Roommates can review completed tasks, personal chore activity histories, and cumulative token totals directly through the Home Dashboard, User Profile, and Member Activity views.

### 4.2 Unverified "Done" Claims & Concurrent Claim Conflicts
* **Problem:** Self-reported task completion without oversight allows disputes over whether a chore was genuinely finished, and simultaneous claiming can cause two roommates to duplicate effort on the same task.
* **Solution:** ChoreBounty enforces a peer-verification workflow in which claimed tasks must be submitted for review and approved by the chore's creator before tokens are disbursed. If work is incomplete, the creator can use the Request Redo feature with written feedback to return the task to in-progress. Server-side concurrency protection ensures that only one roommate can claim an available chore at a time.

### 4.3 Accountability Friction & Repetitive Nagging
* **Problem:** Reminding housemates repeatedly to perform routine chores degrades interpersonal relationships and turns household coordination into nagging.
* **Solution:** ChoreBounty replaces verbal nagging with positive token incentives (10–500+ tokens), time-windowed leaderboards, live activity notifications, celebratory approval pop-ups, and deadline countdowns that automatically lock expired submissions.

### 4.4 Multi-Home Coordination & Member Departures
* **Problem:** Users frequently share multiple living spaces (such as an apartment, a family home, or a dormitory), and departing roommates can leave orphaned tasks or skew historical scores.
* **Solution:** Users can join multiple households and switch between them seamlessly, keeping each home's chore board, leaderboard, member roster, and notifications isolated. When a member leaves or is removed, their active claims are automatically reopened for other roommates, ownership transfers automatically if the owner departs, and completed chore credits earned by remaining members remain intact.

## 5. System Features

### 5.1 Authentication, Security & Profile
* **Session Recovery & Offline Access:** On launch, the application checks the saved session stored securely on the device. Expired sessions return the user to the welcome screen, while network outages preserve the login session and provide a retry screen.
* **Registration & Sign-In:** New users register with their full name, gender, email address, and an eight-character confirmed password. Returning users sign in with clear validation messages, password visibility toggles, and rate-limited login protection.
* **Profile, Avatars & Password Security:** Users can update their personal details, choose from ten built-in profile avatars (with initial-letter fallback), and change their password. Updating a password automatically signs out all other logged-in devices.
* **Account Privacy:** User profiles are visible only to members of the same household, and personal email addresses are kept private from other roommates.

### 5.2 Household Management & Multi-Home Switching
* **Creating & Joining Households:** Users can create a new household with a unique eight-character invite code or join an existing household by entering its code, which notifies current roommates of the new member.
* **Multi-Home Switching:** Users belonging to multiple households can switch between them from the dashboard banner, navigation menu, or profile page, immediately updating the displayed chores, rankings, and alerts.
* **Owner Controls:** Household owners can rename the household, generate a new invite code, transfer ownership to another member, remove members, and delete empty households that have no remaining chores or roommates.
* **Leaving a Household:** When a member leaves, their active chore claims are reopened, unapproved proof photos are deleted, and ownership automatically transfers to another member if the owner departs. Empty households with no chores are removed automatically.

### 5.3 Chore Workflow & Discovery
* **Home Dashboard:** Displays the user's earned token balance, active task count, quick status filters (*All*, *Available*, *My Chores*), tasks awaiting the user's approval, up to five available chores, and ongoing claimed chores.
* **Chore Search, Filtering & Paging:** Users can search chores by title, category, or creator, filter by status (*Available*, *In Progress*, *Completed*, or *Posted by Me* with detailed sub-filters), and browse five items per page.
* **Creating & Editing Chores:** Users can post or edit a chore with a title, optional instructions, a token reward (using manual input, quick increments, or preset amounts from 10 to 500), one of six chore categories, and an optional future deadline.
* **Claiming, Abandoning & Managing Chores:** Roommates can claim open chores posted by others (with safeguards against simultaneous claiming) or release claimed tasks back to the board. Creators can edit, cancel, or delete chores depending on their status, while past-due tasks automatically block new claims and submissions.

### 5.4 Photo Proof, Verification & Feedback
* **Uploading Completion Proof:** Before submitting a finished task for review, assignees can attach up to three compressed photos from their camera or gallery along with an optional note.
* **Viewing Proof Images:** Uploaded proof photos load reliably in small data segments and can be opened in a full-screen viewer with pinch-to-zoom support.
* **Approval, Redo Requests & Cleanup:** Chore creators review submitted proof to approve the work and award tokens, or request a redo with optional written feedback. Rejected, replaced, or deleted proof photos are automatically removed from server storage.
* **Real-Time Outcome Pop-Ups:** Regular background updates notify assignees with a celebration pop-up when a chore is approved or an alert displaying the creator's feedback when a redo is requested.

### 5.5 Notifications, Leaderboard & Reliability
* **Activity Notifications:** The application checks for updates every four seconds, groups alerts by date (*Today*, *Yesterday*, and earlier dates), displays unread counts, opens the related chore when tapped, hides self-triggered actions, and remains viewable offline using cached tasks.
* **Household Leaderboard & Member Profiles:** Ranks roommates across *Week*, *Month*, and *All time* periods with a top-three podium, fair tie handling, and clickable member profiles showing completed, ongoing, and posted chores.
* **Data Efficiency & Connection Recovery:** Server responses are compressed to reduce mobile data usage, and temporary connection errors during data loading are retried automatically.
