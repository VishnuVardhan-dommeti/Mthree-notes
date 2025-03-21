# Git Notes

## Introduction

Git is a distributed version control system (VCS) that tracks changes in your files, allowing you to revert to previous versions and collaborate with others. It's crucial for software development and any project that requires version tracking.

### Why Use Git?

-   **Version Control:** Keeps a history of changes, preventing data loss and enabling rollbacks.
-   **Collaboration:** Facilitates teamwork by managing concurrent changes.
-   **Branching and Merging:** Allows for isolated development of features and bug fixes.
-   **Backup and Recovery:** Protects against data loss due to hardware failures or accidental deletions.

## Basic Concepts

### Repository

A repository (repo) is a directory containing your project files and the Git history. It can be local (on your machine) or remote (on a server like GitHub).

### Commits

A commit is a snapshot of your project at a specific point in time. Each commit has a unique ID and a message describing the changes.

### Branches

A branch is a parallel version of your project, allowing you to work on features or bug fixes without affecting the main codebase.

### Merging

Merging combines changes from one branch into another.

## Basic Git Commands

### Initialization

-   **`git init`**: Initializes a new Git repository in the current directory.

    ```bash
    git init
    ```

-   **`git clone <repository_url>`**: Creates a copy of a remote repository.

    ```bash
    git clone [https://github.com/username/repository.git](https://github.com/username/repository.git)
    ```

### Staging and Committing

-   **`git status`**: Shows the status of your files (modified, staged, etc.).

    ```bash
    git status
    ```

-   **`git add <file>`**: Stages a file for commit.

    ```bash
    git add filename.txt
    ```

-   **`git add .`**: Stages all changes in the current directory.

    ```bash
    git add .
    ```

-   **`git commit -m "Commit message"`**: Commits the staged changes with a message.

    ```bash
    git commit -m "Added new feature"
    ```

### Branching

-   **`git branch`**: Lists all branches (current branch is marked with an asterisk).

    ```bash
    git branch
    ```

-   **`git branch <branch_name>`**: Creates a new branch.

    ```bash
    git branch feature-branch
    ```

-   **`git checkout <branch_name>`**: Switches to a branch.

    ```bash
    git checkout feature-branch
    ```

-   **`git checkout -b <branch_name>`**: Creates and switches to a new branch.

    ```bash
    git checkout -b feature-branch
    ```

-   **`git branch -d <branch_name>`**: Deletes a branch (if merged).

    ```bash
    git branch -d feature-branch
    ```

-   **`git branch -D <branch_name>`**: Force deletes a branch (even if not merged).

    ```bash
    git branch -D feature-branch
    ```

### Merging

-   **`git merge <branch_name>`**: Merges a branch into the current branch.

    ```bash
    git checkout main
    git merge feature-branch
    ```

### Remote Repositories

-   **`git remote add origin <repository_url>`**: Adds a remote repository.

    ```bash
    git remote add origin [https://github.com/username/repository.git](https://github.com/username/repository.git)
    ```

-   **`git push origin <branch_name>`**: Pushes local changes to a remote branch.

    ```bash
    git push origin main
    ```

-   **`git pull origin <branch_name>`**: Pulls changes from a remote branch.

    ```bash
    git pull origin main
    ```

### Viewing History

-   **`git log`**: Shows the commit history.

    ```bash
    git log
    ```

-   **`git log --oneline`**: Shows a condensed commit history.

    ```bash
    git log --oneline
    ```

-   **`git diff`**: Shows changes between commits or files.

    ```bash
    git diff
    ```

## Branching Strategies

### Feature Branching

  - Create a new branch for each feature or bug fix.
  - Merge the feature branch into the main branch after testing.
  - Keeps the main branch stable.

### Gitflow

- Uses multiple branches (main, develop, feature, release, hotfix).
- Provides a structured workflow for releases.

### GitHub Flow

- Simpler than Gitflow, using only main and feature branches.
- Suitable for projects with continuous deployment.

## Merging Branches

Merging combines changes from one branch into another. Git attempts to automatically merge changes, but conflicts can occur.

### Resolving Merge Conflicts

- Git marks conflicting areas in files.
- Manually edit the files to resolve the conflicts.
- Use `git add` to stage the resolved files.
- Use `git commit` to complete the merge.

## Best Practices

- Commit frequently with clear messages.
- Use branches for features and bug fixes.
- Pull changes regularly to stay up-to-date.
- Review code before merging.
- Use a consistent branching strategy.
- use a .gitignore file to prevent commiting files that should not be commited.

## Additional Resources

-      [Git Documentation](https://git-scm.com/doc)
-      [GitHub Documentation](https://docs.github.com/en)
