# Contributing to BAK

Thank you for considering contributing to **BAK**! We appreciate your time and effort to improve our project. This guide will help you get started with contributing, whether you're fixing bugs, implementing new features, or improving documentation.

## Getting Started

Before you begin contributing, please ensure you have read and understood the following:

1. **Code of Conduct**: Be sure to follow our [Code of Conduct](CODE_OF_CONDUCT.md) to create a welcoming environment for everyone.
2. **Issues**: If you're unsure what to contribute, take a look at our [Issues](https://github.com/rubentalstra/BAK/issues) page. It contains a list of bugs, feature requests, and enhancements we need help with.

### Ways to Contribute

You can contribute to **BAK** in many ways:

- Reporting bugs
- Fixing bugs
- Implementing new features
- Writing and improving documentation
- Reviewing pull requests
- Suggesting new features and ideas

## How to Contribute

### 1. Fork the Repository

Before making any changes, fork the repository:

1. Click the "Fork" button at the top right of this repository.
2. You will have a personal copy of the repository under your GitHub account.

### 2. Clone Your Fork

Clone your fork to your local development environment:

```bash
git clone https://github.com/<your-username>/BAK.git
cd BAK
```

### 3. Create a Branch

Always create a new branch for your contributions. Don’t make changes directly to the main branch.

Create a branch specific to the issue you’re working on:

```bash
git checkout -b feature/<your-feature-name>
```

### 4. Make Changes

Make your changes using a good development practice, ensuring that the code is clean, efficient, and adheres to our coding standards.

-	Write meaningful commit messages.
-	Ensure your code follows our existing architecture and patterns.

### 5. Lint and Test Your Code

Before submitting your contribution, make sure you test your changes thoroughly. If you’re adding a new feature, write appropriate tests to ensure your code works as expected.

Run the following command to lint and test your code:

```bash
flutter analyze
flutter test
```

### 6. Commit Your Changes

Once your changes are ready, commit them to your branch:

```bash
git add .
git commit -m "Description of your changes"
```

Ensure your commit message is descriptive and clear.

### 7. Push Your Changes

Push your changes to GitHub:

```bash
git push origin feature/<your-feature-name>
```

### 8. Create a Pull Request

Once your branch is pushed to GitHub, create a Pull Request (PR):

1.	Navigate to the original repository: BAK Tracker.
2.	Click on the “Pull Requests” tab.
3.	Click on “New Pull Request.”
4.	Select the branch you just pushed from your fork and submit a PR.

In the PR description, clearly explain what changes you made and why they are necessary. Link to the relevant issue if applicable.

### 9. Participate in the Review

Once you’ve created the pull request, a reviewer will go through your code. If any changes are requested, update your branch and push again. Continue this process until your contribution is approved and merged.

## Best Practices

-	Write Clean Code: Follow clean code principles. Keep your code modular, readable, and well-commented.
-	Follow Coding Standards: Ensure that your code adheres to the project’s coding standards and architecture.
-	Stay Consistent: Maintain consistency with the project’s existing code style.
-	Write Tests: Ensure your changes are covered with unit or integration tests where applicable.
-	Keep Commits Focused: Make sure each commit is focused and addresses a single issue or task. Avoid large commits that change too many things at once.

## Reporting Issues

If you come across any issues, please create an issue on the GitHub repository. When creating an issue, include as much detail as possible:

-	Steps to reproduce the issue
-	Expected behavior
-	Actual behavior
-	Screenshots (if applicable)
-	Any relevant logs or error messages

We encourage you to check existing issues before submitting a new one to avoid duplicates.

## Code of Conduct

We are committed to fostering a welcoming, inclusive, and respectful environment. Please make sure you follow our Code of Conduct in all your interactions within the community.

## License

By contributing to BAK, you agree that your contributions will be licensed under the GPL-3.0 License.

We appreciate your contributions to BAK. Your effort helps improve the app for associations, and we look forward to working together!
